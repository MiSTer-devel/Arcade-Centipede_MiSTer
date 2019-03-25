
module ram_dp256kx8(input        rclk,
		    input 	 wclk,
		    input [16:0] ai,
		    input [7:0]  i,
		    input [16:0] ao,
		    output [7:0] o,
		    input 	 r,
		    input 	 w);

   reg [7:0] ram[0:262143];
   reg [7:0] d;
   
   wire ram_read;
   wire ram_write;
   assign ram_read = r;
   assign ram_write = w;

   always @(posedge rclk)
     if (ram_read)
       d <= ram[ao];
     else
       d <= 0;

   assign o = d;
   
   always @(posedge wclk)
     if (ram_write)
       ram[ai] <= i;
   
endmodule // ram_dp256kx8
