`timescale 1ns / 1ps
`include "params.vh"

module sprite_storage_tb();
reg clk;
reg [$clog2(SPRITE_NUM)-1:0] sprite_select;
reg w_en;
reg [SPRITE_ADDR_SIZE:0] w_addr;
reg [7:0] w_data;
reg r_en;
reg [SPRITE_ADDR_SIZE:0] r_addr;
wire [3:0] r_data;

// Clock generation
always #5 clk = !clk;

sprite_storage storage (
    clk,
    sprite_select,
    w_en,
    w_addr,
    w_data,
    r_en,
    r_addr,
    r_data
);

initial begin
    clk = 0;
    sprite_select = 0;
    w_en = 0;
    w_addr = 0;
    w_data = 0;
    r_en = 0;
    r_addr = 0;
    
    #20;
    
    // Test simple write and read from 1st sprite
    w_en = 1;
    w_addr = 0;
    w_data = 8'b00010010;
    #10;
    w_addr = 2;
    w_data = 8'b00110100;;
    #10;
    w_addr = 4;
    w_data = 8'b01010110;;
    #10;
    w_addr = 6;
    w_data = 8'b01111000;;
    #10;
    w_en = 0;
    r_en = 1;
    r_addr = 0;
    #10;
    r_addr = 1;
    #10;
    r_addr = 2;
    #10;
    r_addr = 3;
    #10;
    r_addr = 4;
    #10;
    r_addr = 5;
    #10;
    r_addr = 6;
    #10;
    r_addr = 7;
    #10;
    
    // switch sprite
    sprite_select = 1;
    #10;
    r_en = 0;
    w_en = 1;
    w_addr = 2;
    w_data = 8'b10101010;
    #10;
    w_en = 0;
    r_en = 1;
    r_addr = 2;
    #10;
    sprite_select = 0;
    #10;
    
    
    $finish;
end

    
      
endmodule
