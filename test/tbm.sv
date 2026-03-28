`default_nettype none
`timescale 1ns / 1ps

`include "tb_lisa.sv"

/*
Cadence testbench for tt06-um-lisa tb
*/
   localparam ASCII_BEL     = 8'b00000111;
   localparam ASCII_LF      = 8'b00001010;
   localparam ASCII_CR      = 8'b00001101;
   localparam ASCII_sp      = 8'b00100000;
   localparam ASCII_dp      = 8'b00101110;
   localparam ASCII_0       = 8'b00110000;
   localparam ASCII_1       = 8'b00110001;
   localparam ASCII_2       = 8'b00110010;
   localparam ASCII_3       = 8'b00110011;
   localparam ASCII_4       = 8'b00110100;
   localparam ASCII_5       = 8'b00110101;
   localparam ASCII_6       = 8'b00110110;
   localparam ASCII_7       = 8'b00110111;
   localparam ASCII_8       = 8'b00111000;
   localparam ASCII_9       = 8'b00111001;
   localparam ASCII_a       = 8'b01100001;
   localparam ASCII_b       = 8'b01100010;
   localparam ASCII_c       = 8'b01100011;
   localparam ASCII_d       = 8'b01100100;
   localparam ASCII_e       = 8'b01100101;
   localparam ASCII_f       = 8'b01100110;
   localparam ASCII_g       = 8'b01100111;
   localparam ASCII_h       = 8'b01101000;
   localparam ASCII_i       = 8'b01101001;
   localparam ASCII_j       = 8'b01101010;
   localparam ASCII_k       = 8'b01101011;
   localparam ASCII_l       = 8'b01101100;
   localparam ASCII_m       = 8'b01101101;
   localparam ASCII_n       = 8'b01101110;
   localparam ASCII_o       = 8'b01101111;
   localparam ASCII_p       = 8'b01110000;
   localparam ASCII_q       = 8'b01110001;
   localparam ASCII_r       = 8'b01110010;
   localparam ASCII_s       = 8'b01110011;
   localparam ASCII_t       = 8'b01110100;
   localparam ASCII_u       = 8'b01110101;
   localparam ASCII_v       = 8'b01110110;
   localparam ASCII_w       = 8'b01110111;
   localparam ASCII_x       = 8'b01111000;
   localparam ASCII_y       = 8'b01111001;
   localparam ASCII_z       = 8'b01111010;

module tbm
();

   // ==============================================================
   // Clock and reset signals
   // ==============================================================
   logic          clk    = 0;
   logic          rst_n  = 0;
   logic          ena    = 0;

   // ==============================================================
   // I/O signals to interface with tt06-um-lisa
   // ==============================================================
   logic  [7:0]   tx_d;
   logic          tx_wr;
   logic          tx_buf_empty;
   logic          rx_rd;
   logic  [7:0]   rx_d;
   logic          rx_avail;
   logic  [1:0]   uart_port_sel;
   logic  [7:0]   porta_in;
   logic  [7:0]   porta_out;
   logic  [3:0]   nibble;
   logic  [7:0]   ascii;

   // ==============================================================
   // Generate a 20MHz clock
   // ==============================================================
   always #20 clk = ~clk;

   // ================================================
   // Create a reset signal
   // ================================================
   initial begin
      rst_n          = 1'b0;
      uart_port_sel  = 2'h0;
      porta_in       = 8'h0;
      tx_wr          = 1'b0;
      rx_rd          = 1'b0;
      tx_d           = 8'h0;
      #100 ena       = 1'b1;
      #100 rst_n     = 1'b1;
   end

   // ==========================================================================
   // Instantiate the tb
   // ==========================================================================
   tb i_tb
   (
      .clk           ( clk           ),
      .rst_n         ( rst_n         ),
      .ena           ( ena           ),
      .tx_d          ( tx_d          ),
      .tx_wr         ( tx_wr         ),
      .tx_buf_empty  ( tx_buf_empty  ),
      .rx_rd         ( rx_rd         ),
      .rx_d          ( rx_d          ),
      .rx_avail      ( rx_avail      ),
      .uart_port_sel ( uart_port_sel ),
      .porta_in      ( porta_in      ),
      .porta_out     ( porta_out     )
   );

   // ================================================
   // Instantiate the test program.  The test program
   // will create a Tb204b derived Testbench class
   // to preform all tests by accessing this tbm.
   // ================================================
   `T_TEST `T_TEST
   (
   );

endmodule

   // =======================================================================
   // Task to wait for posedge of the clock
   // =======================================================================
   task tb_lisa::AwaitPosedge(int count);
      repeat (count) @(negedge tbm.clk);
   endtask

   // =======================================================================
   // Task to wait for reset
   // =======================================================================
   task tb_lisa::AwaitReset();
      while (tbm.rst_n == 1'b0)
         @(negedge tbm.clk);
   endtask

   // =======================================================================
   // Function to convert nibble to ASCII
   // =======================================================================
   function [7:0] tb_lisa::NibbleToASCII([3:0] nibble);
      case (nibble)
         4'h0: NibbleToASCII = ASCII_0;
         4'h1: NibbleToASCII = ASCII_1;
         4'h2: NibbleToASCII = ASCII_2;
         4'h3: NibbleToASCII = ASCII_3;
         4'h4: NibbleToASCII = ASCII_4;
         4'h5: NibbleToASCII = ASCII_5;
         4'h6: NibbleToASCII = ASCII_6;
         4'h7: NibbleToASCII = ASCII_7;
         4'h8: NibbleToASCII = ASCII_8;
         4'h9: NibbleToASCII = ASCII_9;
         4'hA: NibbleToASCII = ASCII_a;
         4'hB: NibbleToASCII = ASCII_b;
         4'hC: NibbleToASCII = ASCII_c;
         4'hD: NibbleToASCII = ASCII_d;
         4'hE: NibbleToASCII = ASCII_e;
         4'hF: NibbleToASCII = ASCII_f;
         default: NibbleToASCII = ASCII_0;
      endcase
   endfunction

   // =======================================================================
   // Function to ASCII to nibble to ASCII
   // =======================================================================
   function [3:0] tb_lisa::ASCIIToNibble([7:0] ascii);
      case (ascii)
         ASCII_0: ASCIIToNibble = 4'h0;
         ASCII_1: ASCIIToNibble = 4'h1;
         ASCII_2: ASCIIToNibble = 4'h2;
         ASCII_3: ASCIIToNibble = 4'h3;
         ASCII_4: ASCIIToNibble = 4'h4;
         ASCII_5: ASCIIToNibble = 4'h5;
         ASCII_6: ASCIIToNibble = 4'h6;
         ASCII_7: ASCIIToNibble = 4'h7;
         ASCII_8: ASCIIToNibble = 4'h8;
         ASCII_9: ASCIIToNibble = 4'h9;
         ASCII_a: ASCIIToNibble = 4'hA;
         ASCII_b: ASCIIToNibble = 4'hB;
         ASCII_c: ASCIIToNibble = 4'hC;
         ASCII_d: ASCIIToNibble = 4'hD;
         ASCII_e: ASCIIToNibble = 4'hE;
         ASCII_f: ASCIIToNibble = 4'hF;
      endcase
   endfunction

   // =======================================================================
   // Task to Write data to the Debug Controller
   // =======================================================================
   task tb_lisa::DebugWrite(input logic [7:0] data);
      // Wait for the Transmitter to be ready
      while (tbm.tx_buf_empty == 1'b0)
         AwaitPosedge(1);

      // Setup the data write
      tbm.tx_d = data;
      tbm.tx_wr = 1;
      AwaitPosedge(1);

      // Release the data write
      tbm.tx_wr = 0;
      AwaitPosedge(2);
   endtask

   // =======================================================================
   // Task to Write a debug register
   // =======================================================================
   task tb_lisa::DebugWriteReg(input logic [7:0] r, input logic [15:0] val);
      // Write the 'w' command
      DebugWrite(ASCII_w);

      // Write the register number
      DebugWrite(NibbleToASCII(r[7:4]));
      DebugWrite(NibbleToASCII(r[3:0]));

      // Write the register value
      DebugWrite(NibbleToASCII(val[15:12]));
      DebugWrite(NibbleToASCII(val[11:8]));
      DebugWrite(NibbleToASCII(val[7:4]));
      DebugWrite(NibbleToASCII(val[3:0]));

      DebugWrite(ASCII_LF);
   endtask
    
   // =======================================================================
   // Task to Read data from the Debug Controller
   // =======================================================================
   task tb_lisa::DebugRead(output logic [7:0] data);
      // Wait for the Transmitter to be ready
      while (tbm.rx_avail == 1'b0)
         AwaitPosedge(1);

      // Setup the data write
      data = tbm.rx_d;
      tbm.rx_rd = 1;
      AwaitPosedge(1);

      // Release the data write
      tbm.rx_rd = 0;
      AwaitPosedge(2);
   endtask

   // =======================================================================
   // Task to Read a debug register
   // =======================================================================
   task tb_lisa::DebugReadReg(input logic [7:0] r, output logic [15:0] val);
      reg [7:0] dummy;

      // Write the 'r' command
      DebugWrite(ASCII_r);

      // Write the register number
      DebugWrite(NibbleToASCII(r[7:4]));
      DebugWrite(NibbleToASCII(r[3:0]));

      DebugWrite(ASCII_LF);

      // Read the register value
      DebugRead(dummy);
      val[15:12] = ASCIIToNibble(dummy);
      DebugRead(dummy);
      val[11:8]  = ASCIIToNibble(dummy);
      DebugRead(dummy);
      val[7:4]   = ASCIIToNibble(dummy);
      DebugRead(dummy);
      val[3:0]   = ASCIIToNibble(dummy);

      // Read the CR
      DebugRead(dummy);
      // Read the LF
      DebugRead(dummy);
   endtask

