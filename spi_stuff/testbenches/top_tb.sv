`timescale 1ns / 1ps


module top_tb();

reg clk;
reg [3:0]sw;
reg [3:0]btn;
reg spi_mosi;
wire spi_miso;
reg spi_sck;
reg spi_cs;
wire [3:0] led;

always #5 clk = !clk;

main top(
    .sw,
    .btn,
    .spi_mosi,
    .spi_miso,
    .spi_sck,
    .spi_cs,
    .led,
    .sys_clock(clk)
);

task send_byte;
    input [7:0] cmd;
    integer i;
    begin
        for (i = 7; i >= 0; i = i - 1) begin
            spi_mosi = cmd[i]; // Assign the bit to send
            spi_sck = 0; // send SPI clock pulse
            @(posedge clk); // Wait for the positive edge of the clock
            spi_sck = 1;
            @(posedge clk);
        end
    end
endtask

reg[7:0] spi_data;

task send_sprite;
    integer i;
    spi_cs = 0;
    #10;
    // send command
    spi_data = 8'b00000000;
    send_byte(spi_data);
    // send sprite id
    spi_data = 8'b00000010;
    send_byte(spi_data);

    // send sprite pixels
    begin
        for (i = 0; i < 512; i = i + 1) begin
            spi_data = i;
            send_byte(spi_data);
        end
    end
    
    // end command
    spi_data = 8'b00000000;
    send_byte(spi_data);

    #10;
    spi_cs = 1;
endtask

task send_draw;
    spi_cs = 0;
    #10;

    // send command
    spi_data = 8'b00000000;
    send_byte(spi_data);

    // sprite id
    spi_data = 8'b00000010;
    send_byte(spi_data);

    // position x
    spi_data = 8'b00000000;
    send_byte(spi_data);
    spi_data = 8'b00001000;
    send_byte(spi_data);

    // position y
    spi_data = 8'b00010010;
    send_byte(spi_data);
    spi_data = 8'b00011010;
    send_byte(spi_data);

    // scale
    spi_data = 8'b00000010;
    send_byte(spi_data);

    // end command
    spi_data = 8'b00000000;
    send_byte(spi_data);
endtask


initial begin
    clk = 0;
    sw = 0;
    btn = 0;
    spi_mosi = 0;
    spi_sck = 1;
    spi_cs = 1;
    
    #20;
    
    send_sprite();
    
    #500;

    send_draw();

    #20;

    send_draw();

    #500;
    
    $finish;
end
    

endmodule
