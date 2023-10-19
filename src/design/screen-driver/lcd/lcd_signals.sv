`timescale 1ns/1ps

module lcd_signals(
    input wire logic pixel_clock,
    input wire logic pixel_reset,
    output logic [9:0] sx,
    output logic [9:0] sy,
    output logic hsync,
    output logic vsync,
    output logic de
    );
    
    // these timing should generate a signal that differs with 8 clock cycles on how
    // many clock cycles it needs to draw at 60Hz from the vga signals
    
    // horizontal timings
    parameter H_PW = 48;
    parameter H_BP = 40;
    parameter H_FP = 64;
    parameter HA_END = 799;                         // last active horizontal pixel
    parameter HS_START = HA_END + H_FP;             // hsync starts after front porch
    parameter HS_END = HS_START + H_PW;             // hsync ends after pulse width
    parameter LINE = HS_END + H_BP;                 // last pixel on line (after back porch) (951)
    
    // vertical timings
    parameter V_PW = 1;
    parameter V_BP = 31;
    parameter V_FP = 9;
    parameter VA_END = 479;                         // end of active pixels
    parameter VS_START = VA_END + V_FP;             // vsync starts after front porch
    parameter VS_END = VS_START + V_PW;             // vsync end after pulse width
    parameter FRAME = VS_END + V_BP;                // last line on frame after back porch (520)
    
    always_comb begin
        hsync = ~(sx >= HS_START && sx < HS_END);   // invert since negative polarity
        vsync = ~(sy >= VS_START && sy < VS_END);   // invert since negative polarity
        de = (sx <= HA_END && sy <= VA_END);        // enable data when in active pixels
    end
    
    always_ff @(posedge pixel_clock) begin
        if (sx == LINE) begin
            // we reached the end of the line, set sx to 0 and check if we are done with frame as well
            sx <= 0;
            sy <= (sy == FRAME) ? 0 : sy + 1;
        end else begin
            // else increment sx
            sx <= sx + 1;
        end
        // reset positions if reset is high
        if (pixel_reset) begin
            sx <= 0;
            sy <= 0;
        end
    end
endmodule