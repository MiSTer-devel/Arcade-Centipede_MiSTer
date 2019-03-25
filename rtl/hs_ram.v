
module hs_ram(input clk,
	      input 	   reset,
	      input [5:0]  a,
	      output [7:0] dout,
	      input [7:0]  din,
	      input 	   c1,
	      input 	   c2,
	      input 	   cs1);
   
   assign dout = 8'b0;
   
endmodule
