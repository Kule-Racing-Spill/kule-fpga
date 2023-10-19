`timescale 1ns/1ps

module lcd_color(
    input wire logic pixel_clk,
    input logic [9:0] sx,
    input logic [9:0] sy,
    output logic [23:0] color,
    // RAM
    input reg [3:0] ram [0:383999]
    );
    // index in colormap
    logic [3:0] index;
    
    parameter MAX_SX = 799;
    parameter MAX_SY = 479;
    
    always_ff @(posedge pixel_clk) begin
        if (sx <= MAX_SX && sy <= MAX_SY) begin
            // fetch the index
            index <= ram[sy * 800 + sx];
        end
    end
    
    // fetch the color
    lcd_colormap(index, color);
endmodule

module lcd_colormap(
    input logic [3:0] index,
    output logic [23:0] color
    );
    // variables for counting
    integer i;
    integer n;
    
    // color array. Contains 16 24-bit colors
    reg [23:0] colors [0:15];
    
    // TODO: fill with better colors
    initial begin
        for (i = 0; i < 8; i = i + 1) colors[i] <= 24'h000000 + i;
        for (n = 8; n < 16; n = n + 1) colors[n] <= 24'hffffff - n;
    end
    
    // drive color specified by index
    assign color = colors[index];
endmodule