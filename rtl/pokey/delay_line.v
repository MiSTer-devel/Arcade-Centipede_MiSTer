// Converted to Verilog from original VHDL code (c) 2013 mark watson

`timescale 1 ps / 1 ps

module delay_line(clk, sync_reset, data_in, enable, reset_n, data_out);
	parameter       count = 1;
	input           clk;
	input           sync_reset;
	input           data_in;
	input           enable;
	input           reset_n;
	
	output          data_out;
	
	reg [count-1:0] shift_reg;
	reg [count-1:0] shift_next;
	
	always @(posedge clk or negedge reset_n)
		if (reset_n == 1'b0)
			shift_reg <= {count{1'b0}};
		else 
			shift_reg <= shift_next;
	
	
	always @(shift_reg or enable or data_in or sync_reset)
	begin
		shift_next <= shift_reg;
		
		if (enable == 1'b1)
			shift_next <= {data_in, shift_reg[count - 1:1]};
		
		if (sync_reset == 1'b1)
			shift_next <= {count{1'b0}};
	end
	
	assign data_out = shift_reg[0] & enable;
	
endmodule
