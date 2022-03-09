`timescale 1 ps / 1 ps

module car_lx45(
		input  sysclk,
		input  clk_vga,
		input  clk_cpu,
		input  clk_pix,
		input  dcm_reset,
		input  button,
		output auto_coin_n,
		output auto_start_n,
		output auto_throw_n,
		output clk6m,
		output clk12m,
		output clk25m,
		output reset
		);

   reg [15:0] r_count;

   always @(posedge sysclk)
     if (dcm_reset | button)
       r_count <= 16'd0;
     else
       if (r_count != 16'hffff)
	 r_count <= r_count + 16'd1;

`ifdef SIMULATION
   assign reset = r_count < 16'h00ff;

   always @(posedge reset)
     $display("reset: on %t", $time);
   always @(negedge reset)
     $display("reset: off %t", $time);
   
`else
   assign reset = r_count < 16'h0fff;
`endif

`ifndef SIMULATION
   reg [31:0] a_count;

   always @(posedge clk_pix)
     if (reset)
       a_count <= 32'd0;
     else
       if (a_count != 32'hffffffff)
	 a_count <= a_count + 24'd1;
   
   assign auto_coin_n = 1;
   assign auto_start_n = 1;
   assign auto_throw_n = a_count >= 32'hf000_0000 && a_count < 32'hf030_0000;
`else
   assign auto_coin_n = 1;
   assign auto_start_n = 1;
   assign auto_throw_n = 1;
`endif
   
   assign clk6m  = clk_pix;
   assign clk12m = clk_cpu;
   assign clk25m = clk_vga;
   
endmodule
