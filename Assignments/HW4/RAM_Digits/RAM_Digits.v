
`include "vga640x480_sync_gen.v"
`include "Digits.v"
`include "ram.v"

// Renamed chipio to Digits
module RAM_Digits(
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

		
	wire [9:0] ram_addr;
	wire [7:0] ram_read;
	reg [7:0] ram_write;
	reg ram_writeenable = 0;
  
	// RAM to hold 32x32 array of bytes
	RAM_sync ram(
		.clk(clk),
		.dout(ram_read),
		.din(ram_write),
		.addr(ram_addr),
		.we(ram_writeenable)
	);
  
  
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

	// ROM/Digits Conversion:
	
	wire [7:0] outbits;
	wire [4:0] row = vpos[9:5];	// 5-bit row, vpos / 10
	wire [4:0] col = hpos[9:5];	// 5-bit column, hpos / 10
	wire [2:0] rom_yofs = vpos[4:2]; // scanline of cell
	wire [4:0] rom_bits;		   // 5 pixels per scanline
  
	wire [3:0] digit = ram_read[3:0]; // read digit from RAM
	wire [2:0] xofs = hpos[4:2];      // which pixel to draw (0-7)
  
	assign ram_addr = {row,col};	// 10-bit RAM address
  
	digits10_case numbers(
		.digit(digit),
		.yofs(rom_yofs),
		.bits(rom_bits)
	);
	
	// Increase bit output size
	assign outbits = {rom_bits, 3'b000};
	
	// Display/Module Changes:
	wire r = display_on && 0;
	wire g = display_on && outbits[xofs ^ 3'b111];
	wire b = display_on && 0;
	
 // increment the current RAM cell
  always @(posedge clk)
		case (hpos[4:2])
			// on 7th pixel of cell
			6: begin
				// increment RAM cell
				ram_write <= (ram_read + 1);
				// only enable write on last scanline of cell
				ram_writeenable <= (vpos[4:2] == 7);
			end
			// on 8th pixel of cell
			7: begin
				// disable write
				ram_writeenable <= 0;
			end
		endcase	
// Digits code end
	
	
	// I/O and Display Assignments:
   assign VGA_R = {8{r}};
   assign VGA_G = {8{g}};
   assign VGA_B = {8{b}};

   assign LED[0] = ~KEY[0];
   assign LED[1] = ~KEY[1];
   assign LED[2] = ~KEY[2];
   assign LED[3] = ~KEY[3];

endmodule
