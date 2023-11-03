`timescale 1ns / 1ps


module vga_signals(
    input wire logic pixel_clk,     // pixel clock, see calculations.md for details
    input wire logic rst_pixel,     // reset pixel
    output logic [9:0] sx,          // x position
    output logic [9:0] sy,          // y position
    output logic hsync,             // horizontal sync
    output logic vsync,             // vertical sync
    output logic de                 // data enable
    );
    
    // timings are fetched from https://tomverbeure.github.io/video_timings_calculator
    // with w = 800, h = 480, refresh = 60Hz
    // horizontal timings
    parameter HA_END = 799;             // last active horizontal pixel
    parameter HS_START = HA_END + 24;   // hsync starts after front porch
    parameter HS_END = HS_START + 72;   // hsync ends after 72 clock cycles
    parameter LINE = 991;               // last pixel on line (after back porch)
    
    // vertical timings
    parameter VA_END = 479;             // end of active pixels
    parameter VS_START = VA_END + 3;    // vsync starts after front porch
    parameter VS_END = VS_START + 7;    // vsync end after 7 clock cycles
    parameter FRAME = 499;              // last line on frame after back porch
    

    // set control signals (hsync, vsync and de)
    always_comb begin
        hsync = ~(sx >= HS_START && sx < HS_END);   // invert since negative polarity
        vsync = ~(sy >= VS_START && sy < VS_END);   // invert since negative polarity
        de = (sx <= HA_END && sy <= VA_END);        // enable data when in active pixels
    end
    
    
    // decide horizontal and vertical position
    always_ff @(posedge pixel_clk) begin
        if (sx == LINE) begin
            // we reached the end of the line, set sx to 0 and check if we are done with frame as well
            sx <= 0;
            sy <= (sy == FRAME) ? 0 : sy + 1;
        end else begin
            // else increment sx
            sx <= sx + 1;
        end
        // reset positions if reset is high
        if (rst_pixel) begin
            sx <= 0;
            sy <= 0;
        end
    end
endmodule