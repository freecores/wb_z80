///////////////////////////////////////////////////////////////////////////////////////////////
////                                                                                           
////  file name:   z80_sdram_cfg                                                                   
////  description: configure address range and mux data for on-board sdram                                          
////  project:     wb_z80                                                                                       ////
////                                                                                           
////  Author: B.J. Porcella                                                                    
////          bporcella@sbcglobal.net                                                          
////                                                                                           
////                                                                                           
////                                                                                           
///////////////////////////////////////////////////////////////////////////////////////////////
////                                                                                           
//// Copyright (C) 2000-2002 B.J. Porcella                                                     
////                         Real Time Solutions                                               
////                                                                                           
////                                                                                           
//// This source file may be used and distributed without                                      
//// restriction provided that this copyright statement is not                                 
//// removed from the file and that any derivative work contains                               
//// the original copyright notice and the associated disclaimer.                              
////                                                                                           
////     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY                                   
//// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED                                 
//// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS                                 
//// FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR                                    
//// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,                                       
//// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES                                  
//// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE                                 
//// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR                                      
//// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF                                
//// LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT                                
//// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT                                
//// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE                                       
//// POSSIBILITY OF SUCH DAMAGE.                                                               
////                                                                                           
///////////////////////////////////////////////////////////////////////////////////////////////
//  CVS Log
//
//  $Id: z80_sdram_cfg.v,v 1.1 2004-04-27 21:27:13 bporcella Exp $
//
//  $Date: 2004-04-27 21:27:13 $
//  $Revision: 1.1 $
//  $Author: bporcella $
//  $Locker:  $
//  $State: Exp $
//
// Change History:
//      $Log: not supported by cvs2svn $
//      Revision 1.1.1.1  2004/04/13 23:47:42  bporcella
//      import first files
//
//
//
//-------1---------2---------3--------Module Name and Port List------7---------8---------9--------0
module  z80_sdram_cfg (cfg_ce_spram_o, cfg_do, cfg_ack_o, wb_adr_i, sdram_di, wb_dat_i, wb_ack_i, 
                       wb_stb_i, wb_cyc_i, wb_tga_i);


//-------1---------2---------3--------Output Ports---------6---------7---------8---------9--------0
output          cfg_ce_spram_o;
output [7:0]    cfg_do;
output          cfg_ack_o;

//-------1---------2---------3--------Input Ports----------6---------7---------8---------9--------0

input [15:0]    wb_adr_i;
input [7:0]     sdram_di, wb_dat_i;
input           wb_ack_i;
input           wb_stb_i;
input           wb_cyc_i;
input [1:0]     wb_tga_i; 

//-------1---------2---------3--------Parameters-----------6---------7---------8---------9--------0
//-------1---------2---------3--------Wires------5---------6---------7---------8---------9--------0
//-------1---------2---------3--------Registers--5---------6---------7---------8---------9--------0
//-------1---------2---------3--------Assignments----------6---------7---------8---------9--------0

//  this assigns the low half of the address space to the on-board sdram.  Any given implementation
//  might well wish to modify this assigmnment
//  Lot of I/O for not much logic  ---  guess if there were no "rules" I would simply put this stuff
//  in the top level. 



wire sram_addr = ~wb_adr_i[15] & (wb_tga_i == 2'b00);

wire cfg_ce_spram_o = sram_addr & wb_cyc_i & wb_stb_i;

wire [7:0] cfg_do = sram_addr ? sdram_di : wb_dat_i;

wire cfg_ack_o = cfg_ce_spram_o | wb_ack_i;

//-------1---------2---------3--------State Machines-------6---------7---------8---------9--------0



endmodule