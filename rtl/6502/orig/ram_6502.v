// RAM and peripherals for 6502 test system
// fixme: separate peripherals into separate modules
//
// Copyright (c) 2010 Peter Monta

module ram_6502(input eclk,ereset, input clk, input [15:0] a, output reg [7:0] dout, input [7:0] din, input rw);
  reg [7:0] mem[0:65535] /*verilator public*/;

`ifndef verilator
  integer i;
  integer fp;
  integer pc;
  integer c;
  reg [15:0] reset;
  initial begin
    $display($time,,"init memory");
    for (i=0; i<65536; i=i+1)
      mem[i] = 0;
    #4000;
    for (i=0; i<65536; i=i+1)
      mem[i] = 0;
     
    pc = 16'h`CODE_START;
    fp = $fopen(`CODE,"r");
    c = $fgetc(fp);
    while (c!==32'hffffffff) begin
      mem[pc] = c;
      pc = pc + 1;
      c = $fgetc(fp);
    end
//    reset = 16'h`RESET;
//    mem[16'hfffc] = reset[7:0];
//    mem[16'hfffd] = reset[15:8];
    mem[16'hfffc] = mem[16'h3ffc];
    mem[16'hfffd] = mem[16'h3fff];
    $display($time,,"done initializing RAM; last address 0x%x",pc);
  end
`endif

  reg clk1;

  always @(posedge eclk)
    if (ereset) begin
      dout <= 0;
    end else begin
      clk1 <= clk;
      dout <= mem[a];
      //$display("mem[%x] -> %x",a,mem[a]);

      if (!clk && clk1 && !rw) begin                  // writes
//`ifdef DISPLAY_WRITES
        $display("mem[%x] <- %x",a,din);
//`endif
        mem[a] <= din;
      end
    end

endmodule
