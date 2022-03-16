// Converted to Verilog from original VHDL code (c) 2013 mark watson

`timescale 1 ps / 1 ps

module pokey_countdown_timer(clk, enable, enable_underflow, reset_n, wr_en, data_in, data_out);
   parameter   underflow_delay = 3;
   input       clk;
   input       enable;
   input       enable_underflow;
   input       reset_n;
   
   input       wr_en;
   input [7:0] data_in;
   
   output      data_out;
   
   
   function  to_std_logic;
      input       l;
   begin
      if (l)
         to_std_logic = (1'b1);
      else
         to_std_logic = (1'b0);
   end
   endfunction
   
   reg [7:0]   count_reg;
   reg [7:0]   count_next;
   
   reg         underflow;
   
   reg [1:0]   count_command;
   reg [1:0]   underflow_command;
   
   delay_line #(underflow_delay) underflow0_delay(.clk(clk), .sync_reset(wr_en), .data_in(underflow), .enable(enable_underflow), .reset_n(reset_n), .data_out(data_out));
   
   
   always @(posedge clk or negedge reset_n)
      if (reset_n == 1'b0)
         count_reg <= {8{1'b0}};
      else 
         count_reg <= count_next;
   
   
   always @(count_reg or enable or wr_en or count_command or data_in)
   begin
      count_command <= {enable, wr_en};
      case (count_command)
         2'b10 :
            count_next <= (count_reg - 1);
         2'b01, 2'b11 :
            count_next <= data_in;
         default :
            count_next <= count_reg;
      endcase
   end
   
   
   always @(count_reg or enable or underflow_command)
   begin
      underflow_command <= {enable, to_std_logic(count_reg == 8'h00)};
      case (underflow_command)
         2'b11 :
            underflow <= 1'b1;
         default :
            underflow <= 1'b0;
      endcase
   end
   
endmodule
