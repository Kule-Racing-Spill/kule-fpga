module test;
    reg enable = 1;
    reg clk_enable = 1;
    reg clk = 0;
    always begin
        #5 if (clk_enable == 1) begin
            clk = !clk;
        end
    end

    reg mosi = 0;
    initial begin
        enable = 0;
        // byte 1: 01000101
        #10 mosi = 1;
        #10 mosi = 0;
        #30 mosi = 1;
        #10 mosi = 0;
        #10 mosi = 1;
        #10 // 80

        // byte 2: 01101001
        mosi = 0;
        #10 mosi = 1;
        #20 mosi = 0;
        #10 mosi = 1;
        #10 mosi = 0;
        #20 mosi = 1;
        #10 // 160

        // temporarily stop transfer
        #5 clk_enable = 0; // disable clock on positive signal
        enable = 1;
        #30

        // continue transfer
        clk_enable = 1;
        enable = 0;

        // byte 3: 01101011
        mosi = 0;
        #10 mosi = 1;
        #20 mosi = 0;
        #10 mosi = 1;
        #10 mosi = 0;
        #10 mosi = 1;
        #20 // 280

        #5 clk_enable = 0; // disable clock on positive signal
        enable = 1;

        #20 $finish;
    end


    wire[7:0] data;
    wire data_clk;
    spi_byte_reader reader (enable, clk, mosi, data_clk, data);

    always @ (posedge data_clk) begin
        $display ("Read byte at T=%4t: %8b, %c", $time, data, data);
    end
endmodule

module test2;
    // start deselected
    reg cs = 1;
    initial begin
        #100 cs = 0; // 100
        #200 $finish; // 300
    end

    reg clk_enable = 0;
    initial begin
        #20 clk_enable = 1; // 20
        #70 clk_enable = 0; // 90
        #30 clk_enable = 1; // 120
    end

    reg mosi = 0;
    initial begin
        #20 mosi = 1; // 20
        #70 mosi = 0; // 90
        #30 mosi = 1; // 120
        #30 mosi = 0; // 150
        #20 mosi = 1; // 170
        #90 mosi = 0; // 260
    end

    reg clk = 0;
    always begin
        #5 if (clk_enable == 1) begin
            clk = !clk;
        end
    end

    wire miso;
    wire[7:0] data;
    wire data_clk;
    spi_reader reader (cs, clk, mosi, miso, data, data_clk);

    always @ (posedge clk) begin
        $display ("At time %t, cs = %b, miso = %b", $time, cs, miso);
    end

    always @ (posedge data_clk) begin
        $display ("Read byte: %8b", data);
    end
endmodule