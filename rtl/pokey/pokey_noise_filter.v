// Converted to Verilog from original VHDL code (c) 2013 mark watson

`timescale 1 ps / 1 ps

module pokey_noise_filter(clk, reset_n, noise_select, pulse_in, noise_4, noise_5, noise_large, sync_reset, pulse_out);
   input       clk;
   input       reset_n;
   
   input [2:0] noise_select;
   
   input       pulse_in;
   
   input       noise_4;
   input       noise_5;
   input       noise_large;
   
   input       sync_reset;
   
   output      pulse_out;
   
   
   reg         audclk;
   reg         out_next;
   reg         out_reg;
   
   always @(posedge clk or negedge reset_n)
      if (reset_n == 1'b0)
         out_reg <= 1'b0;
      else 
         out_reg <= out_next;
   
   assign pulse_out = out_reg;
   
   
   always @(pulse_in or noise_4 or noise_5 or noise_large or noise_select or audclk or out_reg or sync_reset)
   begin
      audclk <= pulse_in;
      out_next <= out_reg;
      
      if (noise_select[2] == 1'b0)
         audclk <= pulse_in & noise_5;
      
      if (audclk == 1'b1)
      begin
         if (noise_select[0] == 1'b1)
            out_next <= (~(out_reg));
         else
            if (noise_select[1] == 1'b1)
               out_next <= noise_4;
            else
               out_next <= noise_large;
      end
      
      if (sync_reset == 1'b1)
         out_next <= 1'b0;
   end
   
endmodule
