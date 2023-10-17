`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/06/2023 10:50:00 AM
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top(
    input wire logic pin_FPGA_CS,
    input wire logic pin_FPGA_CLK,
    input wire logic pin_FPGA_MISO,
    output     logic pin_FPGA_MOSI
    );
    
    spi_reader spi_reader(
        pin_FPGA_CS,
        pin_FPGA_CLK,
        pin_FPGA_MOSI,
        pin_FPGA_MISO
    );
endmodule
