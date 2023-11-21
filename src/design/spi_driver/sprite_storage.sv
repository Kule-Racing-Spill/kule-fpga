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

module spi_store_write_controller(
    input wire clock,
    input wire reset,
    input wire [7:0] command,
    input wire [7:0] data,
    input wire [15:0] data_index,
    input wire data_read,
    output logic [$clog2(SPRITE_NUM)-1:0] w_select,
    output logic w_en,
    output logic [SPRITE_ADDR_SIZE:0] w_addr, // NB: addresses 4-bits, not bytes
    output logic [7:0] w_data
    );
    assign w_data = { data[3:0], data[7:4] };

    always_ff @(posedge clock) begin
        if (reset) begin
            w_en <= 0;
        end else if (data_read) begin
            if (command == COMMAND_SAVE_SPRITE) begin
                if (data_index == 0) begin
                    w_select <= data;
                    w_en <= 0;
                    w_addr <= 0;
                end else begin
                    w_en <= 1;
                    w_addr <= data_index << 1;
                end
            end
        end
    end
endmodule