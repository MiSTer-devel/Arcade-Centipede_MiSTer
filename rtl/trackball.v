/*============================================================================
	Atari Trackball emulator

	Copyright (C) 2022 - Jim Gregory - https://github.com/JimmyStones/

	This program is free software; you can redistribute it and/or modify it
	under the terms of the GNU General Public License as published by the Free
	Software Foundation; either version 3 of the License, or (at your option)
	any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License along
	with this program. If not, see <http://www.gnu.org/licenses/>.
===========================================================================*/

`timescale 1 ps / 1 ps
`default_nettype none

module trackball(
	input			clk,
	input			flip,
	input  [1:0]	mouse_speed,
	input [24:0]	ps2_mouse,
	output reg		v_dir,
	output reg		v_clk,
	output reg		h_dir,
	output reg		h_clk
);

// Trackball movement
localparam trackball_falloff_width = 11;
reg [trackball_falloff_width-1:0] trackball_falloff;

reg [7:0] mouse_mag_x /* synthesis preserve noprune */;
reg [7:0] mouse_mag_y /* synthesis preserve noprune */;

wire mouse_clock /* synthesis keep */ = ps2_mouse[24];
wire mouse_sign_x = /* synthesis preserve noprune */ ps2_mouse[4];
wire mouse_sign_y = /* synthesis preserve noprune */ ps2_mouse[5];

localparam [15:0] clock_base = 16'd3500;

reg [15:0] h_clock_counter = 0;
reg [15:0] h_clock_max = 0;
reg [15:0] v_clock_counter = 0;
reg [15:0] v_clock_max = 0;

// Trackball movement
always @(posedge clk)
begin
	reg	old_mstate;

	old_mstate <= mouse_clock;
	if(old_mstate != mouse_clock)
	begin
		h_dir <= mouse_sign_x;
		v_dir <= mouse_sign_y;

		mouse_mag_x = mouse_sign_x ? -ps2_mouse[15:8] : ps2_mouse[15:8];
		mouse_mag_y = mouse_sign_y ? -ps2_mouse[23:16] : ps2_mouse[23:16];

		if(mouse_speed == 2'd2) // 25% speed
		begin
			mouse_mag_x = mouse_mag_x >> 2;
			mouse_mag_y = mouse_mag_y >> 2;
		end
		else if(mouse_speed == 2'd2) // 50% speed
		begin
			mouse_mag_x = mouse_mag_x >> 1;
			mouse_mag_y = mouse_mag_y >> 1;
		end
		else if(mouse_speed == 2'd1) // 200% speed
		begin
			mouse_mag_x = mouse_mag_x << 1;
			mouse_mag_y = mouse_mag_y << 1;
		end

		trackball_falloff <= {trackball_falloff_width{1'b1}};
	end

	if(mouse_mag_x > 0) h_clock_max <= clock_base + ((16'd255 - {8'b0,mouse_mag_x}) << 4);
	else h_clock_max <= 0;
	if(mouse_mag_y > 0) v_clock_max <= clock_base + ((16'd255 - {8'b0,mouse_mag_y}) << 4);
	else v_clock_max <= 0;

	if(trackball_falloff == 0)
	begin
		if (mouse_mag_x > 0) mouse_mag_x = mouse_mag_x - 1'b1;
		if (mouse_mag_y > 0) mouse_mag_y = mouse_mag_y - 1'b1;
		trackball_falloff <= {trackball_falloff_width{1'b1}};
	end
	else
		trackball_falloff <= trackball_falloff - 1'b1;

	if(h_clock_max == 0)
		h_clock_counter <= 0;
	else
	begin
		h_clock_counter <= h_clock_counter + 1'b1;
		if(h_clock_counter >= h_clock_max)
		begin
			h_clock_counter <= 0;
			h_clk <= ~h_clk;
		end
	end

	if(v_clock_max == 0)
		v_clock_counter <= 0;
	else
	begin
		v_clock_counter <= v_clock_counter + 1'b1;
		if(v_clock_counter >= v_clock_max)
		begin
			v_clock_counter <= 0;
			v_clk <= ~v_clk;
		end
	end

end

endmodule