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
    // counter variables
    integer i = 0;
    
    // color array. Contains 16 15-bit colors
    reg [14:0] colors [0:15];
    
    // TODO: set better colors
    initial begin
        for (i = 2; i < 16; i = i + 1) colors[i] <= 15'b101010101010101 + i;
        colors[0] <= 15'b000000101001101;
        colors[1] <= 15'b000110101000010;
    end
    
    // drive the color
    always_comb begin
        color <= colors[index];
    end
endmodule
