`timescale 1ns/1ps

module top_tb();
    logic clock;
    // write port
    logic [4:0] w_select;
    logic w_en;
    logic [13:0] w_addr; // NB: addresses 4-bits, not bytes
    logic [7:0] w_data;
    // read 1
    logic [4:0] r0_select;
    logic [13:0] r0_addr;
    logic [3:0] r0_data;
    // read 2
    logic [4:0] r1_select;
    logic [13:0] r1_addr;
    logic [3:0] r1_data;
    
    sprite_storage ss(
        clock,
        w_select,
        w_en,
        w_addr,
        w_data,
        r0_select,
        r0_addr,
        r0_data,
        r1_select,
        r1_addr,
        r1_data
    );
endmodule
