
`include "vga640x480_sync_gen.v"

module TestPattern(
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
	
	// Display Signals:
	wire r,g,b;
   wire display_on;
   wire [9:0] hpos, vpos, hpos_out, vpos_out;
	
   vga640x480_sync_gen video_gen(
      .clk(clk),
      .reset(0),
      .hsync(VGA_HS),
      .vsync(VGA_VS),
      .display_on(display_on),
      .hpos(hpos_out),
      .vpos(vpos_out)
   );
	
   assign VGA_CLK = clk;              				// clock DAC
   assign VGA_BLANK_n = display_on;   				// enable DAC output
   assign VGA_SYNC_n  = (VGA_HS || VGA_VS); 		// turn off "green" mode
		
	
	// Adjust output to expected:
	assign hpos = hpos_out - 144;
	assign vpos = vpos_out - 35;
	  
	// draw a box (0-639, 0-479)
   //assign r = display_on && ((hpos==0) || (hpos==639) || (vpos==0) || (vpos==479));
	//assign g = 1'b0;
   //assign b = 1'b0;

// Test Pattern Code start:
	assign r = display_on && (((hpos&7)==0) || ((vpos&7)==0));
	assign g = display_on && vpos[4];
	assign b = display_on && hpos[4];
// Test Pattern Code end

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
