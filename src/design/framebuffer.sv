`timescale 1ns/1ps

module framebuffer_master(
    input wire logic clock,
    input wire logic reset,
    input wire logic vsync,
    
    // READ VGA
    input [18:0] addr_vga,
    output reg [3:0] data_vga,
    
    // READ LCD
    input [18:0] addr_lcd,
    output reg [3:0] data_lcd,
    
    // write
    input [18:0] addr_wr1,
    input [18:0] addr_wr2,
    input [3:0] data_wr1,
    input [3:0] data_wr2,
    input wr1_en,
    input wr2_en
    );
    
    logic old_vsync;
    logic read_pick = 0;

    // aliases
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
    
    // use vsync to switch buffers
    always_ff @(posedge clock) begin
        // only flip read_pick at negative edge
        if (old_vsync != vsync && ~vsync) begin
            // switch buffers
            read_pick <= ~read_pick;
        end
        // set old_vsync to current vsync so we dont flip read_pick all the time when vsync is low
        old_vsync <= vsync;

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
        clock,
        // port 1
        fb0_wr1_en,
        fb0_addr1,
        fb0_dataw1,
        fb0_datar1,
        // port 2
        fb0_wr2_en,
        fb0_addr2,
        fb0_dataw2,
        fb0_datar2
    );

    // framebuffer 2
    framebuffer fb1(
        clock,
        // port 1
        fb1_wr1_en,
        fb1_addr1,
        fb1_dataw1,
        fb1_datar1,
        // port 2
        fb1_wr2_en,
        fb1_addr2,
        fb1_dataw2,
        fb1_datar2
    );
endmodule


module framebuffer(
    input wire logic clock,
    // R/W port 1
    input logic fb_wr1_en,          // active high. Low means read
    input logic [18:0] fb_addr_1,   // address bus for R/W port 1
    input logic [3:0] fb_dataw_1,    // input data to port 1 (if we write)
    output logic [3:0] fb_datar_1,   // output data from port 1 (if we read)
    // R/W port 2
    input logic fb_wr2_en,
    input logic [18:0] fb_addr_2,
    input logic [3:0] fb_dataw_2,
    output logic [3:0] fb_datar_2
    );
    
    // initialize ram
    reg [3:0] ram [0:383999];
    integer i, n;
    
    initial begin
        for (i = 0; i < 191999; i = i + 1) ram[i] <= 4'b1111;
        for (n = 192000; i < 383999; n = n + 1) ram[n] <= 4'b0000;
    end

    always @(posedge clock) begin
        // R/W port 1
        if (fb_wr1_en) begin
            ram[fb_addr_1] <= fb_dataw_1;
        end else begin
            fb_datar_1 <= ram[fb_addr_1];
        end

        // R/W port 2
        if (fb_wr2_en) begin
            ram[fb_addr_2] <= fb_dataw_2;
        end else begin
            fb_datar_2 <= ram[fb_addr_2];
        end
    end

endmodule