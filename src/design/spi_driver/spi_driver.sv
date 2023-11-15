module spi_driver(
    input wire clock,                   // FPGA clock
    input wire spi_mosi,                // SPI: Master out / slave in
//    input wire spi_miso,                // SPI: Master in / slave out (currently unused)
    input wire spi_clk,                 // SPI: clock
    input wire spi_cs,                  // SPI: chip select
    input wire [$clog2(SPRITE_NUM)-1:0] sprite_r0_select,
    input wire [SPRITE_ADDR_SIZE:0] sprite_r0_addr, // Sprite storage: Address to read from
    output logic [3:0] sprite_r0_data,   // Sprite storage: The read data
    input wire [$clog2(SPRITE_NUM)-1:0] sprite_r1_select,
    input wire [SPRITE_ADDR_SIZE:0] sprite_r1_addr, // Sprite storage: Address to read from
    output logic [3:0] sprite_r1_data,   // Sprite storage: The read data
    input wire dequeue,                 // Sprite write queue: dequeue (removes the first element at posedge)
    output logic is_empty,              // Sprite write queue: Is sprite queue empty?
    output logic [7:0] sprite_id,       // Sprite write queue: First sprite id
    output logic [15:0] sprite_x,       // Sprite write queue: First sprite x position
    output logic [15:0] sprite_y,       // Sprite write queue: First sprite y position
    output logic [7:0] sprite_scale     // Sprite write queue: First sprite scale
);
    // Buffer SPI clock
    BUFG bufg_inst (
        .I(spi_clk),   // Input clock
        .O(spi_clk_bufg)   // Buffered clock
    );
    
    // Sprite storage module
    logic [$clog2(SPRITE_NUM)-1:0] sprite_w_select;
    logic sprite_w_en;
    logic [SPRITE_ADDR_SIZE:0] sprite_w_addr;
    logic [7:0] sprite_w_data;
    
    sprite_storage storage (
        .clock,
        .w_select(sprite_w_select),
        .w_en(sprite_w_en),
        .w_addr(sprite_w_addr),
        .w_data(sprite_w_data),
        .r0_select(sprite_r0_select),
        .r0_addr(sprite_r0_addr),
        .r0_data(sprite_r0_data),
        .r1_select(sprite_r1_select),
        .r1_addr(sprite_r1_addr),
        .r1_data(sprite_r1_data)
    );
    
    // Draw queue module
    logic spi_data_clock;
    logic enqueue_en;
    logic [7:0] spi_data;
    
    sprite_queue draw_queue(
        .clock(clock),
        .data_clk(spi_data_clock),
        .enqueue_en,
        .enqueue_data(spi_data),
        .dequeue,
        .is_empty,
        .sprite_id,
        .sprite_x,
        .sprite_y,
        .sprite_scale
    );     
    
    // SPI reader module
    logic[7:0] command;
    assign enqueue_en = command == 8'b00000001;

    spi_reader reader(
        .clock,
        .cs(spi_cs),
        .sck(spi_clk_bufg),
        .mosi(spi_mosi),
//        .miso(spi_miso),
        .command,
        .data(spi_data),
        .data_index(spi_data_index),
        .byte_read(spi_data_clock)
    );

    spi_store_write_controller sswc(
        .clock,
        .reset(spi_en),
        .command,
        .data(spi_data),
        .data_index(spi_data_index),
        .data_read(spi_data_clock),
        .w_select(sprite_w_select),
        .w_en(sprite_w_en),
        .w_addr(sprite_w_addr),
        .w_data(sprite_w_data)
    );
endmodule
