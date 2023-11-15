`include "params.vh"

module spi_byte_reader (
    input wire clock,       
    input wire reset,       // reset to new initial byte
    input wire sck,         // Serial clock
    input wire mosi,        // Data line
    output logic byte_read, // Positive for one clock cycle every time a new byte is read
    output logic[7:0] data  // The latest read byte
);
    logic sck_posedge;
    posedge_detect pe_det_sck(clock, sck, sck_posedge);

    logic internal_byte_read:;
    posedge_detect pe_det_sck(clock, internal_byte_read, byte_read);

    logic initial_bit = 1;
    logic[2:0] read_index = 0;
    logic[7:0] read_buffer = 0;

    always_ff @(posedge clock) begin
        if(reset) begin
            initial_bit <= 1;
            read_index <= 0;
        end else begin
            // send read byte to output data
            if (read_index == 0 && ~initial_bit) begin
                data <= read_buffer;
                byte_read <= 1;
            end else byte_read <= 0;

            // read next bit
            if (sck_posedge) begin
                read_buffer[7:0] <= {read_buffer[6:0], mosi};
                read_index <= read_index + 1; // overflows to reset for next byte
            end

            // no longer the initial bit
            initial_bit <= 0;
        end
    end
endmodule

/**
*   Gets the command sent via SPI. Keeps track of how many data bytes have been sent for the current command.
*/
module spi_command_parser (
    input wire  clock,
    input wire  reset,
    input wire  byte_read,
    input logic[7:0] data,
    output logic[7:0] command,
    output logic[15:0] data_index
    );
    logic[15:0] data_count = 0; // number of bytes to read for the current command
    initial data_index = 0;

    always_ff @(posedge clock) begin
        if (reset) begin
            data_count <= 0;
            data_index <= 0;
        end else begin
            if (byte_read) begin
                // if command data is all read, read new command
                if (data_index == data_count) begin
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
                    data_index <= data_index + 1;
                end
            end
        end
    end
endmodule

module spi_reader (
    input wire clock,
    input wire cs,
    input wire sck,
    input wire mosi,
//    output logic miso,
    output logic[7:0] command,
    output logic[7:0] data,
    output logic[15:0] data_index,
    output logic byte_read
    );
    spi_byte_reader sbr(
        .clock,
        .reset(cs),
        .sck,
        .mosi,
        .byte_read,
        .data
    );

    spi_command_parser scp(
        .clock,
        .reset(cs),
        .byte_read,
        .data,
        .command,
        .data_index
    );
endmodule