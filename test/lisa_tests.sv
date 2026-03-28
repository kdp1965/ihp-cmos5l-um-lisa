// IQ Analog Proprietary and Confidential
// ------------------------------------------------------------------------------
// (c) Copyright 
//         All Rights Reserved
// ------------------------------------------------------------------------------
//  CONFIDENTIAL
// ------------------------------------------------------------------------------
//
// Module:  Unit test program for PRISM.
// Version: 1.0
//
// ------------------------------------------------------------------------------
//
//  File        : prism_tests.sv
//  Revision    : 1.0
//  Author      : Ken Pettit
//  Created     : 04/01/2015
//
// Description:  
//    This is a program for the JESD204B RX Initial Lane Alignment Sequence
//    FSM.
//
// Modifications:
//
//    Author            Date        Ver  Description
//    ================  ==========  ===  =======================================
//    Ken Pettit        04/01/2015  1.0  Initial version
//
// ------------------------------------------------------------------------------

// Pull in the TestProgram class for the RX CLK gen (TpRxClkGen class)
// and other classes
`include "TpLogConsole.sv"
`include "tb_lisa.sv"

program lisa_tests;

   localparam DEBUG_REG_LISA_CTRL   = 8'h00;
   localparam DEBUG_REG_LISA_STATUS = 8'h01;
   localparam DEBUG_REG_LISA_PC     = 8'h02;
   localparam DEBUG_REG_LISA_SP     = 8'h03;
   localparam DEBUG_REG_LISA_RA     = 8'h04;
   localparam DEBUG_REG_LISA_IX     = 8'h05;
   localparam DEBUG_REG_LISA_DIN    = 8'h06;
   localparam DEBUG_REG_LISA_DADDR  = 8'h07;

   localparam DEBUG_REG_DEBUG_A_LSB = 8'h10;
   localparam DEBUG_REG_DEBUG_A_MSB = 8'h11;
   localparam DEBUG_REG_LISA1_BASE  = 8'h12;
   localparam DEBUG_REG_LISA2_BASE  = 8'h13;
   localparam DEBUG_REG_LISA1_CE    = 8'h14;
   localparam DEBUG_REG_LISA2_CE    = 8'h15;
   localparam DEBUG_REG_DEBUG_CE    = 8'h16;
   localparam DEBUG_REG_CE_MODE     = 8'h17;
   localparam DEBUG_REG_DUMMY_READ  = 8'h18;
   localparam DEBUG_REG_QUAD_WRITE  = 8'h19;
   localparam DEBUG_REG_PLUS_GUARD  = 8'h1a;
   localparam DEBUG_REG_OUT_MUX     = 8'h1b;
   localparam DEBUG_REG_IO_MUX      = 8'h1c;
   localparam DEBUG_REG_CACHE_CTRL  = 8'h1d;

   localparam DEBUG_REG_FLASH_RW    = 8'h20;    // Register to read/write FLASH data
   localparam DEBUG_REG_FLASH_CUSTOM= 8'h21;    // Write custom command
   localparam DEBUG_REG_FLASH_STATUS= 8'h22;    // Register to read flash status

   /*
   ===================================================================
   Create a TestBench interface class pointer to provide the 
   abstraction layer for accessing the tb sigals, etc.
   ===================================================================
   */
   tb_lisa tb;

   /*
   ===================================================================
   Instantiate class pointers for conducting RX CLK and CGS tests.

   These are Test Program (Tp) class for configuring and testing the 
   RxClkGen and RxCgs module in whatever testbench is active.
   ===================================================================
   */
   TpLogConsole   Log;

   /*
   ===================================================================
   Initial test configuration.  Set all registers, etc. prior to
   test start.
   ===================================================================
   */
   task initial_setup ( );
      
      logic [7:0] data;

      // Create an instance of our TestBench class
      tb = new;
      tb.SetTimeReportPs();

      // Create a console log
      //Log = new(tb);
      Log = new;

      tb.AwaitReset();
      tb.AwaitPosedge(5000);

      // Program a faster clock
      //tb.DebugSetBaudDiv(8'h2);

      // First write sets the AutoBaud value
      tb.DebugWrite(8'h0A);
      tb.AwaitPosedge(131072);

      // We should get a \r\n from this
      tb.DebugWrite(8'h0A);
      tb.DebugRead(data);
      tb.DebugRead(data);
      tb.AwaitPosedge(65536);
      tb.DebugWrite(8'h0A);
      tb.DebugRead(data);
      tb.DebugRead(data);
      tb.AwaitPosedge(65536);

      // First set the I/O Mux bits to Mux mode 2 (SPI/QSPI on PMOD)
      //tb.DebugWriteReg(DEBUG_REG_IO_MUX, 16'h00aa);
      tb.DebugWriteReg(DEBUG_REG_IO_MUX, 16'h00ff);

   endtask

   /*
   ===================================================================
   Test the debug bus
   ===================================================================
   */
   task test_debug_bus ( );
      // Set the debug_address to zero
      logic  [15:0]  rdata;
      string         msg;

      // Read a non-existent register
      tb.DebugReadReg(DEBUG_REG_LISA_CTRL, rdata);
      tb.IncTestCount();
      if (rdata != 16'hff01)
      begin
         tb.IncErrorCount();
         msg = $psprintf ("Lisa status readback fail: Expect:0xFF01 Got:0x%04X", rdata);
         Log.LogMessage(msg);
      end
   endtask

   /*
   ===================================================================
   Start the LISA core running
   ===================================================================
   */
   task run_lisa ( );
      // First set the I/O Mux bits to Mux mode 2 (SPI/QSPI on PMOD)
      //tb.DebugWriteReg(DEBUG_REG_IO_MUX, 16'h00aa);
      tb.DebugWriteReg(DEBUG_REG_IO_MUX, 16'h00ff);

      // Configure LISA data bus to use CS1
      tb.DebugWriteReg(DEBUG_REG_LISA2_CE, 16'h0002);

      // Configure Lisa Data cache controller for 4K map
      tb.DebugWriteReg(DEBUG_REG_CACHE_CTRL, 16'h0000);

      // Set the output mux bits so we can see the LISA I/O toggle
      tb.DebugWriteReg(DEBUG_REG_OUT_MUX, 16'h5455);

      // Set QSPI dummy read cycles to 6
      tb.DebugWriteReg(DEBUG_REG_DUMMY_READ, 16'h0066);

      // Start the LISA core by writing to the control register
      tb.DebugWriteReg(DEBUG_REG_LISA_CTRL, 16'hff02);
   endtask

   /*
   ===================================================================
   Halt the LISA core
   ===================================================================
   */
   task halt_lisa ( );
      tb.DebugWriteReg(DEBUG_REG_LISA_CTRL, 16'h1);
   endtask

   /*
   ===================================================================
   Erase flash sector
   ===================================================================
   */
   task await_flash_ready (output integer timedOut );
      reg [15:0] rdata;
      integer    timeout;

      timeout = 400;
      tb.DebugReadReg(DEBUG_REG_FLASH_STATUS, rdata);
      while (rdata != 16'h0)
      begin
         tb.DebugReadReg(DEBUG_REG_FLASH_STATUS, rdata);
         timeout = timeout - 1;
      end

      if (timeout == 16'h0)
         timedOut = 1;
      else
         timedOut = 0;
   endtask

   /*
   ===================================================================
   Erase flash sector
   ===================================================================
   */
   task erase_flash_sector (input [23:0] addr);
      integer timedOut;

      // Halt the core
      halt_lisa();

      // Set the PC to 0
      tb.DebugWriteReg(DEBUG_REG_LISA_PC, 16'h0);

      // Set the debug interface to single SPI FLASH mode
      tb.DebugWriteReg(DEBUG_REG_CE_MODE, 16'h0006);

      // Set the WREN bit in the FLASH
      tb.DebugWriteReg(DEBUG_REG_FLASH_CUSTOM, 16'h0004);

      // Perform a sector erase
      tb.DebugWriteReg(DEBUG_REG_FLASH_CUSTOM, 16'h01d8);
      await_flash_ready(timedOut);
   endtask

   /*
   ===================================================================
   Program the flash
   ===================================================================
   */
   task program_flash ( );
      reg [7:0] memory[0:511];
      reg [15:0] word;
      int       word_int;
      int       lastword_int;
      reg       done;
      integer count;
      integer timedOut;

      $readmemh("firmware.hex", memory);

      done = 0;
      for (count = 0; count < 256; count = count + 1)
      begin
         // Get next word to write
         word[7:0]  = memory[count*2];
         word[15:8] = memory[count*2 + 1];
         word_int = word;

         // Break when no more data
         if (word_int == 0 && lastword_int == 0)
         begin
            done = 1;
            break;
         end

         // Test for end of data (address is zero)
         tb.DebugWriteReg(DEBUG_REG_FLASH_RW, word);
         await_flash_ready(timedOut);
         if (timedOut)
         begin
            $display("Timeout programming FLASH\n");
            break;
         end

         lastword_int = word_int;
      end

      // Set the debug interface to QSPI FLASH / QSPI SRAM mode
      tb.DebugWriteReg(DEBUG_REG_CE_MODE, 16'h0007);

      // Set the WRITE opcode to 0x38
      tb.DebugWriteReg(DEBUG_REG_QUAD_WRITE, 16'h0038);

   endtask

   /*
   ===================================================================
   Test Lisa Version
   ===================================================================
   */
   task test_debug_version ( );
      
      reg   [7:0]    rdata;
      string         rdata_str;
      string         version;
      string         msg;

      tb.AwaitPosedge(131072);
      tb.DebugWrite(8'h76);        // Write 'v' to the UART

      // Read the response
      tb.DebugRead(rdata);         // Read 'l'
      rdata_str = $sformatf("%c", rdata);
      version   = {version, rdata_str};
      tb.DebugRead(rdata);         // Read 'i'
      rdata_str = $sformatf("%c", rdata);
      version   = {version, rdata_str};
      tb.DebugRead(rdata);         // Read 's'
      rdata_str = $sformatf("%c", rdata);
      version   = {version, rdata_str};
      tb.DebugRead(rdata);         // Read 'a'
      rdata_str = $sformatf("%c", rdata);
      version   = {version, rdata_str};
      tb.DebugRead(rdata);         // Read 'v'
      rdata_str = $sformatf("%c", rdata);
      version   = {version, rdata_str};
      tb.DebugRead(rdata);         // Read '1'
      rdata_str = $sformatf("%c", rdata);
      version   = {version, rdata_str};
      tb.DebugRead(rdata);         // Read '.'
      rdata_str = $sformatf("%c", rdata);
      version   = {version, rdata_str};
      tb.DebugRead(rdata);         // Read '2'
      rdata_str = $sformatf("%c", rdata);
      version   = {version, rdata_str};

      tb.DebugRead(rdata);         // Read LF
      tb.DebugRead(rdata);         // Read CR

      msg = $psprintf ("Debug Data readback = %s", version);
      Log.LogMessage(msg);

      // Test the return value
      tb.IncTestCount();
      if (version != "lisav1.2")
         tb.IncErrorCount();

   endtask

   /*
   ===================================================================
   Test the LISA uart access and code
   ===================================================================
   */
   task test_lisa_uart ( );
      logic [7:0]  data;
      string       msg;

      // Send 'l' command to give UART to LISA
      tb.DebugWrite(8'h6c);

      tb.AwaitPosedge(500000);

      // Send a character to LISA that DEBUG wouldn't respond to
      tb.DebugWrite(8'h48);   // Send 'H'

      // Set QSPI dummy read cycles to 4
      tb.DebugRead(data);

      // Test the return value
      tb.IncTestCount();
      if (data != 8'h48)
      begin
         msg = $psprintf ("UART Data readback = %c  expected 'H'", data);
         Log.LogMessage(msg);
         tb.IncErrorCount();
      end
   endtask

   /*
   ===================================================================
   Main test entry point
   ===================================================================
   */
   initial begin
      string msg;

      // Perform initial test signal setup
      initial_setup();

      // Test the Debug version command
      test_debug_version();

      // Test the debug register bus
      test_debug_bus();

      // Erase the flash
      erase_flash_sector (24'h0);

      // Program flash
      program_flash();

      // Start the LISA core running
      run_lisa();

      // Test the LISA UART
      test_lisa_uart();

      // Run for a while
      tb.AwaitPosedge(500000);

      msg = $psprintf ("Total assertions tested: %-d",tb.GetTestCount());
      Log.LogMessage(msg);
      msg = $psprintf ("Total assertion errors:  %-d",tb.GetErrorCount());
      Log.LogMessage(msg);

      Log.LogMessage ("\nDone testing rx_core.");
      if (tb.GetErrorCount() == 0) 
      begin
         Log.LogMessage ("Congratulations, NO ERRORS!\n");
      end

#1000000;

      Log.LogMessage("");
      $finish;
   end

endprogram

