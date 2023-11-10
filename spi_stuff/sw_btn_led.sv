`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/12/2015 02:52:16 PM
// Design Name: 
// Module Name: sw_led
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


module sw_btn_led(
    input [3:0]sw,
    input [3:0]btn,
    output [3:0]led,
    output led0_b,
    output led0_r,
    output led0_g,
    output ck_io10,
    output ck_io9,
    input sys_clock
    );
    
    //assign led = sw | btn;
    
    reg [32:0] counter = 0;
    reg [3:0] reg_led = 0;
    reg reg_r = 0;
    reg reg_g = 0;
    reg reg_b = 0;
    
    assign led = reg_led;
    assign led0_r = reg_r;
    assign led0_g = reg_g;
    assign led0_b = reg_b;
    assign ck_io10 = reg_b;
    assign ck_io9 = reg_r;
      clk_wiz_0 instance_name
   (
        // Clock out ports
        .clk_out1(clk_out1),     // output clk_out1
        // Status and control signals
        //.reset("0"), // input reset
        //.clk_10M(clk_10M),       // output clk_10M
       // Clock in ports
        .clk_in1(sys_clock)      // input clk_in1
    );
    
    
    always @(posedge clk_out1) begin
        counter <= counter + 1;
        if (sw[0])
            reg_r <= 1;
        else
            reg_r <= 0;
        if (sw[1])
            reg_g <= 1;
        else
            reg_g <= 0;
        if (sw[2])
            reg_b <= 1;
        else
            reg_b <= 0;     
    end

endmodule
