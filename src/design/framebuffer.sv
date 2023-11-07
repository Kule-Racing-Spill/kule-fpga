`timescale 1ns/1ps
`include "params.vh"

module framebuffer_master(
    input wire logic read_clock,
    input wire logic write_clock,
    input wire logic reset,
    input wire logic vsync,
    
    // READ VGA
    input wire [18:0] addr_vga,
    output logic [3:0] data_vga,
    
    // READ LCD
    input wire [18:0] addr_lcd,
    output logic [3:0] data_lcd,
    
    // write
    input wire [18:0] addr_wr1,
    input wire [18:0] addr_wr2,
    input wire [3:0] data_wr1,
    input wire [3:0] data_wr2,
    input wire wr1_en,
    input wire wr2_en,
    input logic bram_en
    );
    logic [3:0] count = 0;

    logic old_vsync;
    logic read_pick = 0;

    // aliases
    wire logic fb0_clock, fb1_clock;
    // write signals
    logic fb0_wr1_en, fb0_wr2_en, fb1_wr1_en, fb1_wr2_en;
    // address busses
    logic [18:0] fb0_addr1, fb0_addr2, fb1_addr1, fb1_addr2;
    // input data busses
    logic [3:0] fb0_dataw1, fb0_dataw2, fb1_dataw1, fb1_dataw2;
    // output data busses
    logic [3:0] fb0_datar1, fb0_datar2, fb1_datar1, fb1_datar2;

    // temporary storage for output data when framebuffer is write-only
    logic [3:0] fb_data_temp1, fb_data_temp2;
    
    assign fb0_clock = (!read_pick) ? read_clock : write_clock;
    assign fb1_clock = (read_pick) ? write_clock : read_clock;

    always_ff @(posedge read_clock) begin
        // only flip read_pick at negative edge
        if (old_vsync != vsync && ~vsync) begin
            // switch buffers
            if (count == 4'hF) begin
                read_pick <= ~read_pick;
                count <= 0;
            end else count <= count + 1;
        end
        old_vsync <= vsync;
    end

    // use vsync to switch buffers
    always_comb begin
        // set old_vsync to current vsync so we dont flip read_pick all the time when vsync is low

        if (read_pick) begin
            // read from fb1
            fb1_wr1_en <= 0;
            fb1_wr2_en <= 0;

            // port 1 (VGA)
            fb1_addr1 <= addr_vga;
            data_vga <= fb1_datar1;
            fb1_dataw1 <= 4'b0000;

            // port 2 (LCD)
            fb1_addr2 <= addr_lcd;
            data_lcd <= fb1_datar2;
            fb1_dataw2 <= 4'b0000;

            // write to fb0
            fb0_wr1_en <= wr1_en;
            fb0_wr2_en <= wr2_en;

            // addresses
            fb0_addr1 <= addr_wr1;
            fb0_addr2 <= addr_wr2;

            // input data
            fb0_dataw1 <= data_wr1;
            fb0_dataw2 <= data_wr2;

            // output data
            fb_data_temp1 <= fb0_datar1;
            fb_data_temp2 <= fb0_datar2;
        end else begin
            // read from fb0
            fb0_wr1_en <= 0;
            fb0_wr2_en <= 0;

            // port 1 (VGA)
            fb0_addr1 <= addr_vga;
            data_vga <= fb0_datar1;
            fb0_dataw1 <= 4'b0000;

            // port 2 (LCD)
            fb0_addr2 <= addr_lcd;
            data_lcd <= fb0_datar2;
            fb0_dataw2 <= 4'b0000;

            // write to fb1
            fb1_wr1_en <= wr1_en;
            fb1_wr2_en <= wr2_en;

            // addresses
            fb1_addr1 <= addr_wr1;
            fb1_addr2 <= addr_wr2;

            // input data
            fb1_dataw1 <= data_wr1;
            fb1_dataw2 <= data_wr2;

            // output data
            fb_data_temp1 <= fb1_datar1;
            fb_data_temp2 <= fb1_datar2;
        end
    end

    // framebuffer 1
    framebuffer fb0(
        fb0_clock,
        // port 1
        fb0_wr1_en,
        fb0_addr1,
        fb0_dataw1,
        fb0_datar1,
        // port 2
        fb0_wr2_en,
        fb0_addr2,
        fb0_dataw2,
        fb0_datar2,
        bram_en,
        0
    );

    // framebuffer 2
    framebuffer fb1(
        fb1_clock,
        // port 1
        fb1_wr1_en,
        fb1_addr1,
        fb1_dataw1,
        fb1_datar1,
        // port 2
        fb1_wr2_en,
        fb1_addr2,
        fb1_dataw2,
        fb1_datar2,
        bram_en,
        1
    );
endmodule


module framebuffer(
    input wire logic clock,
    // R/W port 1
    input wire logic fb_wr1_en,          // active high. Low means read
    input wire logic [18:0] fb_addr_1,   // address bus for R/W port 1
    input wire logic [3:0] fb_dataw_1,    // input data to port 1 (if we write)
    output logic [3:0] fb_datar_1,   // output data from port 1 (if we read)
    // R/W port 2
    input wire logic fb_wr2_en,
    input wire logic [18:0] fb_addr_2,
    input wire logic [3:0] fb_dataw_2,
    output logic [3:0] fb_datar_2,
    input wire logic en,
    input logic reversed
    );

    // initialize ram
    logic [3:0] ram [FRAMEBUFFER_SIZE-1:0];
   
    initial begin
        // give it start data
        $readmemb("fb_data.data", ram);
    end

    always @(posedge clock) begin
        // R/W port 1
        if (en) begin
            if (fb_wr1_en) begin
                ram[fb_addr_1] <= fb_dataw_1;
            end
            fb_datar_1 <= ram[fb_addr_1];
        end
    end

    always @(posedge clock) begin
        if (en) begin
            if (fb_wr2_en) begin
                ram[fb_addr_2] <= fb_dataw_2;
            end
            fb_datar_2 <= ram[fb_addr_2];
        end
    end
endmodule