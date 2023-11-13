`timescale 1ns / 1ps
`include "params.vh"

module sprite_render #(
        parameter CORDW = 10,
        parameter SPR_WIDTH = 32,
        parameter SPR_HEIGHT = 32,
        parameter SPR_DATAW = 4
    )(
    input  wire logic clk,                            // clock
    input  wire logic rst,                           // reset
    input  wire logic enable,
    input  wire logic [CORDW-1:0] sx, sy,      // screen position
    input  wire logic [2:0] sprite_scale,
    output wire logic [SPRITE_ADDR_SIZE:0] sprite_r_addr,
    input  wire logic [3:0] sprite_r_data,
    output wire logic [18:0] addr,                     // address to write to fb
    output      logic [SPR_DATAW-1:0] pix,            // pixel colour index
    output      logic drawing                   // bram enable
    );
    
    logic [CORDW-1:0] writing_x, writing_y = 0;
    logic [2:0] count_x, count_y = 0;
    logic [((SPR_WIDTH > SPR_HEIGHT) ? $clog2(SPR_WIDTH) : $clog2(SPR_HEIGHT)):0] reading_x, reading_y;
    
    assign sprite_r_addr = reading_x + reading_y * SPR_WIDTH;
    assign addr = (FRAMEBUFFER_SIZE > 192000) ? (sx + writing_x) + (sy + writing_y) * 800 : ((sx + writing_x) + (sy + writing_y) * 800)/2;
    
    logic finish;
    
    
    always_ff @(posedge clk) begin
        if (enable && !finish) begin
            drawing <= 1;
            if (writing_x == (SPR_WIDTH + SPR_WIDTH * sprite_scale) - 1) begin
                reading_x <= 0;
                writing_x <= 0;
                
                if (writing_y == (SPR_HEIGHT + SPR_HEIGHT * sprite_scale) - 1) begin
                    finish <= 1;
                    reading_y <= 0;
                    writing_y <= 0;
                end else begin
                    writing_y <= writing_y + 1;
                    if (count_y == sprite_scale) begin
                        reading_y <= reading_y + 1;
                        count_y <= 0;
                    end else begin
                        count_y <= count_y + 1;
                    end
                end
            end else begin
                writing_x <= writing_x + 1;
                if (count_x == sprite_scale) begin
                    reading_x <= reading_x + 1;
                    count_x <= 0;
                end else begin
                    count_x <= count_x + 1;
                end
            end
            
            pix <= sprite_r_data;
        end else drawing <= 0;
        
        if (rst) begin
            reading_x <= 0;
            reading_y <= 0;
            drawing <= 0;
            count_x <= 0;
            count_y <= 0;
            writing_x <= 0;
            writing_y <= 0;
            finish <= 0;
        end
    end

endmodule

module rom_async #(
    parameter WIDTH=8,
    parameter DEPTH=256,
    parameter INIT_F="",
    localparam ADDRW=$clog2(DEPTH)
    ) (
    input wire logic [ADDRW-1:0] addr,
    output     logic [WIDTH-1:0] data
    );

    logic [WIDTH-1:0] memory [DEPTH-1:0];

    initial begin
        if (INIT_F != 0) begin
            $display("Creating rom_async from init file '%s'.", INIT_F);
            $readmemb(INIT_F, memory);
        end
    end

    always_comb data = memory[addr];
endmodule
