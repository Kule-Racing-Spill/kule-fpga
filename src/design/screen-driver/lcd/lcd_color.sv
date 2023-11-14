`timescale 1ns/1ps
`include "params.vh"

module lcd_color(
    input logic [9:0] sx,
    input logic [9:0] sy,
    output logic [23:0] color,
    // RAM
    output wire [18:0] addr,
    input logic [3:0] data
    );
    
    parameter MAX_SX = 799;
    parameter MAX_SY = 479;
    
    assign addr = (sx <= MAX_SX && sy <= MAX_SY) ? (FRAMEBUFFER_SIZE > 192000 ? (sy * 800 + sx) : (sy * 800 + sx) / 2) : 0;

    // fetch the color
    lcd_colormap colormap(data, color);
endmodule

module lcd_colormap(
    input logic [3:0] index,
    output logic [23:0] color
    );    
    // color array. Contains 16 24-bit colors
    logic [23:0] colors [0:15];
    
    initial begin
        colors[0] <= 24'h232228;
        colors[1] <= 24'h5f5854;
        colors[2] <= 24'hb8b095;
        colors[3] <= 24'h284261;
        colors[4] <= 24'h2485a6;
        colors[5] <= 24'h54bad2;
        colors[6] <= 24'h754d45;
        colors[7] <= 24'hc65046;
        colors[8] <= 24'he6928a;
        colors[9] <= 24'h1e7453;
        colors[10] <= 24'h55a058;
        colors[11] <= 24'ha1bf41;
        colors[12] <= 24'he3c054;
        colors[13] <= 24'hc3d5c7;
        colors[14] <= 24'hebecdc;
        colors[15] <= 24'h000000;
    end
    
    // drive color specified by index
    always_comb begin
        color <= colors[index];
    end
endmodule
