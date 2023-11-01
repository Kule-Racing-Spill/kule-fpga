`timescale 1ns/1ps

module screen_driver(
    input wire logic clock,
    input wire logic reset,
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
    output logic [7:0] lcd_blue,
    
    // RAM interface
    output wire [18:0] addr_vga,
    input reg [3:0] data_vga,
    output wire [18:0] addr_lcd,
    input reg [3:0] data_lcd
    );
    
    // wire for pixel clock, reset and locked from clocking wizard
    wire logic pixel_clock;
    logic locked, pixel_reset;
    
    /*
    // generate pixel clock
    pixel_clock_wiz pix_clock(
        .clk_in(clock),
        .clk_out(pixel_clock),
        .locked(locked),
        .reset(reset)
    );
    */
    assign pixel_clock = clock;
    
    // set pixel reset either when clocking wizard is setting up or when reset signal is given
    assign pixel_reset = reset;

    // initiate vga driver
    vga_driver vga_driver(
        pixel_clock,
        pixel_reset,
        vga_hsync,
        vga_vsync,
        vga_red,
        vga_green,
        vga_blue,
        addr_vga,
        data_vga
    );
    
    // initiate lcd driver
    lcd_driver lcd_driver(
        pixel_clock,
        pixel_reset,
        lcd_de,
        lcd_hsync,
        lcd_vsync,
        lcd_red,
        lcd_green,
        lcd_blue,
        addr_lcd,
        data_lcd
    );
endmodule