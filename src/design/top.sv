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
    
    // for now, pin reset to low
    logic reset = 0;
    
    // VGA takes the most time to draw active pixels, therefore
    // the global vsync should follow this
    wire logic global_vsync;
    assign global_vsync = vga_vsync;
    
    // address and data buses for the screen drivers
    wire logic [18:0] addr_vga, addr_lcd, addr_wr1, addr_wr2;
    wire logic [3:0] data_wr1, data_wr2;
    wire logic wr1_en, wr2_en;

    reg [3:0] data_vga, data_lcd;

    framebuffer_master fb_master(
        clock,
        reset,
        global_vsync,
        addr_vga,
        data_vga,
        addr_lcd,
        data_lcd,
        addr_wr1,
        addr_wr2,
        data_wr1,
        data_wr2,
        wr1_en,
        wr2_en
    );
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
        addr_vga,
        data_vga,
        addr_lcd,
        data_lcd
    );
endmodule
