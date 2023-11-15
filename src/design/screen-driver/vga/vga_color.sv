`timescale 1ns / 1ps
`include "params.vh"


module vga_color(
    input logic [9:0] sx,
    input logic [9:0] sy,
    output logic [14:0] color,
    // RAM
    output wire [18:0] addr,
    input logic [3:0] data
    );
    
    parameter MAX_SX = 799;
    parameter MAX_SY = 479;
    
    // fetch the next color
    // nasty hack so it supports both a35t and a100t
    assign addr = (sx <= MAX_SX && sy <= MAX_SY) ? (FRAMEBUFFER_SIZE > 192000 ? (sy * 800 + sx) : (sy * 800 + sx) / 2) : 0;
    
    // fetch the color from the colormap
    vga_colormap vga_col(data, color);
endmodule

module vga_colormap(
    input logic [3:0] index,
    output logic [14:0] color
    );
    
    // color array. Contains 16 15-bit colors
    reg [14:0] colors [0:15];
    
    initial begin
        colors[0] <= 15'b000100001000010; // Dark grey (#232228)
        colors[1] <= 15'b001010010100100; // grey (#5f5854)
        colors[2] <= 15'b010100101001000; // light grey / beige (#b8b095)
        colors[3] <= 15'b000100001100101; // dark blue (#284261)
        colors[4] <= 15'b000100011101001; // blue (#2485a6)
        colors[5] <= 15'b001000101001100; // sky blue (#54bad2)
        colors[6] <= 15'b001100010000100; // brown (#754d45)
        colors[7] <= 15'b010110010000100; // red (#c65046)
        colors[8] <= 15'b011010100001000; // pink (#e6928a)
        colors[9] <= 15'b000010011000100; // dark green (#1e7453)
        colors[10] <= 15'b001010100100101; // green (#55a058)
        colors[11] <= 15'b010010101100011; // light green (#a1bf41)
        colors[12] <= 15'b011010101100100; // yellow (#e3c054)
        colors[13] <= 15'b010110110001011; // green-white (#c3d5c7)
        colors[14] <= 15'b011010110101100; // off-white (#ebecdc)
        // colors[15] is transparent
        colors[15] <= 15'b000000000000000;
    end
    
    // drive the color
    always_comb begin
        color <= colors[index];
    end
endmodule
