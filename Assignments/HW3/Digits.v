
`include "vga640x480_sync_gen.v"


// module for 10-digit bitmap ROM
module digits10_case(digit, yofs, bits);
  
  input [3:0] digit;		// digit 0-9
  input [2:0] yofs;		// vertical offset (0-4)
  output reg [4:0] bits;					// output (5 bits)
  
  
  // combine {digit,yofs} into single ROM address
  wire [6:0] caseexpr = {digit,yofs};
  // Bits signal:
  
  always @(*)
    case (caseexpr)/*{w:5,h:5,count:10}*/
      7'o00: bits = 5'b11111;
      7'o01: bits = 5'b10001;
      7'o02: bits = 5'b10001;
      7'o03: bits = 5'b10001;
      7'o04: bits = 5'b11111;

      7'o10: bits = 5'b01100;
      7'o11: bits = 5'b00100;
      7'o12: bits = 5'b00100;
      7'o13: bits = 5'b00100;
      7'o14: bits = 5'b11111;

      7'o20: bits = 5'b11111;
      7'o21: bits = 5'b00001;
      7'o22: bits = 5'b11111;
      7'o23: bits = 5'b10000;
      7'o24: bits = 5'b11111;

      7'o30: bits = 5'b11111;
      7'o31: bits = 5'b00001;
      7'o32: bits = 5'b11111;
      7'o33: bits = 5'b00001;
      7'o34: bits = 5'b11111;

      7'o40: bits = 5'b10001;
      7'o41: bits = 5'b10001;
      7'o42: bits = 5'b11111;
      7'o43: bits = 5'b00001;
      7'o44: bits = 5'b00001;

      7'o50: bits = 5'b11111;
      7'o51: bits = 5'b10000;
      7'o52: bits = 5'b11111;
      7'o53: bits = 5'b00001;
      7'o54: bits = 5'b11111;

      7'o60: bits = 5'b11111;
      7'o61: bits = 5'b10000;
      7'o62: bits = 5'b11111;
      7'o63: bits = 5'b10001;
      7'o64: bits = 5'b11111;

      7'o70: bits = 5'b11111;
      7'o71: bits = 5'b00001;
      7'o72: bits = 5'b00001;
      7'o73: bits = 5'b00001;
      7'o74: bits = 5'b00001;

      7'o100: bits = 5'b11111;
      7'o101: bits = 5'b10001;
      7'o102: bits = 5'b11111;
      7'o103: bits = 5'b10001;
      7'o104: bits = 5'b11111;

      7'o110: bits = 5'b11111;
      7'o111: bits = 5'b10001;
      7'o112: bits = 5'b11111;
      7'o113: bits = 5'b00001;
      7'o114: bits = 5'b11111;

      default: bits = 0;
    endcase
endmodule


// Renamed chipio to Digits
module Digits(
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

	
	
	// Digits Code:
	// Move digit to hpos[9:6] 
	// Change x/y offset up two bits (scaling times 4)
	wire [3:0] digit = hpos[9:6];
	wire [2:0] xofs = hpos[4:2];
	wire [2:0] yofs = vpos[4:2];
	wire [4:0] bits;
	wire [7:0] outbits;
	
	digits10_case numbers(
		.digit(digit),
		.yofs(yofs),
		.bits(bits)
	);

	assign outbits = {bits, 3'b000};
	
	wire r = display_on && 0;
	wire g = display_on && outbits[xofs ^ 3'b111];
	wire b = display_on && 0;
	
	
	// Digits code end
	
   assign VGA_R = {8{r}};
   assign VGA_G = {8{g}};
   assign VGA_B = {8{b}};

//   assign VGA_R = SW[0] ? {8{1'b1}} : {8{1'b0}};
//   assign VGA_G = SW[1] ? {8{1'b1}} : {8{1'b0}};
//   assign VGA_B = SW[2] ? {8{1'b1}} : {8{1'b0}};

   assign LED[0] = ~KEY[0];
   assign LED[1] = ~KEY[1];
   assign LED[2] = ~KEY[2];
   assign LED[3] = ~KEY[3];

endmodule
