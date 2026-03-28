// IQ Analog Proprietary and Confidential
// ------------------------------------------------------------------------------
// (c) Copyright 
//         All Rights Reserved
// ------------------------------------------------------------------------------
//  CONFIDENTIAL
// ------------------------------------------------------------------------------
//
// Module:  Test Bench interface class for PRISM baseline core.
// Version: 1.0
//
// ------------------------------------------------------------------------------
//
//  File        : tb_rx_core.sv
//  Revision    : 1.0
//  Author      : Ken Pettit
//  Created     : 04/02/2015
//
// Description:  
//    This is the testbench interface class for the PRISM core
//    interfaces.  It provides the abstraction layer for accessing and
//    controlling various signals within the testbench.
//
// Modifications:
//
//    Author            Date        Ver  Description
//    ================  ==========  ===  =======================================
//    Ken Pettit        04/02/2015  1.0  Initial version
//
// ------------------------------------------------------------------------------

`ifndef CLASS_TB_LISA
`define CLASS_TB_LISA

`include "TbGeneric.sv"

class tb_lisa extends TbGeneric;

   /*
   =======================================================================
   Define Common variables.
   =======================================================================
   */
   int               errors, tests;
   int               timePs;

   function new();
      timePs = 0;
      errors = 0;
      tests = 0;
   endfunction

   // Task to delay a specified number of posedge clocks
   extern task AwaitPosedge(int count);

   // Task to delay a specified number of negedge clocks
   extern task AwaitReset();

   // Task to write data to the Debug UART
   extern task DebugWrite(input logic [7:0] data);

   // Task to read data from the Debug UART
   extern task DebugRead(output logic [7:0] data);

   // Task to write a debug register
   extern task DebugWriteReg(input logic [7:0] r, input logic [15:0] val);

   // Task to read a debug register
   extern task DebugReadReg(input logic [7:0] r, output logic [15:0] val);

   extern function [7:0] NibbleToASCII([3:0] nibble);
   extern function [3:0] ASCIIToNibble([7:0] ascii);
endclass
   
`endif
