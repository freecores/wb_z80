//////////////////////////////////////////////////////////////////////
////                                                              ////
////  Generic Single-Port Synchronous RAM                         ////
////                                                              ////
////  This file is part of memory library available from          ////
////  http://www.opencores.org/cvsweb.shtml/generic_memories/     ////
////                                                              ////
////  Description                                                 ////
////  This block is a wrapper with common single-port             ////
////  synchronous memory interface for different                  ////
////  types of ASIC and FPGA RAMs. Beside universal memory        ////
////  interface it also provides a behavioral model of generic    ////
////  single-port synchronous RAM.                                ////
////  It also contains a synthesizeable model for FPGAs.          ////
////  It should be used in all OPENCORES designs that want to be  ////
////  portable accross different target technologies and          ////
////  independent of target memory.                               ////
////                                                              ////
////  Supported ASIC RAMs are:                                    ////
////  - Artisan Single-Port Sync RAM                              ////
////  - Avant! Two-Port Sync RAM (*)                              ////
////  - Virage Single-Port Sync RAM                               ////
////  - Virtual Silicon Single-Port Sync RAM                      ////
////                                                              ////
////  Supported FPGA RAMs are:                                    ////
////  - Generic FPGA (VENDOR_FPGA)                                ////
////    Tested RAMs: Altera, Xilinx                               ////
////    Synthesis tools: LeonardoSpectrum, Synplicity             ////
////  - Xilinx (VENDOR_XILINX)                                    ////
////  - Altera (VENDOR_ALTERA)                                    ////
////                                                              ////
////  To Do:                                                      ////
////   - fix avant! two-port ram                                  ////
////   - add additional RAMs                                      ////
////                                                              ////
////  Author(s):                                                  ////
////      - Richard Herveille, richard@asics.ws                   ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
//
// CVS Revision History
//
// $Log: not supported by cvs2svn $
// Revision 1.1  2004/04/27 21:27:13  bporcella
// first core build
//
// Revision 1.3  2001/11/09 00:34:19  samg
// minor changes: unified with all common rams
//
// Revision 1.2  2001/11/08 19:32:59  samg
// corrected output: output not valid if ce low
//
// Revision 1.1.1.1  2001/09/14 09:57:09  rherveille
// Major cleanup.
// Files are now compliant to Altera & Xilinx memories.
// Memories are now compatible, i.e. drop-in replacements.
// Added synthesizeable generic FPGA description.
// Created "generic_memories" cvs entry.
//
// Revision 1.2  2001/07/30 05:38:02  lampret
// Adding empty directories required by HDL coding guidelines
//
//

//`include "timescale.v"

//`define VENDOR_XILINX
//`define VENDOR_ALTERA
//`define VENDOR_FPGA
//
//--------------------- WARNING ------------------------------------
//
// The way this "generic" ram works is not compatable with ANY SRAM that
// I have used in 30 years in this industry.......
//
// WHY register the address on read  - but not on write?  makes absolutly
// no sense to me.  I suppose that there might be no real register file 
// compatable SRAMS in some of the FPGA libraries.  In which case, I probably
// need to make modifications to the basic core.  
//
// Well for now just patch this to work like I expected,
// 
//  AS OF 4/29/2004 this is a seriously modified file.   bjp
//   see changes under bjp below
module generic_spram(
    // Generic synchronous single-port RAM interface
    clk, rst, ce, we, oe, addr, di, do
);

    //
    // Default address and data buses width
    //
    parameter aw = 6; //number of address-bits
    parameter dw = 8; //number of data-bits

    //
    // Generic synchronous single-port RAM interface
    //
    input           clk;  // Clock, rising edge
    input           rst;  // Reset, active high
    input           ce;   // Chip enable input, active high
    input           we;   // Write enable input, active high
    input           oe;   // Output enable input, active high
    input  [aw-1:0] addr; // address bus inputs
    input  [dw-1:0] di;   // input data bus
    output [dw-1:0] do;   // output data bus

    //
    // Module body
    //


    // Generic single-port synchronous RAM model
    //

    //
    // Generic RAM's registers and wires
    //
    reg  [dw-1:0] mem [(1<<aw)-1:0];    // RAM content

    // bjp  change  was
    //reg  [aw-1:0] raddr;             // RAM read address
    //wire raddr = addr;
    //
    // Data output drivers
    //
    assign do = (oe & ce) ? mem[addr] : {dw{1'bz}};

    //
    // RAM read and write
    //

    // bjp read operation made asynchronous   (only write is on clock)
    //always@(posedge clk)
    //if (ce) // && !we)
    //    raddr <= #1 addr;    // read address needs to be registered to read clock
    

    // write operation
    always@(posedge clk)
        if (ce && we)
            mem[addr] <=  di;



endmodule



