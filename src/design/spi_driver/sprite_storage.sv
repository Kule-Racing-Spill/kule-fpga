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
    output logic [3:0] r0_data,
    // read 2
    input logic [$clog2(SPRITE_NUM)-1:0] r1_select,
    input logic [SPRITE_ADDR_SIZE:0] r1_addr,
    output logic [3:0] r1_data
    );
    
    // port a needs to switch
    logic [SPRITE_ADDR_SIZE:0] addra, addrb;
    
    // pin b write to low
    logic [7:0] dinb = 0;
    logic web = 0;
    
    always_comb begin
        if (w_en) begin
            addra <= w_addr + SPRITE_WORD_SIZE * w_select;
        end else begin
            addra <= r0_addr + SPRITE_WORD_SIZE * r0_select;
        end
        addrb <= r1_addr + SPRITE_WORD_SIZE * r1_select;
    end
    
    sprite_bram spritebuffer(
        .addra(addra),
        .clka(clock),
        .dina(w_data),
        .douta(r0_data),
        .wea(w_en),
        .addrb(addrb),
        .clkb(clock),
        .dinb(dinb),
        .doutb(r1_data),
        .web(web)
    );
endmodule

module spritebuffer #(
    parameter INIT_F="sprite.mem"
)(
    input logic clock,
    // Write port (full byte from SPI)
    input logic sb_w_en,          // active high
    input logic [SPRITE_ADDR_SIZE:0] sb_w_addr,   // address bus, NB: addresses 4-bits, not bytes
    input logic [7:0] sb_w_data,    // input data to port 1
    // Read port 1 (4bit pixel value)
    input logic sb_r0_en,
    input logic [SPRITE_ADDR_SIZE:0] sb_r0_addr,
    output logic [3:0] sb_r0_data,
    // Read port 2 (4bit pixel value)
    input logic sb_r1_en,
    input logic [SPRITE_ADDR_SIZE:0] sb_r1_addr,
    output logic [3:0] sb_r1_data
    );

    // initialize ram
    logic [3:0] ram [SPRITE_SIZE-1:0];
   
    initial begin
        // give it start data
        $readmemb(INIT_F, ram);
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
