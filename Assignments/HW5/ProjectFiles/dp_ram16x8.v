
`ifndef DP_RAM16x8_V
`define DP_RAM16x8_V

//-------------------------------
// 16 bytes of 8-bit RAM
//-------------------------------
module dp_ram16x8
(
   // inputs
   input clk,
   input [7:0] data_a, data_b,
   input [3:0] addr_a, addr_b,
   input we_a, we_b,
   // outputs
   output reg [7:0] q_a, q_b
);

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

  // declare register array (RAM)
  reg [7:0] ram[15:0];
  initial begin
    // initial position of cars
    ram[PLAYER_X] = 100;
    ram[PLAYER_Y] = 100;
    ram[ENEMY_X]  = 200;
    ram[ENEMY_Y]  = 200;
  end

  // port A (used by CPU)
  always @ (posedge clk) begin
    if (we_a)  begin
      ram[addr_a] <= data_a;
      q_a <= data_a;
    end else begin
      q_a <= ram[addr_a];
   end
  end

  // port B (used by sprite renderers)
  always @ (posedge clk) begin
    if (we_b) begin
      ram[addr_b] <= data_b;
      q_b <= data_b;
    end else begin
      q_b <= ram[addr_b];
    end
  end

endmodule

`endif
