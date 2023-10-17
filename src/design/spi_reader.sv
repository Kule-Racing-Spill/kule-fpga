module spi_byte_reader (
    input wire enable, // 0: enabled, 1: not enabled
    input wire sck,    // Serial clock
    input wire mosi,   // Data line
    output logic data_clk, // Data clock
    output logic[7:0] data // The latest read byte
);
    logic[2:0] index;
    logic[7:0] data_nxt;
    
    initial begin
        index = 0;
        data_nxt = 0;
        data_clk = 0;
    end

    // read on positive edge
    always @(posedge sck or posedge enable) begin
        if (enable) begin
            index <= 0;
        end else begin
            data_nxt[7:0] <= {data_nxt[6:0], mosi};
            index <= index + 1; // will overflow to 0 on 8th bit
        
            // if we are starting on a new byte next posedge, 
            // we should output the current complete byte
            if (index == 7) begin
                data[7:0] <= data_nxt[7:0];
                data_clk <= 1;
            end else begin
                data_clk <= 0;
            end
        end
    end
endmodule


module spi_command_parser (
    input wire data_clk,
    input wire[7:0] data
);
    logic read_command;
    logic[7:0] command;
    logic[15:0] data_count;
    logic[15:0] data_index;
    
    initial begin
        read_command = 1;
        data_count = 0;
        data_index = 0;
    end

    always @(posedge data_clk) begin
        if (data_count == data_index) begin
            command <= data;
            data_index <= 0;
            case(data)
                8'b00000000: begin
                    // send sprite command
                    // 1(spriteid) + 512(pixel values) bytes of data
                    data_count <= 513;
                end
                8'b00000001: begin
                    // draw sprite command
                    data_count <= 2;
                end
                default begin
                    // unknown command
                    data_count <= 0; // just ignore and use next byte as command
                end
            endcase
        end else begin
            data_index = data_index + 1;

            if (command == 8'b00000001 && data_index < 2) begin
                
            end
        end
    end
endmodule

module spi_reader (
    input wire cs,
    input wire sck,
    input wire mosi,
    output wire miso
);
    wire[7:0] data;
    wire data_clk;

    spi_byte_reader byte_reader(cs, sck, mosi, data_clk, data);
    spi_command_parser command_parser(data_clk, data);
endmodule