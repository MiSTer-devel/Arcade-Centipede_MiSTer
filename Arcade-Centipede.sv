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
	inout  [48:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler
	output        VGA_DISABLE, // analog out is off

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
	output        HDMI_FREEZE,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

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

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
	//Secondary SDRAM
	//Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS
);

///////// Default values for ports not used in this core /////////

assign ADC_BUS  = 'Z;
assign USER_OUT = '1;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
assign FB_FORCE_BLANK = '0;

assign VGA_F1 = '0;
assign VGA_SCALER = '0;
assign VGA_DISABLE = '0;
assign HDMI_FREEZE = '0;

assign AUDIO_S = '0;
assign AUDIO_MIX = '0;

assign LED_DISK = '0;
assign LED_POWER = '0;
assign LED_USER = '0;
assign BUTTONS = '0;

wire [1:0] ar = status[20:19];

assign VIDEO_ARX = (!ar) ? (status[2]  ? 8'd16 : 8'd15) : (ar - 1'd1);
assign VIDEO_ARY = (!ar) ? (status[2]  ? 8'd15 : 8'd16) : 12'd0;

`include "build_id.v"
localparam CONF_STR = {
	"A.CENTIPED;;",
	"H0OJK,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"H0O2,Orientation,Vert,Horz;",
	"O35,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"OEFG,Mouse/trackball speed,100%,200%,400%,25%,50%,-,-,-;",
	"OB,Vertical flip,Off,On;",
	"OC,Cabinet,Cocktail,Upright;",
	"-;",
	"OD,Test,Off,On;",
	"-;",
	"DIP;",
	"-;",
	"OR,Autosave Hiscores,Off,On;",
	"P1,Pause options;",
	"P1OP,Pause when OSD is open,On,Off;",
	"P1OQ,Dim video after 10s,On,Off;",
	"-;",
	"R0,Reset;",
	"J1,Fire,Start 1P,Start 2P,Coin,Pause;",
	"Jn,A,Start,Select,R,L;",
	"V,v",`BUILD_DATE
};

////////////////////   CLOCKS   ///////////////////

wire clk_sys=clk_12;
wire clk_24;
wire clk_12;

pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(),
	.outclk_1(clk_24),
	.outclk_2(clk_12)

);

///////////////////////////////////////////////////

wire [31:0] status;
wire  [1:0] buttons;
wire        forced_scandoubler;
wire        video_rotated;
wire        direct_video;

wire        ioctl_download;
wire        ioctl_upload;
wire        ioctl_upload_req;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire  [7:0] ioctl_din;

wire [15:0] joystick_0, joystick_1;
wire [15:0] joy = joystick_0 | joystick_1;

wire [24:0] ps2_mouse;

wire [21:0] gamma_bus;


hps_io #(.CONF_STR(CONF_STR)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),
	.EXT_BUS(),

	.buttons(buttons),
	.status(status),
	.status_menumask({direct_video}),

	.forced_scandoubler(forced_scandoubler),
	.video_rotated(video_rotated),
	.gamma_bus(gamma_bus),
	.direct_video(direct_video),

	.ioctl_download(ioctl_download),
	.ioctl_upload(ioctl_upload),
	.ioctl_upload_req(ioctl_upload_req),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_din(ioctl_din),
	.ioctl_index(ioctl_index),

	.joystick_0(joystick_0),
	.joystick_1(joystick_1),

	.ps2_mouse(ps2_mouse)
);


///////////////////   CONTROLS   ////////////////////

wire m_up_2     = joy[3];
wire m_down_2   = joy[2];
wire m_left_2   = joy[1];
wire m_right_2  = joy[0];
wire m_fire_2  =  joy[4] | ps2_mouse[0];

wire m_up     = joy[3];
wire m_down   = joy[2];
wire m_left   = joy[1];
wire m_right  = joy[0];
wire m_fire   = joy[4] | ps2_mouse[0];

wire m_start1 = joy[5];
wire m_start2 = joy[6];
wire m_coin   = joy[7];

wire m_test = status[13];
wire m_slam = 1'b0;//generate Noise
wire m_pause   = joy[8];
wire screen_flip = status[11];
wire m_cocktail = status[12];

