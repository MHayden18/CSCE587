
`include "vga_clk_pll.v"
`include "digits10.v"

module chipio(
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
   output VGA_HS;
   output VGA_VS;
   output VGA_CLK;
   output VGA_BLANK_n;
   output VGA_SYNC_n;
   output [7:0] VGA_R;
   output [7:0] VGA_G;
   output [7:0] VGA_B;

   // create a 25.175Mhz clock source for entire design
   wire clk;
   vga_clk_pll vga_clk(
      .refclk(OSC_50_B3B),    // reference clock
      .rst(0),                // reset
      .outclk_0(clk),         // output clock : 25.175 MHz
//      .locked(locked)         // locked.export
   );

   // create digits
   wire [2:0] rgb;
   test_numbers digits(
      .clk(clk),
      .reset(0),
      .hsync(VGA_HS),
      .vsync(VGA_VS),
      .rgb(rgb)
   );

   // video generation signals
   assign VGA_CLK     = clk;               // clock DAC
   assign VGA_BLANK_n = ~(rgb == 3'b000);  // enable DAC output
   assign VGA_SYNC_n  = 1'b0;              // turn off "green" mode

   assign VGA_R = {8{rgb[0]}};
   assign VGA_G = {8{rgb[1]}};
   assign VGA_B = {8{rgb[2]}};

   assign LED[0] = ~KEY[0];
   assign LED[1] = ~KEY[1];
   assign LED[2] = ~KEY[2];
   assign LED[3] = ~KEY[3];

endmodule
