`include "vga640x480_sync_gen.v"
`include "Sprite_Bitmap.v"
`include "Sprite_Renderer.v"
`include "cpu8.v"


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
	  
	// Signal declarations:
	parameter PADDLE_X = 0;	// paddle X coordinate
	parameter PADDLE_Y = 1;	// paddle Y coordinate
	parameter PLAYER_X = 2;	// player X coordinate
	parameter PLAYER_Y = 3;	// player Y coordinate
	parameter ENEMY_X = 4;	// enemy X coordinate
	parameter ENEMY_Y = 5;	// enemy Y coordinate
	parameter ENEMY_DIR = 6;	// enemy direction (1, -1)
	parameter SPEED = 7;		// player speed
	parameter TRACKPOS_LO = 8;	// track position (lo byte)
	parameter TRACKPOS_HI = 9;	// track position (hi byte)
	
	parameter IN_HPOS = 8'h40;	// CRT horizontal position
	parameter IN_VPOS = 8'h41;	// CRT vertical position
	// flags: [0, 0, collision, vsync, hsync, vpaddle, hpaddle, display_on]
	parameter IN_FLAGS = 8'h42;
	
	// Registers for IO:
	reg [7:0] reg_PLAYER_X		= 100;
	reg [7:0] reg_PLAYER_Y		= 100;
	reg [7:0] reg_ENEMY_X		= 200;
	reg [7:0] reg_ENEMY_Y		= 200;
	reg [7:0] reg_TRACKPOS_LO;
	reg [7:0] reg_TRACKPOS_HI;
		
	// Define ram and rom's initial states:
	reg [7:0] ram[0:15];	// 16 bytes of RAM
	initial begin
		rom[0] = 8'h6B;
		rom[1] = 8'h80;
	end
	
	reg [7:0] rom[0:127];	// 128 bytes of ROM
	// Initialize ram/rom:
	initial begin
		$readmemh("racing_car.mem", rom);
	end
	
	wire [7:0] address_bus;	// CPU address bus
	reg  [7:0] to_cpu;		// data bus to CPU
	wire [7:0] from_cpu;		// data bus from CPU
	wire write_enable;	
	
	// RACING GAME CODE BEFORE ASM STUFF
	// 8-bit CPU module
	CPU cpu(.clk(clk),
        .reset(reset),
        .address(address_bus),
        .data_in(to_cpu),
        .data_out(from_cpu),
        .write(write_enable));

	// RAM write from CPU
	always @(posedge clk)
		if (write_enable) begin
			ram[address_bus[3:0]] <= from_cpu;
			ram[PLAYER_X] <= reg_PLAYER_X;
		end
   wire vpaddle, hpaddle;
	
	// RAM read from CPU
	always @(*)
		casez (address_bus)
			// RAM
			8'b00??????: to_cpu = ram[address_bus[3:0]];
			// special read registers
			IN_HPOS:  to_cpu = hpos[7:0];
			IN_VPOS:  to_cpu = vpos[7:0];
			IN_FLAGS: to_cpu = {2'b0, frame_collision,
								VGA_VS, VGA_HS, vpaddle, hpaddle, display_on};
			// ROM
			8'b1???????: to_cpu = rom[address_bus[6:0]];
			default: to_cpu = 8'bxxxxxxxx;
		endcase
		
		
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
	
	// flags for player sprite renderer module
	wire player_vstart = {1'b0,ram[PLAYER_Y]} == vpos;
	wire player_hstart = {1'b0,ram[PLAYER_X]} == hpos;
	wire player_gfx;
	wire player_is_drawing;
	
	// flags for enemy sprite renderer module
	wire enemy_vstart = {1'b0,ram[ENEMY_Y]} == vpos;
	wire enemy_hstart = {1'b0,ram[ENEMY_X]} == hpos;
	wire enemy_gfx;
	wire enemy_is_drawing;
	
	// select player or enemy access to ROM
	wire player_load = (hpos >= 256) && (hpos < 260);
	wire enemy_load = (hpos >= 260);
	
	// wire up car sprite ROM
	// multiplex between player and enemy ROM address
	wire [3:0] player_sprite_yofs;
	wire [3:0] enemy_sprite_yofs;
	wire [3:0] car_sprite_yofs = player_load ? player_sprite_yofs : enemy_sprite_yofs;  
	wire [7:0] car_sprite_bits;  
	car_bitmap car(
		.yofs(car_sprite_yofs), 
		.bits(car_sprite_bits));
  
	// player sprite renderer
	sprite_renderer player_renderer(
		.clk(clk),
		.vstart(player_vstart),
		.hstart(player_hstart),
		.load(player_load),
		.rom_addr(player_sprite_yofs),
		.rom_bits(car_sprite_bits),
		.gfx(player_gfx),
		.in_progress(player_is_drawing));

	// enemy sprite renderer
	sprite_renderer enemy_renderer(
		.clk(clk),
		.vstart(enemy_vstart),
		.hstart(enemy_hstart),
		.load(enemy_load),
		.rom_addr(enemy_sprite_yofs),
		.rom_bits(car_sprite_bits),
		.gfx(enemy_gfx),
		.in_progress(enemy_is_drawing));
  
	// collision detection logic
	reg frame_collision;
	always @(posedge clk)
		if (player_gfx && (enemy_gfx || track_gfx))
			frame_collision <= 1;
		else if (vpos==0)
			frame_collision <= 0;
  
			
	// track graphics
	wire track_offside = (hpos[7:5]==0) || (hpos[7:5]==7);
	wire track_shoulder = (hpos[7:3]==3) || (hpos[7:3]==28);
	wire track_gfx = (vpos[5:1]!=ram[TRACKPOS_LO][5:1]) && track_offside;
  
	// RGB output
	wire r = display_on && (player_gfx || enemy_gfx || track_shoulder) && (hpos < 309) && (vpos < 262);
	wire g = display_on && (player_gfx || track_gfx) && (hpos < 309) && (vpos < 262);
	wire b = display_on && (enemy_gfx || track_shoulder) && (hpos < 309) && (vpos < 262);
	// Display Assignments:
	assign VGA_R = {8{r}};
	assign VGA_G = {8{g}};
	assign VGA_B = {8{b}};
	
	// RACING GAME END 
	//assign hpaddle = ~KEY[0];
	wire move_right = ~KEY[3];
	wire move_left = ~KEY[0];
	wire move_dir = SW[0];
	
	always @(posedge VGA_VS)
		if (move_right)	// If I want to move, move based on direction
			reg_PLAYER_X <= reg_PLAYER_X + 2;
		else if (move_left)
			reg_PLAYER_X <= reg_PLAYER_X - 2;
				
	assign vpaddle = 0;		
	assign hpaddle = 1;
	assign LED[0] = move_right;
	assign LED[1] = move_left;
	
	// Misc. assignments:
	assign VGA_CLK = clk;              // clock DAC
	assign VGA_BLANK_n = display_on;   // enable DAC output
	assign VGA_SYNC_n  = (VGA_VS || VGA_HS);         // turn off "green" mode
	
	
endmodule

	