wire		vtb_dir1;
wire		vtb_clk1;
wire		htb_dir1;
wire		htb_clk1;
trackball trackball
(
	.clk(clk_sys),
	.flip(control_flip),
	.mouse_speed(status[16:14]),
	.ps2_mouse(ps2_mouse),
	.v_dir(vtb_dir1),
	.v_clk(vtb_clk1),
	.h_dir(htb_dir1),
	.h_clk(htb_clk1)
);

// PAUSE SYSTEM
wire				pause_cpu;
wire [8:0]		rgb_out;
pause #(3,3,3,24) pause (
	.*,
	.user_button(m_pause),
	.pause_request(hs_pause),
	.options(~status[26:25]),
	.r(rgb_in[2:0]),
	.g(rgb_in[5:3]),
	.b(rgb_in[8:6])
);

// DIPS

reg [7:0] sw[8];
always @(posedge clk_sys)
begin
	if (ioctl_wr && (ioctl_index==8'd254) && !ioctl_addr[24:3]) sw[ioctl_addr[2:0]] <= ioctl_dout;
end

// DISPLAY
wire hblank, vblank;
wire hs, vs;
wire [8:0] rgb_in;
reg ce_pix;
always @(posedge clk_24) begin
	reg [1:0] div;
	div <= div + 1'd1;
	ce_pix <= !div;
end
wire no_rotate = status[2] | direct_video ;
wire rotate_ccw = 1;
wire flip = 0;

screen_rotate screen_rotate (.*);

arcade_video #(256,9,1) arcade_video
(
	.*,
	.clk_video(clk_24),
	.RGB_in(rgb_out),
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

wire control_flip;
wire [3:0] led_o;
wire [7:0] trakball_i;
wire [7:0] joystick_i;
wire [7:0] sw1_i;
wire [7:0] sw2_i;
wire [9:0] playerinput_i;

// inputs: coin R, coin C, coin L, self test, cocktail, slam, start 2, start 1, fire 2, fire 1
assign playerinput_i = ~{ 1'b0, 1'b0, m_coin, m_test, m_cocktail, m_slam, m_start2, m_start1, m_fire_2, m_fire };
assign joystick_i = ~{ m_right, m_left, m_down, m_up, m_right_2, m_left_2, m_down_2, m_up_2 };
assign trakball_i = ~{ htb_dir1, htb_dir1, htb_clk1, htb_clk1, vtb_dir1, vtb_dir1, vtb_clk1, vtb_clk1 };

wire rom_download = ioctl_download & ioctl_index == 8'd0;
wire nvram_download = ioctl_download & ioctl_index == 8'd4;
wire reset = (RESET | status[0] | buttons[1] | rom_download);
wire clk_6_o;

// game & cpu
centipede uut(
	.clk_12mhz(clk_12),
	.reset(reset),
	.playerinput_i(playerinput_i),
	.trakball_i(trakball_i),
	.flip_o(control_flip),
	.scrn_flip_i(screen_flip),
	.joystick_i(joystick_i),
	.sw1_i(sw[1]),
	.sw2_i(sw[2]),
	.led_o(led_o),
	.audio_o(audio),

	.dn_addr(ioctl_addr[15:0]),
	.dn_data(ioctl_dout),
	.dn_wr(ioctl_wr & rom_download),

	.rgb_o(rgb_in),
	.sync_o(),
	.hsync_o(hs),
	.vsync_o(vs),
	.hblank_o(hblank),
	.vblank_o(vblank),
	.clk_6mhz_o(clk_6_o),

	.pause(pause_cpu),

	.hs_address(ioctl_download ? ioctl_addr[5:0] : hs_address),
	.hs_data_out(hs_data_out),
	.hs_data_in(ioctl_dout),
	.hs_write(ioctl_wr & nvram_download)

);

// HISCORE SYSTEM
// --------------
wire [5:0] hs_address;
wire [7:0] hs_data_out;
wire hs_pause;

nvram #(
	.DUMPWIDTH(6),
	.DUMPINDEX(4),
	.PAUSEPAD(2)
) hi (
	.*,
	.clk(clk_sys),
	.paused(pause_cpu),
	.autosave(status[27]),
	.nvram_address(hs_address),
	.nvram_data_out(hs_data_out),
	.pause_cpu(hs_pause)
);

endmodule
