//
// scanconvert2_lx45.v
//
// "scan convert" the cga video into a vga video stream
// basically two engines; one follows the cga frame and writes
// pixels into a dual-port ram.  the other follows the vga frame
// and reads them out, doubling the pixels and lines...
//

module scanconvert2_lx45(
			 input 	      clk6m,
			 input 	      clk12m,
			 input 	      clk25m,
			 input 	      reset,
			 input 	      hsync_i,
			 input 	      vsync_i,
			 input 	      hblank_i,
			 input 	      vblank_i,
			 input [8:0]  rgb_i,
			 output       hsync_o,
			 output       vsync_o,
			 output       blank_o,
			 output [7:0] rgb_o
			);

   // ----------------------------------------------------
   // cga-ish 512x253
   
   wire [16:0] cga_ram_addr;
   wire [7:0]  cga_data;
   wire        cga_we;
   wire        cga_visable;

   reg [10:0]  cga_hcount;
   reg [10:0]  cga_vcount;

   reg 	      hsync_i_d, vsync_i_d;
   wire       hsync_i_fall, vsync_i_fall;
   wire       hsync_i_rise, vsync_i_rise;

   always @(posedge clk6m)
     if (reset)
       begin
	  hsync_i_d <= 0;
	  vsync_i_d <= 0;
       end
     else
       begin
	  hsync_i_d <= hsync_i;
	  vsync_i_d <= vsync_i;
       end

   assign hsync_i_fall = hsync_i_d & ~hsync_i;
   assign vsync_i_fall = vsync_i_d & ~vsync_i;

   assign hsync_i_rise = ~hsync_i_d & hsync_i;
   assign vsync_i_rise = ~vsync_i_d & vsync_i;

   //
   always @(posedge clk6m)
     if (reset)
       begin
	  cga_hcount <= 0;
	  cga_vcount <= 0;
       end
     else
       begin
//	  if (hsync_i_rise/*fall*/ || hblank_i)
	  if (hblank_i)
//	  if (hsync_i_rise)
	    cga_hcount <= 0;
	  else
	    cga_hcount <= cga_hcount + 10'd1;

//	  if (vsync_i_rise/*fall*/ || vblank_i)
	  if (vblank_i)
//	  if (vsync_i_rise)
	    cga_vcount <= 0;
	  else
	    if (hsync_i_fall)
	      cga_vcount <= cga_vcount + 11'd1;
       end
   
//   assign cga_visable = (cga_hcount < 624) && (cga_vcount < 253);
   assign cga_visable = ~(hblank_i | vblank_i);


   // -------------------------------------------------
   // vga 640x480
   //
   // mapping 2x
   //  320x200 -> 640x400
   //
   wire [16:0] vga_ram_addr;
   wire [7:0]  vga_data;
   wire        vga_ce;
   wire        vga_visable;
   wire        vga_valid;
   
   reg [10:0] vga_hcount;
   reg [10:0] vga_vcount;
   wire       vga_hsync;
   wire       vga_vsync;

   wire [9:0] r_addr;
   reg [7:0]  rgb_data;

   
   //
   // output is 2x hsync rate of input
   //
   // input	--l0-- --l1-- --l2-- --l3-- ...
   // output	xx-xx- l0-l0- l1-l1- l2-l2- ...
   //

   always @(posedge clk25m)
     if (reset)
       begin
	  vga_hcount <= 0;
	  vga_vcount <= 11'h7ff;
       end
     else
       begin
	  if (vga_hcount == 800-1)
	    vga_hcount <= 0;
	  else
	    vga_hcount <= vga_hcount + 10'd1;

	  if (vga_vcount == 525-1)
	    vga_vcount <= 0;
	  else
	    if (vga_hcount == 799)
	      vga_vcount <= vga_vcount + 11'd1;
       end

