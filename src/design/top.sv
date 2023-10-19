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


module top(
    input wire logic clock,
    // todo, add reset signal
    // VGA
    output logic vga_hsync,
    output logic vga_vsync,
    output logic [4:0] vga_red,
    output logic [4:0] vga_green,
    output logic [4:0] vga_blue,
    // LCD
    output logic lcd_de,
    output logic lcd_hsync,
    output logic lcd_vsync,
    output logic [7:0] lcd_red,
    output logic [7:0] lcd_green,
    output logic [7:0] lcd_blue
    );
    
    // counter variables, TODO: remove
    integer i = 0;
    integer n = 0;
    
    // bram for framebuffer
    // TODO: move to separate module
    reg [3:0] ram [0:383999];
    
    // set some initial data in the framebuffers
    initial begin
        for (i = 0; i < 191999; i = i + 1) ram[i] <= 14;
        for (n = 192000; i < 383999; n = n + 1) ram[n] <= 0;
    end
    
    // for now, pin reset to low
    logic reset = 0;
    
    // initiate screen_driver module
    screen_driver sd(
        clock,
        reset,
        vga_hsync,
        vga_vsync,
        vga_red,
        vga_green,
        vga_blue,
        lcd_de,
        lcd_hsync,
        lcd_vsync,
        lcd_red,
        lcd_green,
        lcd_blue,
        ram
    );
endmodule
