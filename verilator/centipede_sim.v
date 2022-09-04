`timescale 1ns/1ns
// top end ff for verilator

module top(

	input clk_48 /*verilator public_flat*/,
	input clk_12 /*verilator public_flat*/,
	input RESET/*verilator public_flat*/,
	input [11:0]  inputs/*verilator public_flat*/,
	input [24:0]  ps2_mouse/*verilator public_flat*/,

	output [7:0] VGA_R/*verilator public_flat*/,
	output [7:0] VGA_G/*verilator public_flat*/,
	output [7:0] VGA_B/*verilator public_flat*/,
	
	output VGA_HS,
	output VGA_VS,
	output VGA_HB,
	output VGA_VB,

	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	
	input OSD_STATUS,
	input        ioctl_download,
	input        ioctl_upload,
	output       ioctl_upload_req,
	input        ioctl_wr,
	input [24:0] ioctl_addr,
	input [7:0]  ioctl_dout,
	output [7:0] ioctl_din,   
	input [7:0]  ioctl_index,
	output  reg  ioctl_wait=1'b0
	
);
	
	// Core inputs/outputs
	wire [7:0] audio;
	wire [8:0] rgb;
	wire [3:0] led/*verilator public_flat*/;
	reg [7:0]  trakball_i/*verilator public_flat*/;
	reg [7:0]  joystick/*verilator public_flat*/;
	reg [9:0]  playerinput/*verilator public_flat*/;  

	// Hardcode default switches
	//reg [7:0]  sw1 = 8'b01001100; // 5 lives
	reg [7:0]  sw1 = 8'b01000000; // 2 lives
	reg [7:0]  sw2 = 8'h02;

	 
	// MAP INPUTS FROM SIM
	// -------------------
	assign playerinput[9] = ~inputs[10]; // coin r
	assign playerinput[8] = ~inputs[9]; // coin m
	assign playerinput[7] = ~inputs[8]; // coin l
	assign playerinput[6] = 1'b1;       // self-test
	assign playerinput[5] = 1'b0;       // cocktail
	assign playerinput[4] = 1'b1;       // slam
	assign playerinput[3] = ~inputs[7]; // start 2
	assign playerinput[2] = ~inputs[6]; // start 1
	assign playerinput[1] = ~inputs[5]; // fire 2
	assign playerinput[0] = ~inputs[4]; // fire 1  
	assign joystick[7:4] = { ~inputs[0],~inputs[1],~inputs[2],~inputs[3] }; // right, left, down, up 1
	assign joystick[3:0] = { ~inputs[0],~inputs[1],~inputs[2],~inputs[3] }; // right, left, down, up 2
	wire m_pause = inputs[11];       // pause

	// Trackball
	// ---------
	wire		flip;
	wire		vtb_dir1;
	wire		vtb_clk1;
	wire		htb_dir1;
	wire		htb_clk1;
	reg [1:0]	mouse_speed /*verilator public_flat*/ = 2'd02;
	reg			joystick_sensitivity /*verilator public_flat*/ = 1'b0;

	assign trakball_i = {htb_dir1,htb_dir1,htb_clk1,htb_clk1,vtb_dir1,vtb_dir1,vtb_clk1,vtb_clk1};

	trackball trackball
	(
		.clk(clk_12),
		.flip(flip),
		.mouse_speed(mouse_speed),
		.ps2_mouse(ps2_mouse),
		.v_dir(vtb_dir1),
		.v_clk(vtb_clk1),
		.h_dir(htb_dir1),
		.h_clk(htb_clk1)
	);

	// MAP OUTPUTS
	assign AUDIO_L = {audio,audio};
	assign AUDIO_R = AUDIO_L;

	reg ce_pix;
	always @(posedge clk_48) begin
		reg old_clk;
		
		old_clk <= clk_12;
		ce_pix <= old_clk & ~clk_12;
	end

	
// PAUSE SYSTEM
wire				pause_cpu;
wire [8:0]		rgb_out;
pause #(3,3,3,24) pause (
	.*,
	.clk_sys(clk_12),
	.user_button(m_pause),
	.pause_request(hs_pause),
	.options(2'b11),
	.r(rgb[2:0]),
	.g(rgb[5:3]),
	.b(rgb[8:6])
);

	// Convert 3bpp output to 8bpp
	assign VGA_R = {rgb_out[8:6],rgb_out[8:6],rgb_out[8:7]};
	assign VGA_G = {rgb_out[5:3],rgb_out[5:3],rgb_out[5:4]};
	assign VGA_B = {rgb_out[2:0],rgb_out[2:0],rgb_out[2:1]};

	reg rom_downloaded = 0;
	wire rom_download = ioctl_download && ioctl_index == 8'd0;
	wire nvram_download = ioctl_download && ioctl_index == 8'd4;
	wire reset = (RESET | rom_download | nvram_download | !rom_downloaded);
	always @(posedge clk_12) if(rom_download) rom_downloaded <= 1'b1; // Latch downloaded rom state to release reset

	centipede uut(
		.clk_12mhz(clk_12),
 		.reset(reset),
		.playerinput_i(playerinput),
		.trakball_i(trakball_i),
		.joystick_i(8'hFF),
		//.joystick_i(joystick),
		.sw1_i(sw1),
		.sw2_i(sw2),
		.led_o(led),
		.rgb_o(rgb),
		.sync_o(),
		.hsync_o(VGA_HS),
		.vsync_o(VGA_VS),
		.hblank_o(VGA_HB),
		.vblank_o(VGA_VB),
		.audio_o(audio),
		.clk_6mhz_o(),
		.flip_o(),
		.scrn_flip_i(1'b0),
		.dn_addr(ioctl_addr[15:0]),
		.dn_data(ioctl_dout),
		.dn_wr(ioctl_wr && rom_download),
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
	.clk(clk_12),
	.paused(pause_cpu),
	.autosave(1'b1),
	.nvram_address(hs_address),
	.nvram_data_out(hs_data_out),
	.pause_cpu(hs_pause)
);

endmodule
