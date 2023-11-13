`timescale 1ns / 1ps
`include "params.vh"

module sprite_render #(
        parameter CORDW = 10,
        parameter SPR_WIDTH = 8,
        parameter SPR_HEIGHT = 8,
        parameter SPR_DATAW = 4
    )(
    input  wire logic clk,                            // clock
    input  wire logic rst,                           // reset
    input  wire logic enable,
    input  wire logic [CORDW-1:0] sx, sy,      // screen position
    output wire logic [SPRITE_ADDR_SIZE:0] sprite_r_addr,
    input  wire logic [3:0] sprite_r_data,
    output wire logic [18:0] addr,                     // address to write to fb
    output      logic [SPR_DATAW-1:0] pix,            // pixel colour index
    output      logic drawing                   // bram enable
    );
    
;
    logic [((SPR_WIDTH > SPR_HEIGHT) ? $clog2(SPR_WIDTH) : $clog2(SPR_HEIGHT)):0] sprx, spry;
    
    assign sprite_r_addr = sprx + spry * SPR_WIDTH;
    assign addr = (FRAMEBUFFER_SIZE > 192000) ? (sx + sprx) + (sy + spry) * 800 : ((sx + sprx) + (sy + spry) * 800)/2;
    
    logic finish;
    
    always_ff @(posedge clk) begin
        if (enable && !finish) begin
            drawing <= 1;
            if (sprx == SPR_WIDTH - 1) begin
                sprx <= 0;
                if (spry == SPR_HEIGHT - 1) begin
                    finish <= 1;
                    spry <= 0;
                end else spry <= spry + 1;
            end else sprx <= sprx + 1;
            
            pix <= sprite_r_data;
        end else drawing <= 0;
        if (rst) begin
            sprx <= 0;
            spry <= 0;
            drawing <= 0;
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
