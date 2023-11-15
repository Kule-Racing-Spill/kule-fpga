`timescale 1ns / 1ps
`include "params.vh"

module sprite_render #(
        parameter CORDW = 10,
        parameter SPR_WIDTH = 16,
        parameter SPR_HEIGHT = 16,
        parameter SPR_DATAW = 4
    )(
    input  wire logic clk,                            // clock
    input  wire logic rst,                           // reset
    input  wire logic enable,
    input  wire logic [CORDW-1:0] sx, sy,      // screen position
    input  wire logic [7:0] sprite_scale,
    output wire logic [SPRITE_ADDR_SIZE:0] sprite_r_addr,
    input  wire logic [3:0] sprite_r_data,
    output wire logic [18:0] addr,                     // address to write to fb
    output      logic [SPR_DATAW-1:0] pix,            // pixel colour index
    output      logic drawing,                   // bram enable
    output      logic finished
    );
    
    logic finish;
    
    logic [CORDW-1:0] writing_x, writing_y = 0;
    logic [7:0] count_x, count_y = 0;
    logic [((SPR_WIDTH > SPR_HEIGHT) ? $clog2(SPR_WIDTH) : $clog2(SPR_HEIGHT)):0] reading_x, reading_y;
    
    assign sprite_r_addr = reading_x + reading_y * SPR_WIDTH;
    assign addr = (FRAMEBUFFER_SIZE > 192000) ? (sx + writing_x) + (sy + writing_y) * 800 : ((sx + writing_x) + (sy + writing_y) * 800)/2;
    assign finished = finish;
    
    /*
    Scaling byte
    MSB
    0 - 8 for every pixel
    0 - 4 for every pixel
    1 - 2 for every pixel
    1 - every pixel
    0 - every 2 pixels
    1 - every 4 pixels
    0 - every 8 pixels
    0 - every 16 pixels
    LSB
    */
    
    logic [7:0] max_count_x, max_count_y;
    
    always_comb begin
        max_count_x <= sprite_scale[7:4]
            + (sprite_scale[3] && reading_x[0] ? 1 : 0)
            + (sprite_scale[2] && reading_x[1:0] == 2'b11 ? 1 : 0)
            + (sprite_scale[1] && reading_x[2:0] == 3'b111 ? 1 : 0)
            + (sprite_scale[0] && reading_x[3:0] == 4'b1111 ? 1 : 0);
        
        max_count_y <= sprite_scale[7:4]
            + (sprite_scale[3] && reading_y[0] ? 1 : 0)
            + (sprite_scale[2] && reading_y[1:0] == 2'b11 ? 1 : 0)
            + (sprite_scale[1] && reading_y[2:0] == 3'b111 ? 1 : 0)
            + (sprite_scale[0] && reading_y[3:0] == 4'b1111 ? 1 : 0);  
    end
    
    
    always_ff @(posedge clk) begin
        if (enable && !finish) begin
            drawing <= 1;
            if (max_count_x == 0 || max_count_y == 0) drawing <= 0;
            if (writing_x == sprite_scale - 1) begin
                reading_x <= 0;
                writing_x <= 0;
                count_x <= 1;
                
                if (writing_y == sprite_scale - 1) begin
                    finish <= 1;
                    reading_y <= 0;
                    writing_y <= 0;
                    count_y <= 1;
                end else begin
                    writing_y <= writing_y + 1;
                    if (count_y >= max_count_y) begin
                        reading_y <= reading_y + 1;
                        count_y <= 1;
                    end else begin
                        count_y <= count_y + 1;
                    end
                end
            end else begin
                writing_x <= writing_x + 1;
                if (count_x >= max_count_x) begin
                    reading_x <= reading_x + 1;
                    count_x <= 1;
                end else begin
                    count_x <= count_x + 1;
                end
            end
            
            // Don't draw transparent
            if (sprite_r_data == 4'b1111) drawing <= 0;
            else pix <= sprite_r_data;

        end else drawing <= 0;
        
        if (rst) begin
            reading_x <= 0;
            reading_y <= 0;
            drawing <= 0;
            count_x <= 1;
            count_y <= 1;
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
