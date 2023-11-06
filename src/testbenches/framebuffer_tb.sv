`timescale 1ns / 1ps
`include "params.vh"

module framebuffer_tb();
    logic clock = 0, reset = 0, vsync = 1;
    wire [18:0] addr_vga, addr_lcd;
    reg [3:0] data_vga, data_lcd;
 
    // write
    wire [18:0] addr_wr1, addr_wr2;
    wire [3:0] data_wr1, data_wr2;
    wire wr1_en, wr2_en;
    logic bram_en = 0;
    
    // regs that is driven to the wires
    logic [18:0] reg_addr_vga, reg_addr_lcd, reg_addr_wr1, reg_addr_wr2;
    logic [3:0] reg_data_wr1, reg_data_wr2;
    logic reg_wr1_en = 0, reg_wr2_en = 0;
    
    initial begin
        reg_addr_vga <= 1;
        reg_addr_lcd <= FRAMEBUFFER_SIZE - 2;
        // clock goes high
        #30 bram_en <= 1; // expected: data on vga and lcd data corresponding to the address
        #60 begin // expected: data on address FRAMEBUFFER_SIZE - 2 in data_vga and data on address 1 in data_lcd
            // expected: lcd addres = 1, vga address = FRAMEBUFFER_SIZE - 2
            reg_addr_lcd <= 1;
            reg_addr_vga <= FRAMEBUFFER_SIZE - 2;
        end
        // expected after 60ns: data is updated
        #120 begin // expected: no data since the fb_master has changed the fb being read to
            vsync <= 0;
        end
        #30 begin
            reg_addr_lcd <= FRAMEBUFFER_SIZE - 2;
            reg_addr_vga <= 1;
        end
        #30 begin // expected: data from prevoius address is on the data
            vsync <= 1;
            reg_addr_lcd <= 1;
            reg_addr_vga <= FRAMEBUFFER_SIZE - 2;
        end
        #60 begin // expected: data from prevoius address is on the data
            reg_addr_lcd <= FRAMEBUFFER_SIZE - 2;
            reg_addr_vga <= 1;
        end
        #60 vsync <= 0; // expected: data is swapped, since framebuffer is swapped
        // test writing
        #30 begin
            vsync <= 1;
            reg_wr1_en <= 1;
            reg_wr2_en <= 1;
            reg_addr_wr1 <= 1;
            reg_addr_wr2 <= 2;
            reg_data_wr1 <= 4'b1111;
            reg_data_wr2 <= 4'b1010;
        end
        // swap buffers so we can read from it again
        #90 vsync <= 0;
        #30 begin
            reg_addr_vga <= 1;
            reg_addr_lcd <= 2;
        end
        $finish;
    end
    
    assign addr_vga = reg_addr_vga;
    assign addr_lcd = reg_addr_lcd;
    assign addr_wr1 = reg_addr_wr1;
    assign addr_wr2 = reg_addr_wr2;
    assign data_wr1 = reg_data_wr1;
    assign data_wr2 = reg_data_wr2;
    assign wr1_en = reg_wr1_en;
    assign wr2_en = reg_wr2_en;
    
    // artificial clock
    always #30 clock <= ~clock;
    
    framebuffer_master fb_master(
        clock,
        reset,
        vsync,
        addr_vga,
        data_vga,
        addr_lcd,
        data_lcd,
        addr_wr1,
        addr_wr2,
        data_wr1,
        data_wr2,
        wr1_en,
        wr2_en,
        bram_en
    );
endmodule