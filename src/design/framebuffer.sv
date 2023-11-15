`timescale 1ns/1ps
`include "params.vh"

module framebuffer_reset(
    input wire logic clock,
    input wire logic reset,
    input logic enable,
    output logic finished,
    // ports
    output logic [18:0] addr_wr1,
    output logic [3:0] data_wr1,
    output logic wr1_en,
    output logic [18:0] addr_wr2,
    output logic [3:0] data_wr2,
    output logic wr2_en
    );
    
    // internal variables
    logic [$clog2(FRAMEBUFFER_SIZE):0] counter = 0;
    logic enable_internal = 0;
    logic finished_internal = 0;
    
    always_ff @(posedge clock) begin
        // if we have a positive edge on the enable signal, reset the counter
        if (enable_internal != enable && enable) begin
            counter <= 0;
        end
        
        // set internal enable
        enable_internal <= enable;
        
        // if enabled start counting and check if reset of fb is finished
        if (enable_internal) begin
            counter <= counter + 2;
            if (counter >= FRAMEBUFFER_SIZE - 2) begin
                finished_internal <= 1;
            end else finished_internal <= 0;
        end else finished_internal <= 0;
        
        // reset
        if (reset) begin
            counter <= 0;
            finished_internal <= 0;
        end
    end
    
    always_comb begin
        wr1_en <= enable;
        wr2_en <= enable;
        addr_wr1 <= counter;
        addr_wr2 <= counter + 1;
        data_wr1 <= (counter >= FRAMEBUFFER_SIZE / 4) ? 4'b1011 : 4'b0101;
        data_wr2 <= (counter + 1 >= FRAMEBUFFER_SIZE / 4) ? 4'b1011 : 4'b0101;
        finished <= finished_internal;
    end
endmodule

module framebuffer_master(
    input wire logic clock,
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
    
    // framebuffer reset
    output logic fb_resetting
    );

    logic old_vsync;
    logic read_pick = 0;
    logic [4:0] framerate_transformer = 0;
    
    // reset signals
    logic fb_reset_finished, fb_reset_enable;
    // reset busses
    logic [18:0] fb_reset_addr1, fb_reset_addr2;
    logic [3:0] fb_reset_data1, fb_reset_data2;
    logic fb_reset_wr1, fb_reset_wr2;

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
        if (old_vsync != vsync && ~vsync) begin
            // switch buffers
            if (framerate_transformer == 8) begin
                framerate_transformer <= 0;
                read_pick <= ~read_pick;
                fb_resetting <= 1;
                fb_reset_enable <= 1;
            end else framerate_transformer <= framerate_transformer + 1;
        end
        // set old_vsync to current vsync so we dont flip read_pick all the time when vsync is low
        old_vsync <= vsync;
        
        if (fb_reset_finished) begin
            fb_reset_enable <= 0;
            fb_resetting <= 0;
        end
    end

    always_comb begin
        
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
            // check if we are resetting
            if (fb_reset_enable) begin
                fb0_wr1_en <= fb_reset_wr1;
                fb0_wr2_en <= fb_reset_wr2;
    
                // addresses
                fb0_addr1 <= fb_reset_addr1;
                fb0_addr2 <= fb_reset_addr2;
    
                // input data
                fb0_dataw1 <= fb_reset_data1;
                fb0_dataw2 <= fb_reset_data2;
            end else begin
                fb0_wr1_en <= wr1_en;
                fb0_wr2_en <= wr2_en;
    
                // addresses
                fb0_addr1 <= addr_wr1;
                fb0_addr2 <= addr_wr2;
    
                // input data
                fb0_dataw1 <= data_wr1;
                fb0_dataw2 <= data_wr2;
            end

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
            // check if we are resetting
            if (fb_reset_enable) begin
                fb1_wr1_en <= fb_reset_wr1;
                fb1_wr2_en <= fb_reset_wr2;
    
                // addresses
                fb1_addr1 <= fb_reset_addr1;
                fb1_addr2 <= fb_reset_addr2;
    
                // input data
                fb1_dataw1 <= fb_reset_data1;
                fb1_dataw2 <= fb_reset_data2;
            end else begin
                fb1_wr1_en <= wr1_en;
                fb1_wr2_en <= wr2_en;
    
                // addresses
                fb1_addr1 <= addr_wr1;
                fb1_addr2 <= addr_wr2;
    
                // input data
                fb1_dataw1 <= data_wr1;
                fb1_dataw2 <= data_wr2;
            end

            // output data
            fb_data_temp1 <= fb1_datar1;
            fb_data_temp2 <= fb1_datar2;
        end
    end
    
    framebuffer_reset(
        clock,
        reset,
        fb_reset_enable,
        fb_reset_finished,
        fb_reset_addr1,
        fb_reset_data1,
        fb_reset_wr1,
        fb_reset_addr2,
        fb_reset_data2,
        fb_reset_wr2
    );
    
    framebuffer_bram fb0(
        // PORT A
        .addra(fb0_addr1[17:0]),
        .clka(clock),
        .dina(fb0_dataw1),
        .douta(fb0_datar1),
        .wea(fb0_wr1_en),
        //PORT B
        .addrb(fb0_addr2[17:0]),
        .clkb(clock),
        .dinb(fb0_dataw2),
        .doutb(fb0_datar2),
        .web(fb0_wr2_en)
    );
    
    framebuffer_bram fb1(
        // PORT A
        .addra(fb1_addr1[17:0]),
        .clka(clock),
        .dina(fb1_dataw1),
        .douta(fb1_datar1),
        .wea(fb1_wr1_en),
        //PORT B
        .addrb(fb1_addr2[17:0]),
        .clkb(clock),
        .dinb(fb1_dataw2),
        .doutb(fb1_datar2),
        .web(fb1_wr2_en)
    );
endmodule