//   assign vga_visable = (vga_hcount < 514/*640*/) && (vga_vcount < 255/*525*/)/* && (vga_vcount > 32)*/;
//   assign vga_visable = (vga_hcount < 640) && (vga_vcount < 525)/* && (vga_vcount > 32)*/;

   // cut off parts which are not valid
   assign vga_valid = (vga_hcount >= 0 && vga_hcount < 640-160/*134*/) &&
		      (vga_vcount >= 0 && vga_vcount <= 480+2);
		       
   // hdmi seems sensative to blanking - use full vga window
   assign vga_visable = (vga_hcount >= 0 && vga_hcount < 640) &&
			(vga_vcount >= 0 && vga_vcount <= 480+2);

   // front-porch = 16
   // pulse-width = 96
   // back-porch = 48
   assign vga_hsync = (vga_hcount >= (640+16) & vga_hcount <= (640+16+96));

   // front-porch = 10
   // pulse-width = 2
   // back-porch = 29
   assign vga_vsync = (vga_vcount > (480+10) & vga_vcount <= (480+10+2));

   assign hsync_o = ~vga_hsync;
   assign vsync_o = ~vga_vsync;
   assign blank_o = ~vga_visable;

   // ----------------------------------------------------

//`define CGA_HOFFSET 11'd80
`define CGA_HOFFSET 11'd0
`define CGA_VOFFSET 11'd16

   wire [10:0] cga_hcount_offset, cga_vcount_offset;
   assign cga_hcount_offset = cga_hcount - `CGA_HOFFSET;
   assign cga_vcount_offset = cga_vcount - `CGA_VOFFSET;
   
   assign cga_ram_addr = { 1'b0, cga_vcount_offset[7:0], cga_hcount_offset[8:0] };
   assign cga_we = cga_visable && (cga_hcount >= `CGA_HOFFSET);
   assign cga_data = { rgb_i[8:6], rgb_i[4:3], rgb_i[2:0] };

`define VGA_HOFFSET 9'd0
`define VGA_VOFFSET 9'd0

   // pixel & line doubling
`define flip
//`define normal
//`define normal_double
`ifdef flip
   wire [8:0]  v_lo;
   wire [8:0]  v_hi;
   
   assign v_hi = 240 + vga_hcount[9:1];
   assign v_lo = ~(256 + vga_vcount[9:1]);

   assign vga_ram_addr = { 1'b0, v_hi[7:0], v_lo };
`endif

`ifdef normal
   assign vga_ram_addr = { vga_vcount[7:0], vga_hcount[8:0] };
`endif

`ifdef normal_double
   assign vga_ram_addr = { vga_vcount[8:1], vga_hcount[9:1] };
`endif

   assign vga_ce = vga_visable;
   assign rgb_o = (vga_visable & vga_valid) ? vga_data : /*8'hff*/8'h00;

   reg [7:0]   cga_wr_data;
   always @(negedge clk6m)
     if (reset)
       cga_wr_data <= 0;
     else
       cga_wr_data <= cga_data;
   
   ram_dp128kx8 scan_ram(
			 .rclk(clk25m),
			 .wclk(clk6m),

			 .ai(cga_ram_addr),
			 .i(cga_wr_data),
			 .w(cga_we),

			 .ao(vga_ram_addr),
			 .o(vga_data),
			 .r(vga_ce)
			 );
   

`ifdef SIMULATION
   integer     c_hsize, c_vsize;

   initial
     begin
	c_hsize = 0;
	c_vsize = 0;
     end
	  
   always @(posedge clk6m)
     begin
	if (hsync_i_fall)
	  begin
	     if (cga_vcount < 20)
	     $display("hsync: cga pixels %d (line %d blank %b)", c_hsize, c_vsize, vblank_i);
	     c_hsize = 0;
	     c_vsize = c_vsize + 1;
	  end
	else
	  c_hsize = c_hsize + 1;
	
	if (vsync_i_fall)
	  begin
	     $display("hsync: cga lines %d", c_vsize);
	     c_vsize = 0;
	  end
     end
     
`endif
   
endmodule
