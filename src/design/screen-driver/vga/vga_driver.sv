`timescale 1ns/1ps

module vga_driver(
    input wire logic pixel_clk,
    input wire logic rst_pixel,
    output logic vga_hsync,
    output logic vga_vsync,
    output logic [4:0] vga_red,
    output logic [4:0] vga_green,
    output logic [4:0] vga_blue,
    // RAM
    output wire [18:0] addr,
    input logic [3:0] data
    );
    
    // data enable
    logic de;
    // control signals
    logic hsync, vsync;
    // positions
    logic [9:0] sx, sy;
    // color
    logic [14:0] current_color;
    
    // generate signals
    vga_signals vga_signals(pixel_clk, rst_pixel, sx, sy, hsync, vsync, de);
    
    // fetch the color on position sx, sy
    vga_color vga_color(sx, sy, current_color, addr, data);
    
    always_ff @(posedge pixel_clk) begin
        // send sync signals
        vga_hsync <= hsync;
        vga_vsync <= vsync;
        
        // should we draw?
        vga_red <= (de) ? current_color[14:10] : 5'b00000;
        vga_green <= (de) ? current_color[9:5] : 5'b00000;
        vga_blue <= (de) ? current_color[4:0] : 5'b00000;
    end
endmodule