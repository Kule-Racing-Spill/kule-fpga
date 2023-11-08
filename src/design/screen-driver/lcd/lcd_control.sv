module Control(Enable, en, rst, clk_lcd, off_lcd, en_sync, reset, AVDD);

input wire Enable, rst, clk_lcd, off_lcd;
output reg en_sync, en, reset, AVDD;


reg [3:0] S;
reg [3:0] SS;

parameter [3:0]init=0;
parameter [3:0]Espera=1;
parameter [3:0]LCD_ON1=2;
parameter [3:0]LCD_ON2=3;
parameter [3:0]LCD_OFF1=4;
parameter [3:0]LCD_OFF2=5;

//Next state logic
always @(S or Enable or rst or off_lcd)
case (S)
init: if(Enable) SS=Espera; else SS=init;
Espera: if(Enable) SS=LCD_ON1; else SS=init;
LCD_ON1: SS=LCD_ON2;
LCD_ON2: if(Enable) SS=LCD_ON2; else SS=LCD_OFF1;
LCD_OFF1: if(off_lcd) SS=LCD_OFF2; else SS=LCD_OFF1;
LCD_OFF2: if(Enable) SS=init; else SS=LCD_OFF2;
default: SS=init;
endcase

//State memory
always @(posedge clk_lcd)
if(rst) S=init;
else S=SS;

//Output logic
always @(S)
case (S)
init: begin en_sync=0; AVDD=1; reset=1; en=0; end
Espera: begin en_sync=0; AVDD=1; reset=0; en=0; end
LCD_ON1: begin en_sync=1; AVDD=1; reset=0; en=1; end
LCD_ON2: begin en_sync=1; AVDD=1; reset=0; en=1; end
LCD_OFF1: begin en_sync=1; AVDD=1; reset=0; en=0; end
LCD_OFF2: begin en_sync=0; AVDD=0; reset=0; en=0; end
default: begin en_sync=0; AVDD=1; reset=1; en=0; end
endcase

endmodule
