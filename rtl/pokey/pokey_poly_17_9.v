// Converted to Verilog from original VHDL code (c) 2013 mark watson

`timescale 1 ps / 1 ps

module pokey_poly_17_9(clk, reset_n, enable, select_9_17, init, bit_out, rand_out);
   input        clk;
   input        reset_n;
   input        enable;
   input        select_9_17;
   input        init;
   
   output       bit_out;
   
   output [7:0] rand_out;
   
   reg [16:0]   shift_reg;
   reg [16:0]   shift_next;
   
   reg          cycle_delay_reg;
   reg          cycle_delay_next;
   
   reg          select_9_17_del_reg;
   reg          select_9_17_del_next;
   
   wire         feedback;
   
   always @(posedge clk or negedge reset_n)
      if (reset_n == 1'b0)
      begin
         shift_reg <= 17'b01010101010101010;
         cycle_delay_reg <= 1'b0;
         select_9_17_del_reg <= 1'b0;
      end
      else 
      begin
         shift_reg <= shift_next;
         cycle_delay_reg <= cycle_delay_next;
         select_9_17_del_reg <= select_9_17_del_next;
      end
   
   assign feedback = shift_reg[13] ~^ shift_reg[8];
   
   always @(enable or shift_reg or feedback or select_9_17 or select_9_17_del_reg or init or cycle_delay_reg)
   begin
      shift_next <= shift_reg;
      cycle_delay_next <= cycle_delay_reg;
      select_9_17_del_next <= select_9_17_del_reg;
      
      if (enable == 1'b1)
      begin
         select_9_17_del_next <= select_9_17;
         shift_next[15:8] <= shift_reg[16:9];
         shift_next[7] <= feedback;
         shift_next[6:0] <= shift_reg[7:1];
         
         shift_next[16] <= ((feedback & select_9_17_del_reg) | (shift_reg[0] & (~(select_9_17)))) & (~(init));
         
         cycle_delay_next <= shift_reg[9];
      end
   end
   
   assign bit_out = cycle_delay_reg;
   assign rand_out[7:0] = (~(shift_reg[15:8]));
   
endmodule
