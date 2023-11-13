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
    output logic [7:0] lcd_blue,
    // SPI
    input logic spi_cs,
    input logic spi_clk,
    input logic spi_mosi,
    output logic spi_miso,
    input logic [2:0] sw
);
    // Sprite memory interface
    logic sprite_r_en;
    logic [SPRITE_ADDR_SIZE:0] sprite_r_addr;
    logic [3:0] sprite_r_data;

    // Sprite draw queue interface
    logic sprite_queue_dequeue;
    logic sprite_queue_is_empty;
    logic [7:0] sprite_queue_sprite_id;
    logic [15:0] sprite_queue_sprite_x;
    logic [15:0] sprite_queue_sprite_y;
    logic [7:0] sprite_queue_sprite_scale;

    // SPI reader module
    spi_driver spi(
        .clock,
        .spi_mosi,
        .spi_miso,
        .spi_clk,
        .spi_cs,
        .sprite_r_en,
        .sprite_r_addr,
        .sprite_r_data,
        .dequeue(sprite_queue_dequeue),
        .is_empty(sprite_queue_is_empty),
        .sprite_id(sprite_queue_sprite_id),
        .sprite_x(sprite_queue_sprite_x),
        .sprite_y(sprite_queue_sprite_y),
        .sprite_scale(sprite_queue_sprite_scale)
    );
    
    // for now, pin reset to low
    logic reset = 0;
    
    // VGA takes the most time to draw active pixels, therefore
    // the global vsync should follow this
    wire logic global_vsync;
    assign global_vsync = vga_vsync;
    
    // address and data buses for the screen drivers
    wire logic [18:0] addr_vga, addr_lcd;
    wire logic [18:0] addr_wr1;
    wire logic [18:0] addr_wr2;
    wire logic [3:0] data_wr1;
    wire logic [3:0] data_wr2;
    wire logic wr1_en; 
    wire logic wr2_en;
    
    // clock and lock signal for clocking wizard
    wire logic pixel_clk;
    logic locked;
            
    // generate pixel clock
    pixel_clock_wiz pix_clock(
        .clk_in(clock),
        .clk_out(pixel_clk),
        .locked(locked),
        .reset(reset)
    );
    
    // framebuffer reset
    logic fb_resetting;
    
    // color index for vga and lcd
    logic [3:0] data_vga, data_lcd;
    
    // initiate framebuffers
    framebuffer_master fb_master(
        pixel_clk,
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
        fb_resetting
    );

    // initiate screen_driver module
    screen_driver sd(
        pixel_clk,
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
    

    sprite_driver spr_driver(
        pixel_clk,
        !locked,
        addr_wr1,
        data_wr1,
        wr1_en,
        addr_wr2,
        data_wr2,
        wr2_en,
        fb_resetting,
        sprite_r_en,
        sprite_r_addr,
        sprite_r_data,
        sprite_queue_dequeue,
        sprite_queue_is_empty,
        sprite_queue_sprite_id,
        sprite_queue_sprite_x,
        sprite_queue_sprite_y,
        sprite_queue_sprite_scale,
        sw
    );

endmodule
