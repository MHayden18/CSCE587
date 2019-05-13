
`ifndef DIGITS10
`define DIGITS10

`include "vga640x480_sync_gen.v"

//
// ROM module with 8x8 bitmaps for the digits 0-9
//

module digits10_case(
      // inputs
      digit,       // selects digit 0-9
      yofs,        // vertical/y offset (0-4)
      // outputs
      bits         // 8 bits 
   );

   input [3:0] digit;  // digit 0-9
   input [2:0] yofs;   // vertical offset (0-4)
   output [7:0] bits;  // output (8 bits)

   // combine {digit, yofs} into single ROM address
   wire [6:0] caseexpr = {digit, yofs};

   reg [4:0] rom = 0;  // rom output (5 bits)
   always @(*)
      case (caseexpr)/*{w:5,h:5,count:10}*/
         7'o00: rom = 5'b11111;
         7'o01: rom = 5'b10001;
         7'o02: rom = 5'b10001;
         7'o03: rom = 5'b10001;
         7'o04: rom = 5'b11111;

         7'o10: rom = 5'b01100;
         7'o11: rom = 5'b00100;
         7'o12: rom = 5'b00100;
         7'o13: rom = 5'b00100;
         7'o14: rom = 5'b11111;

         7'o20: rom = 5'b11111;
         7'o21: rom = 5'b00001;
         7'o22: rom = 5'b11111;
         7'o23: rom = 5'b10000;
         7'o24: rom = 5'b11111;

         7'o30: rom = 5'b11111;
         7'o31: rom = 5'b00001;
         7'o32: rom = 5'b11111;
         7'o33: rom = 5'b00001;
         7'o34: rom = 5'b11111;

         7'o40: rom = 5'b10001;
         7'o41: rom = 5'b10001;
         7'o42: rom = 5'b11111;
         7'o43: rom = 5'b00001;
         7'o44: rom = 5'b00001;

         7'o50: rom = 5'b11111;
         7'o51: rom = 5'b10000;
         7'o52: rom = 5'b11111;
         7'o53: rom = 5'b00001;
         7'o54: rom = 5'b11111;

         7'o60: rom = 5'b11111;
         7'o61: rom = 5'b10000;
         7'o62: rom = 5'b11111;
         7'o63: rom = 5'b10001;
         7'o64: rom = 5'b11111;

         7'o70: rom = 5'b11111;
         7'o71: rom = 5'b00001;
         7'o72: rom = 5'b00001;
         7'o73: rom = 5'b00001;
         7'o74: rom = 5'b00001;

         7'o100: rom = 5'b11111;
         7'o101: rom = 5'b10001;
         7'o102: rom = 5'b11111;
         7'o103: rom = 5'b10001;
         7'o104: rom = 5'b11111;

         7'o110: rom = 5'b11111;
         7'o111: rom = 5'b10001;
         7'o112: rom = 5'b11111;
         7'o113: rom = 5'b00001;
         7'o114: rom = 5'b11111;

         default: rom = 0;
      endcase

   assign bits = {rom, 3'b000};

endmodule

//
// test displaying digits
//

module test_numbers(
      // inputs
      clk,
      reset,
      hsync,
      vsync,
      // outputs
      rgb,
   );

   input clk, reset;
   output hsync, vsync;
   output [2:0] rgb;

   // create VGA sync generator
   wire [9:0] hpos;
   wire [9:0] vpos;
   wire display_on;
   vga640x480_sync_gen video_gen(
      .clk(clk),
      .reset(reset),
      .hsync(hsync),
      .vsync(vsync),
      .display_on(display_on),
      .hpos(hpos),
      .vpos(vpos)
    );

   wire [3:0] digit = hpos[9:6];  // select digit 0-9
   wire [2:0] xofs  = hpos[4:2];  // horiz offset (4x size)
   wire [2:0] yofs  = vpos[4:2];  // vert offset (4x size)
   wire [7:0] bits;

   digits10_case numbers(
      .digit(digit),
      .yofs(yofs),
      .bits(bits)
   );

   // red box
   wire r = ((hpos==0) || (hpos==639) || (vpos==0) || (vpos==479)) ? 1'b1 : 1'b0;
   // green digits
   wire g = bits[xofs ^ 3'b111];
   // blue indicates we are within display area
   wire b = display_on;
   // map rgb values to a single variable considering if we are within display area
   assign rgb = {3{display_on}} & {b, g, r};

endmodule

`endif
