//
// centipede
// fpga top for pipistrello lx45 fpga board
// Brad Parker <brad@heeltoe.com> 11/2015
//

`define sound
`define hdmi
`define scan_convert

module cent_top_lx45(
		     output [5:1]   led,
		     input 	    sysclk,
			      
		     output 	    vga_hsync,
		     output 	    vga_vsync,
		     output 	    vga_r,
		     output 	    vga_g,
		     output 	    vga_b,
			      
		     input 	    switch,
		     input [10:0]   Wing_A_in,
		     input [6:0]    Wing_B_in,
		     output [15:11] Wing_A_out,
			      
		     output [3:0]   tmds,
		     output [3:0]   tmdsb,
			      
		     output 	    audio_l,
		     output 	    audio_r
		   );

   // -----
   
   wire sysclk_buf;
   BUFG sysclk_bufg (.I(sysclk), .O(sysclk_buf));

   wire dcm_reset;

   wire auto_coin_n, auto_start_n, auto_throw_n;

   wire cga_hsync, cga_vsync, cga_csync, cga_hblank, cga_vblank;
   wire [8:0] cga_rgb;

   wire [3:0] led_o;
   wire [7:0] trakball_i;
   wire [7:0] joystick_i;
   wire [7:0] sw1_i;
   wire [7:0] sw2_i;
   wire [9:0] playerinput_i;
   wire [7:0] audio_o;

   wire       clk_vga;
   wire       clk_cpu;
   wire       clk_pix;
   wire       reset;

   assign trakball_i = 0;
   assign joystick_i = 0;
   assign sw1_i = 8'h54;
   assign sw2_i = 8'b0;

   wire       coin_r, coin_c, coin_l, self_test, cocktail, slam, start1, start2, fire2, fire1;
   
`ifdef testing
   assign coin_r = 1;
   assign coin_c = 1;
   assign coin_l = 1;
   assign self_test = 1;
   assign cocktail = 0;
   assign slam = 1;
   assign start1 = 1;
   assign start2 = 1;
   assign fire2 = 1;
   assign fire1 = 1;

//   assign playerinput_i = { coin_r, coin_c, coin_l, self_test, cocktail, slam, start1, start2, fire2, fire1 };
   assign playerinput_i = 10'b111_101_11_11;
