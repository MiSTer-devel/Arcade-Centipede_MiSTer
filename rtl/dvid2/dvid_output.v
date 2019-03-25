// original vhdl from Mike Field <hamster@snap.net.nz>
// dvid_test 
// Top level design for testing my DVI-D interface

module dvid_output(input clk50,
		   input 	reset,
		   input 	reset_clk,
		   input [7:0] 	red,
		   input [7:0] 	green,
		   input [7:0] 	blue,
		   input 	hsync,
		   input 	vsync,
		   input 	blank,
		   output 	clk_vga,
		   output 	clk_cpu,
		   output [3:0] TMDS,
		   output [3:0] TMDSB);

   wire       red_s;
   wire       green_s;
   wire       blue_s;
   wire       clock_s;

   wire       clk_vga2x, clk_vga10x;

   //
   wire       pll_clkfbout, pll_clkout1, pll_clkout2, pll_clkout3, pll_locked;
   wire       clkout4_unused;
   wire       clkout5_unused;

`ifdef SIMULATION
  reg pc3, pc2, pc1, pc, pl;

  assign pll_clkout3 = pc3;
  assign pll_clkout2 = pc2;
  assign pll_clkout1 = pc1;
  assign pll_clk = pc;
  assign pll_locked = pl;

  initial
    begin
       pl = 1'b0;
       #100;
       pl = 1'b1;
    end

  assign pll_locked = 1'b1;
   
  always
    begin // 12Mhz
       #41.5;
       pc3 = 1'b0;
       #41.5;
       pc3 = 1'b1;
    end

  always
    begin // 24Mhz
       #10.3;
       pc2 = 1'b0;
       #10.3;
       pc2 = 1'b1;
    end

  always
    begin // 48Mhz
       #20.7;
       pc1 = 1'b0;
       #20.7;
       pc1 = 1'b1;
    end

  always
    begin // 240Mhz
       #2.1;
       pc = 1'b0;
       #2.1;
       pc = 1'b1;
    end
`else
   // (50*29)/2 = 750Mhz
   // 725Mhz / 3   = 250Mhz (pll_clk)
   // 725Mhz / 30  = 25Mhz  (clk_vga)
   // 725Mhz / 15  = 50MHz  (clk_vga2x)
   // 725Mhz / 60  = 12.5MHz  (clk_cpu)
  PLL_BASE
  #(.BANDWIDTH              ("OPTIMIZED"),
    .CLK_FEEDBACK           ("CLKFBOUT"),
    .COMPENSATION           ("INTERNAL"),

    .DIVCLK_DIVIDE          (2),
    .CLKFBOUT_MULT          (30),
    .CLKFBOUT_PHASE         (0.000),

    .CLKOUT0_DIVIDE         (3),    // 250mhz
    .CLKOUT0_PHASE          (0.000),
    .CLKOUT0_DUTY_CYCLE     (0.500),

    .CLKOUT1_DIVIDE         (30),   // 25mhz
    .CLKOUT1_PHASE          (0.000),
    .CLKOUT1_DUTY_CYCLE     (0.500),

    .CLKOUT2_DIVIDE         (15),   // 50mhz
    .CLKOUT2_PHASE          (0.000),
    .CLKOUT2_DUTY_CYCLE     (0.500),

    .CLKOUT3_DIVIDE         (60),   // 12mhz
    .CLKOUT3_PHASE          (0.000),
    .CLKOUT3_DUTY_CYCLE     (0.500),

    .CLKIN_PERIOD           (20.000),
    .REF_JITTER             (0.010))
  pll_base_inst
    // Output clocks
   (.CLKFBOUT              (pll_clkfbout),
    .CLKOUT0               (pll_clk),
    .CLKOUT1               (pll_clkout1),
    .CLKOUT2               (pll_clkout2),
    .CLKOUT3               (pll_clkout3),
    .CLKOUT4               (clkout4_unused),
    .CLKOUT5               (clkout5_unused),
    // Status and control signals
    .LOCKED                (pll_locked),
    .RST                   (reset_clk),
     // Input clock control
    .CLKFBIN               (pll_clkfbout),
    .CLKIN                 (clk50));
`endif
  
   // clk_vga10x is generated in the BUFPLL below
  BUFG clkout1_buf (.I(pll_clkout1), .O(clk_vga));
  BUFG clkout2_buf (.I(pll_clkout2), .O(clk_vga2x));
  BUFG clkout3_buf (.I(pll_clkout3), .O(clk_cpu));
   
   //
   wire serdes_strobe;
   wire serdes_reset;
   wire bufpll_locked;

   assign serdes_reset = reset_clk | ~bufpll_locked;

   BUFPLL #(.DIVIDE(5)) ioclk_buf (.PLLIN(pll_clk), .GCLK(clk_vga2x), .LOCKED(pll_locked),
				   .IOCLK(clk_vga10x), .SERDESSTROBE(serdes_strobe), .LOCK(bufpll_locked));

   dvid dvid_inst(
		  .clk_pixel(clk_vga),
		  .clk_pixel2x(clk_vga2x),
		  .clk_pixel10x(clk_vga10x),
		  .reset    (reset),
		  .serdes_strobe(serdes_strobe),
		  .serdes_reset (serdes_reset),
		  .red_p    (red),
		  .green_p  (green),
		  .blue_p   (blue),
		  .blank    (blank),
		  .hsync    (hsync),
		  .vsync    (vsync),
		  // outputs to TMDS drivers
		  .red_s    (red_s),
		  .green_s  (green_s),
		  .blue_s   (blue_s),
		  .clock_s  (clock_s)
		  );
      
   OBUFDS OBUFDS_blue  ( .O(TMDS[0]), .OB(TMDSB[0]), .I(blue_s ) );
   OBUFDS OBUFDS_red   ( .O(TMDS[1]), .OB(TMDSB[1]), .I(green_s) );
   OBUFDS OBUFDS_green ( .O(TMDS[2]), .OB(TMDSB[2]), .I(red_s  ) );
   OBUFDS OBUFDS_clock ( .O(TMDS[3]), .OB(TMDSB[3]), .I(clock_s) );

endmodule // dvid_output

