`ifndef _params_vh
`define _params_vh
localparam FRAMEBUFFER_SIZE = 384000;
localparam SPRITE_NUM = 4;
localparam SPRITE_SIZE = 1024;
localparam SPRITE_ADDR_SIZE = $clog2(SPRITE_SIZE)-1;
`endif