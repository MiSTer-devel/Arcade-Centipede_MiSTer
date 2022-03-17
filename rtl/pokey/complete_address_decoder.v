// Converted to Verilog from original VHDL code (c) 2013 mark watson

`timescale 1 ps / 1 ps

module complete_address_decoder(addr_in, addr_decoded);
	parameter               width = 1;
	input [width-1:0]       addr_in;
	
	output [(2**width)-1:0] addr_decoded;
	reg [(2**width)-1:0]    addr_decoded;
	
	parameter               stage = width;
	reg                     p[stage:0][2**stage-1:0];
	wire [width-1:0]        a;
	assign a = addr_in;
	
	always @(a or p)
	begin: xhdl0
		integer                 s;
		integer                 r;
		integer                 i;
		p[stage][0] <= 1'b1;
		
		for (s = stage; s >= 1; s = s - 1)
			for (r = 0; r <= (2 ** (stage - s) - 1); r = r + 1)
			begin
				p[s - 1][2 * r] <= ((~a[s - 1])) & p[s][r];
				p[s - 1][2 * r + 1] <= a[s - 1] & p[s][r];
			end
		
		for (i = 0; i <= (2 ** stage - 1); i = i + 1)
			addr_decoded[i] <= p[0][i];
	end
	
endmodule
