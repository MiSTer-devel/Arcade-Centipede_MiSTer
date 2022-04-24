// Converted to Verilog from original VHDL code (c) 2013 mark watson

`timescale 1 ps / 1 ps

module pokey_poly_5(clk, reset_n, enable, init, bit_out);
   input     clk;
   input     reset_n;
   input     enable;
   input     init;
   
   output    bit_out;
   
   reg [4:0] shift_reg;
   reg [4:0] shift_next;
   
   always @(posedge clk or negedge reset_n)
      if (reset_n == 1'b0)
         shift_reg <= 5'b01010;
      else 
         shift_reg <= shift_next;
   
   
   always @(shift_reg or enable or init)
   begin
      shift_next <= shift_reg;
      if (enable == 1'b1)
         shift_next <= {((shift_reg[2] ~^ shift_reg[0]) & (~(init))), shift_reg[4:1]};
   end
   
   assign bit_out = shift_reg[0];
   
endmodule
