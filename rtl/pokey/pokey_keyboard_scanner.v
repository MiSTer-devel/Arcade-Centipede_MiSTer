// Converted to Verilog from original VHDL code (c) 2013 mark watson

`timescale 1 ps / 1 ps

module pokey_keyboard_scanner(clk, reset_n, enable, keyboard_response, debounce_disable, scan_enable, keyboard_scan, key_held, shift_held, keycode, other_key_irq, break_irq);
   input           clk;
   input           reset_n;
   
   input           enable;
   input [1:0]     keyboard_response;
   input           debounce_disable;
   input           scan_enable;
   
   output [5:0]    keyboard_scan;
   
   output          key_held;
   output          shift_held;
   output [7:0]    keycode;
   output          other_key_irq;
   output          break_irq;
   
   reg [5:0]       bincnt_next;
   reg [5:0]       bincnt_reg;
   
   reg             break_pressed_next;
   reg             break_pressed_reg;
   
   reg             shift_pressed_next;
   reg             shift_pressed_reg;
   
   reg             control_pressed_next;
   reg             control_pressed_reg;
   
   reg [5:0]       compare_latch_next;
   reg [5:0]       compare_latch_reg;
   
   reg [7:0]       keycode_latch_next;
   reg [7:0]       keycode_latch_reg;
   
   reg             irq_next;
   reg             irq_reg;
   
   reg             break_irq_next;
   reg             break_irq_reg;
   
   reg             key_held_next;
   reg             key_held_reg;
   
   reg             my_key;
   
   reg [1:0]       state_next;
   reg [1:0]       state_reg;
   parameter [1:0] state_wait_key = 2'b00;
   parameter [1:0] state_key_bounce = 2'b01;
   parameter [1:0] state_valid_key = 2'b10;
   parameter [1:0] state_key_debounce = 2'b11;
   
   
   always @(posedge clk or negedge reset_n)
      if (reset_n == 1'b0)
      begin
         bincnt_reg <= {6{1'b0}};
         break_pressed_reg <= 1'b0;
         shift_pressed_reg <= 1'b0;
         control_pressed_reg <= 1'b0;
         compare_latch_reg <= {6{1'b0}};
         keycode_latch_reg <= {8{1'b1}};
         key_held_reg <= 1'b0;
         state_reg <= state_wait_key;
         irq_reg <= 1'b0;
         break_irq_reg <= 1'b0;
      end
      else 
      begin
         bincnt_reg <= bincnt_next;
         state_reg <= state_next;
         break_pressed_reg <= break_pressed_next;
         shift_pressed_reg <= shift_pressed_next;
         control_pressed_reg <= control_pressed_next;
         compare_latch_reg <= compare_latch_next;
         keycode_latch_reg <= keycode_latch_next;
         key_held_reg <= key_held_next;
         state_reg <= state_next;
         irq_reg <= irq_next;
         break_irq_reg <= break_irq_next;
      end
   
   
   always @(enable or keyboard_response or scan_enable or key_held_reg or my_key or state_reg or bincnt_reg or compare_latch_reg or break_pressed_next or break_pressed_reg or shift_pressed_reg or break_irq_reg or control_pressed_reg or keycode_latch_reg or debounce_disable)
   begin
      bincnt_next <= bincnt_reg;
      state_next <= state_reg;
      compare_latch_next <= compare_latch_reg;
      irq_next <= 1'b0;
      break_irq_next <= 1'b0;
      break_pressed_next <= break_pressed_reg;
      shift_pressed_next <= shift_pressed_reg;
      control_pressed_next <= control_pressed_reg;
      keycode_latch_next <= keycode_latch_reg;
      key_held_next <= key_held_reg;
      
      my_key <= 1'b0;
      if (bincnt_reg == compare_latch_reg | debounce_disable == 1'b1)
         my_key <= 1'b1;
      
      if (enable == 1'b1 & scan_enable == 1'b1)
      begin
         bincnt_next <= (bincnt_reg + 1);
         
         key_held_next <= 1'b0;
         
         case (state_reg)
            state_wait_key :
               if (keyboard_response[0] == 1'b0)
               begin
                  if (debounce_disable == 1'b1)
                  begin
                     keycode_latch_next <= {control_pressed_reg, shift_pressed_reg, bincnt_reg};
                     irq_next <= 1'b1;
                     key_held_next <= 1'b1;
                  end
                  else
                  begin
                     state_next <= state_key_bounce;
                     compare_latch_next <= bincnt_reg;
                  end
               end
            
            state_key_bounce :
               if (keyboard_response[0] == 1'b0)
               begin
                  if (my_key == 1'b1)
                  begin
                     keycode_latch_next <= {control_pressed_reg, shift_pressed_reg, compare_latch_reg};
                     irq_next <= 1'b1;
                     key_held_next <= 1'b1;
                     state_next <= state_valid_key;
                  end
                  else
                     state_next <= state_wait_key;
               end
               else
                  if (my_key == 1'b1)
                     state_next <= state_wait_key;
            
            state_valid_key :
               begin
                  key_held_next <= 1'b1;
                  if (my_key == 1'b1)
                  begin
                     if (keyboard_response[0] == 1'b1)
                        state_next <= state_key_debounce;
                  end
               end
            
            state_key_debounce :
               begin
                  key_held_next <= 1'b1;
                  if (my_key == 1'b1)
                  begin
                     if (keyboard_response[0] == 1'b1)
                     begin
                        key_held_next <= 1'b0;
                        state_next <= state_wait_key;
                     end
                     else
                        state_next <= state_valid_key;
                  end
               end
            
            default :
               state_next <= state_wait_key;
         endcase
         
         if (bincnt_reg[3:0] == 4'b0000)
            case (bincnt_reg[5:4])
               2'b11 :
                  break_pressed_next <= (~(keyboard_response[1]));
               2'b01 :
                  shift_pressed_next <= (~(keyboard_response[1]));
               2'b00 :
                  control_pressed_next <= (~(keyboard_response[1]));
               default :
                  ;
            endcase
      end
      
      if (break_pressed_next == 1'b1 & break_pressed_reg == 1'b0)
         break_irq_next <= 1'b1;
   end
   
   assign keyboard_scan = (~(bincnt_reg));
   
   assign key_held = key_held_reg;
   assign shift_held = shift_pressed_reg;
   assign keycode = keycode_latch_reg;
   assign other_key_irq = irq_reg;
   assign break_irq = break_irq_reg;
   
endmodule
