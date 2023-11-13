`include "params.vh"

module spi_byte_reader (
    input wire enable, // 1: enabled, 0: not enabled
    input wire sck,    // Serial clock
    input wire mosi,   // Data line
    output logic data_clk, // Data clock
    output logic[7:0] data // The latest read byte
);
    logic[2:0] index;
    logic initial_byte;
    logic[7:0] data_nxt;
    
    initial begin
        index = 0;
        initial_byte = 1;
        data_nxt = 0;
        data_clk = 0;
    end

    // read on positive edge
    always @(posedge sck or negedge enable) begin
        if (!enable) begin
            // if disabled at the end of byte, output it to data
            if (index == 0 && !initial_byte) begin 
                data[7:0] <= data_nxt[7:0];
                data_clk <= 1;
            end
            // always reset bit-index after disable
            index <= 0;
            initial_byte <= 1;
        end else begin
            // if a byte was just completed, output it to data
            if (index == 0 && !initial_byte) begin
                data[7:0] <= data_nxt[7:0];
                data_clk <= 1;
            end else begin
                data_clk <= 0;
            end

            // read next bit
            data_nxt[7:0] <= {data_nxt[6:0], mosi};
            index <= index + 1; // will overflow to 0 on 8th bit
            initial_byte <= 0;
        end
    end
endmodule


module spi_command_parser (
    input logic clock,
    input logic enable,
    input logic data_clk,
    input logic[7:0] data,
    output logic[7:0] command,
    output logic[$clog2(SPRITE_NUM)-1:0] sprite_select,
    output logic sprite_w_en,
    output logic[SPRITE_ADDR_SIZE:0] sprite_w_addr,
    output logic[7:0] sprite_w_data
);
    logic[15:0] data_count;
    logic[15:0] data_index;
    
    logic[SPRITE_ADDR_SIZE:0] sprite_address;
    logic sprite_write;

    initial begin
        data_count = 0;
        data_index = 0;

        sprite_w_en = 0;
        sprite_write = 0;
    end
    
    always @(posedge clock) begin
        if (sprite_write) begin
            sprite_w_en <= 1;
            sprite_w_addr <= sprite_address;
            sprite_w_data <= data;
            
            sprite_write <= 0;
            sprite_address <= sprite_address + 2;
        end else begin
            sprite_w_en <= 0;
        end
    end

    always @(negedge data_clk or negedge enable) begin
        if (!enable) begin
            data_count <= 0;
            data_index <= 0;
        end else if (data_count == data_index) begin
            command <= data;
            data_index <= 0;
            case(data)
                COMMAND_SAVE_SPRITE: begin
                    // send sprite command
                    // 1(spriteid) + 512(pixel values) bytes of data
                    data_count <= 513;
                end
                COMMAND_DRAW_SPRITE: begin
                    // draw sprite command
                    data_count <= 6;
                end

                default begin
                    // unknown command
                    data_count <= 0; // just ignore and use next byte as command
                end
            endcase
        end else begin
            case(command)
                COMMAND_SAVE_SPRITE: begin
                    // parse "send sprite" command
                    if (data_index == 0) begin
                        sprite_select <= data;
                        sprite_address <= 0;
                    end else begin
                        // Signal to write another byte
                        sprite_write <= 1;
                    end
                end
            endcase


            data_index <= data_index + 1;
        end
    end
endmodule

module spi_reader (
    input wire clock,
    input wire cs,
    input wire sck,
    input wire mosi,
    output logic miso,
    output logic[7:0] command,
    output logic[7:0] data,
    output logic data_clk,
    output logic[$clog2(SPRITE_NUM)-1:0] sprite_select,
    output logic sprite_w_en,
    output logic[SPRITE_ADDR_SIZE:0] sprite_w_addr,
    output logic[7:0] sprite_w_data
);
    logic enable;
    assign enable = ~cs;

    spi_byte_reader byte_reader(
        enable, 
        sck, 
        mosi, 
        data_clk, 
        data
    );
    spi_command_parser command_parser(
        clock,
        enable, 
        data_clk, 
        data, 
        command, 
        sprite_select, 
        sprite_w_en, 
        sprite_w_addr, 
        sprite_w_data
    );
endmodule