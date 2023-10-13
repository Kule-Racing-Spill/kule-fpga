`timescale 1ns/1ps

module vga_color(
    input logic [3:0] index,
    output logic [14:0] color
    );
    integer i;
    integer n;
    reg [14:0] colors [0:14];
    initial begin
        for (i = 0; i < 8; i = i + 1) colors[i] <= 15'b000000000000000 + i;
        for (n = 8; n < 16; n = n + 1) colors[n] <= 15'b111111111111111 - n;
    end
    
    assign color = colors[index];
endmodule