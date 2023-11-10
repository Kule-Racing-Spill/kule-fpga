module sprite_cache(
    input logic write_enable,
    input logic write_clk,
    input logic[7:0] write_data,
    input logic[7:0] write_id
);

    // 4*32*32=4096 bits per sprite, assuming 8 sprites
    logic[32767:0] pixel_storage;
    logic pixel_index;

    initial begin
        pixel_storage = 0;
        pixel_index = 0;
    end

    always @(posedge write_clk) begin
        if (!write_enable) begin
            pixel_index <= 0;
        end else begin
            pixel_storage[pixel_index+7:pixel_index] = write_data[7:0];
            pixel_index <= pixel_index + 1;
        end
    end

endmodule