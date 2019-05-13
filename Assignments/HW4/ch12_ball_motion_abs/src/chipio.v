
`include "vga_clk_pll.v"
`include "vga640x480_sync_gen.v"
`include "vga640x480_rgb_gen.v"

module chipio(
      // inputs
      OSC_50_B3B,
      // outputs
      VGA_R, VGA_G, VGA_B,
      VGA_HS, VGA_VS,
      VGA_CLK, VGA_BLANK_n, VGA_SYNC_n
   );

   // inputs
   input OSC_50_B3B;
   // outputs
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
      .outclk_0(clk)          // output clock : 25.175 MHz
//      .locked(locked)         // locked.export
   );

   // VGA sync generator
   wire [9:0] hpos;
   wire [9:0] vpos;
   wire display_on;
   vga640x480_sync_gen sync_signals(
      .clk(clk),
      .reset(0),
      .hsync(VGA_HS),
      .vsync(VGA_VS),
      .display_on(display_on),
      .hpos(hpos),
      .vpos(vpos)
    );

   // RGB signal generator
   wire [2:0] rgb;
   vga640x480_rgb_gen rgb_signals(
     .vsync(VGA_VS),
     .reset(0),
     .hpos(hpos),
     .vpos(vpos),
     .rgb(rgb)
   );

   // video generation signals
   assign VGA_CLK     = clk;          // clock DAC
   assign VGA_BLANK_n = display_on;   // enable DAC output
   assign VGA_SYNC_n  = 1'b0;         // turn off "green" mode

   assign VGA_R = {8{rgb[0]}};
   assign VGA_G = {8{rgb[1]}};
   assign VGA_B = {8{rgb[2]}};

endmodule
