`timescale 1ns / 1ps
`include "params.vh"


module top (
    input wire logic clock,
    // todo, add reset signal
    //input wire logic reset_btn,
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
    wire logic [18:0] addr_vga, addr_lcd;
    wire logic [18:0] addr_wr1 = 0, addr_wr2 = 0;
    wire logic [3:0] data_wr1 = 0, data_wr2 = 0;
    wire logic wr1_en = 0, wr2_en = 0;
    
    // clock and lock signal for clocking wizard
    wire logic clk;
    logic locked;
    
    // generate pixel clock
    pixel_clock_wiz pix_clock(
        .clk_in(clock),
        .clk_out(clk),
        .locked(locked),
        .reset(reset)
    );
    
    // enable bram
    logic bram_en = 1;
    
    // color index for vga and lcd
    logic [3:0] data_vga, data_lcd;
    
    // initiate framebuffers
    framebuffer_master fb_master(
        clk,
        !locked,
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
        wr2_en,
        bram_en
    );

    // initiate screen_driver module
    screen_driver sd(
        clk,
        !locked,
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
