`timescale 1ns/1ps

module lcd_signals_tb(
    );
    // set up clock
    reg clk;
    initial begin
        clk <= 0;
        
    end
    always #10 clk <= ~clk;
    
endmodule