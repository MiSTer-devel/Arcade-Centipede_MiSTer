//============================================================================
//  Arcade: Centipede
//
//  Port to MiSTer
//  Copyright (C) 2019 alanswx
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [45:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	output [11:0] VIDEO_ARX,
	output [11:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler

	// Use framebuffer from DDRAM (USE_FB=1 in qsf)
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of 16 bytes.
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,    // 1 - signed audio samples, 0 - unsigned

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT
);

assign VGA_F1    = 0;
assign VGA_SCALER= 0;
assign USER_OUT  = '1;
assign LED_USER  = ioctl_download;
assign LED_DISK  = 0;
assign LED_POWER = 0;

wire [1:0] ar = status[20:19];

assign VIDEO_ARX = (!ar) ? (status[2]  ? 8'd4 : 8'd3) : (ar - 1'd1);
assign VIDEO_ARY = (!ar) ? (status[2]  ? 8'd3 : 8'd4) : 12'd0;

`include "build_id.v" 
localparam CONF_STR = {
	"A.CENTIPED;;",
	"H0OJK,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"H0O2,Orientation,Vert,Horz;",
	"O35,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",  
	"-;",
	"O89,Lives,2,3,4,5;",
	"OAB,Bonus,10000,12000,15000,20000;",
	"OC,Cabinet,Upright,Cocktail;",
	"OD,Test,No,Yes;",
	"OEF,Language,English,German,French,Spanish;",
	"OG,Difficulty,Easy,Hard;",
	"-;",

	"R0,Reset;",
	"J1,Fire,Start 1P,Start 2P,Coin;",
	"Jn,A,Start,Select,Right;",
	"V,v",`BUILD_DATE
};

wire [7:0]m_dip = {   1'b0, ~status[16],status[11:10],status[9:8],status[15:14]};


////////////////////   CLOCKS   ///////////////////

wire clk_sys=clk_12;
wire clk_48;
wire clk_24;
wire clk_12;
wire clk_6;
wire clk_100mhz;

pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_24),
	.outclk_1(clk_12),
	.outclk_2(clk_6),
	.outclk_3(clk_100mhz),
	.outclk_4(clk_48)
	
);

///////////////////////////////////////////////////

wire [31:0] status;
wire  [1:0] buttons;
wire        forced_scandoubler;
wire        direct_video;

wire        ioctl_download;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

wire [15:0] joystick_0, joystick_1;
wire [15:0] joy = joystick_0 | joystick_1;

wire [21:0] gamma_bus;


hps_io #(.STRLEN($size(CONF_STR)>>3)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),
	.EXT_BUS(),

	.conf_str(CONF_STR),

	.buttons(buttons),
	.status(status),
	.status_menumask({direct_video}),

	.forced_scandoubler(forced_scandoubler),
	.gamma_bus(gamma_bus),
	.direct_video(direct_video),

	.ioctl_download(ioctl_download),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),

	.joystick_0(joystick_0),
	.joystick_1(joystick_1)
);


wire m_up_2     = joy[3];
wire m_down_2   = joy[2];
wire m_left_2   = joy[1];
wire m_right_2  = joy[0];
wire m_fire_2  =  joy[4];

wire m_up     = joy[3];
wire m_down   = joy[2];
wire m_left   = joy[1];
wire m_right  = joy[0];
wire m_fire   = joy[4];

wire m_start1 = joy[5];
wire m_start2 = joy[6];
wire m_coin   = joy[7];

wire m_test = ~status[13];
wire m_slam = 1'b1;//generate Noise



wire hblank, vblank;
wire hs, vs;
wire [2:0] r,g;
wire [2:0] b;
wire ce_vid = clk_6_o;
wire [8:0] rgb;

reg ce_pix;
always @(posedge clk_48) begin
        reg [1:0] div;

        div <= div + 1'd1;
        ce_pix <= !div;
end

wire no_rotate = status[2] | direct_video ;
wire rotate_ccw = 0;
screen_rotate screen_rotate (.*);


arcade_video #(521,9,1) arcade_video
(
	.*,

	.clk_video(clk_48),
	.RGB_in({rgb[2:0],rgb[5:3],rgb[8:6]}),
	.HBlank(hblank),
	.VBlank(vblank),
	.HSync(hs),
	.VSync(vs),
	
	.fx(status[5:3])

);


   wire [7:0] audio;
   assign AUDIO_L = {audio,audio};
   assign AUDIO_R = AUDIO_L;
   assign AUDIO_S = 0;

   wire [3:0] led_o;
   wire [7:0] trakball_i;
   wire [7:0] joystick_i;
   wire [7:0] sw1_i;
   wire [7:0] sw2_i;
   wire [9:0] playerinput_i;

  

   assign trakball_i = 0;
   assign sw1_i = 8'h54;
   assign sw2_i = 8'b0;
/*
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
*/
//   assign playerinput_i = { coin_r, coin_c, coin_l, self_test, cocktail, slam, ~mstart1, ~mstart2, 1'b1, ~mfire };
   assign playerinput_i = { 1'b1, 1'b1, ~(m_coin), m_test, status[12], m_slam, ~(m_start2), ~(m_start1), ~m_fire_2, ~m_fire };
	
	
	assign joystick_i = { ~m_right,~m_left,~m_down,~m_up, ~m_right_2,~m_left_2,~m_down_2,~m_up_2};
//   assign playerinput_i = 10'b111_101_11_11;




	wire reset;
assign reset = (RESET | status[0] | buttons[1] | ioctl_download);
wire clk_6_o;
	
   // game & cpu
   centipede uut(
		 .clk_12mhz(clk_12),
		 .clk_100mhz(clk_100mhz),
 		 .reset(reset),
		 .playerinput_i(playerinput_i),
		 .trakball_i(trakball_i),
		 .joystick_i(joystick_i),
		 .sw1_i(m_dip),
		 .sw2_i(sw2_i),
		 .led_o(led_o),
		 .audio_o(audio),

		 .dn_addr(ioctl_addr[15:0]),
		 .dn_data(ioctl_dout),
		 .dn_wr(ioctl_wr),
	 
		 
		 .rgb_o(rgb),
		 .sync_o(),
		 .hsync_o(hs),
		 .vsync_o(vs),
		 .hblank_o(hblank),
		 .vblank_o(vblank),
		 .clk_6mhz_o(clk_6_o)

		 /*
		 
		 .rgb_o(cga_rgb),
		 .sync_o(cga_csync),
		 .hsync_o(cga_hsync),
		 .vsync_o(cga_vsync),
		 .hblank_o(cga_hblank),
		 .vblank_o(cga_vblank),
*/
		 );


endmodule
