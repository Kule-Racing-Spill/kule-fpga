`timescale 1ns/1ps

module vga_color_tb(
    );
    logic [3:0] index;
    logic [14:0] color;
    integer i;
    
    initial begin
        index <= 0;
        #10 index <= 1;
        #10 index <= 2;
        #10 index <= 3;
        #10 index <= 4;
        #10 index <= 5;
        #10 index <= 6;
        #10 index <= 7;
        #10 index <= 8;
        #10 index <= 9;
        #10 index <= 10;
        #10 index <= 11;
        #10 index <= 12;
        #10 index <= 13;
        #10 index <= 14;
        #10 $finish;
    end
    
    vga_color vga_col(index, color);
endmodule