//-------------------------------------------------------------------------------
//
// Delta-Sigma DAC
//
// Refer to Xilinx Application Note XAPP154
//
// This DAC requires an external RC low-pass filter:
//
//   dac_o 0---XXXXX---+---0 analog audio
//              3k3    |
//                    === 4n7
//                     |
//                    GND
//
//-------------------------------------------------------------------------------

module ds_dac(
	      input 	  clk_i,
	      input 	  res_i,
	      input [7:0] dac_i,
	      output reg  dac_o
	      );

   parameter msbi_g = 7;

   reg [msbi_g+2:0] sig_in;
   
   always @(posedge clk_i or posedge res_i)
     if (res_i)
       begin
	  sig_in <= 1 << msbi_g+1;
	  dac_o  <= 1'b0;
       end
     else
       begin
	  sig_in <= sig_in + { sig_in[msbi_g+2], sig_in[msbi_g+2], dac_i };
	  dac_o  <= sig_in[msbi_g+2];
       end

endmodule // DAC

