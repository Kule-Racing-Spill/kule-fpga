`ifndef _params_vh
`define _params_vh

localparam FRAMEBUFFER_SIZE = 384000;
localparam FRAMEBUFFER_ADDR_SIZE = $clog2(FRAMEBUFFER_SIZE) - 1;
localparam SPRITE_NUM = 128;
localparam SPRITE_NUM_LOG = $clog2(SPRITE_NUM);
localparam SPRITE_SIZE = 1024;
localparam SPRITE_WORD_SIZE = 256;
localparam SPRITE_ADDR_SIZE = $clog2(SPRITE_WORD_SIZE * SPRITE_NUM)-1;

localparam COMMAND_SAVE_SPRITE = 8'b00000010;
localparam COMMAND_DRAW_SPRITE = 8'b00000001;

`endif