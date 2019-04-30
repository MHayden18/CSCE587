`ifndef VGA640x480_SYNC_GENERATOR
`define VGA640x480_SYNC_GENERATOR

//----------------------------------------------------------------------
// Video sync generator, used to drive a VGA display at 640x480 @60Hz
// Notes:
//    Wire the hsync and vsync signals to top level outputs
//    Add a 3-bit (or more) "rgb" output to the top level
//----------------------------------------------------------------------

module vga640x480_sync_gen(
    // inputs
    clk,           // 25.175 MHz clock input
    reset,         // reset
    // outputs
    hsync,         // horizonal sync pulse
    vsync,         // vertical sync pulse
    display_on,    // indicates within active display area
    hpos,          // 10-bit horizonal position
    vpos           // 10-bit vertical position
  );

  input clk;
  input reset;
  output reg hsync = 1'b1;
  output reg vsync = 1'b1;
  output display_on;
  output reg [9:0] hpos = 10'b0;
  output reg [9:0] vpos = 10'b0;
  
  // horizontal constants
  parameter H_DISPLAY       = 640; // horizontal display width
  parameter H_BACK          =  48; // horizontal left border (back porch)
  parameter H_FRONT         =  16; // horizontal right border (front porch)
  parameter H_SYNC          =  96; // horizontal sync width
  // vertical constants
  parameter V_DISPLAY       = 480; // vertical display height
  parameter V_TOP           =  10; // vertical top border
  parameter V_BOTTOM        =  33; // vertical bottom border
  parameter V_SYNC          =   2; // vertical sync # lines

  // derived constants
  parameter H_SYNC_START    = 0; //H_DISPLAY + H_FRONT;
  parameter H_SYNC_END      = H_SYNC - 1; //H_DISPLAY + H_FRONT + H_SYNC - 1;
  parameter H_START			 = H_SYNC + H_BACK;
  parameter H_END				 = H_START + H_DISPLAY - 1;
  parameter H_MAX           = H_DISPLAY + H_BACK + H_FRONT + H_SYNC - 1;
  
  parameter V_SYNC_START    = 0; //V_DISPLAY + V_BOTTOM;
  parameter V_SYNC_END      = V_SYNC - 1; //V_DISPLAY + V_BOTTOM + V_SYNC - 1;
  parameter V_START 			 = V_SYNC + V_BOTTOM;
  parameter V_END			  	 = V_START + V_DISPLAY - 1;
  parameter V_MAX           = V_DISPLAY + V_TOP + V_BOTTOM + V_SYNC - 1;
  
  
  wire hmaxxed = (hpos == H_MAX) || reset;	// set when hpos is maximum
  wire vmaxxed = (vpos == V_MAX) || reset;	// set when vpos is maximum
  
  // horizontal position counter
  always @(posedge clk)
  begin
    hsync <= ~(hpos>=H_SYNC_START && hpos<=H_SYNC_END);
    if (hmaxxed)
      hpos <= 0;
    else
      hpos <= hpos + 1;
  end

  // vertical position counter
  always @(posedge clk)
  begin
    vsync <= ~(vpos>=V_SYNC_START && vpos<=V_SYNC_END);
    if (hmaxxed)
      if (vmaxxed)
        vpos <= 0;
      else
        vpos <= vpos + 1;
  end
  
  // display_on is set when beam is active display area
  assign display_on = (hpos >= H_START) && (hpos <= H_END) && (vpos >= V_START) && (vpos <= V_END);

endmodule

`endif
