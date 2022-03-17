// Converted to Verilog from original VHDL code (c) 2013 mark watson

`timescale 1 ps / 1 ps

module latch_delay_line(clk, sync_reset, data_in, enable, reset_n, data_out);
   parameter       count = 1;
   input           clk;
   input           sync_reset;
   input           data_in;
   input           enable;
   input           reset_n;
   
   output          data_out;
   
   reg [count-1:0] shift_reg;
   reg [count-1:0] shift_next;
   
   reg             data_in_reg;
   reg             data_in_next;
   
   always @(posedge clk or negedge reset_n)
      if (reset_n == 1'b0)
      begin
         shift_reg <= {count{1'b0}};
         data_in_reg <= 1'b0;
      end
      else 
      begin
         shift_reg <= shift_next;
         data_in_reg <= data_in_next;
      end
   
   
   always @(shift_reg or enable or data_in or data_in_reg or sync_reset)
   begin
      shift_next <= shift_reg;
      
      data_in_next <= data_in | data_in_reg;
      
      if (enable == 1'b1)
      begin
         shift_next <= {(data_in | data_in_reg), shift_reg[count - 1:1]};
         data_in_next <= 1'b0;
      end
      
      if (sync_reset == 1'b1)
      begin
         shift_next <= {count{1'b0}};
         data_in_next <= 1'b0;
      end
   end
   
   assign data_out = shift_reg[0] & enable;
   
endmodule
