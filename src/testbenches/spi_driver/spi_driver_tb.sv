`timescale 1ns / 1ps


module spi_driver_tb();

reg clk;
reg spi_mosi;
wire spi_miso;
reg spi_sck;
reg spi_cs;
reg sprite_r_en;
reg [SPRITE_ADDR_SIZE:0] sprite_r_addr;
wire [3:0] sprite_r_data;
reg dequeue;
wire is_empty;
wire [7:0] sprite_id;
wire [15:0] sprite_x;
wire [15:0] sprite_y;
wire [7:0] sprite_scale;

always #5 clk = !clk;

main spi_driver(
    .sys_clock(clk),
    .spi_mosi,
    .spi_miso,
    .spi_sck,
    .spi_cs,
    .sprite_r_en,
    .sprite_r_addr,
    .sprite_r_data,
    .dequeue,
    .is_empty,
    .sprite_id,
    .sprite_x,
    .sprity_y,
    .sprite_scale
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
