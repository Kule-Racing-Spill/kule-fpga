`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/06/2023 10:50:00 AM
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module vga_color(
    input wire logic pixel_clk,
    input logic [9:0] sx,
    input logic [9:0] sy,
    output logic [14:0] color,
    // RAM
    output wire [18:0] addr,
    input reg [3:0] data
    );
    
    parameter MAX_SX = 799;
    parameter MAX_SY = 479;
    
    // fetch the next color
    assign addr = (sx <= MAX_SX && sy <= MAX_SY) ? (sy * 800 + sx) : 0;
    
    // fetch the color from the colormap
    vga_colormap vga_col(pixel_clk, data, color);
endmodule

module vga_colormap(
    input wire logic pixel_clk,
    input logic [3:0] index,
    output logic [14:0] color
    );
    // counter variables
    integer i = 0;
    integer n = 0;
    
    // color array. Contains 16 15-bit colors
    reg [14:0] colors [0:15];
    
    // TODO: set better colors
    initial begin
        for (i = 0; i < 8; i = i + 1) colors[i] <= 15'b000000000000000 + i;
        for (n = 8; n < 16; n = n + 1) colors[n] <= 15'b111111111111111 - n;
    end
    
    // drive the color
    always_ff @(posedge pixel_clk) begin
        color <= colors[index];
    end
endmodule