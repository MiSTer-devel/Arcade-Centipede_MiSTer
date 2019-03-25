//
// centipede
// fpga top for pipistrello lx45 fpga board
// Brad Parker <brad@heeltoe.com> 11/2015
//

// 50Mhz (sysclk)
// 25Mhz (clk_vga)
// 12MHz (clk_cpu)
//  6MHz (clk_pix)

`define scan_convert

module cent_top(
		     output [5:1] led,
		     input 	  sysclk,
		     input 	  clk_vga,
		     input 	  clk_cpu,
		     input 	  clk_pix,
			      
		     output 	  vga_hsync,
		     output 	  vga_vsync,
		     output 	  vga_r,
		     output 	  vga_g,
		     output 	  vga_b,
			      
		     input 	  switch,
		     input 	  button1,
		     input 	  button2,
		     input 	  button3
		   );

   // -----
   
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

   wire       reset;

   assign trakball_i = 0;
   assign joystick_i = 0;
   assign sw1_i = 8'h54;
   assign sw2_i = 8'b0;

   wire       coin_r, coin_c, coin_l, self_test, cocktail, slam, start1, start2, fire2, fire1;
   
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
   assign vga_rrr = { vga_rgb[7], vga_rgb[6], vga_rgb[5] };
   assign vga_ggg = { vga_rgb[4], vga_rgb[3], 1'b0   };
   assign vga_bbb = { vga_rgb[0], vga_rgb[1], vga_rgb[2] };

   // to raw vga output
   assign vga_r = vga_rgb[7] | vga_rgb[6] | vga_rgb[5];
   assign vga_g = vga_rgb[4] | vga_rgb[3];
   assign vga_b = vga_rgb[0] | vga_rgb[1] | vga_rgb[2];
//assign vga_b = 1;

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
		 .vblank_o(cga_vblank)
		 );

   wire dcm_reset;
   reg 	[9:0] local_reset;

   initial
     local_reset = 10'b1111111111;
   
   always @(posedge sysclk)
     local_reset <= {local_reset[8:0], 1'b0};

   assign dcm_reset = local_reset[9];
   
   // clocks and reset
   car_lx45 car(
		.sysclk(sysclk),
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
   

endmodule // ff_top_lx45
