///////////////////////////////////////////////////////////////////////////////////////////////////
////                                                                                           ////
////  file name:   z80_testbed.v                                                               ////
////  description: testbed for Wishbone z80                                                    ////
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
//  $Id: z80_testbed.v,v 1.3 2004-05-21 02:51:25 bporcella Exp $
//
//  $Date: 2004-05-21 02:51:25 $
//  $Revision: 1.3 $
//  $Author: bporcella $
//  $Locker:  $
//  $State: Exp $
//
// Change History:
//      $Log: not supported by cvs2svn $
//      Revision 1.2  2004/05/18 22:31:21  bporcella
//      instruction test getting to final stages
//
//      Revision 1.1  2004/05/13 14:57:35  bporcella
//      testbed files
//
//      Revision 1.1.1.1  2004/04/13 23:47:42  bporcella
//      import first files
//
//
//
//-------1---------2---------3--------Module Name and Port List------7---------8---------9--------0


`timescale 1ns/10ps
`define  COMPILE_BIST   // need this for this file to work

// testbench - do not synthesize.  this just sequences the bist signals
module z80_testbed();

reg      rst, bist_req, clk;
wire     bist_ack;
wire     bist_err;



//-------   CAUTION  TEST RESULTS DEPEND ON INITIAL CONDITIONS -------
//  bist will not pass if some of these imputs are not as specified.
//
z80_core_top i_z80_core_top(                   
    .wb_dat_o(wb_dat),      
    .wb_stb_o(wb_stb),      
    .wb_cyc_o(wb_cyc),      
    .wb_we_o(wb_we),       
    .wb_adr_o(wb_adr),      
    .wb_tga_o(wb_tga),
    .wb_ack_i(ack),
    .wb_clk_i(clk),
    .wb_dat_i(io_i),
    .wb_rst_i(rst),
    .bist_ack_o(bist_ack),
    .bist_err_o(bist_err),
    .bist_req_i(bist_req),
    .int_req_i(1'b0)        // initial test inst test only 
    );            


reg   ack;
wire [1:0]  wb_tga;
wire [15:0] wb_adr;
wire        wb_stb, wb_cyc, wb_we;
wire [7:0]  wb_dat;
wire [7:0]    io_i;
reg [7:0]   out_state;

parameter   TAG_IO    = 2'b01,   // need to review general wb usage to undrstand how best to 
            TAG_INT   = 2'b10;   // document this.

parameter   MY_IO_ADR = 8'h10 ;
// ----------------- a pretty simple I/O device   -------
//  output simply displays the data written   --  
//  input cycles through 
//  various interesting data  patterens as used by the instruction test
//  namely   7f 55 80 0  ff  aa


assign io_i = (wb_adr[7:0] == MY_IO_ADR) & wb_stb & wb_cyc & (wb_tga == TAG_IO) & !wb_we ?
                  out_state : 8'hz;
wire a2me = (wb_adr[7:0] == MY_IO_ADR) & wb_stb & wb_cyc & (wb_tga == TAG_IO);

always @(posedge clk or posedge rst)
begin
    if (rst )              ack <= 1'b0;
    else if (a2me & !ack) 
    begin                  
                           ack <= 1'b1;
                           if (wb_we)    $write("%s",wb_dat);      
    end
    else                   ack <= 1'b0;    
end

always @(posedge clk or posedge rst)
begin
    if (rst)              out_state <=  8'h7f;
    else if (a2me & !wb_we & ack)
        case (out_state)
            8'h7f:         out_state <=  8'h55 ;
            8'h55:         out_state <=  8'h80 ;
            8'h80:         out_state <=  8'h00 ;
            8'h00:         out_state <=  8'hff ;
            8'hff:         out_state <=  8'haa ;
            8'haa:         out_state <=  8'h7f ;
            default:       out_state <=  8'h7f ;
        endcase
end



initial
begin
    clk = 0;
    //  timeout if u hang up  -- always a good idea.
    #500000     $finish;
    $display("simulation timeout"); 
end

always   #5 clk = ~clk;

// The bist sequencer  --- pertty trivial
initial
begin
    rst = 1'b0;
    bist_req = 1'b0;
    @( posedge clk)  rst = 1'b1;
    @( posedge clk)  rst = 1'b0;
    @( posedge clk)  bist_req = 1'b1;
    @( bist_ack ) ;
    @( posedge clk)
        if ( bist_err ) $display("bist error");
        else            $display( "bist ok"    );
    $finish;
end


initial
begin
    $dumpfile("dump.vcd");
    $dumpvars;
end

endmodule