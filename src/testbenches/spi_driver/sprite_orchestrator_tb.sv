`timescale 1ns / 1ps


module sprite_queue_tb();
reg clk;
reg enqueue_en;
reg [7:0] enqueue_data;
reg dequeue;

logic is_empty;
logic [7:0] sprite_id;
logic [15:0] sprite_x;
logic [15:0] sprite_y;
logic [7:0] sprite_scale;

always #5 clk = !clk;

sprite_queue queue(
    clk,
    enqueue_en,
    enqueue_data,
    dequeue,
    is_empty,
    sprite_id,
    sprite_x,
    sprite_y,
    sprite_scale
);

initial begin
    clk = 0;
    enqueue_en = 0;
    enqueue_data = 8'b00000000;
    dequeue = 0;
    #20;
    
    // enqueue one sprite
    enqueue_en = 1;
    enqueue_data = 8'b00000001; // sprite id
    #10;
    enqueue_data = 8'b00010000; // pos x
    #10;
    enqueue_data = 8'b00000100;
    #10;
    enqueue_data = 8'b10000000; // pos y
    #10;
    enqueue_data = 8'b00000000;
    #10;
    enqueue_data = 8'b00000010; // scale
    #10;
    enqueue_en = 0;
    
    #20;
    
    // enqueue another sprite
    enqueue_en = 1;
    enqueue_data = 8'b00000010; // sprite id
    #10;
    enqueue_data = 8'b00000100; // pos x
    #10;
    enqueue_data = 8'b00000100;
    #10;
    enqueue_data = 8'b10010000; // pos y
    #10;
    enqueue_data = 8'b00000000;
    #10;
    enqueue_data = 8'b00000101; // scale
    #10;
    enqueue_en = 0;
    
    #20;
    
    // dequeue
    dequeue = 1;
    #10;
    dequeue = 0;
    
    #40;
    
    dequeue = 1;
    #10;
    dequeue = 0;
    
    #40;
    $finish;
end

endmodule
