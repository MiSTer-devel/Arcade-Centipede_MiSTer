//
// playfield ram
//  synchronous dual port, addressed as 32bit words with byte enables for 4x lanes
//  port a: r/w, 8 bit (i.e. only one enable asserted per cycle)
//  port b: r/o, 32 bit (any enable honored)
//
`timescale 1 ps / 1 ps

module ram_256x8dp (
	input			reset,
	input			clk_a,
	input			clk_b,
	input	[7:0]	addr_a,
	input	[7:0]	din_a,
	output	[7:0]	dout_a,
	input			ce_a,
	input			we_a,

	input	[7:0]	addr_b,
	output	[7:0]	dout_b,
	input			ce_b
);

reg [7:0] ram[0:255];
reg [7:0] d_a;
wire [7:0] d_b;

//
// port a - r/w, 8 bits
//
always @(posedge clk_a)
	if (reset)
		d_a <= 0;
	else
	if (~ce_a | ~we_a)
	begin
		if (~we_a)
			ram[addr_a] <= din_a;
		d_a <= ram[addr_a];
	end

assign dout_a = d_a;

//
// port b - read only, 32 bits
//
assign dout_b = ram[addr_b];

endmodule 

module pf_ram_dp (
	input 	clk_a,
	input 	clk_b,
	input 	reset,
	input [7:0] 	addr_a,
	input [7:0] 	din_a,
	output [7:0] 	dout_a,
	input [3:0] 	ce_a,
	input [3:0] 	we_a,

	input [7:0] 	addr_b,
	output [31:0] dout_b,
	input [3:0] 	ce_b
);

wire [7:0] d_a3, d_a2, d_a1, d_a0;
wire [7:0] d_b3, d_b2, d_b1, d_b0;

assign dout_a =
		~ce_a[3] ? d_a3 :
		~ce_a[2] ? d_a2 :
		~ce_a[1] ? d_a1 :
		~ce_a[0] ? d_a0 :
		8'b0;

assign dout_b = { d_b3, d_b2, d_b1, d_b0 };

ram_256x8dp ram0(.reset(reset), .clk_a(clk_a), .clk_b(clk_b), .addr_a(addr_a),
		.din_a(din_a), .dout_a(d_a0), .ce_a(ce_a[0]), .we_a(we_a[0]),
		.addr_b(addr_b), .dout_b(d_b0),.ce_b(ce_b[0]));

ram_256x8dp ram1(.reset(reset), .clk_a(clk_a), .clk_b(clk_b), .addr_a(addr_a),
		.din_a(din_a), .dout_a(d_a1), .ce_a(ce_a[1]), .we_a(we_a[1]),
		.addr_b(addr_b), .dout_b(d_b1),.ce_b(ce_b[1]));

ram_256x8dp ram2(.reset(reset), .clk_a(clk_a), .clk_b(clk_b), .addr_a(addr_a),
		.din_a(din_a), .dout_a(d_a2), .ce_a(ce_a[2]), .we_a(we_a[2]),
		.addr_b(addr_b), .dout_b(d_b2),.ce_b(ce_b[2]));

ram_256x8dp ram3(.reset(reset), .clk_a(clk_a), .clk_b(clk_b), .addr_a(addr_a),
		.din_a(din_a), .dout_a(d_a3), .ce_a(ce_a[3]), .we_a(we_a[3]),
		.addr_b(addr_b), .dout_b(d_b3),.ce_b(ce_b[3]));

endmodule

