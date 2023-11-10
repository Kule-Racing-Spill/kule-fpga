`timescale 1ns/1ps
`include "params.vh"

module main(
    input [3:0]sw,
    input [3:0]btn,
    input spi_mosi,
    input spi_miso,
    input spi_sck,
    input spi_cs,
    output [3:0]led,
    output led0_b,
    output led0_r,
    output led0_g,
    input sys_clock
    );
    reg [3:0] reg_led = 0;
    reg reg_r = 0;
    reg reg_g = 0;
    reg reg_b = 0;
    
    assign led[3:0] = command[3:0];
    assign led0_r = reg_r;
    assign led0_g = reg_g;
    assign led0_b = reg_b;

    // Buffer SPI clock
    BUFG bufg_inst (
        .I(spi_sck),   // Input clock
        .O(spi_clk_bufg)   // Buffered clock
    );
    
    // Sprite storage module
    logic [$clog2(SPRITE_NUM)-1:0] sprite_select;
    logic sprite_w_en;
    logic [SPRITE_ADDR_SIZE:0] sprite_w_addr;
    logic [7:0] sprite_w_data;
    logic sprite_r_en;
    logic [SPRITE_ADDR_SIZE:0] sprite_r_addr;
    logic [3:0] sprite_r_data;  
    
    sprite_storage storage (
        sys_clock,
        sprite_select,
        sprite_w_en,
        sprite_w_addr,
        sprite_w_data,
        sprite_r_en,
        sprite_r_addr,
        sprite_r_data
    );
    
    logic spi_data_clock;
    logic enqueue_en;
    assign enqueue_en = command == 8'b00000001;
    logic [7:0] spi_data;
    logic dequeue;
    
    logic is_empty;
    logic [7:0] sprite_id;
    logic [15:0] sprite_x;
    logic [15:0] sprite_y;
    logic [7:0] sprite_scale;
    
    sprite_queue draw_queue(
        spi_data_clock,
        enqueue_en,
        enqueue_data,
        dequeue,
        is_empty,
        sprite_id,
        sprite_x,
        sprite_y,
        sprite_scale
    );     
    
    // SPI reader module
    logic[7:0] command;
    spi_reader reader(
        sys_clock,
        spi_cs,
        spi_clk_bufg,
        spi_mosi,
        spi_miso,
        command,
        spi_data,
        spi_data_clock,
        sprite_select,
        sprite_w_en,
        sprite_w_addr,
        sprite_w_data
    );

    always @(posedge sys_clock) begin
        reg_led <= 0;
        if (command == 8'b00000000) begin
            reg_r <= 1;
        end
        else
            reg_r <= 0;
        
        if (command == 8'b00000001) begin
            reg_g <= 1;
        end
        else begin
            reg_g <= 0;
        end
        
        if (command == 8'b00000010) begin
            reg_b <= 1;
        end
        else begin
            reg_b <= 0;
        end
        
    end

endmodule