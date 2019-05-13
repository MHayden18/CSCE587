
`ifndef VGA640x480_RGB_GENERATOR
`define VGA640x480_RGB_GENERATOR

//----------------------------------------------------------------------
// Video RGB signals generator for display at 640x480 @60Hz
//----------------------------------------------------------------------

module vga640x480_rgb_gen(
    // inputs
    vsync,         // vertical sync pulse
    reset,         // reset
    hpos,          // horizonal position
    vpos,          // vertical position
    // outputs
    rgb            // rgb color to display
  );

  input vsync;
  input reset;
  input [9:0] hpos;
  input [9:0] vpos;
  output [2:0] rgb;

  parameter [9:0] INITIAL_X = 128;  // ball initial X position
  parameter [9:0] INITIAL_Y = 128;  // ball initial Y position
  parameter [9:0] BALL_SIZE = 2;    // ball size (in pixels)

  reg [9:0] x_pos = INITIAL_X; // ball current X position
  reg [9:0] y_pos = INITIAL_Y;  // ball current Y position

  reg [9:0] x_move = 2;    // X velocity
  reg [9:0] y_move = 2;    // Y velocity

  reg x_direction = 1'b1;  
  reg y_direction = 1'b1;

  //-------------------------------------
  // ball movement logic
  //-------------------------------------

  // update horizontal timer
  always @(posedge vsync)
  begin
    if (reset) begin
      // reset ball position to center
      x_pos <= INITIAL_X;
      y_pos <= INITIAL_Y;
    end else begin
      // add "X" velocity vector to ball position
      if (x_direction)
        x_pos <= x_pos + x_move;
      else
        x_pos <= x_pos - x_move;
      // add "Y" velocity vector to ball position
      if (y_direction)
        y_pos <= y_pos + y_move;
      else
        y_pos <= y_pos - y_move;
      //---------------------
      // bounce
      //---------------------
      // "X" bounce
      if (x_pos >= (640 - BALL_SIZE))
        x_direction <= 1'b0;
      if (x_pos <= BALL_SIZE)
        x_direction <= 1'b1;
      // "Y" bounce
      if (y_pos >= (480 - BALL_SIZE))
        y_direction <= 1'b0;
      if (y_pos <= BALL_SIZE)
        y_direction <= 1'b1;
    end
  end

  //-------------------------------------
  // ball display logic
  //-------------------------------------
  
  // offset of ball position from video beam
  wire [9:0] x_diff = hpos - x_pos;
  wire [9:0] y_diff = vpos - y_pos;

  // ball graphics output
  wire x_gfx = x_diff < BALL_SIZE;
  wire y_gfx = y_diff < BALL_SIZE;
  wire ball = x_gfx && y_gfx;

  // combine signals to RGB output
  wire grid_gfx = (((hpos&7)==0) && ((vpos&7)==0));
  wire r = (x_gfx | ball);
  wire g = (grid_gfx | ball);
  wire b = (y_gfx | ball);
  assign rgb = {b,g,r};

endmodule

`endif
