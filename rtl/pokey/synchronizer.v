// Converted to Verilog from original VHDL code (c) 2013 mark watson

`timescale 1 ps / 1 ps

module synchronizer(clk, raw, sync);
   input      clk;
   input      raw;
   output     sync;
   
   wire [2:0] ff_next;
   reg [2:0]  ff_reg;
   
   always @(posedge clk)
      
         ff_reg <= ff_next;
   
   assign ff_next = {raw, ff_reg[2:1]};
   
   assign sync = ff_reg[0];
   
endmodule


