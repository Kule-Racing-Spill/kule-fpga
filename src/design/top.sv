`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/06/2023 10:50:00 AM
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module top_not_working (
    input wire logic clk_100m,
    input  wire logic btn_rst_n,
    // VGA
    output logic vga_hsync,
    output logic vga_vsync,
    output      logic [3:0] vga_r,  // 4-bit VGA red
    output      logic [3:0] vga_g,  // 4-bit VGA green
    output      logic [3:0] vga_b   // 4-bit VGA blue
    );
    
    
    // for now, pin reset to low
    logic reset = 0;
    
    // VGA takes the most time to draw active pixels, therefore
    // the global vsync should follow this
    wire logic global_vsync;
    assign global_vsync = vga_vsync;
    
    // address and data buses for the screen drivers
    wire logic [18:0] addr_vga;
    wire logic [18:0] addr_wr1 = 0, addr_wr2 = 0;
    wire logic [3:0] data_wr1 = 0, data_wr2 = 0;
    wire logic wr1_en = 0, wr2_en = 0;
    
    // generate pixel clock
    logic clk;
    logic clk_pix_locked;
    logic rst_pix;
    clock_480p clock_pix_inst (
       .clk_100m,
       .rst(!btn_rst_n),  // reset button is active low
       .clk_pix(clk),
       .clk_pix_5x(),  // not used for VGA output
       .clk_pix_locked
    );
    always_ff @(posedge clk) rst_pix <= !clk_pix_locked;  // wait for clock lock
    
    // enable bram
    logic bram_en = 1;
    
    // color index for vga
    logic [3:0] data_vga;
    
    // initiate framebuffers
    framebuffer_master fb_master(
        clk,
        !locked,
        global_vsync,
        addr_vga,
        data_vga,
        addr_wr1,
        addr_wr2,
        data_wr1,
        data_wr2,
        wr1_en,
        wr2_en,
        bram_en
    );
    
    // initiate screen_driver module
    /*screen_driver sd(
        clk,
        vga_hsync,
        vga_vsync,
        vga_r,
        vga_g,
        vga_b,
        addr_vga,
        data_vga,
    );*/
    
    always_ff @(posedge clk) begin
        vga_r <= 4'b1111;
        vga_g <= 4'b1111;
        vga_b <= 4'b1111;
    end
    
endmodule

module framebuffer_master(
    input wire logic clock,
    input wire logic reset,
    input wire logic vsync,
    
    // READ VGA
    input wire [18:0] addr_vga,
    output logic [3:0] data_vga,
    
    
    // write
    input wire [18:0] addr_wr1,
    input wire [18:0] addr_wr2,
    input wire [3:0] data_wr1,
    input wire [3:0] data_wr2,
    input wire wr1_en,
    input wire wr2_en,
    input logic bram_en
    );

    logic old_vsync;
    logic read_pick = 0;

    // aliases
    // write signals
    logic fb0_wr1_en, fb0_wr2_en, fb1_wr1_en, fb1_wr2_en;
    // address busses
    logic [18:0] fb0_addr1, fb0_addr2, fb1_addr1, fb1_addr2;
    // input data busses
    logic [3:0] fb0_dataw1, fb0_dataw2, fb1_dataw1, fb1_dataw2;
    // output data busses
    logic [3:0] fb0_datar1, fb0_datar2, fb1_datar1, fb1_datar2;

    // temporary storage for output data when framebuffer is write-only
    logic [3:0] fb_data_temp1, fb_data_temp2;

    always_ff @(posedge clock) begin
        // only flip read_pick at negative edge
        if (old_vsync != vsync && ~vsync) begin
            // switch buffers
            read_pick <= ~read_pick;
        end
    end

    // use vsync to switch buffers
    always_comb begin
        // set old_vsync to current vsync so we dont flip read_pick all the time when vsync is low
        old_vsync <= vsync;

        if (read_pick) begin
            // read from fb1
            fb1_wr1_en <= 0;
            fb1_wr2_en <= 0;

            // port 1 (VGA)
            fb1_addr1 <= addr_vga;
            data_vga <= fb1_datar1;
            fb1_dataw1 <= 4'b0000;

            // write to fb0
            fb0_wr1_en <= wr1_en;
            fb0_wr2_en <= wr2_en;

            // addresses
            fb0_addr1 <= addr_wr1;
            fb0_addr2 <= addr_wr2;

            // input data
            fb0_dataw1 <= data_wr1;
            fb0_dataw2 <= data_wr2;

            // output data
            fb_data_temp1 <= fb0_datar1;
            fb_data_temp2 <= fb0_datar2;
        end else begin
            // read from fb0
            fb0_wr1_en <= 0;
            fb0_wr2_en <= 0;

            // port 1 (VGA)
            fb0_addr1 <= addr_vga;
            data_vga <= fb0_datar1;
            fb0_dataw1 <= 4'b0000;


            // write to fb1
            fb1_wr1_en <= wr1_en;
            fb1_wr2_en <= wr2_en;

            // addresses
            fb1_addr1 <= addr_wr1;
            fb1_addr2 <= addr_wr2;

            // input data
            fb1_dataw1 <= data_wr1;
            fb1_dataw2 <= data_wr2;

            // output data
            fb_data_temp1 <= fb1_datar1;
            fb_data_temp2 <= fb1_datar2;
        end
    end

    // framebuffer 1
    framebuffer fb0(
        clock,
        // port 1
        fb0_wr1_en,
        fb0_addr1,
        fb0_dataw1,
        fb0_datar1,
        // port 2
        fb0_wr2_en,
        fb0_addr2,
        fb0_dataw2,
        fb0_datar2,
        bram_en
    );

    // framebuffer 2
    framebuffer fb1(
        clock,
        // port 1
        fb1_wr1_en,
        fb1_addr1,
        fb1_dataw1,
        fb1_datar1,
        // port 2
        fb1_wr2_en,
        fb1_addr2,
        fb1_dataw2,
        fb1_datar2,
        bram_en
    );
endmodule

module top_ (
    input  wire logic clk_100m,     // 100 MHz clock
    input  wire logic btn_rst_n,    // reset button
    output      logic vga_hsync,    // horizontal sync
    output      logic vga_vsync,    // vertical sync
    output      logic [3:0] vga_r,  // 4-bit VGA red
    output      logic [3:0] vga_g,  // 4-bit VGA green
    output      logic [3:0] vga_b   // 4-bit VGA blue
    );

    // generate pixel clock
    logic clk_pix;
    logic clk_pix_locked;
    logic rst_pix;
    clock_480p clock_pix_inst (
       .clk_100m,
       .rst(!btn_rst_n),  // reset button is active low
       .clk_pix,
       .clk_pix_5x(),  // not used for VGA output
       .clk_pix_locked
    );
    //always_ff @(posedge clk_pix) rst_pix <= !clk_pix_locked;  // wait for clock lock

    // display sync signals and coordinates
    localparam CORDW = 19;  // signed coordinate width (bits)
    logic signed [CORDW-1:0] sx, sy;
    
    logic hsync, vsync;
    logic de, frame;
    
    //vga_signals vga_signals(clk_pix, rst_pix, sx, sy, hsync, vsync, de);
    
    display_480p #(.CORDW(CORDW)) display_inst (
        .clk_pix,
        .rst_pix,
        .sx,
        .sy,
        .hsync,
        .vsync,
        .de,
        .frame,
        .line()
    );
    

    // framebuffer (FB)
    localparam FB_WIDTH  = 800;  // framebuffer width in pixels
    localparam FB_HEIGHT = 480;  // framebuffer width in pixels
    localparam FB_PIXELS = FB_WIDTH * FB_HEIGHT;  // total pixels in buffer
    localparam FB_ADDRW  = 19;//$clog2(FB_PIXELS);  // address width
    localparam FB_DATAW  = 4;  // colour bits per pixel
    
    
    logic [3:0] counter = 4'b0;
    logic write;
    
    
    
    logic [FB_ADDRW-1:0] fb_addr_read;
    logic [3:0] fb_pixel_value;

    // framebuffer memory
    framebuffer #(
    ) framebuffer_instance_1 (
        .clock(clk_pix),
        .fb_wr1_en(0), // active high. Low means read
        .fb_addr_1(fb_addr_read),   // address bus for R/W port 1
        .fb_dataw_1(counter), // input data to port 1 (if we write)
        .fb_datar_1(fb_pixel_value),   // output data from port 1 (if we read)
        
        .fb_wr2_en(0),
        .fb_addr_2(0),
        .fb_dataw_2(),
        .fb_datar_2(),
        .en(1)
    );
    
    


    // calculate framebuffer read address for display output
    logic read_fb;
    always_ff @(posedge clk_pix) begin
        /*read_fb <= (sy <= FB_HEIGHT && sx <= FB_WIDTH);
        if (rst_pix) begin  // reset address at start of frame
            fb_addr_read <= 0;
        end else if (sy == 479 && sx == 799) begin  // increment address in painting area
            fb_addr_read <= 0;
        end else if (read_fb) begin  // increment address in painting area
            fb_addr_read <= fb_addr_read + 1;
        end*/
        
        if (sy <= 480 && sx <= 800) begin
            fb_addr_read <= (sy*FB_WIDTH)+sx;
        end
        /*if(frame) begin
            counter <= counter + 1;
            //write <= 1;
        end else begin
            write <= 0;
        end
        
        if(counter == 4'b1111) begin
            counter <= 4'b0;
        end*/
    end

    // paint screen. display colour: paint colour but black in blanking interval
    logic [3:0] display_r, display_g, display_b;
    
    always_comb begin
        if(!de) begin
          { display_r, display_g, display_b} = {4'b0,4'b0,4'b0};
        end
        else begin
            if (sy <= 480 && sx <= 800) begin
                { display_r, display_g, display_b} = {fb_pixel_value,4'b0,4'b0};
            end else begin
            { display_r, display_g, display_b} = {4'b0,4'b1111,4'b0};
            end
        end
    end
    
    // VGA Pmod output
    always_ff @(posedge clk_pix) begin
        vga_hsync <= hsync;
        vga_vsync <= vsync;
        vga_r <= display_r;
        vga_g <= display_g;
        vga_b <= display_b;
    end
endmodule

module screen_driver(
    input wire logic pixel_clock,
    input wire logic pixel_reset,
    // VGA
    output logic vga_hsync,
    output logic vga_vsync,
    output logic [4:0] vga_red,
    output logic [4:0] vga_green,
    output logic [4:0] vga_blue,
    
    
    // RAM interface
    output wire [18:0] addr_vga,
    input logic [3:0] data_vga
    );
    

    // initiate vga driver
    vga_driver vga_driver(
        pixel_clock,
        pixel_reset,
        vga_hsync,
        vga_vsync,
        vga_red,
        vga_green,
        vga_blue,
        addr_vga,
        data_vga
    );
    
endmodule

module framebuffer(
    input wire logic clock,
    // R/W port 1
    input wire logic fb_wr1_en,          // active high. Low means read
    input wire logic [18:0] fb_addr_1,   // address bus for R/W port 1
    input wire logic [3:0] fb_dataw_1,    // input data to port 1 (if we write)
    output logic [3:0] fb_datar_1,   // output data from port 1 (if we read)
    // R/W port 2
    input wire logic fb_wr2_en,
    input wire logic [18:0] fb_addr_2,
    input wire logic [3:0] fb_dataw_2,
    output logic [3:0] fb_datar_2,
    input wire logic en
    );

    // initialize ram
    logic [3:0] ram [384000-1:0];
    
    //191999
    integer i,a,b,c,d;
    initial begin
        begin for (i = 0; i <= (480/2); i = i + 2) 
            for (a = 0; a <= (400); a = a + 1) ram[((i+0)*800)+a] <= 4'b1111;
            //for (b = 0; b <= (800); b = b + 1) ram[((i+1)*800)+b] <= 4'b0001;
            //for (c = 0; c < (800); c = c + 1) ram[((i+2)*800)+c] <= 4'b0100;
            //for (d = 0; d < (800); d = d + 1) ram[((i+3)*800)+d] <= 4'b1111;
        end
        //for (i = 0; i < (400); i = i + 1) ram[i+(480)] <= 4'b1111;
        /*
        for (i = 0; i < (800); i = i + 1) ram[i+(480*1)] <= 4'b0000;
        for (i = 0; i < (800); i = i + 1) ram[i+(480*2)] <= 4'b0000;
        for (i = 0; i < (800); i = i + 1) ram[i+(480*3)] <= 4'b1111;*/
        //for (i = 192000; i 3840< ; i = i + 1) ram[i] <= 4'b0011;
    end

    always @(posedge clock) begin
        // R/W port 1
        if (en) begin
            if (fb_wr1_en) begin
                ram[fb_addr_1] <= fb_dataw_1;
            end
            fb_datar_1 <= ram[fb_addr_1];
        end
    end

    always @(posedge clock) begin
        if (en) begin
            if (fb_wr2_en) begin
                ram[fb_addr_2] <= fb_dataw_2;
            end
            fb_datar_2 <= ram[fb_addr_2];
        end
    end
endmodule

module vga_driver(
    input wire logic pixel_clk,
    input wire logic rst_pixel,
    output logic vga_hsync,
    output logic vga_vsync,
    output logic [4:0] vga_red,
    output logic [4:0] vga_green,
    output logic [4:0] vga_blue,
    // RAM
    output wire [18:0] addr,
    input logic [3:0] data
    );
    
    // data enable
    logic de;
    // control signals
    logic hsync, vsync;
    // positions
    logic [9:0] sx, sy;
    // color
    logic [14:0] current_color;
    
    // generate signals
    vga_signals vga_signals(pixel_clk, rst_pixel, sx, sy, hsync, vsync, de);
    
    // fetch the color on position sx, sy
    vga_color vga_color(sx, sy, current_color, addr, data);
    
    always_ff @(posedge pixel_clk) begin
        // send sync signals
        vga_hsync <= hsync;
        vga_vsync <= vsync;
        
        // should we draw?
        vga_red <= (de) ? current_color[14:10] : 5'b11111;
        vga_green <= (de) ? current_color[9:5] : 5'b11111;
        vga_blue <= (de) ? current_color[4:0] : 5'b11111;
    end
endmodule

module vga_color(
    input logic [9:0] sx,
    input logic [9:0] sy,
    output logic [14:0] color,
    // RAM
    output wire [18:0] addr,
    input logic [3:0] data
    );
    
    parameter MAX_SX = 799;
    parameter MAX_SY = 479;
    
    // fetch the next color
    // nasty hack so it supports both a35t and a100t
    assign addr = (sx <= MAX_SX && sy <= MAX_SY) ? ((sy * 800 + sx) < 384000 ? (sy * 800 + sx) : (sy * 800 + sx) / 2) : 0;
    
    // fetch the color from the colormap
    vga_colormap vga_col(data, color);
endmodule

module vga_colormap(
    input logic [3:0] index,
    output logic [14:0] color
    );
    // counter variables
    integer i = 0;
    
    // color array. Contains 16 15-bit colors
    reg [14:0] colors [0:15];
    
    // TODO: set better colors
    initial begin
        for (i = 2; i < 16; i = i + 1) colors[i] <= 15'b101010101010101 + i;
        colors[0] <= 15'b111111111111111;
        colors[1] <= 15'b000010001100111;
    end
     
    // drive the color
    always_comb begin
        color <= 15'b111111111111111;//colors[index];
    end
endmodule


module vga_signals(
    input wire logic pixel_clk,     // pixel clock, see calculations.md for details
    input wire logic rst_pixel,     // reset pixel
    output logic [9:0] sx,          // x position
    output logic [9:0] sy,          // y position
    output logic hsync,             // horizontal sync
    output logic vsync,             // vertical sync
    output logic de                 // data enable
    );
    
    // timings are fetched from https://tomverbeure.github.io/video_timings_calculator
    // with w = 800, h = 480, refresh = 60Hz
    // horizontal timings
    parameter HA_END = 799;             // last active horizontal pixel
    parameter HS_START = HA_END + 24;   // hsync starts after front porch
    parameter HS_END = HS_START + 72;   // hsync ends after 72 clock cycles
    parameter LINE = 991;               // last pixel on line (after back porch)
    
    // vertical timings
    parameter VA_END = 479;             // end of active pixels
    parameter VS_START = VA_END + 3;    // vsync starts after front porch
    parameter VS_END = VS_START + 7;    // vsync end after 7 clock cycles
    parameter FRAME = 499;              // last line on frame after back porch
    

    // set control signals (hsync, vsync and de)
    always_comb begin
        hsync = ~(sx >= HS_START && sx < HS_END);   // invert since negative polarity
        vsync = ~(sy >= VS_START && sy < VS_END);   // invert since negative polarity
        de = (sx <= HA_END && sy <= VA_END);        // enable data when in active pixels
    end
    
    
    // decide horizontal and vertical position
    always_ff @(posedge pixel_clk) begin
        if (sx == LINE) begin
            // we reached the end of the line, set sx to 0 and check if we are done with frame as well
            sx <= 0;
            sy <= (sy == FRAME) ? 0 : sy + 1;
        end else begin
            // else increment sx
            sx <= sx + 1;
        end
        // reset positions if reset is high
        if (rst_pixel) begin
            sx <= 0;
            sy <= 0;
        end
    end
endmodule


module framebuffer_old(
    input wire logic clock,
    // R/W port 1
    input logic fb_wr1_en,          // active high. Low means read
    input logic [18:0] fb_addr_1,   // address bus for R/W port 1
    input logic [3:0] fb_dataw_1,    // input data to port 1 (if we write)
    output logic [3:0] fb_datar_1,   // output data from port 1 (if we read)
    // R/W port 2
    input logic fb_wr2_en,
    input logic [18:0] fb_addr_2,
    input logic [3:0] fb_dataw_2,
    output logic [3:0] fb_datar_2
    );
    
    // initialize ram
    reg [3:0] ram [0:299];
    integer i, n;
    

    always @(posedge clock) begin
        // R/W port 1
        if (fb_wr1_en) begin
            ram[fb_addr_1] <= fb_dataw_1;
        end else begin
            fb_datar_1 <= ram[fb_addr_1];
        end

        // R/W port 2
        if (fb_wr2_en) begin
            ram[fb_addr_2] <= fb_dataw_2;
        end else begin
            fb_datar_2 <= ram[fb_addr_2];
        end
    end

endmodule

module top_old (
    input  wire logic clk_100m,     // 100 MHz clock
    input  wire logic btn_rst_n,    // reset button
    output      logic vga_hsync,    // horizontal sync
    output      logic vga_vsync,    // vertical sync
    output      logic [3:0] vga_r,  // 4-bit VGA red
    output      logic [3:0] vga_g,  // 4-bit VGA green
    output      logic [3:0] vga_b   // 4-bit VGA blue
    );

    // generate pixel clock
    logic clk_pix;
    logic clk_pix_locked;
    logic rst_pix;
    clock_480p clock_pix_inst (
       .clk_100m,
       .rst(!btn_rst_n),  // reset button is active low
       .clk_pix,
       .clk_pix_5x(),  // not used for VGA output
       .clk_pix_locked
    );
    always_ff @(posedge clk_pix) rst_pix <= !clk_pix_locked;  // wait for clock lock

    // display sync signals and coordinates
    localparam CORDW = 16;  // signed coordinate width (bits)
    logic signed [CORDW-1:0] sx, sy;
    logic hsync, vsync;
    logic de, frame;
    display_480p #(.CORDW(CORDW)) display_inst (
        .clk_pix,
        .rst_pix,
        .sx,
        .sy,
        .hsync,
        .vsync,
        .de,
        .frame,
        .line()
    );

    // colour parameters
    localparam CHANW = 4;        // colour channel width (bits)
    localparam COLRW = 3*CHANW;  // colour width: three channels (bits)
    localparam BG_COLR = 'h137;  // background colour

    // framebuffer (FB)
    localparam FB_WIDTH  = 160;  // framebuffer width in pixels
    localparam FB_HEIGHT = 120;  // framebuffer width in pixels
    localparam FB_PIXELS = FB_WIDTH * FB_HEIGHT;  // total pixels in buffer
    localparam FB_ADDRW  = $clog2(FB_PIXELS);  // address width
    localparam FB_DATAW  = 1;  // colour bits per pixel
    localparam FB_IMAGE  = "david_1bit.mem";  // bitmap file
    // localparam FB_IMAGE  = "test_box_mono_160x120.mem";  // bitmap file

    // pixel read address and colour
    logic [FB_ADDRW-1:0] fb_addr_read;
    logic [FB_DATAW-1:0] fb_colr_read;

    // framebuffer memory
    bram_sdp #(
        .WIDTH(FB_DATAW),
        .DEPTH(FB_PIXELS),
        .INIT_F(FB_IMAGE)
    ) bram_inst (
        .clk_write(clk_pix),
        .clk_read(clk_pix),
        .we(),
        .addr_write(),
        .addr_read(fb_addr_read),
        .data_in(),
        .data_out(fb_colr_read)
    );

    // calculate framebuffer read address for display output
    localparam LAT = 2;  // read_fb+1, BRAM+1
    logic read_fb;
    always_ff @(posedge clk_pix) begin
        read_fb <= (sy >= 0 && sy < FB_HEIGHT && sx >= -LAT && sx < FB_WIDTH-LAT);
        if (frame) begin  // reset address at start of frame
            fb_addr_read <= 0;
        end else if (read_fb) begin  // increment address in painting area
            fb_addr_read <= fb_addr_read + 1;
        end
    end

    // paint screen
    logic paint_area;  // area of framebuffer to paint
    logic [CHANW-1:0] paint_r, paint_g, paint_b;  // colour channels
    always_comb begin
        paint_area = (sy >= 0 && sy < FB_HEIGHT && sx >= 0 && sx < FB_WIDTH);
        {paint_r, paint_g, paint_b} = paint_area ? {COLRW{fb_colr_read}} : BG_COLR;
    end

    // display colour: paint colour but black in blanking interval
    logic [CHANW-1:0] display_r, display_g, display_b;
    always_comb {display_r, display_g, display_b} = (de) ? {1, 1, 1} : 0;

    // VGA Pmod output
    always_ff @(posedge clk_pix) begin
        vga_hsync <= hsync;
        vga_vsync <= vsync;
        vga_r <= 1;
        vga_g <= 1;
        vga_b <= paint_b;
    end
endmodule

module top (
    input  wire logic clk_100m,     // 100 MHz clock
    input  wire logic btn_rst_n,    // reset button
    output      logic vga_hsync,    // horizontal sync
    output      logic vga_vsync,    // vertical sync
    output      logic [3:0] vga_r,  // 4-bit VGA red
    output      logic [3:0] vga_g,  // 4-bit VGA green
    output      logic [3:0] vga_b   // 4-bit VGA blue
    );

    // generate pixel clock
    logic clk_pix;
    logic clk_pix_locked;
    logic rst_pix;
    clock_480p clock_pix_inst (
       .clk_100m,
       .rst(!btn_rst_n),  // reset button is active low
       .clk_pix,
       .clk_pix_5x(),  // not used for VGA output
       .clk_pix_locked
    );
    always_ff @(posedge clk_pix) rst_pix <= !clk_pix_locked;  // wait for clock lock

    // display sync signals and coordinates
    localparam CORDW = 16;  // signed coordinate width (bits)
    logic signed [CORDW-1:0] sx, sy;
    logic hsync, vsync;
    logic de, frame, line;
    display_480p #(.CORDW(CORDW)) display_inst (
        .clk_pix,
        .rst_pix,
        .sx,
        .sy,
        .hsync,
        .vsync,
        .de,
        .frame,
        .line
    );

    // screen dimensions (must match display_inst)
    localparam H_RES = 640;
    localparam V_RES = 480;

    // sprite parameters
    localparam SPR_WIDTH  = 8;  // bitmap width in pixels
    localparam SPR_HEIGHT = 8;  // bitmap height in pixels
    localparam SPR_SCALE  = 3;  // 2^3 = 8x scale
    localparam SPR_DATAW  = 1;  // bits per pixel
    localparam SPR_DRAWW  = SPR_WIDTH  * 2**SPR_SCALE;  // draw width
    localparam SPR_DRAWH  = SPR_HEIGHT * 2**SPR_SCALE;  // draw height
    localparam SPR_SPX    = 4;  // horizontal speed (pixels/frame)
    localparam SPR_FILE   = "letter_f.mem";  // bitmap file

    // draw sprite at position (sprx,spry)
    logic signed [CORDW-1:0] sprx, spry;
    logic dx;  // direction: 0 is right/down

    // update sprite position once per frame
    always_ff @(posedge clk_pix) begin
        if (frame) begin
            if (dx == 0) begin  // moving right
                if (sprx + SPR_DRAWW >= H_RES + 2*SPR_DRAWW) dx <= 1;  // move left
                else sprx <= sprx + SPR_SPX;  // continue right
            end else begin  // moving left
                if (sprx <= -2*SPR_DRAWW) dx <= 0;  // move right
                else sprx <= sprx - SPR_SPX;  // continue left
            end
        end
        if (rst_pix) begin  // centre sprite and set direction right
            sprx <= H_RES/2 - SPR_DRAWW/2;
            spry <= V_RES/2 - SPR_DRAWH/2;
            dx <= 0;
        end
    end

    logic drawing;  // drawing at (sx,sy)
    logic [SPR_DATAW-1:0] pix;  // pixel colour index
    sprite #(
        .CORDW(CORDW),
        .H_RES(H_RES),
        .SPR_FILE(SPR_FILE),
        .SPR_WIDTH(SPR_WIDTH),
        .SPR_HEIGHT(SPR_HEIGHT),
        .SPR_SCALE(SPR_SCALE),
        .SPR_DATAW(SPR_DATAW)
        ) sprite_f (
        .clk(clk_pix),
        .rst(rst_pix),
        .line,
        .sx,
        .sy,
        .sprx,
        .spry,
        .pix,
        .drawing
    );

    // paint colour: yellow sprite, blue background
    logic [3:0] background_r, background_g, background_b;
    
    always_comb begin
        background_r = (sy < V_RES/2) ?  4'h0 : 4'h2;
        background_g = (sy < V_RES/2) ?  4'hF : 4'h4;
        background_b = (sy < V_RES/2) ?  4'h0 : 4'hF;
    end
    
    logic [3:0] paint_r, paint_g, paint_b;
    always_comb begin
        paint_r = (drawing && pix) ? 4'hF : background_r;
        paint_g = (drawing && pix) ? 4'h5 : background_g;
        paint_b = (drawing && pix) ? 4'h5 : background_b;
        
        
    end

    // display colour: paint colour but black in blanking interval
    logic [3:0] display_r, display_g, display_b;
    always_comb begin
        display_r = (de) ? paint_r : 4'h0;
        display_g = (de) ? paint_g : 4'h0;
        display_b = (de) ? paint_b : 4'h0;
    end

    // VGA Pmod output
    always_ff @(posedge clk_pix) begin
        vga_hsync <= hsync;
        vga_vsync <= vsync;
        vga_r <= 1;
        vga_g <= 0;
        vga_b <= 0;
    end
endmodule

module sprite #(
    parameter CORDW=16,      // signed coordinate width (bits)
    parameter H_RES=640,     // horizontal screen resolution (pixels)
    parameter SX_OFFS=2,     // horizontal screen offset (pixels)
    parameter SPR_FILE="",   // sprite bitmap file ($readmemh format)
    parameter SPR_WIDTH=8,   // sprite bitmap width in pixels
    parameter SPR_HEIGHT=8,  // sprite bitmap height in pixels
    parameter SPR_SCALE=0,   // scale factor: 0=1x, 1=2x, 2=4x, 3=8x etc.
    parameter SPR_DATAW=1    // data width: bits per pixel
    ) (
    input  wire logic clk,                            // clock
    input  wire logic rst,                            // reset
    input  wire logic line,                           // start of active screen line
    input  wire logic signed [CORDW-1:0] sx, sy,      // screen position
    input  wire logic signed [CORDW-1:0] sprx, spry,  // sprite position
    output      logic [SPR_DATAW-1:0] pix,            // pixel colour index
    output      logic drawing                         // drawing at position (sx,sy)
    );

    // sprite bitmap ROM
    localparam SPR_ROM_DEPTH = SPR_WIDTH * SPR_HEIGHT;
    logic [$clog2(SPR_ROM_DEPTH)-1:0] spr_rom_addr;  // pixel position
    logic [SPR_DATAW-1:0] spr_rom_data;  // pixel colour
    rom_async #(
        .WIDTH(SPR_DATAW),
        .DEPTH(SPR_ROM_DEPTH),
        .INIT_F(SPR_FILE)
    ) spr_rom (
        .addr(spr_rom_addr),
        .data(spr_rom_data)
    );

    // horizontal coordinate within sprite bitmap
    logic [$clog2(SPR_WIDTH)-1:0] bmap_x;

    // horizontal scale counter
    logic [SPR_SCALE:0] cnt_x;

    // for registering sprite position
    logic signed [CORDW-1:0] sprx_r, spry_r;

    // status flags: used to change state
    logic signed [CORDW-1:0]  spr_diff;  // diff vertical screen and sprite positions
    logic spr_active;  // sprite active on this line
    logic spr_begin;   // begin sprite drawing
    logic spr_end;     // end of sprite on this line
    logic line_end;    // end of screen line, corrected for sx offset
    always_comb begin
        spr_diff = (sy - spry_r) >>> SPR_SCALE;  // arithmetic right-shift
        spr_active = (spr_diff >= 0) && (spr_diff < SPR_HEIGHT);
        spr_begin = (sx >= sprx_r - SX_OFFS);
        spr_end = (bmap_x == SPR_WIDTH-1);
        line_end = (sx == H_RES - SX_OFFS);
    end

    // sprite state machine
    enum {
        IDLE,      // awaiting line signal
        REG_POS,   // register sprite position
        ACTIVE,    // check if sprite is active on this line
        WAIT_POS,  // wait for horizontal sprite position
        SPR_LINE,  // iterate over sprite pixels
        WAIT_DATA  // account for data latency
    } state;

    always_ff @(posedge clk) begin
        if (line) begin  // prepare for new line
            state <= REG_POS;
            pix <= 0;
            drawing <= 0;
        end else begin
            case (state)
                REG_POS: begin
                    state <= ACTIVE;
                    sprx_r <= sprx;
                    spry_r <= spry;
                end
                ACTIVE: state <= spr_active ? WAIT_POS : IDLE;
                WAIT_POS: begin
                    if (spr_begin) begin
                        state <= SPR_LINE;
                        spr_rom_addr <= spr_diff * SPR_WIDTH + (sx - sprx_r) + SX_OFFS;
                        bmap_x <= 0;
                        cnt_x <= 0;
                    end
                end
                SPR_LINE: begin
                    if (line_end) state <= WAIT_DATA;
                    pix <= spr_rom_data;
                    drawing <= 1;
                    if (SPR_SCALE == 0 || cnt_x == 2**SPR_SCALE-1) begin
                        if (spr_end) state <= WAIT_DATA;
                        spr_rom_addr <= spr_rom_addr + 1;
                        bmap_x <= bmap_x + 1;
                        cnt_x <= 0;
                    end else cnt_x <= cnt_x + 1;
                end
                WAIT_DATA: begin
                    state <= IDLE;  // 1 cycle between address set and data receipt
                    pix <= 0;  // default colour
                    drawing <= 0;
                end
                default: state <= IDLE;
            endcase
        end

        if (rst) begin
            state <= IDLE;
            spr_rom_addr <= 0;
            bmap_x <= 0;
            cnt_x <= 0;
            pix <= 0;
            drawing <= 0;
        end
    end
endmodule

module bram_sdp #(
    parameter WIDTH=8, 
    parameter DEPTH=256, 
    parameter INIT_F="",
    localparam ADDRW=$clog2(DEPTH)
    ) (
    input wire logic clk_write,               // write clock (port a)
    input wire logic clk_read,                // read clock (port b)
    input wire logic we,                      // write enable (port a)
    input wire logic [ADDRW-1:0] addr_write,  // write address (port a)
    input wire logic [ADDRW-1:0] addr_read,   // read address (port b)
    input wire logic [WIDTH-1:0] data_in,     // data in (port a)
    output     logic [WIDTH-1:0] data_out     // data out (port b)
    );

    logic [WIDTH-1:0] memory [DEPTH];

    initial begin
        if (INIT_F != 0) begin
            $display("Load init file '%s' into bram_sdp.", INIT_F);
            $readmemh(INIT_F, memory);
        end
    end

    // Port A: Sync Write
    always_ff @(posedge clk_write) begin
        if (we) memory[addr_write] <= data_in;
    end

    // Port B: Sync Read
    always_ff @(posedge clk_read) begin
        data_out <= memory[addr_read];
    end
endmodule

module rom_async #(
    parameter WIDTH=8,
    parameter DEPTH=256,
    parameter INIT_F="",
    localparam ADDRW=$clog2(DEPTH)
    ) (
    input wire logic [ADDRW-1:0] addr,
    output     logic [WIDTH-1:0] data
    );

    logic [WIDTH-1:0] memory [DEPTH];

    initial begin
        if (INIT_F != 0) begin
            $display("Creating rom_async from init file '%s'.", INIT_F);
            $readmemh(INIT_F, memory);
        end
    end

    always_comb data = memory[addr];
endmodule

module clock_480p (
    input  wire logic clk_100m,       // input clock (100 MHz)
    input  wire logic rst,            // reset
    output      logic clk_pix,        // pixel clock
    output      logic clk_pix_5x,     // 5x clock for 10:1 DDR SerDes
    output      logic clk_pix_locked  // pixel clock locked?
    );

    localparam MULT_MASTER=31.5;  // master clock multiplier (2.000-64.000)
    localparam DIV_MASTER=5;      // master clock divider (1-106)
    localparam DIV_5X=5.0;        // 5x pixel clock divider
    localparam DIV_1X=25;         // pixel clock divider
    localparam IN_PERIOD=10.0;    // period of master clock in ns (10 ns == 100 MHz)

    logic feedback;          // internal clock feedback
    logic clk_pix_unbuf;     // unbuffered pixel clock
    logic clk_pix_5x_unbuf;  // unbuffered 5x pixel clock
    logic locked;            // unsynced lock signal

    MMCME2_BASE #(
        .CLKFBOUT_MULT_F(MULT_MASTER),
        .CLKIN1_PERIOD(IN_PERIOD),
        .CLKOUT0_DIVIDE_F(DIV_5X),
        .CLKOUT1_DIVIDE(DIV_1X),
        .DIVCLK_DIVIDE(DIV_MASTER)
    ) MMCME2_BASE_inst (
        .CLKIN1(clk_100m),
        .RST(rst),
        .CLKOUT0(clk_pix_5x_unbuf),
        .CLKOUT1(clk_pix_unbuf),
        .LOCKED(locked),
        .CLKFBOUT(feedback),
        .CLKFBIN(feedback),
        /* verilator lint_off PINCONNECTEMPTY */
        .CLKOUT0B(),
        .CLKOUT1B(),
        .CLKOUT2(),
        .CLKOUT2B(),
        .CLKOUT3(),
        .CLKOUT3B(),
        .CLKOUT4(),
        .CLKOUT5(),
        .CLKOUT6(),
        .CLKFBOUTB(),
        .PWRDWN()
        /* verilator lint_on PINCONNECTEMPTY */
    );

    // explicitly buffer output clocks
    BUFG bufg_clk(.I(clk_pix_unbuf), .O(clk_pix));
    BUFG bufg_clk_5x(.I(clk_pix_5x_unbuf), .O(clk_pix_5x));

    // ensure clock lock is synced with pixel clock
    logic locked_sync_0;
    always_ff @(posedge clk_pix) begin
        locked_sync_0 <= locked;
        clk_pix_locked <= locked_sync_0;
    end
endmodule

module display_480p #(
    CORDW=16,    // signed coordinate width (bits)
    H_RES=800,   // horizontal resolution (pixels)
    V_RES=480,   // vertical resolution (lines)
    H_FP=16,     // horizontal front porch
    H_SYNC=96,   // horizontal sync
    H_BP=48,     // horizontal back porch
    V_FP=10,     // vertical front porch
    V_SYNC=2,    // vertical sync
    V_BP=33,     // vertical back porch
    H_POL=0,     // horizontal sync polarity (0:neg, 1:pos)
    V_POL=0      // vertical sync polarity (0:neg, 1:pos)
    ) (
    input  wire logic clk_pix,  // pixel clock
    input  wire logic rst_pix,  // reset in pixel clock domain
    output      logic hsync,    // horizontal sync
    output      logic vsync,    // vertical sync
    output      logic de,       // data enable (low in blanking interval)
    output      logic frame,    // high at start of frame
    output      logic line,     // high at start of line
    output      logic signed [CORDW-1:0] sx,  // horizontal screen position
    output      logic signed [CORDW-1:0] sy   // vertical screen position
    );

    // horizontal timings
    localparam signed H_STA  = 0 - H_FP - H_SYNC - H_BP;    // horizontal start
    localparam signed HS_STA = H_STA + H_FP;                // sync start
    localparam signed HS_END = HS_STA + H_SYNC;             // sync end
    localparam signed HA_STA = 0;                           // active start
    localparam signed HA_END = H_RES - 1;                   // active end

    // vertical timings
    localparam signed V_STA  = 0 - V_FP - V_SYNC - V_BP;    // vertical start
    localparam signed VS_STA = V_STA + V_FP;                // sync start
    localparam signed VS_END = VS_STA + V_SYNC;             // sync end
    localparam signed VA_STA = 0;                           // active start
    localparam signed VA_END = V_RES - 1;                   // active end

    logic signed [CORDW-1:0] x, y;  // screen position

    // generate horizontal and vertical sync with correct polarity
    always_ff @(posedge clk_pix) begin
        hsync <= H_POL ? (x >= HS_STA && x < HS_END) : ~(x >= HS_STA && x < HS_END);
        vsync <= V_POL ? (y >= VS_STA && y < VS_END) : ~(y >= VS_STA && y < VS_END);
        if (rst_pix) begin
            hsync <= H_POL ? 0 : 1;
            vsync <= V_POL ? 0 : 1;
        end
    end

    // control signals
    always_ff @(posedge clk_pix) begin
        de    <= (y >= VA_STA && x >= HA_STA);
        frame <= (y == V_STA  && x == H_STA);
        line  <= (x == H_STA);
        if (rst_pix) begin
            de <= 0;
            frame <= 0;
            line <= 0;
        end
    end

    // calculate horizontal and vertical screen position
    always_ff @(posedge clk_pix) begin
        if (x == HA_END) begin  // last pixel on line?
            x <= H_STA;
            y <= (y == VA_END) ? V_STA : y + 1;  // last line on screen?
        end else begin
            x <= x + 1;
        end
        if (rst_pix) begin
            x <= H_STA;
            y <= V_STA;
        end
    end

    // delay screen position to match sync and control signals
    always_ff @ (posedge clk_pix) begin
        sx <= x;
        sy <= y;
        if (rst_pix) begin
            sx <= H_STA;
            sy <= V_STA;
        end
    end
endmodule

module pwm (
    input wire logic clk,
    input wire logic [7:0] duty,
    output     logic pwm_out
    );

    logic [7:0] cnt = 8'b0;
    always_ff @(posedge clk) begin
        cnt <= cnt + 1;
    end

    always_comb pwm_out = (cnt < duty);
endmodule
