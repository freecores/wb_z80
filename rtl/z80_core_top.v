///////////////////////////////////////////////////////////////////////////////////////////////
////                                                                                           
////  file name:   z80_core_top.v                                                                   
////  description: interconnect module for z80 core.                                          
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
//  $Id: z80_core_top.v,v 1.4 2004-05-18 22:31:21 bporcella Exp $
//
//  $Date: 2004-05-18 22:31:21 $
//  $Revision: 1.4 $
//  $Author: bporcella $
//  $Locker:  $
//  $State: Exp $
//
// Change History:
//      $Log: not supported by cvs2svn $
//      Revision 1.3  2004/05/13 14:58:53  bporcella
//      testbed built and verification in progress
//
//      Revision 1.2  2004/04/27 21:38:22  bporcella
//      test lint on core
//
//      Revision 1.1  2004/04/27 21:27:13  bporcella
//      first core build
//
//      Revision 1.1.1.1  2004/04/13 23:47:42  bporcella
//      import first files
//
//
//
// connects modules:
//  memstate2.v       // main state machine for z8 
//  inst_exec.v       // main execution engine for z80
//  generic_spram.v   // main memory  (on board)
//  z80_sdram_config.v // fundamentally wishbone glue logic - not on top per design guidelines
//  add a comment test lint
//-------1---------2---------3--------Module Name and Port List------7---------8---------9--------0
module z80_core_top(  
                      wb_dat_o,      
                      wb_stb_o,      
                      wb_cyc_o,      
                      wb_we_o,       
                      wb_adr_o,      
                      wb_tga_o,
                      wb_ack_i,
                      wb_clk_i,
                      wb_dat_i,
                      wb_rst_i,
`ifdef COMPILE_BIST
                      bist_ack_o,
                      bist_err_o,
                      bist_req_i,
`endif
                      int_req_i 

);

//-------1---------2---------3--------Output Ports---------6---------7---------8---------9--------0

output [7:0]    wb_dat_o;
output          wb_stb_o;
output          wb_cyc_o;
output          wb_we_o;
output [15:0]   wb_adr_o;
output [1:0]    wb_tga_o;


//-------1---------2---------3--------Input Ports----------6---------7---------8---------9--------0

input           wb_ack_i;
input           wb_clk_i;
input  [7:0]    wb_dat_i;
input           wb_rst_i;
input           int_req_i;


`ifdef COMPILE_BIST
output          bist_err_o;
output          bist_ack_o;
input           bist_req_i;
`endif


//-------1---------2---------3--------Parameters-----------6---------7---------8---------9--------0
//-------1---------2---------3--------Wires------5---------6---------7---------8---------9--------0
wire   [15:0]    wb_adr_o; 
wire   [9:0]     ir1, ir2;
wire   [15:0]    nn;
wire   [15:0]    sp;
wire   [7:0]     ar, fr, br, cr, dr, er, hr, lr, intr;
wire   [15:0]    ixr, iyr;
wire   [7:0]     wb_dat_i, wb_dat_o, sdram_do, cfg_do;
wire   [15:0]    add16;         //  ir2 execution engine output for sp updates
wire   [7:0]     alu8_out, sh_alu, bit_alu;






//-------1---------2---------3--------Registers--5---------6---------7---------8---------9--------0
//-------1---------2---------3--------Assignments----------6---------7---------8---------9--------0
//-------1---------2---------3--------State Machines-------6---------7---------8---------9--------0


`ifdef COMPILE_BIST
z80_bist_logic i_z80_bist_logic( 
        .bist_err_o(bist_err_o), .bist_ack_o(bist_ack_o),
        .wb_adr_i(wb_adr_o), .wb_dat_i(wb_dat_o), .wb_we_i(wb_we_o), .wb_cyc_i(wb_cyc_o),
        .wb_stb_i(wb_stb_o), .wb_tga_i(wb_tga_o), .wb_clk_i(wb_clk_i), .wb_rst_i(wb_rst_i)
        );
`endif



