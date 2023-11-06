`timescale 1ns/1ps

module lcd_driver(
    input wire logic pixel_clock,
    input wire logic pixel_reset,
    output logic lcd_de,
    output logic lcd_hsync,
    output logic lcd_vsync,
    output logic [7:0] lcd_red,
    output logic [7:0] lcd_green,
    output logic [7:0] lcd_blue,
    // RAM
    output wire [18:0] addr,
    input logic [3:0] data
    );
    
    // control signals
    logic de, hsync, vsync;
    
    // positions
    logic [9:0] sx, sy;
    
    // color
    logic [23:0] color;
    
    // generate signals
    lcd_signals signals(
        pixel_clock,
        pixel_reset,
        sx,
        sy,
        hsync,
        vsync,
        de
    );
    
    // get the color
    lcd_color lcd_color(
        sx,
        sy,
        color,
        addr,
        data
    );
    
    // drive the control signals and color
    always_ff @(posedge pixel_clock) begin
        // drive control signals
        lcd_de <= de;
        lcd_hsync <= hsync;
        lcd_vsync <= vsync;
        
        // should we draw?
        lcd_red <= (de) ? color[23:16] : 8'h00;
        lcd_green <= (de) ? color[15:8] : 8'h00;
        lcd_blue <= (de) ? color[7:0] : 8'h00;
    end
endmodule