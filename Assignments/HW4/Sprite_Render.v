`include "vga640x480_sync_gen.v"
`include "Sprite_Bitmap.v"
`include "Sprite_Renderer.v"

module Sprite_Render(
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
	
	// Use switches to determine direction
	// Use key to determine whether or not to move
	wire hpaddle, vpaddle, h_dir, v_dir;
	
	assign h_dir = SW[3];
	assign v_dir = SW[0];
	assign hpaddle = ~KEY[3];
	assign vpaddle = ~KEY[0];
	
	// player position
	reg [9:0] player_x;
	reg [9:0] player_y;
	
	// paddle position
	reg [9:0] paddle_x;
	reg [9:0] paddle_y;
	
	// car bitmap ROM and associated wires
	wire [3:0] car_sprite_addr;
	wire [7:0] car_sprite_bits;
	
	car_bitmap car(
		.yofs(car_sprite_addr), 
		.bits(car_sprite_bits));
	
	 // convert player X/Y to 9 bits and compare to CRT hpos/vpos
	wire vstart = {1'b0,player_y} == vpos;
	wire hstart = {1'b0,player_x} == hpos;
	
	wire car_gfx;		// car sprite video signal
	wire in_progress;	// 1 = rendering taking place on scanline

	// sprite renderer module
	sprite_renderer renderer(
		.clk(clk),
		.vstart(vstart),
		.load(VGA_HS),
		.hstart(hstart),
		.rom_addr(car_sprite_addr),
		.rom_bits(car_sprite_bits),
		.gfx(car_gfx),
		.in_progress(in_progress));
	
// Update Paddle locations:
	always @(posedge VGA_VS)
		begin
			if (hpaddle) begin
				if (h_dir)
					paddle_x <= paddle_x + 2;
				else
					paddle_x <= paddle_x - 2;
			end
			if (vpaddle) begin
				if (v_dir)
					paddle_y <= paddle_y + 2;
				else
					paddle_y <= paddle_y - 2;
			end
			// See if paddle exceeds bounds:
			if (paddle_x < 0)
				paddle_x <= 0;
			if (paddle_x > 640)
				paddle_x <= 640;
			if (paddle_y < 0)
				paddle_y <= 0;
			if (paddle_y > 480)
				paddle_y <= 480;
		end
		
	// Update player location
	always @(posedge VGA_VS)
		begin
			player_x <= paddle_x;
			player_y <= paddle_y;
		end
		
	// video RGB output
	wire r = display_on && car_gfx;
	wire g = display_on && car_gfx;
	wire b = display_on && in_progress;
	
	// I/O and Display Assignments:
	assign VGA_R = {8{r}};
	assign VGA_G = {8{g}};
	assign VGA_B = {8{b}};
	
endmodule

	