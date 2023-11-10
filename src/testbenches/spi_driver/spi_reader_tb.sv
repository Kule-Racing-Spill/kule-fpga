`timescale 1ns/1ps

module spi_reader_tb();
    
reg cs, sclk, sclk_enable, mosi;
wire miso;
wire [7:0] data_out;

// Instantiate the SPI reader module
spi_reader reader(
    .cs(cs),
    .sck(sclk),
    .mosi(mosi),
    .miso(miso),
    .command(data_out)
);

// SPI clock generation 
always #500 sclk = sclk_enable ? ~sclk : 1;

// Test procedure
initial begin
    // Initializations
    cs = 1;
    sclk = 0;
    sclk_enable = 1;
    mosi = 0;
    #520;
    
    // Start SPI transaction (CS low)
    cs = 0;
    #480; // Wait until next clk negedge
    
    // Send a byte (0b10101010 for example)
    mosi = 1; #1000; // Bit 7
    mosi = 0; #1000; // Bit 6
    mosi = 1; #1000; // Bit 5
    mosi = 0; #1000; // Bit 4
    mosi = 1; #1000; // Bit 3
    mosi = 0; #1000; // Bit 2
    mosi = 1; #1000; // Bit 1
    mosi = 0; #800; // Bit 0
    
    // End SPI transaction (CS high)
    cs = 1;
    sclk_enable = 0;
    #4000; // Wait for a while
    
    // Check the received data
    if (data_out == 8'b10101010) begin
        $display("Test Passed!");
    end else begin
        $display("Test Failed! Expected: 10101010, Received: %b", data_out);
    end
    
    // Finish simulation
    $finish;
end

endmodule