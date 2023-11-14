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
    output logic [$clog2(SPRITE_NUM)-1:0] sprite_r0_select,
    output logic [SPRITE_ADDR_SIZE:0] sprite_r0_addr,
    input logic [3:0] sprite_r0_data,
    output logic [$clog2(SPRITE_NUM)-1:0] sprite_r1_select,
    output logic [SPRITE_ADDR_SIZE:0] sprite_r1_addr,
    input logic [3:0] sprite_r1_data,
    // Sprite draw queue
    output logic sprite_queue_dequeue,
    input logic sprite_queue_is_empty,
    input logic [7:0] sprite_queue_sprite_id,
    input logic [15:0] sprite_queue_sprite_x, sprite_queue_sprite_y,
    input logic [7:0] sprite_queue_sprite_scale
    );
    
    wire logic [18:0] sr0_addr, sr1_addr;
    logic [3:0] sr0_data, sr1_data;
    wire logic sprite0_drawing, sprite1_drawing;
    wire logic sprite0_en, sprite1_en;
    logic [15:0] sprite0_x, sprite0_y, sprite1_x, sprite1_y;
    logic [7:0] sprite0_scale, sprite1_scale;
    logic sprite0_finished, sprite1_finished;
    
    assign wr1_addr = sr0_addr;
    assign wr1_data = sr0_data;
    assign wr1_en = sprite0_drawing;
    
    assign wr2_addr = sr1_addr;
    assign wr2_data = sr1_data;
    assign wr2_en = sprite1_drawing;

    sprite_distributor sd(
        .clock,
        .sprite_queue_dequeue,
        .sprite_queue_is_empty,
        .sprite_queue_sprite_id,
        .sprite_queue_sprite_x,
        .sprite_queue_sprite_y,
        .sprite_queue_sprite_scale,
        .sprite0_en,
        .sprite0_id(sprite_r0_select),
        .sprite0_x,
        .sprite0_y,
        .sprite0_scale,
        .sprite0_finished,
        .sprite1_en,
        .sprite1_id(sprite_r1_select),
        .sprite1_x,
        .sprite1_y,
        .sprite1_scale,
        .sprite1_finished
    );
    
    logic [9:0] spr1x = 0, spr2x = 100;
    
    always_ff @(posedge fb_resetting) begin
        spr1x <= (spr1x + 1) % 800;
        spr2x <= (spr2x + 1) % 800;
    end
    
    sprite_render sr0(
        .clk(clock),
        .rst(reset || fb_resetting),
        .enable(sprite0_en),
        .sx(sprite0_x),
        .sy(sprite0_y),
        .sprite_scale(sprite0_scale),
        .sprite_r_addr(sprite_r0_addr),
        .sprite_r_data(sprite_r0_data),
        .addr(sr0_addr),
        .pix(sr0_data),
        .drawing(sr0_drawing),
        .finished(sprite0_finished)
    );
    
    sprite_render sr1(
        .clk(clock),
        .rst(reset || fb_resetting),
        .enable(sprite1_en),
        .sx(sprite1_x),
        .sy(sprite1_y),
        .sprite_scale(sprite1_scale),
        .sprite_r_addr(sprite_r1_addr),
        .sprite_r_data(sprite_r1_data),
        .addr(sr1_addr),
        .pix(sr1_data),
        .drawing(sr1_drawing),
        .finished(sprite0_finished)
    );
endmodule

module sprite_distributor (
    input logic clock,
    // main sprite queue interface
    output logic sprite_queue_dequeue,
    input logic sprite_queue_is_empty,
    input logic [7:0] sprite_queue_sprite_id,
    input logic [15:0] sprite_queue_sprite_x, sprite_queue_sprite_y,
    input logic [7:0] sprite_queue_sprite_scale,
    // sprite render 0
    output logic sprite0_en,
    output logic [7:0] sprite0_id,
    output logic [15:0] sprite0_x, sprite0_y,
    output logic [7:0] sprite0_scale,
    input logic sprite0_finished,
    // sprite render 1
    output logic sprite1_en,
    output logic [7:0] sprite1_id,
    output logic [15:0] sprite1_x, sprite1_y,
    output logic [7:0] sprite1_scale,
    input logic sprite1_finished
);
    always_ff @(posedge clock) begin
        if (sprite_queue_dequeue) begin
            sprite_queue_dequeue <= 0;
        end

        if(sprite0_en && sprite0_finished) begin
            sprite0_en <= 0;
        end
        if(sprite1_en && sprite1_finished) begin
            sprite1_en <= 0;
        end

        if (!sprite_queue_is_empty && !sprite_queue_dequeue) begin
            if (!sprite0_en) begin
                sprite0_en <= 1;
                sprite0_id <= sprite_queue_sprite_id;
                sprite0_x <= sprite_queue_sprite_x;
                sprite0_y <= sprite_queue_sprite_y;
                sprite0_scale <= sprite_queue_sprite_scale;
                sprite_queue_dequeue <= 1;
            end else if (!sprite1_en) begin
                sprite1_en <= 1;
                sprite1_id <= sprite_queue_sprite_id;
                sprite1_x <= sprite_queue_sprite_x;
                sprite1_y <= sprite_queue_sprite_y;
                sprite1_scale <= sprite_queue_sprite_scale;
                sprite_queue_dequeue <= 1;
            end
        end
    end
endmodule