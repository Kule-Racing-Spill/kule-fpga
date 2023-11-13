`timescale 1ns / 1ps
`include "params.vh"

module sprite_storage(
    input logic clock,
    // write port
    input logic [$clog2(SPRITE_NUM)-1:0] w_select,
    input logic w_en,
    input logic [SPRITE_ADDR_SIZE:0] w_addr, // NB: addresses 4-bits, not bytes
    input logic [7:0] w_data,
    // read 1
    input logic [$clog2(SPRITE_NUM)-1:0] r0_select,
    input logic [SPRITE_ADDR_SIZE:0] r0_addr,
    output logic [3:0] r0_data
    // read 2
    input logic [$clog2(SPRITE_NUM)-1:0] r1_select,
    input logic [SPRITE_ADDR_SIZE:0] r1_addr,
    output logic [3:0] r1_data
    );
    
    logic sb_w_en[SPRITE_NUM-1:0];
    logic sb_r0_en[SPRITE_NUM-1:0];
    logic sb_r1_en[SPRITE_NUM-1:0];
    
    spritebuffer sb[SPRITE_NUM-1:0] (
        .clock(clock),
        .sb_w_en(sb_w_en),
        .sb_w_addr(w_addr),
        .sb_w_data(w_data),
        .sb_r0_en(sb_r0_en),
        .sb_r0_addr(r0_addr),
        .sb_r0_data(r0_data),
        .sb_r1_en(sb_r1_en),
        .sb_r1_addr(r1_addr),
        .sb_r1_data(r1_data)
    );
   
    genvar i;
    for (i = 0; i < SPRITE_NUM; i = i + 1) begin
        assign sb_w_en[i] = w_select == i && w_en;
        assign sb_r0_en[i] = r0_select == i;
        assign sb_r1_en[i] = r1_select == i;
    end
endmodule

module spritebuffer(
    input logic clock,
    // Write port (full byte from SPI)
    input logic sb_w_en,          // active high
    input logic [SPRITE_ADDR_SIZE:0] sb_w_addr,   // address bus, NB: addresses 4-bits, not bytes
    input logic [7:0] sb_w_data,    // input data to port 1
    // Read port 1 (4bit pixel value)
    input logic sb_r0_en,
    input logic [SPRITE_ADDR_SIZE:0] sb_r0_addr,
    output logic [3:0] sb_r0_data
    // Read port 2 (4bit pixel value)
    input logic sb_r1_en,
    input logic [SPRITE_ADDR_SIZE:0] sb_r1_addr,
    output logic [3:0] sb_r1_data
    );

    // initialize ram
    logic [3:0] ram [SPRITE_SIZE-1:0];
   
    initial begin
        // give it start data
        $readmemb("sprite.mem", ram);
    end

    always @(posedge clock) begin
        // Write
        if (sb_w_en) begin
            ram[sb_w_addr] <= sb_w_data[7:4];
            ram[sb_w_addr+1] <= sb_w_data[3:0];
        end
        // Read port 0
        if (sb_r0_en) begin
            sb_r0_data <= ram[sb_r0_addr];
        end
        // Read port 1
        if (sb_r1_en) begin
            sb_r1_data <= ram[sb_r1_addr];
        end
    end
endmodule
