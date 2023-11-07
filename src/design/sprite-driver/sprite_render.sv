`timescale 1ns / 1ps
`include "params.vh"

module sprite_render #(
        parameter CORDW = 10,
        parameter SPR_WIDTH = 8,
        parameter SPR_HEIGHT = 8,
        parameter SPR_DATAW = 4
    )(
    input  wire logic clk,                            // clock
    input  wire logic rst,                           // reset
    input  wire logic enable,
    input  wire logic [CORDW-1:0] sx, sy,      // screen position
    output wire logic [18:0] addr,                     // address to write to fb
    output      logic [SPR_DATAW-1:0] pix,            // pixel colour index
    output      logic drawing                   // bram enable
    );
    
    wire logic [5:0] spr_rom_addr;
    logic [SPR_DATAW-1:0] spr_rom_data;
    
    logic [((SPR_WIDTH > SPR_HEIGHT) ? $clog2(SPR_WIDTH) : $clog2(SPR_HEIGHT)):0] sprx, spry;
    
    assign spr_rom_addr = sprx + spry * SPR_WIDTH;
    assign addr = (FRAMEBUFFER_SIZE > 192000) ? (sx + sprx) + (sy + spry) * 800 : ((sx + sprx) + (sy + spry) * 800)/2;
    
    rom_async #(
        .WIDTH(SPR_DATAW),
        .DEPTH(64),
        .INIT_F("sprite.mem")
    ) spr_rom (
        .addr(spr_rom_addr),
        .data(spr_rom_data)
    );
    
    logic finish;
    
    always_ff @(posedge clk) begin
        if (enable && !finish) begin
            drawing <= 1;
            if (sprx == SPR_WIDTH - 1) begin
                sprx <= 0;
                if (spry == SPR_HEIGHT - 1) begin
                    finish <= 1;
                    spry <= 0;
                end else spry <= spry + 1;
            end else sprx <= sprx + 1;
            
            pix <= spr_rom_data;
        end else drawing <= 0;
        if (rst) begin
            sprx <= 0;
            spry <= 0;
            drawing <= 0;
            finish <= 0;
        end
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

module sprite #(
    parameter CORDW=16,      // signed coordinate width (bits)
    parameter H_RES=640,     // horizontal screen resolution (pixels)
    parameter SPR_FILE="",   // sprite bitmap file ($readmemh format)
    parameter SPR_WIDTH=8,   // sprite bitmap width in pixels
    parameter SPR_HEIGHT=8,  // sprite bitmap height in pixels
    parameter SPR_SCALE=0,   // scale factor: 0=1x, 1=2x, 2=4x, 3=8x etc.
    parameter SPR_DATAW=1    // data width: bits per pixel
    ) (
    input  wire logic clk,                            // clock
    input  wire logic rst,                            // reset
    input  wire logic line,                           // start of active screen line
    input  wire logic [CORDW-1:0] sx, sy,      // screen position
    output wire logic addr,
    output      logic [SPR_DATAW-1:0] pix,            // pixel colour index
    output      logic drawing                         // drawing at position (sx,sy)
    );
    
    logic sprx = 0, spry = 0;
    
    assign addr = (spry + sy) * H_RES + (sx + sprx);
    
    logic end_of_sprite = 0;

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
    logic line_end = 0;    // end of screen line, corrected for sx offset
    
    always_comb begin
        spr_diff = (sy - spry_r) >>> SPR_SCALE;  // arithmetic right-shift
        spr_active = (spr_diff >= 0) && (spr_diff < SPR_HEIGHT);
        spr_begin = (sx >= sprx_r);
        spr_end = (bmap_x == SPR_WIDTH-1);
    end
    
    always_ff @(posedge clk) begin
        if (sprx == (SPR_WIDTH <<< SPR_SCALE) - 1) begin
            line_end <= 1;
            sprx <= 0;
            spry <= spry + 1;
        end else sprx <= sprx + 1;
        if (spry == (SPR_HEIGHT <<< SPR_SCALE) - 1) begin
            sprx <= 0;
            spry <= 0;
            
        end
    end

    // sprite state machine
    enum {
        REG_POS,   // register sprite position
        ACTIVE,    // check if sprite is active on this line
        WAIT_POS,  // wait for horizontal sprite position
        SPR_LINE,  // iterate over sprite pixels
        WAIT_DATA  // account for data latency
    } state;

    always_ff @(posedge clk) begin
        if (sprx == (SPR_WIDTH <<< SPR_SCALE) - 1) begin  // prepare for new line
            state <= REG_POS;
            pix <= 0;
            drawing <= 0;
        end else begin
            case (state)
                REG_POS: begin
                    state <= ACTIVE;
                    sprx_r <= sprx;
                    spry_r <= spry;
                    if (sprx == (SPR_WIDTH <<< SPR_SCALE) - 1) begin
                        line_end <= 1;
                        sprx <= 0;
                        spry <= spry + 1;
                    end else sprx <= sprx + 1;
                    if (spry == (SPR_HEIGHT <<< SPR_SCALE) - 1) begin
                        sprx <= 0;
                        spry <= 0;
                        
                    end
                end
                ACTIVE: state <= spr_active ? WAIT_POS : REG_POS;
                WAIT_POS: begin
                    state <= SPR_LINE;
                    spr_rom_addr <= spr_diff * SPR_WIDTH + (sx - sprx_r);
                    bmap_x <= 0;
                    cnt_x <= 0;
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
                    state <= REG_POS;  // 1 cycle between address set and data receipt
                    pix <= 0;  // default colour
                    drawing <= 0;
                end
                default: state <= REG_POS;
            endcase
        end

        if (rst) begin
            state <= REG_POS;
            spr_rom_addr <= 0;
            bmap_x <= 0;
            cnt_x <= 0;
            pix <= 0;
            drawing <= 0;
        end
    end
endmodule
