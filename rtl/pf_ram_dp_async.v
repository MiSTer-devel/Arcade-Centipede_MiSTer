// old, unused, async dp ram

module pf_ram_dp (
		  input 	clk_a,
		  input 	clk_b,
		  input 	reset,
		  input [7:0] 	addr_a,
		  input [7:0] 	din_a,
		  output [7:0] 	dout_a,
		  input [3:0] 	ce_a,
		  input [3:0] 	we_a,

		  input [7:0] 	addr_b,
		  output [31:0] dout_b,
		  input [3:0] 	ce_b
		  );

   reg [7:0] ram3[0:255];
   reg [7:0] ram2[0:255];
   reg [7:0] ram1[0:255];
   reg [7:0] ram0[0:255];
   reg [7:0] d_a, d_b3, d_b2, d_b1, d_b0;

`ifdef SIMULATION
   integer    j;
   
   initial
     begin
	for (j = 0; j < 256; j = j + 1)
	  begin
	     //ram[j] = j & 8'h3f;
	     ram3[j] = 0;
	     ram2[j] = 0;
	     ram1[j] = 0;
	     ram0[j] = 0;
	  end
     end
`endif

   wire       ram_read_a, ram_write_a;
   wire       ram_read_b;

   //
   assign ram_read_a = ce_a != 4'b1111 & we_a == 4'b1111;
   assign ram_write_a = we_a != 4'b1111;

   always @(addr_a or ram_write_a or din_a or we_a)
     if (ram_write_a)
       begin
	  //$display("pf_ram_dp: wr a addr %x (we %b)", addr_a, we_a);
	  if (~we_a[3])
	    ram3[addr_a] = din_a;
	  else
	    if (~we_a[2])
	      ram2[addr_a] = din_a;
	    else
	      if (~we_a[1])
		ram1[addr_a] = din_a;
	      else
		if (~we_a[0])
		  ram0[addr_a] = din_a;
       end

   assign dout_a = d_a;
   
   always @(addr_a or ram_read_a or ce_a)
     if (ram_read_a)
       begin
	  if (~ce_a[3])
	    d_a = ram3[addr_a];
	  else
	    if (~ce_a[2])
	      d_a = ram2[addr_a];
	    else
	      if (~ce_a[1])
		d_a = ram1[addr_a];
	      else
		if (~ce_a[0])
		  d_a = ram0[addr_a];
	  //$display("pf_ram_dp: rd a addr %x (ce %b) -> %x", addr_a, ce_a, d_a);
       end

   //
   assign ram_read_b = ce_b != 4'b1111;

   assign dout_b = { d_b3, d_b2, d_b1, d_b0 };
   
   always @(addr_b or ram_read_b)
     if (ram_read_b)
       begin
	  d_b3 = ram3[addr_b];
	  d_b2 = ram2[addr_b];
	  d_b1 = ram1[addr_b];
	  d_b0 = ram0[addr_b];
	  //$display("pf_ram_dp: rd b addr %x -> %x", addr_b, {d_b3,d_b2,d_b1,d_b0});
       end
   
endmodule // pf_ram_dp