z80_memstate2 i_z80_memstate2(
                .wb_adr_o(wb_adr_o), .wb_we_o(wb_we_o), .wb_cyc_o(wb_cyc_o), .wb_stb_o(wb_stb_o), .wb_tga_o(wb_tga_o), .wb_dat_o(wb_dat_o), 
                .exec_ir2(exec_ir2), .ir1(ir1), .ir2(ir2), .ir1dd(ir1dd), .ir1fd(ir1fd), .ir2dd(ir2dd), .ir2fd(ir2fd), .nn(nn), .sp(sp),
                .upd_ar(upd_ar), .upd_br(upd_br), .upd_cr(upd_cr), .upd_dr(upd_dr), .upd_er(upd_er), .upd_hr(upd_hr), .upd_lr(upd_lr),.upd_fr(upd_fr),
                .beq0(br_eq0), .ceq0(cr_eq0),
                .ar(ar), .fr(fr), .br(br), .cr(cr), .dr(dr), .er(er), .hr(hr), .lr(lr), 
                .ixr(ixr), .iyr(iyr), 
                .wb_dat_i(cfg_do), .wb_ack_i(cfg_ack_o), 
                .int_req_i(int_req_i),
                .add16(add16),
                .alu8_out(alu8_out),
                .sh_alu(sh_alu),
                .bit_alu(bit_alu),
                .wb_clk_i(wb_clk_i),
                .rst_i(wb_rst_i)         // keep this generic - may turn out to be different from wb_rst
                 );


z80_inst_exec i_z80_inst_exec( 
                  .br_eq0(br_eq0),
                  .cr_eq0(cr_eq0),
                  .upd_ar(upd_ar), .upd_br(upd_br), .upd_cr(upd_cr), .upd_dr(upd_dr), .upd_er(upd_er), .upd_hr(upd_hr), .upd_lr(upd_lr),.upd_fr(upd_fr),
                  .ar(ar), .fr(fr), .br(br), .cr(cr), .dr(dr), .er(er), .hr(hr), .lr(lr), .intr(intr), 
                  .ixr(ixr), .iyr(iyr), .add16(add16), .alu8_out(alu8_out),
                   .sh_alu(sh_alu),
                   .bit_alu(bit_alu),
                   .exec_ir2(exec_ir2),
                   .exec_decbc(exec_decbc), .exec_decb(exec_decb), 
                   .ir2(ir2),
                   .clk(wb_clk_i),
                   .rst(wb_rst_i),
                   .nn(nn), .sp(sp),
                   .ir2dd(ir2dd),
                   .ir2fd(ir2fd)
                   );

// The parameter passed to i_generic_sprem specifies the number of address bits used by the
// memory  -- and thus the memory size.   We expect to use 15 here in the released documentation -
// giving an onboard 32k SRAM and allowing 32k space for off-chip memory.  Note that any change to
// this parameter requires modifications to the decode logic in z80_sdram_cfg.
//
// The generic_spram is being used here per Open Cores coding guidelines.  I'm not sure I'm totally
// happy with this......    Depending on which target technology is specified, read behavior changes.
// It is easy to insure all possible behavior will in fact operate properly  -- see the data reduction
// logic in sdram_cfg.v --  but still...   I guess the important thing to be aware of is that 
// big memories like this typically require special back-end handeling.   This is likely to prove
// no exception  - despite the work that has been done to make this file as generally useful as 
// possible.

generic_spram #(15) i_generic_spram(
    // Generic synchronous single-port RAM interface
    .clk(wb_clk_i), .rst(wb_rst_i), .ce(cfg_ce_spram_o), .we(wb_we_o), .oe(1'b1), .addr(wb_adr_o[14:0]), .di(wb_dat_o), .do(sdram_do)
    );



z80_sdram_cfg i_z80_sdram_cfg( 
    .cfg_ce_spram_o(cfg_ce_spram_o), .cfg_do(cfg_do),  .cfg_ack_o(cfg_ack_o), .sdram_di(sdram_do), 
    .wb_adr_i(wb_adr_o), .wb_dat_i(wb_dat_i), .wb_ack_i(wb_ack_i),  .wb_stb_i(wb_stb_o),
    .wb_cyc_i(wb_cyc_o), .wb_tga_i(wb_tga_o) 
    );


endmodule