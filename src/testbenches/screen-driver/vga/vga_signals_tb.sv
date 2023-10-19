`timescale 1ns/1ps

module vga_signals_tb(
    );
    // set up clock
    logic clk;
    logic rst_pixel;
    logic hsync;
    logic vsync;
    logic [9:0] sx;
    logic [9:0] sy;
    logic de;
    initial begin
        $monitor ("hsync=%b, vsync=%b, sx=%i, sy=%i, de=%b", hsync, vsync, sx, sy, de);
        clk <= 0;
        rst_pixel <= 0;
    end
    always #10 clk <= ~clk;
    
    vga_signals vga_sig(clk, rst_pixel, sx, sy, hsync, vsync, de);
    
endmodule