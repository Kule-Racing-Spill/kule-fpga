`timescale 1ns / 1ps
`include "params.vh"

module sprite_driver(
    input wire logic clock,
    input wire logic reset,
    // write port 1
    output wire logic [18:0] wr1_addr,
    output wire logic [3:0] wr1_data,
    output wire logic wr1_en,
    // write port 2
    output wire logic [18:0] wr2_addr,
    output wire logic [3:0] wr2_data,
    output wire logic wr2_en,
    input logic fb_resetting,
    // sprite memory
    output logic sprite_r_en,
    output logic [SPRITE_ADDR_SIZE:0] sprite_r_addr,
    input logic [3:0] sprite_r_data,
    // Sprite draw queue
    output logic sprite_queue_dequeue,
    input logic sprite_queue_is_empty,
    input logic [7:0] sprite_queue_sprite_id,
    input logic [15:0] sprite_queue_sprite_x,
    input logic [15:0] sprite_queue_sprite_y,
    input logic [7:0] sprite_queue_sprite_scale,
    input logic [2:0] sw
    );

    assign sprite_r_en = 1;
    assign sprite_queue_dequeue = 0;
    
    wire logic [18:0] sr0_addr, sr1_addr;
    wire logic sr0_drawing, sr1_drawing;
    wire logic sr0_en, sr1_en;
    logic [3:0] sr0_data, sr1_data;
    
    assign wr1_addr = sr0_addr;
    assign wr1_data = sr0_data;
    assign wr1_en = sr0_drawing;
    assign sr0_en = 1;
    
    assign wr2_addr = sr1_addr;
    assign wr2_data = sr1_data;
    assign wr2_en = sr1_drawing;
    assign sr1_en = 1;
    
    logic [9:0] spr1x = 0, spr2x = 100;
    
    always_ff @(posedge fb_resetting) begin
        spr1x <= (spr1x + 1) % 800;
        spr2x <= (spr2x + 1) % 800;
    end
    
    sprite_render sr0(
        clock,
        reset || fb_resetting,
        sr0_en,
        spr1x,
        sprite_queue_sprite_y,
        sw,//sprite_queue_sprite_scale,
        sprite_r_addr,
        sprite_r_data,
        sr0_addr,
        sr0_data,
        sr0_drawing
    );
    
    /*
    sprite_render sr1(
        clock,
        reset || fb_resetting,
        sr1_en,
        spr2x,
        100,
        sr1_addr,
        sr1_data,
        sr1_drawing
    );
    */
endmodule