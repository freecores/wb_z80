///////////////////////////////////////////////////////////////////////////////////////////////////
////                                                                                           ////
////  file name:   z80_bist_logic.v                                                               ////
////  description: built in self test logic                                                    ////
////  project:     wb_z80                                                                      ////
////                                                                                           ////
////                                                                                           ////
////  Author: B.J. Porcella                                                                    ////
////          bporcella@sbcglobal.net                                                          ////
////                                                                                           ////
////                                                                                           ////
////                                                                                           ////
///////////////////////////////////////////////////////////////////////////////////////////////////
////                                                                                           ////
//// Copyright (C) 2000-2002 B.J. Porcella                                                     ////
////                         Real Time Solutions                                               ////
////                                                                                           ////
////                                                                                           ////
//// This source file may be used and distributed without                                      ////
//// restriction provided that this copyright statement is not                                 ////
//// removed from the file and that any derivative work contains                               ////
//// the original copyright notice and the associated disclaimer.                              ////
////                                                                                           ////
////     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY                                   ////
//// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED                                 ////
//// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS                                 ////
//// FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR                                    ////
//// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,                                       ////
//// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES                                  ////
//// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE                                 ////
//// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR                                      ////
//// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF                                ////
//// LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT                                ////
//// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT                                ////
//// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE                                       ////
//// POSSIBILITY OF SUCH DAMAGE.                                                               ////
////                                                                                           ////
///////////////////////////////////////////////////////////////////////////////////////////////////
//  CVS Log
//
//  $Id: z80_bist_logic.v,v 1.1 2004-05-13 14:57:35 bporcella Exp $
//
//  $Date: 2004-05-13 14:57:35 $
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
//  Not much here.   Just a very simple memory mapped register to 
//  supply the required bist signals, and the commands necessary to 
//  load the internal memory.   Not that if thes bist is to be 
//  actually synthesized a different method of loading the core SRAM 
//  (eq from external PROM) must be implemented.
//
//-------1---------2---------3--------Module Name and Port List------7---------8---------9--------0
module z80_bist_logic( bist_err_o, 
                       bist_ack_o,
                       wb_adr_i  , 
                       wb_dat_i  , 
                       wb_we_i   , 
                       wb_cyc_i  ,
                       wb_stb_i  , 
                       wb_clk_i  ,
                       wb_tga_i  , 
                       wb_rst_i     );


//-------1---------2---------3--------Output Ports---------6---------7---------8---------9--------0
output bist_err_o;
output bist_ack_o;
//-------1---------2---------3--------Input Ports----------6---------7---------8---------9--------0

input [15:0]  wb_adr_i;  
input         wb_we_i;   
input         wb_cyc_i;  
input         wb_stb_i;  
input [1:0]   wb_tga_i;
input         wb_clk_i;
input         wb_rst_i;  
input [7:0]   wb_dat_i;



//-------1---------2---------3--------Parameters-----------6---------7---------8---------9--------0
//-------1---------2---------3--------Wires------5---------6---------7---------8---------9--------0
//-------1---------2---------3--------Registers--5---------6---------7---------8---------9--------0
reg   [1:0]  bist_reg;
integer      i;
//-------1---------2---------3--------Assignments----------6---------7---------8---------9--------0
assign bist_err_o = bist_reg[1];
assign bist_ack_o = bist_reg[0];
//-------1---------2---------3--------State Machines-------6---------7---------8---------9--------0

//  my address is selected as memory mapped to top of SDRAM.
//  any system implementation may choose to modify this.

wire wb_wr = wb_cyc_i & wb_stb_i & wb_we_i;
wire my_adr = (wb_tga_i == 2'b00) & ( wb_adr_i == 16'h7fff);
always @(posedge wb_clk_i or wb_rst_i) 
    if (wb_rst_i)               bist_reg <= 2'b0;
    else if (my_adr & wb_wr )   bist_reg <= wb_dat_i[1:0];


initial 
begin
    $readmemh( "readmem.txt", z80_testbed.i_z80_core_top.i_generic_spram.mem );
    // be sure at least some of the data got properly loaded.
    for (i=0; i<10; i=i+1)
        $display( "mem [%0d] = %h", i, z80_testbed.i_z80_core_top.i_generic_spram.mem[i]); 
end

endmodule