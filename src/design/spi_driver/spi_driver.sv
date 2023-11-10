module spi_driver(
    input wire sys_clock,               // FPGA clock
    input wire spi_mosi,                // SPI: Master out / slave in
    input wire spi_miso,                // SPI: Master in / slave out (currently unused)
    input wire spi_sck,                 // SPI: clock
    input wire spi_cs,                  // SPI: chip select
    input wire sprite_r_en,             // Sprite storage: read enable
    input wire [SPRITE_ADDR_SIZE:0] sprite_r_addr, // Sprite storage: Address to read from
    output logic [3:0] sprite_r_data,   // Sprite storage: The read data
    input wire dequeue,                 // Sprite write queue: dequeue (removes the first element at posedge)
    output logic is_empty,              // Sprite write queue: Is sprite queue empty?
    output logic [7:0] sprite_id,       // Sprite write queue: First sprite id
    output logic [15:0] sprite_x,       // Sprite write queue: First sprite x position
    output logic [15:0] sprite_y,       // Sprite write queue: First sprite y position
    output logic [7:0] sprite_scale     // Sprite write queue: First sprite scale
);
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
    
    // Draw queue module
    logic spi_data_clock;
    logic enqueue_en;
    assign enqueue_en = command == 8'b00000001;
    logic [7:0] spi_data;
    
    logic is_empty;
    logic [7:0] sprite_id;
    logic [15:0] sprite_x;
    logic [15:0] sprite_y;
    logic [7:0] sprite_scale;
    
    sprite_queue draw_queue(
        .clock(spi_data_clock),
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
endmodule