`else
   assign coin_r = Wing_A_in[0];
   assign coin_c = 1;
   assign coin_l = 1;
   assign self_test = 1;
   assign cocktail = 0;
   assign slam = 1;
   assign start1 = Wing_A_in[1];
   assign start2 = Wing_A_in[2];
   assign fire2 = 1;
   assign fire1 = Wing_B_in[6];

   assign playerinput_i = { coin_r, coin_c, coin_l, self_test, cocktail, slam, start1, start2, fire2, fire1 };

   assign Wing_A_out[11] = led_o[0];
   assign Wing_A_out[12] = led_o[1];
   assign Wing_A_out[13] = led_o[2];
   assign Wing_A_out[14] = led_o[3];
   assign Wing_A_out[15] = reset;
`endif
       
   assign led[1] = led_o[0];
   assign led[2] = led_o[1];
   assign led[3] = led_o[2];
   assign led[4] = led_o[3];
   assign led[5] = reset;

   wire hsync, vsync, blank;

   // video from scan converter
   wire vga_blank;
   wire [7:0] vga_rgb;
   wire [2:0] vga_rrr, vga_ggg, vga_bbb;

   // to hdmi
   assign vga_bbb = { vga_rgb[7], vga_rgb[6], vga_rgb[5] };
   assign vga_ggg = { vga_rgb[4], vga_rgb[3], 1'b0 };
   assign vga_rrr = { vga_rgb[2], vga_rgb[1], vga_rgb[0] };

   // to raw vga output
   assign vga_b = vga_rgb[7] | vga_rgb[6] | vga_rgb[5];
   assign vga_g = vga_rgb[4] | vga_rgb[3];
   assign vga_r = vga_rgb[2] | vga_rgb[1] | vga_rgb[0];

   wire clk6m, clk12m, clk25m;

   // game & cpu
   centipede uut(
		 .clk_12mhz(clk12m),
 		 .reset(reset),
		 .playerinput_i(playerinput_i),
		 .trakball_i(trakball_i),
		 .joystick_i(joystick_i),
		 .sw1_i(sw1_i),
		 .sw2_i(sw2_i),
		 .led_o(led_o),
		 .audio_o(audio_o),

		 .rgb_o(cga_rgb),
		 .sync_o(cga_csync),
		 .hsync_o(cga_hsync),
		 .vsync_o(cga_vsync),
		 .hblank_o(cga_hblank),
		 .vblank_o(cga_vblank),
		 .clk_6mhz_o(clk_pix)
		 );

   // clocks and reset
   car_lx45 car(
		.sysclk(sysclk_buf),
		.clk_vga(clk_vga),
		.clk_cpu(clk_cpu),
		.clk_pix(clk_pix),
		.dcm_reset(dcm_reset),
		.button(switch),
		.reset(reset),
		.auto_coin_n(auto_coin_n),
		.auto_start_n(auto_start_n),
		.auto_throw_n(auto_throw_n),
		.clk6m(clk6m),
		.clk12m(clk12m),
		.clk25m(clk25m)
		);

`ifdef scan_convert
   // cga -> vga
   
   scanconvert2_lx45 scanconv(
			      .clk6m(clk6m),
			      .clk12m(clk12m),
			      .clk25m(clk25m),
			      .reset(reset),
			      .hsync_i(cga_hsync),
			      .vsync_i(cga_vsync),
			      .hblank_i(cga_hblank),
			      .vblank_i(cga_vblank),
			      .rgb_i(cga_rgb),
			      .hsync_o(vga_hsync),
			      .vsync_o(vga_vsync),
			      .blank_o(vga_blank),
			      .rgb_o(vga_rgb)
			      );
`else
   assign vga_hsync = cga_hsync;
   assign vga_vsync = cga_vsync;
   assign vga_blank = cga_vblank | cga_hblank;
`endif
   
`ifdef sound
   //
   wire dac_o;
   
   ds_dac ds_output(.clk_i(sysclk_buf),
		    .res_i(reset),
		    .dac_i(audio_o),
		    .dac_o(dac_o)
		    );

   assign audio_l = dac_o;
   assign audio_r = dac_o;
`else
   assign audio_l = dac[1] | dac[4];
   assign audio_r = dac[1] | dac[4];
`endif

`ifdef hdmi
   //
   wire dvid_hsync, dvid_vsync, dvid_blank;
   wire [7:0] dvid_red;
   wire [7:0] dvid_green;
   wire [7:0] dvid_blue;
   reg [3:0]  reset_reg;

   // quick reset
   assign dcm_reset = reset_reg[3];
   initial reset_reg = 4'b1111;
		     
   always @ (posedge sysclk_buf)
     reset_reg <= {reset_reg[2:0],1'b0};

   //
   // 12mhz clock, 83ns
   // video counter; 0..16639
   // video addres
   // 11111
   // 432109876543210
   // xxxxxxxxxx1110x hsync 001e
   // x11111xxxxxxxxx vsync
   // 1xxxxxxxxxxxxxx mask
   // 011111100000000 mask

   // x11 111x xxxx xxxx vsync
   //
   // 111111000000000
   // 7  e   0   0	7300 32256
   // 100000011111111
   // 4  0   f   f      40ff 16639
   //
   //
   // 32 x 1000ns = 32us / line
   // 16640 x 1000ns = 16.640us / frame

   //
   assign dvid_red   = (vga_rrr == 3'b0) ? 8'b0 : { vga_rrr, 5'b11111 };
   assign dvid_green = (vga_ggg == 3'b0) ? 8'b0 : { vga_ggg, 5'b11111 };
   assign dvid_blue  = (vga_bbb == 3'b0) ? 8'b0 : { vga_bbb, 5'b11111 };
   
   assign dvid_hsync = ~vga_hsync;
   assign dvid_vsync = ~vga_vsync;
   assign dvid_blank = vga_blank;

   dvid_output hdmi(.clk50(sysclk_buf),
		    .reset(/*reset*/dcm_reset),
		    .reset_clk(dcm_reset),
		    .red(dvid_red),
		    .green(dvid_green),
		    .blue(dvid_blue),
		    .hsync(dvid_hsync),
		    .vsync(dvid_vsync),
		    .blank(dvid_blank),
		    .clk_vga(clk_vga),
		    .clk_cpu(clk_cpu),
		    .TMDS(tmds),
		    .TMDSB(tmdsb));
`else // !`ifdef hdmi

   wire       LOCKED;
   reg [3:0]  reset_reg;

   // quick reset
   assign dcm_reset = reset_reg[3];
   initial reset_reg = 4'b1111;
		     
   always @ (posedge sysclk_buf)
     reset_reg <= {reset_reg[2:0],1'b0};

   wire [15:0] do_unused;
   wire        drdy_unused;
   wire        clkfbout;
   wire        clkout0, clkout1;
   wire        clkout2_unused, clkout3_unused, clkout4_unused, clkout5_unused;

   // 50*12 = 600Mhz
   // 600Mhz / 24  = 25Mhz (clk_vga)
   // 600Mhz / 50  = 12MHz (clk_cpu)
  PLL_BASE
  #(.BANDWIDTH              ("OPTIMIZED"),
    .CLK_FEEDBACK           ("CLKFBOUT"),
    .COMPENSATION           ("INTERNAL"),
    .DIVCLK_DIVIDE          (1),
    .CLKFBOUT_MULT          (12),
    .CLKFBOUT_PHASE         (0.000),

    .CLKOUT0_DIVIDE         (24),
    .CLKOUT0_PHASE          (0.000),
    .CLKOUT0_DUTY_CYCLE     (0.500),

    .CLKOUT1_DIVIDE         (50),
    .CLKOUT1_PHASE          (0.000),
    .CLKOUT1_DUTY_CYCLE     (0.500),

    .CLKIN_PERIOD           (20.000),
    .REF_JITTER             (0.010))
  pll_base_inst
    // Output clocks
   (.CLKFBOUT              (clkfbout),
    .CLKOUT0               (clkout0),
    .CLKOUT1               (clkout1),
    .CLKOUT2               (clkout2_unused),
    .CLKOUT3               (clkout3_unused),
    .CLKOUT4               (clkout4_unused),
    .CLKOUT5               (clkout5_unused),
    // Status and control signals
    .LOCKED                (LOCKED),
    .RST                   (dcm_reset),
     // Input clock control
    .CLKFBIN               (clkfbout),
    .CLKIN                 (sysclk_buf));

   BUFG clkout0_buf (.O(clk_vga), .I(clkout0));
   BUFG clkout1_buf (.O(clk_cpu), .I(clkout1));

   // null drivers
   wire blue_s, green_s, red_s, clock_s;

   assign blue_s = 1'b0;
   assign green_s = 1'b0;
   assign red_s = 1'b0;
   assign clock_s = 1'b0;

   OBUFDS OBUFDS_blue  ( .O(tmds[0]), .OB(tmdsb[0]), .I(blue_s ) );
   OBUFDS OBUFDS_green ( .O(tmds[1]), .OB(tmdsb[1]), .I(green_s) );
   OBUFDS OBUFDS_red   ( .O(tmds[2]), .OB(tmdsb[2]), .I(red_s  ) );
   OBUFDS OBUFDS_clock ( .O(tmds[3]), .OB(tmdsb[3]), .I(clock_s) );

`endif
   
endmodule // ff_top_lx45
