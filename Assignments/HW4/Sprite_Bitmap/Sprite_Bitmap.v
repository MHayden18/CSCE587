`ifndef SPRITE_BITMAP_H
`define SPRITE_BITMAP_H

`include "vga640x480_sync_gen.v"

/*
Simple sprite renderer example.

car_bitmap - ROM for a car sprite.
sprite_bitmap_top - Example sprite rendering module.
*/

module car_bitmap(yofs, bits);
  
  input [3:0] yofs;
  output [7:0] bits;

  reg [7:0] bitarray[0:15];
  
  assign bits = bitarray[yofs];
  
  initial begin/*{w:8,h:16}*/
    bitarray[0] = 8'b0;
    bitarray[1] = 8'b1100;
    bitarray[2] = 8'b11001100;
    bitarray[3] = 8'b11111100;
    bitarray[4] = 8'b11101100;
    bitarray[5] = 8'b11100000;
    bitarray[6] = 8'b1100000;
    bitarray[7] = 8'b1110000;
    bitarray[8] = 8'b110000;
    bitarray[9] = 8'b110000;
    bitarray[10] = 8'b110000;
    bitarray[11] = 8'b1101110;
    bitarray[12] = 8'b11101110;
    bitarray[13] = 8'b11111110;
    bitarray[14] = 8'b11101110;
    bitarray[15] = 8'b101110;
  end
  
endmodule

module Sprite_Bitmap(
     // inputs
     KEY, OSC_50_B3B, SW,
     // outputs
     LED, 
     VGA_R, VGA_G, VGA_B,
     VGA_HS, VGA_VS,
     VGA_CLK, VGA_BLANK_n, VGA_SYNC_n
   );

   // inputs
   input [3:0] KEY;
   input OSC_50_B3B;
   input [3:0] SW;
   // outputs
   output [3:0] LED;
   output [7:0] VGA_R;
   output [7:0] VGA_G;
   output [7:0] VGA_B;
   output VGA_HS;
   output VGA_VS;
   output VGA_CLK;
   output VGA_BLANK_n;
   output VGA_SYNC_n;

   // create a 25Mhz clock source for entire design
   reg clk = 1'b0;
   always @(posedge OSC_50_B3B)
      clk <= ~clk;
		
	// create VGA sync generator
   wire display_on;
   wire [9:0] hpos, vpos;
   vga640x480_sync_gen video_gen(
      .clk(clk),
      .reset(0),
      .hsync(VGA_HS),
      .vsync(VGA_VS),
      .display_on(display_on),
      .hpos(hpos),
      .vpos(vpos)
   );
   assign VGA_CLK = clk;              // clock DAC
   assign VGA_BLANK_n = display_on;   // enable DAC output
   assign VGA_SYNC_n  = (VGA_VS || VGA_HS);         // turn off "green" mode
	

	
	reg sprite_active;
	reg [3:0] car_sprite_xofs;
	reg [3:0] car_sprite_yofs;
	wire [7:0] car_sprite_bits;
  
	reg [9:0] player_x = 320;
	reg [9:0] player_y = 240;
	
	car_bitmap car(
    .yofs(car_sprite_yofs), 
    .bits(car_sprite_bits));
	
	// start Y counter when we hit the top border (player_y)
	always @(posedge VGA_HS)
		if (vpos == player_y)
			car_sprite_yofs <= 15;
		else if (car_sprite_yofs != 0)
			car_sprite_yofs <= car_sprite_yofs - 1;
  
	// restart X counter when we hit the left border (player_x)
	always @(posedge clk)
		if (hpos == player_x)
			car_sprite_xofs <= 15;
		else if (car_sprite_xofs != 0)
			car_sprite_xofs <= car_sprite_xofs - 1;

	// mirror sprite in X direction
	wire [3:0] car_bit = car_sprite_xofs>=8 ? 
                                 15-car_sprite_xofs:
                                 car_sprite_xofs;

	wire car_gfx = car_sprite_bits[car_bit[2:0]];

	wire r = display_on && car_gfx;
	wire g = display_on && car_gfx;
	wire b = display_on && car_gfx;
  
	// Car Module code endif
	
	// Assign I/O:
	// I/O and Display Assignments:
	assign VGA_R = {8{r}};
	assign VGA_G = {8{g}};
	assign VGA_B = {8{b}};
	
	assign LED[0] = ~KEY[0];
	assign LED[1] = ~KEY[1];
	assign LED[2] = ~KEY[2];
	assign LED[3] = ~KEY[3];

endmodule
	
`endif