`timescale 1ns / 1ps
`include "params.vh"

module sprite_storage(
    input logic clock,
    input logic [$clog2(SPRITE_NUM)-1:0] sprite_select,
    input logic w_en,
    input logic [SPRITE_ADDR_SIZE:0] w_addr, // NB: addresses 4-bits, not bytes
    input logic [7:0] w_data,
    input logic r_en,
    input logic [SPRITE_ADDR_SIZE:0] r_addr,
    output logic [3:0] r_data
    );
    
    logic sb_w_en[SPRITE_NUM-1:0];
    logic sb_r_en[SPRITE_NUM-1:0];
    
    spritebuffer sb[SPRITE_NUM-1:0] (
        .clock(clock),
        .sb_w_en(sb_w_en),
        .sb_w_addr(w_addr),
        .sb_w_data(w_data),
        .sb_r_en(sb_r_en),
        .sb_r_addr(r_addr),
        .sb_r_data(r_data)
    );
   
    genvar i;
    for (i = 0; i < SPRITE_NUM; i = i + 1) begin
        assign sb_w_en[i] = sprite_select == i && w_en;
        assign sb_r_en[i] = sprite_select == i && r_en;
    end
endmodule

module spritebuffer(
    input logic clock,
    // Write port (full byte from SPI)
    input logic sb_w_en,          // active high
    input logic [SPRITE_ADDR_SIZE:0] sb_w_addr,   // address bus, NB: addresses 4-bits, not bytes
    input logic [7:0] sb_w_data,    // input data to port 1
    // Read port (4bit pixel value)
    input logic sb_r_en,
    input logic [SPRITE_ADDR_SIZE:0] sb_r_addr,
    output logic [3:0] sb_r_data
    );

    // initialize ram
    logic [3:0] ram [SPRITE_SIZE-1:0];
   
    initial begin
        // give it start data
        // $readmemb("fb_data.data", ram);
    end

    always @(posedge clock) begin
        // Write
        if (sb_w_en) begin
            ram[sb_w_addr] <= sb_w_data[7:4];
            ram[sb_w_addr+1] <= sb_w_data[3:0];
        end
        // Read
        if (sb_r_en) begin
            sb_r_data <= ram[sb_r_addr];
        end
    end
endmodule
