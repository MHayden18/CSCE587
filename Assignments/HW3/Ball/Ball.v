
`include "vga640x480_sync_gen.v"

module Ball(
     // inputs
     KEY, OSC_50_B3B, SW,
     // outputs
     LED,
	  VGA_R, VGA_G, VGA_B,
     VGA_HS, VGA_VS,
     VGA_CLK, VGA_BLANK_n, VGA_SYNC_n
   );

   // inputsk
	input [3:0] KEY;
	input [3:0] SW;
	
   input OSC_50_B3B;
	
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
	wire reset;
	
	
	// Ball signal declarations:
	reg [9:0] ball_hpos;	// ball current X position
	reg [9:0] ball_vpos;	// ball current Y position
  
	reg [9:0] ball_xVel = 2;	// ball current X velocity
	reg [9:0] ball_yVel = 2;		// ball current Y velocity
  

	localparam ball_horiz_initial = 130;	// ball initial X position
	localparam ball_vert_initial = 130;	// ball initial Y position
  
	localparam BALL_SIZE = 4;		// ball size (in pixels)
	
	// Ball directions:
	reg ball_y_sign, ball_x_sign;
	
   vga640x480_sync_gen video_gen(
      .clk(clk),
      .reset(reset),
      .hsync(VGA_HS),
      .vsync(VGA_VS),
      .display_on(display_on),
      .hpos(hpos),
      .vpos(vpos)
   );
	
   assign VGA_CLK = clk;              // clock DAC
   assign VGA_BLANK_n = display_on;   // enable DAC output
   assign VGA_SYNC_n  = (VGA_HS || VGA_VS);         // turn off "green" mode
	assign reset = ~KEY[0];

	
// Ball code here:
	
	// Ball Velocities:
	always @(posedge VGA_VS or posedge reset)
	begin
	// Initial State:
		if (reset) begin
			// reset ball position to center
			ball_hpos <= ball_horiz_initial;
			ball_vpos <= ball_vert_initial;
		end else begin
	// add velocity vector to ball position
			if (ball_x_sign) begin
				ball_hpos <= ball_hpos + ball_xVel;
			end else  begin
				ball_hpos <= ball_hpos - ball_xVel;
			end
			if (ball_y_sign) begin
				ball_vpos <= ball_vpos + ball_yVel;
			end else begin
				ball_vpos <= ball_vpos - ball_yVel;
			end
		end
	end

	
// Collisions:
	// vertical bounce
	always @(posedge ball_vert_collide)
	begin
		ball_y_sign <= ~ball_y_sign;
	end

	
	// horizontal bounce
	always @(posedge ball_horiz_collide)
	begin
		ball_x_sign <= ~ball_x_sign;
	end
  

   // collide with vertical and horizontal boundaries
	// these are set when the ball touches a border
	wire ball_vert_collide = (ball_vpos >= 480 - BALL_SIZE);
	wire ball_horiz_collide = (ball_hpos >= 640 - BALL_SIZE);
	
	
// Graphics:

	// offset of ball position from video beam
	wire [9:0] ball_hdiff = hpos - ball_hpos;
	wire [9:0] ball_vdiff = vpos - ball_vpos;

	
	// ball graphics output
	wire ball_hgfx = ball_hdiff < BALL_SIZE;
	wire ball_vgfx = ball_vdiff < BALL_SIZE;
	wire ball_gfx = ball_hgfx && ball_vgfx;

		
	// combine signals to RGB output
	wire grid_gfx = (((hpos&7)==0) && ((vpos&7)==0));
	wire r = display_on && ( (ball_hgfx | ball_gfx) );
	wire g = display_on && (grid_gfx | ball_gfx);
	wire b = display_on && (ball_vgfx | ball_gfx);
	assign rgb = {b,g,r};
	// Ball code end
	
   assign VGA_R = {8{r}};
   assign VGA_G = {8{g}};
   assign VGA_B = {8{b}};

	
// Assignments:
	assign LED[0] = SW[0] && SW[1] && SW[2] && SW[3];
	assign LED[1] = ~KEY[1];
   assign LED[2] = ~KEY[2];
   assign LED[3] = ~KEY[3];
	
endmodule
