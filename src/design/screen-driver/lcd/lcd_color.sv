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
    // variables for counting
    integer i;
    
    // color array. Contains 16 24-bit colors
    logic [23:0] colors [0:15];
    
    // TODO: fill with better colors
    initial begin
        for (i = 2; i < 16; i = i + 1) colors[i] <= 24'h0E7007 + i;
        colors[0] <= 24'h00AAE4;
        colors[1] <= 24'h04A443;
    end
    
    // drive color specified by index
    always_comb begin
        color <= colors[index];
    end
endmodule
