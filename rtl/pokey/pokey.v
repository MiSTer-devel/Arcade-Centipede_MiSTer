// Converted to Verilog from original VHDL code (c) 2013 mark watson

`timescale 1 ps / 1 ps

module pokey(clk, enable_179, addr, data_in, wr_en, reset_n, keyboard_scan_enable, keyboard_scan, keyboard_response, pot_in, sio_in1, sio_in2, sio_in3, data_out, channel_0_out, channel_1_out, channel_2_out, channel_3_out, irq_n_out, sio_out1, sio_out2, sio_out3, sio_clockin_in, sio_clockin_out, sio_clockin_oe, sio_clockout, pot_reset);
   parameter    custom_keyboard_scan = 0;
   input        clk;
   input        enable_179;
   input [3:0]  addr;
   input [7:0]  data_in;
   input        wr_en;
   
   input        reset_n;
   
   input        keyboard_scan_enable;
   output [5:0] keyboard_scan;
   input [1:0]  keyboard_response;
   
   input [7:0]  pot_in;
   
   input        sio_in1;
   input        sio_in2;
   input        sio_in3;
   
   output [7:0] data_out;
   reg [7:0]    data_out;
   
   output [3:0] channel_0_out;
   output [3:0] channel_1_out;
   output [3:0] channel_2_out;
   output [3:0] channel_3_out;
   
   output       irq_n_out;
   
   output       sio_out1;
   output       sio_out2;
   output       sio_out3;
   
   input        sio_clockin_in;
   output       sio_clockin_out;
   output       sio_clockin_oe;
   output       sio_clockout;
   
   output       pot_reset;
   
   
   wire         enable_64;
   wire         enable_15;
   
   reg [7:0]    audf0_reg;
   reg [7:0]    audc0_reg;
   reg [7:0]    audf1_reg;
   reg [7:0]    audc1_reg;
   reg [7:0]    audf2_reg;
   reg [7:0]    audc2_reg;
   reg [7:0]    audf3_reg;
   reg [7:0]    audc3_reg;
   reg [7:0]    audctl_reg;
   reg [7:0]    audf0_next;
   reg [7:0]    audc0_next;
   reg [7:0]    audf1_next;
   reg [7:0]    audc1_next;
   reg [7:0]    audf2_next;
   reg [7:0]    audc2_next;
   reg [7:0]    audf3_next;
   reg [7:0]    audc3_next;
   reg [7:0]    audctl_next;
   
   wire         audf0_pulse;
   wire         audf1_pulse;
   wire         audf2_pulse;
   wire         audf3_pulse;
   
   reg          audf0_reload;
   reg          audf1_reload;
   reg          audf2_reload;
   reg          audf3_reload;
   
   reg          stimer_write;
   wire         stimer_write_delayed;
   
   wire         audf0_pulse_noise;
   wire         audf1_pulse_noise;
   wire         audf2_pulse_noise;
   wire         audf3_pulse_noise;
   
   reg          audf0_enable;
   reg          audf1_enable;
   reg          audf2_enable;
   reg          audf3_enable;
   
   wire         chan0_output_next;
   wire         chan1_output_next;
   wire         chan2_output_next;
   wire         chan3_output_next;
   reg          chan0_output_reg;
   reg          chan1_output_reg;
   reg          chan2_output_reg;
   reg          chan3_output_reg;
   
   reg          chan0_output_del_next;
   reg          chan1_output_del_next;
   reg          chan0_output_del_reg;
   reg          chan1_output_del_reg;
   
   reg          highpass0_next;
   reg          highpass1_next;
   reg          highpass0_reg;
   reg          highpass1_reg;
   
   reg [3:0]    volume_channel_0_next;
   reg [3:0]    volume_channel_1_next;
   reg [3:0]    volume_channel_2_next;
   reg [3:0]    volume_channel_3_next;
   reg [3:0]    volume_channel_0_reg;
   reg [3:0]    volume_channel_1_reg;
   reg [3:0]    volume_channel_2_reg;
   reg [3:0]    volume_channel_3_reg;
   
   wire [15:0]  addr_decoded;
   
   wire         noise_4;
   wire         noise_5;
   wire         noise_large;
   reg [2:0]    noise_4_next;
   reg [2:0]    noise_4_reg;
   reg [2:0]    noise_5_next;
   reg [2:0]    noise_5_reg;
   reg [2:0]    noise_large_next;
   reg [2:0]    noise_large_reg;
   
   wire [7:0]   rand_out;
   
   wire         initmode;
   
   reg [7:0]    irqen_next;
   reg [7:0]    irqen_reg;
   
   reg [7:0]    irqst_next;
   reg [7:0]    irqst_reg;
   
   reg          irq_n_next;
   reg          irq_n_reg;
   
   reg          serial_ip_ready_interrupt;
   reg          serial_ip_framing_next;
   reg          serial_ip_framing_reg;
   reg          serial_ip_overrun_next;
   reg          serial_ip_overrun_reg;
   reg          serial_op_needed_interrupt;
   
   reg [7:0]    skctl_next;
   reg [7:0]    skctl_reg;
   
   reg [9:0]    serin_shift_next;
   reg [9:0]    serin_shift_reg;
   reg [7:0]    serin_next;
   reg [7:0]    serin_reg;
   reg [3:0]    serin_bitcount_next;
   reg [3:0]    serin_bitcount_reg;
   
   wire         sio_in1_reg;
   wire         sio_in2_reg;
   wire         sio_in3_reg;
   wire         sio_in_next;
   reg          sio_in_reg;
   
   reg          sio_out_next;
   reg          sio_out_reg;
   reg          serial_out_next;
   reg          serial_out_reg;
   
   reg [9:0]    serout_shift_next;
   reg [9:0]    serout_shift_reg;
   
   reg          serout_holding_full_next;
   reg          serout_holding_full_reg;
   reg [7:0]    serout_holding_next;
   reg [7:0]    serout_holding_reg;
   reg          serout_holding_load;
   
   reg [3:0]    serout_bitcount_next;
   reg [3:0]    serout_bitcount_reg;
   
   reg          serout_active_next;
   reg          serout_active_reg;
   
   reg          serial_reset;
   wire         serout_sync_reset;
   reg          skrest_write;
   
   reg          serout_enable;
   wire         serout_enable_delayed;
   reg          serin_enable;
   
   reg          async_serial_reset;
   wire         waiting_for_start_bit;
   
   reg          serin_clock_next;
   reg          serin_clock_reg;
   reg          serin_clock_last_next;
   reg          serin_clock_last_reg;
   
   reg          serout_clock_next;
   reg          serout_clock_reg;
   reg          serout_clock_last_next;
   reg          serout_clock_last_reg;
   
   reg          twotone_reset;
   wire         twotone_reset_delayed;
   reg          twotone_next;
   reg          twotone_reg;
   
   reg          clock_next;
   reg          clock_reg;
   reg          clock_sync_next;
   reg          clock_sync_reg;
   reg          clock_input;
   
   reg          keyboard_overrun_next;
   reg          keyboard_overrun_reg;
   
   wire         shift_held;
   wire         break_irq;
   wire         key_held;
   wire         other_key_irq;
   
   wire [7:0]   kbcode;
   
   reg [7:0]    pot0_next;
   reg [7:0]    pot0_reg;
   reg [7:0]    pot1_next;
   reg [7:0]    pot1_reg;
   reg [7:0]    pot2_next;
   reg [7:0]    pot2_reg;
   reg [7:0]    pot3_next;
   reg [7:0]    pot3_reg;
   reg [7:0]    pot4_next;
   reg [7:0]    pot4_reg;
   reg [7:0]    pot5_next;
   reg [7:0]    pot5_reg;
   reg [7:0]    pot6_next;
   reg [7:0]    pot6_reg;
   reg [7:0]    pot7_next;
   reg [7:0]    pot7_reg;
   
   reg [7:0]    allpot_next;
   reg [7:0]    allpot_reg;
   
   reg [7:0]    pot_counter_next;
   reg [7:0]    pot_counter_reg;
   
   reg          potgo_write;
   
   reg          pot_reset_next;
   reg          pot_reset_reg;
   
   always @(posedge clk or negedge reset_n)
      if (reset_n == 1'b0)
      begin
         audf0_reg <= 8'h00;
         audc0_reg <= 8'h00;
         audf1_reg <= 8'h00;
         audc1_reg <= 8'h00;
         audf2_reg <= 8'h00;
         audc2_reg <= 8'h00;
         audf3_reg <= 8'h00;
         audc3_reg <= 8'h00;
         audctl_reg <= 8'h00;
         
         irqen_reg <= 8'h00;
         irqst_reg <= 8'hff;
         irq_n_reg <= 1'b1;
         
         skctl_reg <= 8'h00;
         
         highpass0_reg <= 1'b0;
         highpass1_reg <= 1'b0;
         
         chan0_output_reg <= 1'b0;
         chan1_output_reg <= 1'b0;
         chan2_output_reg <= 1'b0;
         chan3_output_reg <= 1'b0;
         
         chan0_output_del_reg <= 1'b0;
         chan1_output_del_reg <= 1'b0;
         
         volume_channel_0_reg <= {4{1'b0}};
         volume_channel_1_reg <= {4{1'b0}};
         volume_channel_2_reg <= {4{1'b0}};
         volume_channel_3_reg <= {4{1'b0}};
         
         serin_reg <= {8{1'b0}};
         serin_shift_reg <= {10{1'b0}};
         serin_bitcount_reg <= {4{1'b0}};
         serout_shift_reg <= {10{1'b0}};
         serout_holding_reg <= {8{1'b0}};
         serout_holding_full_reg <= 1'b0;
         serout_active_reg <= 1'b0;
         sio_out_reg <= 1'b1;
         serial_out_reg <= 1'b1;
         
         serial_ip_framing_reg <= 1'b0;
         serial_ip_overrun_reg <= 1'b0;
         
         clock_reg <= 1'b0;
         clock_sync_reg <= 1'b0;
         
         keyboard_overrun_reg <= 1'b0;
         
         serin_clock_reg <= 1'b0;
         serin_clock_last_reg <= 1'b0;
         serout_clock_reg <= 1'b0;
         serout_clock_last_reg <= 1'b0;
         
         twotone_reg <= 1'b0;
         
         sio_in_reg <= 1'b0;
         
         pot0_reg <= {8{1'b0}};
         pot1_reg <= {8{1'b0}};
         pot2_reg <= {8{1'b0}};
         pot3_reg <= {8{1'b0}};
         pot4_reg <= {8{1'b0}};
         pot5_reg <= {8{1'b0}};
         pot6_reg <= {8{1'b0}};
         pot7_reg <= {8{1'b0}};
         
         allpot_reg <= {8{1'b1}};
         
         pot_counter_reg <= {8{1'b0}};
         
         pot_reset_reg <= 1'b1;
         
         noise_4_reg <= {3{1'b0}};
         noise_5_reg <= {3{1'b0}};
         noise_large_reg <= {3{1'b0}};
      end
      
      else 
      begin
         audf0_reg <= audf0_next;
         audc0_reg <= audc0_next;
         audf1_reg <= audf1_next;
         audc1_reg <= audc1_next;
         audf2_reg <= audf2_next;
         audc2_reg <= audc2_next;
         audf3_reg <= audf3_next;
         audc3_reg <= audc3_next;
         audctl_reg <= audctl_next;
         
         irqen_reg <= irqen_next;
         irqst_reg <= irqst_next;
         irq_n_reg <= irq_n_next;
         
         skctl_reg <= skctl_next;
         
         highpass0_reg <= highpass0_next;
         highpass1_reg <= highpass1_next;
         
         chan0_output_reg <= chan0_output_next;
         chan1_output_reg <= chan1_output_next;
         chan2_output_reg <= chan2_output_next;
         chan3_output_reg <= chan3_output_next;
         
         chan0_output_del_reg <= chan0_output_del_next;
         chan1_output_del_reg <= chan1_output_del_next;
         
         volume_channel_0_reg <= volume_channel_0_next;
         volume_channel_1_reg <= volume_channel_1_next;
         volume_channel_2_reg <= volume_channel_2_next;
         volume_channel_3_reg <= volume_channel_3_next;
         
         serin_reg <= serin_next;
         serin_shift_reg <= serin_shift_next;
         serin_bitcount_reg <= serin_bitcount_next;
         serout_shift_reg <= serout_shift_next;
         serout_bitcount_reg <= serout_bitcount_next;
         
         serout_holding_reg <= serout_holding_next;
         serout_holding_full_reg <= serout_holding_full_next;
         serout_active_reg <= serout_active_next;
         
         sio_out_reg <= sio_out_next;
         serial_out_reg <= serial_out_next;
         
         serial_ip_framing_reg <= serial_ip_framing_next;
         serial_ip_overrun_reg <= serial_ip_overrun_next;
         
         clock_reg <= clock_next;
         clock_sync_reg <= clock_sync_next;
         
         keyboard_overrun_reg <= keyboard_overrun_next;
         
         serin_clock_reg <= serin_clock_next;
         serin_clock_last_reg <= serin_clock_last_next;
         serout_clock_reg <= serout_clock_next;
         serout_clock_last_reg <= serout_clock_last_next;
         
         twotone_reg <= twotone_next;
         
         sio_in_reg <= sio_in_next;
         
         pot0_reg <= pot0_next;
         pot1_reg <= pot1_next;
         pot2_reg <= pot2_next;
         pot3_reg <= pot3_next;
         pot4_reg <= pot4_next;
         pot5_reg <= pot5_next;
         pot6_reg <= pot6_next;
         pot7_reg <= pot7_next;
         
         allpot_reg <= allpot_next;
         
         pot_counter_reg <= pot_counter_next;
         
         pot_reset_reg <= pot_reset_next;
         
         noise_4_reg <= noise_4_next;
         noise_5_reg <= noise_5_next;
         noise_large_reg <= noise_large_next;
      end
   
   
   complete_address_decoder #(4) decode_addr1(.addr_in(addr), .addr_decoded(addr_decoded));
   
   
   always @(enable_64 or enable_15 or enable_179 or audctl_reg or audf0_pulse or audf2_pulse)
   begin
      audf0_enable <= enable_64;
      audf1_enable <= enable_64;
      audf2_enable <= enable_64;
      audf3_enable <= enable_64;
      
      if (audctl_reg[0] == 1'b1)
      begin
         audf0_enable <= enable_15;
         audf1_enable <= enable_15;
         audf2_enable <= enable_15;
         audf3_enable <= enable_15;
      end
      
      if (audctl_reg[6] == 1'b1)
         audf0_enable <= enable_179;
      
      if (audctl_reg[5] == 1'b1)
         audf2_enable <= enable_179;
      
      if (audctl_reg[4] == 1'b1)
         audf1_enable <= audf0_pulse;
      
      if (audctl_reg[3] == 1'b1)
         audf3_enable <= audf2_pulse;
   end
   
   
   pokey_countdown_timer #(3) timer0(.clk(clk), .enable(audf0_enable), .enable_underflow(enable_179), .reset_n(reset_n), .wr_en(audf0_reload), .data_in(audf0_next), .data_out(audf0_pulse));
   
   pokey_countdown_timer #(3) timer1(.clk(clk), .enable(audf1_enable), .enable_underflow(enable_179), .reset_n(reset_n), .wr_en(audf1_reload), .data_in(audf1_next), .data_out(audf1_pulse));
   
   pokey_countdown_timer #(3) timer2(.clk(clk), .enable(audf2_enable), .enable_underflow(enable_179), .reset_n(reset_n), .wr_en(audf2_reload), .data_in(audf2_next), .data_out(audf2_pulse));
   
   pokey_countdown_timer #(3) timer3(.clk(clk), .enable(audf3_enable), .enable_underflow(enable_179), .reset_n(reset_n), .wr_en(audf3_reload), .data_in(audf3_next), .data_out(audf3_pulse));
   
   
   always @(audctl_reg or audf0_pulse or audf1_pulse or audf2_pulse or audf3_pulse or stimer_write_delayed or async_serial_reset or twotone_reset_delayed)
   begin
      audf0_reload <= (((~(audctl_reg[4])) & audf0_pulse)) | (audctl_reg[4] & audf1_pulse) | stimer_write_delayed | twotone_reset_delayed;
      audf1_reload <= audf1_pulse | stimer_write_delayed | twotone_reset_delayed;
      audf2_reload <= (((~(audctl_reg[3])) & audf2_pulse)) | (audctl_reg[3] & audf3_pulse) | stimer_write_delayed | async_serial_reset;
      audf3_reload <= audf3_pulse | stimer_write_delayed | async_serial_reset;
   end
   
   
   latch_delay_line #(2) twotone_del(.clk(clk), .sync_reset(1'b0), .data_in(twotone_reset), .enable(enable_179), .reset_n(reset_n), .data_out(twotone_reset_delayed));
   
   
   always @(data_in or wr_en or addr_decoded or audf0_reg or audc0_reg or audf1_reg or audc1_reg or audf2_reg or audc2_reg or audf3_reg or audc3_reg or audf0_enable or audf1_enable or audf2_enable or audf3_enable or audctl_reg or irqen_reg or skctl_reg or serout_holding_reg)
   begin
      audf0_next <= audf0_reg;
      audc0_next <= audc0_reg;
      audf1_next <= audf1_reg;
      audc1_next <= audc1_reg;
      audf2_next <= audf2_reg;
      audc2_next <= audc2_reg;
      audf3_next <= audf3_reg;
      audc3_next <= audc3_reg;
      audctl_next <= audctl_reg;
      
      irqen_next <= irqen_reg;
      skctl_next <= skctl_reg;
      
      stimer_write <= 1'b0;
      
      serout_holding_load <= 1'b0;
      serout_holding_next <= serout_holding_reg;
      
      serial_reset <= 1'b0;
      skrest_write <= 1'b0;
      potgo_write <= 1'b0;
      
      if (wr_en == 1'b1)
      begin
         if (addr_decoded[0] == 1'b1)
            audf0_next <= data_in;
         
         if (addr_decoded[1] == 1'b1)
            audc0_next <= data_in;
         
         if (addr_decoded[2] == 1'b1)
            audf1_next <= data_in;
         
         if (addr_decoded[3] == 1'b1)
            audc1_next <= data_in;
         
         if (addr_decoded[4] == 1'b1)
            audf2_next <= data_in;
         
         if (addr_decoded[5] == 1'b1)
            audc2_next <= data_in;
         
         if (addr_decoded[6] == 1'b1)
            audf3_next <= data_in;
         
         if (addr_decoded[7] == 1'b1)
            audc3_next <= data_in;
         
         if (addr_decoded[8] == 1'b1)
            audctl_next <= data_in;
         
         if (addr_decoded[9] == 1'b1)
            stimer_write <= 1'b1;
         
         if (addr_decoded[10] == 1'b1)
            skrest_write <= 1'b1;
         
         if (addr_decoded[11] == 1'b1)
            potgo_write <= 1'b1;
         
         if (addr_decoded[13] == 1'b1)
         begin
            serout_holding_next <= data_in;
            serout_holding_load <= 1'b1;
         end
         
         if (addr_decoded[14] == 1'b1)
            irqen_next <= data_in;
         
         if (addr_decoded[15] == 1'b1)
         begin
            skctl_next <= data_in;
            
            if (data_in[6:4] == 3'b000)
               serial_reset <= 1'b1;
         end
      end
   end
   
   
   always @(addr_decoded or kbcode or rand_out or irqst_reg or key_held or shift_held or sio_in_reg or serin_reg or keyboard_overrun_reg or serial_ip_framing_reg or serial_ip_overrun_reg or waiting_for_start_bit or pot_in or pot0_reg or pot1_reg or pot2_reg or pot3_reg or pot4_reg or pot5_reg or pot6_reg or pot7_reg or allpot_reg)
   begin
      data_out <= 8'hff;
      
      if (addr_decoded[0] == 1'b1)
         data_out <= pot0_reg;
      
      if (addr_decoded[1] == 1'b1)
         data_out <= pot1_reg;
      
      if (addr_decoded[2] == 1'b1)
         data_out <= pot2_reg;
      
      if (addr_decoded[3] == 1'b1)
         data_out <= pot3_reg;
      
      if (addr_decoded[4] == 1'b1)
         data_out <= pot4_reg;
      
      if (addr_decoded[5] == 1'b1)
         data_out <= pot5_reg;
      
      if (addr_decoded[6] == 1'b1)
         data_out <= pot6_reg;
      
      if (addr_decoded[7] == 1'b1)
         data_out <= pot7_reg;
      
      if (addr_decoded[8] == 1'b1)
         data_out <= allpot_reg;
      
      if (addr_decoded[9] == 1'b1)
         data_out <= kbcode;
      
      if (addr_decoded[10] == 1'b1)
         data_out <= rand_out;
      
      if (addr_decoded[13] == 1'b1)
         data_out <= serin_reg;
      
      if (addr_decoded[14] == 1'b1)
         data_out <= irqst_reg;
      
      if (addr_decoded[15] == 1'b1)
         data_out <= {(~(serial_ip_framing_reg)), (~(keyboard_overrun_reg)), (~(serial_ip_overrun_reg)), sio_in_reg, (~(shift_held)), (~(key_held)), waiting_for_start_bit, 1'b1};
   end
   
   
   always @(irqen_reg or irqst_reg or audf0_pulse or audf1_pulse or audf3_pulse or other_key_irq or serial_ip_ready_interrupt or serout_active_reg or serial_op_needed_interrupt or break_irq)
   begin
      irqst_next <= irqst_reg | (~(irqen_reg));
      
      irq_n_next <= 1'b0;
      
      if ((irqst_reg | {4'b0000, (~(irqen_reg[3])), 3'b000}) == 8'hff)
         irq_n_next <= 1'b1;
      
      if (audf0_pulse == 1'b1)
         irqst_next[0] <= (~(irqen_reg[0]));
      
      if (audf1_pulse == 1'b1)
         irqst_next[1] <= (~(irqen_reg[1]));
      
      if (audf3_pulse == 1'b1)
         irqst_next[2] <= (~(irqen_reg[2]));
      
      if (other_key_irq == 1'b1)
         irqst_next[6] <= (~(irqen_reg[6]));
      
      if (break_irq == 1'b1)
         irqst_next[7] <= (~(irqen_reg[7]));
      
      if (serial_ip_ready_interrupt == 1'b1)
         irqst_next[5] <= (~(irqen_reg[5]));
      
      irqst_next[3] <= serout_active_reg;
      
      if (serial_op_needed_interrupt == 1'b1)
         irqst_next[4] <= (~(irqen_reg[4]));
   end
   
   
   latch_delay_line #(3) stimer_delay(.clk(clk), .sync_reset(1'b0), .data_in(stimer_write), .enable(enable_179), .reset_n(reset_n), .data_out(stimer_write_delayed));
   
   
   pokey_noise_filter pokey_noise_filter0(.clk(clk), .reset_n(reset_n), .noise_select(audc0_reg[7:5]), .pulse_in(audf0_pulse), .pulse_out(audf0_pulse_noise), .noise_4(noise_4), .noise_5(noise_5), .noise_large(noise_large), .sync_reset(stimer_write_delayed));
   
   pokey_noise_filter pokey_noise_filter1(.clk(clk), .reset_n(reset_n), .noise_select(audc1_reg[7:5]), .pulse_in(audf1_pulse), .pulse_out(audf1_pulse_noise), .noise_4(noise_4_reg[0]), .noise_5(noise_5_reg[0]), .noise_large(noise_large_reg[0]), .sync_reset(stimer_write_delayed));
   
   pokey_noise_filter pokey_noise_filter2(.clk(clk), .reset_n(reset_n), .noise_select(audc2_reg[7:5]), .pulse_in(audf2_pulse), .pulse_out(audf2_pulse_noise), .noise_4(noise_4_reg[1]), .noise_5(noise_5_reg[1]), .noise_large(noise_large_reg[1]), .sync_reset(stimer_write_delayed));
   
   pokey_noise_filter pokey_noise_filter3(.clk(clk), .reset_n(reset_n), .noise_select(audc3_reg[7:5]), .pulse_in(audf3_pulse), .pulse_out(audf3_pulse_noise), .noise_4(noise_4_reg[2]), .noise_5(noise_5_reg[2]), .noise_large(noise_large_reg[2]), .sync_reset(stimer_write_delayed));
   
   assign chan0_output_next = audf0_pulse_noise;
   assign chan1_output_next = audf1_pulse_noise;
   assign chan2_output_next = audf2_pulse_noise;
   assign chan3_output_next = audf3_pulse_noise;
   
   
   always @(audctl_reg or audf2_pulse or audf3_pulse or chan0_output_reg or chan1_output_reg or chan2_output_reg or chan3_output_reg or highpass0_reg or highpass1_reg)
   begin
      highpass0_next <= highpass0_reg;
      highpass1_next <= highpass1_reg;
      
      if (audctl_reg[2] == 1'b1)
      begin
         if (audf2_pulse == 1'b1)
            highpass0_next <= chan0_output_reg;
      end
      else
         highpass0_next <= 1'b1;
      
      if (audctl_reg[1] == 1'b1)
      begin
         if (audf3_pulse == 1'b1)
            highpass1_next <= chan1_output_reg;
      end
      else
         highpass1_next <= 1'b1;
   end
   
   
   always @(chan0_output_reg or chan1_output_reg or chan0_output_del_reg or chan1_output_del_reg or enable_179)
   begin
      chan0_output_del_next <= chan0_output_del_reg;
      chan1_output_del_next <= chan1_output_del_reg;
      
      if (enable_179 == 1'b1)
      begin
         chan0_output_del_next <= chan0_output_reg;
         chan1_output_del_next <= chan1_output_reg;
      end
   end
   
   
   syncreset_enable_divider #(28, 6) enable_64_div(.clk(clk), .syncreset(initmode), .reset_n(reset_n), .enable_in(enable_179), .enable_out(enable_64));
   
   
   syncreset_enable_divider #(114, 33) enable_15_div(.clk(clk), .syncreset(initmode), .reset_n(reset_n), .enable_in(enable_179), .enable_out(enable_15));
   
   assign initmode = ~(skctl_next[1] | skctl_next[0]);
   
   pokey_poly_17_9 poly_17_19_lfsr(.clk(clk), .reset_n(reset_n), .init(initmode), .enable(enable_179), .select_9_17(audctl_reg[7]), .bit_out(noise_large), .rand_out(rand_out));
   
   
   pokey_poly_5 poly_5_lfsr(.clk(clk), .reset_n(reset_n), .init(initmode), .enable(enable_179), .bit_out(noise_5));
   
   
   pokey_poly_4 poly_4_lfsr(.clk(clk), .reset_n(reset_n), .init(initmode), .enable(enable_179), .bit_out(noise_4));
   
   
   always @(noise_large_reg or noise_5_reg or noise_4_reg or noise_large or noise_5 or noise_4 or enable_179)
   begin
      noise_large_next <= noise_large_reg;
      noise_5_next <= noise_5_reg;
      noise_4_next <= noise_4_reg;
      
      if (enable_179 == 1'b1)
      begin
         noise_large_next <= {noise_large_reg[1:0], noise_large};
         noise_5_next <= {noise_5_reg[1:0], noise_5};
         noise_4_next <= {noise_4_reg[1:0], noise_4};
      end
   end
   
   
   always @(chan0_output_del_reg or chan1_output_del_reg or chan2_output_reg or chan3_output_reg or audc0_reg or audc1_reg or audc2_reg or audc3_reg or highpass0_reg or highpass1_reg)
   begin
      volume_channel_0_next <= 4'b0000;
      volume_channel_1_next <= 4'b0000;
      volume_channel_2_next <= 4'b0000;
      volume_channel_3_next <= 4'b0000;
      
      if (((chan0_output_del_reg ^ highpass0_reg) | audc0_reg[4]) == 1'b1)
         volume_channel_0_next <= audc0_reg[3:0];
      
      if (((chan1_output_del_reg ^ highpass1_reg) | audc1_reg[4]) == 1'b1)
         volume_channel_1_next <= audc1_reg[3:0];
      
      if ((chan2_output_reg | audc2_reg[4]) == 1'b1)
         volume_channel_2_next <= audc2_reg[3:0];
      
      if ((chan3_output_reg | audc3_reg[4]) == 1'b1)
         volume_channel_3_next <= audc3_reg[3:0];
   end
   
   assign serout_sync_reset = serial_reset | stimer_write_delayed;
   
   delay_line #(2) serout_clock_delay(.clk(clk), .sync_reset(serout_sync_reset), .data_in(serout_enable), .enable(enable_179), .reset_n(reset_n), .data_out(serout_enable_delayed));
   
   
   always @(serout_enable_delayed or skctl_reg or serout_active_reg or serout_clock_last_reg or serout_clock_reg or serout_holding_load or serout_holding_reg or serout_holding_full_reg or serout_shift_reg or serout_bitcount_reg or serial_out_reg or twotone_reg or audf0_pulse or audf1_pulse or serial_reset)
   begin
      serout_clock_next <= serout_clock_reg;
      serout_clock_last_next <= serout_clock_reg;
      
      serout_shift_next <= serout_shift_reg;
      serout_bitcount_next <= serout_bitcount_reg;
      serout_holding_full_next <= serout_holding_full_reg;
      serout_active_next <= serout_active_reg;
      
      serial_out_next <= serial_out_reg;
      sio_out_next <= serial_out_reg;
      
      twotone_next <= twotone_reg;
      twotone_reset <= 1'b0;
      
      if ((audf1_pulse | (audf0_pulse & serial_out_reg)) == 1'b1)
      begin
         twotone_next <= (~(twotone_reg));
         twotone_reset <= skctl_reg[3];
      end
      
      if (skctl_reg[3] == 1'b1)
         sio_out_next <= twotone_reg;
      
      serial_op_needed_interrupt <= 1'b0;
      
      if (serout_enable_delayed == 1'b1)
         serout_clock_next <= (~(serout_clock_reg));
      
      if (serout_clock_last_reg == 1'b0 & serout_clock_reg == 1'b1)
      begin
         serout_shift_next <= {1'b0, serout_shift_reg[9:1]};
         serial_out_next <= serout_shift_reg[1] | (~(serout_active_reg));
         
         if (serout_bitcount_reg == 4'h0)
         begin
            if (serout_holding_full_reg == 1'b1)
            begin
               serout_bitcount_next <= 4'h9;
               serout_shift_next <= {1'b1, serout_holding_reg, 1'b0};
               serial_out_next <= 1'b0;
               serout_holding_full_next <= 1'b0;
               serial_op_needed_interrupt <= 1'b1;
               serout_active_next <= 1'b1;
            end
            else
            begin
               serout_active_next <= 1'b0;
               serial_out_next <= 1'b1;
            end
         end
         else
            serout_bitcount_next <= (serout_bitcount_reg - 1);
      end
      
      if (skctl_reg[7] == 1'b1)
         serial_out_next <= 1'b0;
      
      if (serout_holding_load == 1'b1)
         serout_holding_full_next <= 1'b1;
      
      if (serial_reset == 1'b1)
      begin
         twotone_next <= 1'b0;
         serout_bitcount_next <= {4{1'b0}};
         serout_shift_next <= {10{1'b0}};
         serout_holding_full_next <= 1'b0;
         serout_clock_next <= 1'b0;
         serout_clock_last_next <= 1'b0;
         serout_active_next <= 1'b0;
      end
   end
   
   
   synchronizer sio_in1_synchronizer(.clk(clk), .raw(sio_in1), .sync(sio_in1_reg));
   
   synchronizer sio_in2_synchronizer(.clk(clk), .raw(sio_in2), .sync(sio_in2_reg));
   
   synchronizer sio_in3_synchronizer(.clk(clk), .raw(sio_in3), .sync(sio_in3_reg));
   assign sio_in_next = sio_in1_reg & sio_in2_reg & sio_in3_reg;
   
   assign waiting_for_start_bit = (serin_bitcount_reg == 4'h9) ? 1'b1 : 
                                  1'b0;
   
   always @(serin_enable or serin_clock_last_reg or serin_clock_reg or sio_in_reg or serin_reg or serin_shift_reg or serin_bitcount_reg or serial_ip_overrun_reg or serial_ip_framing_reg or skrest_write or irqst_reg or skctl_reg or waiting_for_start_bit or serial_reset)
   begin
      serin_clock_next <= serin_clock_reg;
      serin_clock_last_next <= serin_clock_reg;
      
      serin_shift_next <= serin_shift_reg;
      serin_bitcount_next <= serin_bitcount_reg;
      serin_next <= serin_reg;
      
      serial_ip_overrun_next <= serial_ip_overrun_reg;
      serial_ip_framing_next <= serial_ip_framing_reg;
      serial_ip_ready_interrupt <= 1'b0;
      
      async_serial_reset <= 1'b0;
      
      if (serin_enable == 1'b1)
         serin_clock_next <= (~(serin_clock_reg));
      
      if ((skctl_reg[4] & sio_in_reg & waiting_for_start_bit) == 1'b1)
      begin
         async_serial_reset <= 1'b1;
         serin_clock_next <= 1'b1;
      end
      
      if (serin_clock_last_reg == 1'b1 & serin_clock_reg == 1'b0)
      begin
         if (((waiting_for_start_bit & (~(sio_in_reg))) | (~(waiting_for_start_bit))) == 1'b1)
         begin
            serin_shift_next <= {sio_in_reg, serin_shift_reg[9:1]};
            
            if (serin_bitcount_reg == 4'h0)
            begin
               serin_next <= serin_shift_reg[9:2];
               
               serin_bitcount_next <= 4'h9;
               
               serial_ip_ready_interrupt <= 1'b1;
               
               if (irqst_reg[5] == 1'b0)
                  serial_ip_overrun_next <= 1'b1;
               
               if (sio_in_reg == 1'b0)
                  serial_ip_framing_next <= 1'b1;
            end
            else
               serin_bitcount_next <= (serin_bitcount_reg - 1);
         end
      end
      
      if (skrest_write == 1'b1)
      begin
         serial_ip_overrun_next <= 1'b0;
         serial_ip_framing_next <= 1'b0;
      end
      
      if (serial_reset == 1'b1)
      begin
         serin_clock_next <= 1'b0;
         serin_bitcount_next <= 4'h9;
         serin_shift_next <= {10{1'b0}};
      end
   end
   
   
   always @(sio_clockin_in or skctl_reg or clock_reg or clock_sync_reg or audf1_pulse or audf2_pulse or audf3_pulse)
   begin
      clock_next <= sio_clockin_in;
      clock_sync_next <= clock_reg;
      
      serout_enable <= 1'b0;
      serin_enable <= 1'b0;
      clock_input <= 1'b1;
      
      case (skctl_reg[6:4])
         3'b000 :
            begin
               serin_enable <= (~(clock_sync_reg)) & clock_reg;
               serout_enable <= (~(clock_sync_reg)) & clock_reg;
            end
         3'b001 :
            begin
               serin_enable <= audf3_pulse;
               serout_enable <= (~(clock_sync_reg)) & clock_reg;
            end
         3'b010 :
            begin
               serin_enable <= audf3_pulse;
               serout_enable <= audf3_pulse;
               clock_input <= 1'b0;
            end
         3'b011 :
            begin
               serin_enable <= audf3_pulse;
               serout_enable <= audf3_pulse;
            end
         3'b100 :
            begin
               serin_enable <= (~(clock_sync_reg)) & clock_reg;
               serout_enable <= audf3_pulse;
            end
         3'b101 :
            begin
               serin_enable <= audf3_pulse;
               serout_enable <= audf3_pulse;
            end
         3'b110 :
            begin
               serin_enable <= audf3_pulse;
               serout_enable <= audf1_pulse;
               clock_input <= 1'b0;
            end
         3'b111 :
            begin
               serin_enable <= audf3_pulse;
               serout_enable <= audf1_pulse;
            end
         default :
            ;
      endcase
   end
   
   
   always @(other_key_irq or keyboard_overrun_reg or skrest_write or irqst_reg)
   begin
      keyboard_overrun_next <= keyboard_overrun_reg;
      
      if (other_key_irq == 1'b1 & irqst_reg[6] == 1'b0)
         keyboard_overrun_next <= 1'b1;
      
      if (skrest_write == 1'b1)
         keyboard_overrun_next <= 1'b0;
   end
   
   generate
      if (custom_keyboard_scan == 1)
      begin : gen_custom_scan
         
         pokey_keyboard_scanner pokey_keyboard_scanner1(.clk(clk), .reset_n(reset_n), .enable(keyboard_scan_enable), .keyboard_response(keyboard_response), .debounce_disable((~(skctl_reg[0]))), .scan_enable(skctl_reg[1]), .keyboard_scan(keyboard_scan), .key_held(key_held), .shift_held(shift_held), .keycode(kbcode), .other_key_irq(other_key_irq), .break_irq(break_irq));
      end
   endgenerate
   
   generate
      if (custom_keyboard_scan == 0)
      begin : gen_normal_scan
         
         pokey_keyboard_scanner pokey_keyboard_scanner1(.clk(clk), .reset_n(reset_n), .enable(enable_15), .keyboard_response(keyboard_response), .debounce_disable((~(skctl_reg[0]))), .scan_enable(skctl_reg[1]), .keyboard_scan(keyboard_scan), .key_held(key_held), .shift_held(shift_held), .keycode(kbcode), .other_key_irq(other_key_irq), .break_irq(break_irq));
      end
   endgenerate
   
   
   always @(potgo_write or pot_reset_reg or pot_counter_reg or pot_in or enable_15 or enable_179 or skctl_reg or pot0_reg or pot1_reg or pot2_reg or pot3_reg or pot4_reg or pot5_reg or pot6_reg or pot7_reg or allpot_reg)
   begin
      pot0_next <= pot0_reg;
      pot1_next <= pot1_reg;
      pot2_next <= pot2_reg;
      pot3_next <= pot3_reg;
      pot4_next <= pot4_reg;
      pot5_next <= pot5_reg;
      pot6_next <= pot6_reg;
      pot7_next <= pot7_reg;
      
      allpot_next <= allpot_reg;
      
      pot_reset_next <= pot_reset_reg;
      
      pot_counter_next <= pot_counter_reg;
      
      if (((enable_15 & (~(skctl_reg[2]))) | (enable_179 & skctl_reg[2])) == 1'b1)
      begin
         pot_counter_next <= (pot_counter_reg + 1);
         if (pot_counter_reg == 8'he4)
         begin
            pot_reset_next <= 1'b1;
            allpot_next <= {8{1'b0}};
         end
         
         if (pot_reset_reg == 1'b0)
         begin
            if (pot_in[0] == 1'b0)
               pot0_next <= pot_counter_reg;
            if (pot_in[1] == 1'b0)
               pot1_next <= pot_counter_reg;
            if (pot_in[2] == 1'b0)
               pot2_next <= pot_counter_reg;
            if (pot_in[3] == 1'b0)
               pot3_next <= pot_counter_reg;
            if (pot_in[4] == 1'b0)
               pot4_next <= pot_counter_reg;
            if (pot_in[5] == 1'b0)
               pot5_next <= pot_counter_reg;
            if (pot_in[6] == 1'b0)
               pot6_next <= pot_counter_reg;
            if (pot_in[7] == 1'b0)
               pot7_next <= pot_counter_reg;
            
            allpot_next <= allpot_reg & (~(pot_in));
         end
      end
      
      if (potgo_write == 1'b1)
      begin
         pot_counter_next <= {8{1'b0}};
         pot_reset_next <= 1'b0;
         allpot_next <= {8{1'b1}};
      end
   end
   
   assign irq_n_out = irq_n_reg;
   
   assign channel_0_out = volume_channel_0_reg;
   assign channel_1_out = volume_channel_1_reg;
   assign channel_2_out = volume_channel_2_reg;
   assign channel_3_out = volume_channel_3_reg;
   
   assign sio_out1 = sio_out_reg;
   assign sio_out2 = sio_out_reg;
   assign sio_out3 = sio_out_reg;
   
   assign sio_clockout = serout_clock_reg;
   assign sio_clockin_oe = (~(clock_input));
   assign sio_clockin_out = serin_clock_reg;
   
   assign pot_reset = pot_reset_reg;
   
endmodule
