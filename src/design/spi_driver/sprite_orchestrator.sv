`timescale 1ns / 1ps

localparam QUEUE_SIZE = 8;

module sprite_queue(
    input logic clock,
    input logic enqueue_en,
    input logic [7:0] enqueue_data,
    input logic dequeue,
    output logic is_empty,
    output logic [7:0] sprite_id,
    output logic [15:0] sprite_x,
    output logic [15:0] sprite_y,
    output logic [7:0] sprite_scale
    );
    logic [7:0] sprite_id_queue [QUEUE_SIZE-1:0];
    logic [15:0] sprite_x_queue [QUEUE_SIZE-1:0];
    logic [15:0] sprite_y_queue [QUEUE_SIZE-1:0];
    logic [7:0] sprite_scale_queue [QUEUE_SIZE-1:0];
    
    logic [$clog2(QUEUE_SIZE)-1:0] queue_size = 1;
    logic [2:0] read_index = 0;
    
    logic old_dequeue;
    
    initial begin
        sprite_id_queue[0] = 8'b00000001;
        sprite_x_queue[0] = 200;
        sprite_y_queue[0] = 200;
        sprite_scale_queue[0] = 8'b00000000;
    end

    assign is_empty = (queue_size == 0) ? 1 : 0;
    assign sprite_id = sprite_id_queue[0];
    assign sprite_x = sprite_x_queue[0];
    assign sprite_y = sprite_y_queue[0];
    assign sprite_scale = sprite_scale_queue[0];

    
    always @(posedge clock) begin
        if (enqueue_en) begin
            read_index <= read_index + 1;
            if (read_index == 0) begin
                sprite_id_queue[queue_size] <= enqueue_data;
            end else if (read_index == 1) begin
                sprite_x_queue[queue_size][15:8] <= enqueue_data;
            end else if (read_index == 2) begin
                sprite_x_queue[queue_size][7:0] <= enqueue_data;
            end else if (read_index == 3) begin
                sprite_y_queue[queue_size][15:8] <= enqueue_data;
            end else if (read_index == 4) begin
                sprite_y_queue[queue_size][7:0] <= enqueue_data;
            end else if (read_index == 5) begin
                sprite_scale_queue[queue_size] <= enqueue_data;
                queue_size <= queue_size + 1;
                read_index <= 0;
            end
        end else begin
            read_index <= 0;
        end
        
        if (dequeue != old_dequeue && dequeue) begin
            if (!is_empty) begin
                queue_size <= queue_size - 1;
                sprite_id_queue <= { 8'b00000000, sprite_id_queue[QUEUE_SIZE-1:1] };
                sprite_x_queue <= { 8'b00000000, sprite_x_queue[QUEUE_SIZE-1:1] };
                sprite_y_queue <= { 8'b00000000, sprite_y_queue[QUEUE_SIZE-1:1] };
                sprite_scale_queue <= { 8'b00000000, sprite_scale_queue[QUEUE_SIZE-1:1] };
            end
        end
        old_dequeue <= dequeue;
    end
endmodule
