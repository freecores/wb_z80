///////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                               //
//  file name:   istate.v                                                                       //
//  description: Instruction State Machine z80                                                       //
//  project:     wb_z80                                                                          //
//                                                                                               //
//  Author: B.J. Porcella                                                                        //
//  e-mail: bporcella@sbcglobal.net                                                              //
//                                                                                               //
//                                                                                               //
//                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                               //
// Copyright (C) 2000-2002 B.J. Porcella                                                         //
//                         Real Time Solutions                                                   //
//                                                                                               //
//                                                                                               //
// This source file may be used and distributed without                                          //
// restriction provided that this copyright statement is not                                     //
// removed from the file and that any derivative work contains                                   //
// the original copyright notice and the associated disclaimer.                                  //
//                                                                                               //
//     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY                                       //
// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED                                     //
// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS                                     //
// FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR                                        //
// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,                                           //
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES                                      //
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE                                     //
// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR                                          //
// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF                                    //
// LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT                                    //
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT                                    //
// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE                                           //
// POSSIBILITY OF SUCH DAMAGE.                                                                   //
//                                                                                               //
//-------1---------2---------3--------Comments on file  -------------7---------8---------9--------0
//
// 
// Instructions may contain 1,2 or 3 bytes of "instruction" data.
// The state machine implemented here is responsible only for understanding
// that aspect of the instruction flow  ---  keeping the flow of instructions
// comming - differentiating instructions proper from immediate operands (XX).  
// and indicating to the execution logic when its time to execute an instruction.
//
// Instructions are considered 9 bits of data with 2 bits of "modifier"
// the Most significant Data bits ir[9:8]  are 01 for CB_grp, 10 for ED_grp;  
// The "modifiers" DD_grp, and FD_grp are sent as seperate signals  ( they are ignored by a lot
// of logic).  The modifiers change operation of normal instructions and the CB group.  They
// are never active whlie and ED_grp instruction is being executed.
//
//-------1---------2---------3--------CVS Log -----------------------7---------8---------9--------0
//
//  $Id: istate.v,v 1.1.1.1 2004-04-13 23:49:57 bporcella Exp $
//
//  $Date: 2004-04-13 23:49:57 $
//  $Revision: 1.1.1.1 $
//  $Author: bporcella $
//  $Locker:  $
//  $State: Exp $
//
// Change History:
//      $Log: not supported by cvs2svn $
//
//
//-------1---------2---------3--------Module Name and Port List------7---------8---------9--------0
module istate(ir1_x, xfer, dat_i, if_act, wb_ack, hazard, jmp, run, clk, rst);

//-------1---------2---------3--------Output Ports---------6---------7---------8---------9--------0

output  [10:0]  ir1_x;      // {3bit extension code, ir} 
output          ir1;
output          ir2;
output          ir1CB;  //  make these 1 hot should decode faster
output          ir2CB;
output          ir1ED;
output          ir2ED;
output          ir1DD;
output          ir2DD;
output          ir1FD;
output          ir2FD;
//-------1---------2---------3--------Input Ports----------6---------7---------8---------9--------0

input   [7:0]   dat_i;
input           if_act;    // if in progress
input           wb_ack ;  // memory xfer done.
input           hazard;    // refill pipeline - we just stored into a location already fetched
input           jmp;       // refill pipeline - jump negates instruction just fetched
                           // (includes call and ret)
input           run;       // execute instructions
input           clk;
input           rst;

//-------1---------2---------3--------Parameters-----------6---------7---------8---------9--------0

//bj  -  think through issues of 11 vs 8 bits here...   don't think the synthesizer can get it right
//all the time.
`include  "opcodes.v"      // description of ALL opcodes

parameter   IF_IDLE     = 3'h0,  
            IF_IR_MT    = 3'h1,   // we are active...  start fetching new insts
            IF_IR_NEW   = 3'h2,   // first byte of a new inst is active.
            IF_I2       = 3'h3,   // we now know this is at least a 2 byte instruction
            IF_N2       = 3'h4,   // go here for 16 bit immediates
            IF_N1       = 3'h5,   // go here for last 8 bits of immediates
            IF_I3       = 3'h6,   // go here for 3 byte instructions
            IF_N_I3     = 3'h7;   // 3 byte instructions with an immediate offset here.
            
parameter   SET_STD     = 3'h0,    // this state machine is closly related to above - IR extension
            SET_CB      = 3'h1,
            SET_DD      = 3'h2,
            SET_DDCB    = 3'h3,
            SET_ED      = 3'h4,
            SET_FD      = 3'h5,
            SET_FDCB    = 3'h6;

//-------1---------2---------3--------Wires----------------6---------7---------8---------9--------0
wire    ir_wait;
wire    dec_i2;
wire    dec_n2;
wire    dec_n1;

wire    dec_i2n2;  // decoded from 2nd instruction
wire    dec_i2n1;  // decoded from 2nd instruction
wire    dec_ni3;   // decoded from 2nd instruction  the immediate operand comes before the last I
wire    xfer;
wire    if_i2_done;
wire    rd_n2;
wire    rd_n1;
//-------1---------2---------3--------Registers------------6---------7---------8---------9--------0

reg [2:0]   if_state;
reg [2:0]   ir_grp;
reg [7:0]   ir;

//-------1---------2---------3--------Assignments----------6---------7---------8---------9--------0
assign rd_n2 = ( if_state == IF_N2 );
assign rd_n1 = ( if_state == IF_N1 );

assign ir1_x = { ir_grp, ir};

assign exec = ( if_state == IF_N1    ) |
              ( if_state == IF_I3    ) |
              ( if_i2_done           )  ;


assign if_i2_done = (if_state == IF_I2) & !( dec_i2n2 | dec_i2n1 | dec_ni3);


assign dec_i2 = (ir == CBgrp) | 
                (ir == DDgrp) |
                (ir == EDgrp) |
                (ir == FDgrp) ;
                
assign dec_n1 = (ir == LDsB_N    ) |  
                (ir == LDsC_N    ) |  (ir == LDsA_N    ) |
                (ir == LDsD_N    ) |  (ir == ADDsA_N   ) |
                (ir == LDsE_N    ) |  (ir == ADCsA_N   ) |
                (ir == LDsH_N    ) |  (ir == OUTs6N7_A ) |
                (ir == LDsL_N    ) |  (ir == SUBsN     ) |
                (ir == LDs6HL7_N ) |  (ir == INsA_6N7  ) ;
                                           
assign dec_n2   (ir == LDsBC_NN    ) |  (ir == LDsA_6NN7   ) |
                (ir == LDsDE_NN    ) |  (ir == CALLsNZ_NN  ) |
                (ir == LDsHL_NN    ) |  (ir == CALLsZ_NN   ) |
                (ir == LDs6NN7_HL  ) |  (ir == CALLsNN     ) |
                (ir == LDsHL_6NN7  ) |  (ir == CALLsNC_NN  ) |
                (ir == LDsSP_NN    ) |  (ir == CALLsNC_NN  ) |
                (ir == LDs6NN7_A   ) |  (ir == CALLsC_NN   ) ;
                
assign dec i2n1=
    (ir == INCs6IXtN7  ) | (ir == INCs6IYtN7 ) | (ir == LDs6IXtN7_H ) | (ir == LDs6IYtN7_H ) |
    (ir == DECs6IXtN7  ) | (ir == DECs6IYtN7 ) | (ir == LDs6IXtN7_L ) | (ir == LDs6IYtN7_L ) |
    (ir == LDsB_6IXtN7 ) | (ir == LDsB_6IYtN7) | (ir == LDs6IXtN7_A ) | (ir == LDs6IYtN7_A ) |
    (ir == LDsC_6IXtN7 ) | (ir == LDsC_6IYtN7) | (ir == LDsA_6IXtN7 ) | (ir == LDsA_6IYtN7 ) |
    (ir == LDsD_6IXtN7 ) | (ir == LDsD_6IYtN7) | (ir == ADDsA_6IXtN7) | (ir == ADDsA_6IYtN7) |
    (ir == LDsE_6IXtN7 ) | (ir == LDsE_6IYtN7) | (ir == ADCsA_6IXtN7) | (ir == ADCsA_6IYtN7) |
    (ir == LDsH_6IXtN7 ) | (ir == LDsH_6IYtN7) | (ir == SUBs6IXtN7  ) | (ir == SUBs6IYtN7  ) |
    (ir == LDsL_6IXtN7 ) | (ir == LDsL_6IYtN7) | (ir == SBCsA_6IXtN7) | (ir == SBCsA_6IYtN7) |
    (ir == LDs6IXtN7_B ) | (ir == LDs6IYtN7_B) | (ir == ANDs6IXtN7  ) | (ir == ANDs6IYtN7  ) |
    (ir == LDs6IXtN7_C ) | (ir == LDs6IYtN7_C) | (ir == XORs6IXtN7  ) | (ir == XORs6IYtN7  ) |
    (ir == LDs6IXtN7_D ) | (ir == LDs6IYtN7_D) | (ir == ORs6IXtN7   ) | (ir == ORs6IYtN7   ) |
    (ir == LDs6IXtN7_E ) | (ir == LDs6IYtN7_E) | (ir == CPs6IXtN7   ) | (ir == CPs6IYtN7   ) ;
                 
assign dec_i2n2 = (ir == LDsIX_NN     ) |   (ir == LDsDE_6NN7   ) |                   
                  (ir == LDs6NN7_IX   ) |   (ir == LDs6NN7_SP   ) |         
                  (ir == LDsIX_6NN7   ) |   (ir == LDsSP_6NN7   ) |         
                  (ir == LDs6IXtN7_N  ) |   (ir == LDsIY_NN     ) |         
                  (ir == LDs6NN7_BC   ) |   (ir == LDs6NN7_IY   ) |         
                  (ir == LDsBC_6NN7   ) |   (ir == LDsIY_6NN7   ) |         
                  (ir == LDs6NN7_DE   ) |   (ir == LDs6IYtN7_N  ) ;        
                     
assign dec_ni3 = (ir == FDCBgrp) | | (ir == DDCBgrp) ;                     
                     

assign i_rdy = if_act & wb_ack;

//-------1---------2---------3--------State Machines-------6---------7---------8---------9--------0

//  note run - like reset gets the machine to IDLE --  but in a more orderly fasion.
//
the hazard terms are not correct.   should go frm IF_NEW to IF_MT
always @(posedge clk or posedge rst)
begin
    if (rst )                 if_state <= IF_IDLE;
    else if (i_rdy)
    begin
        case (if_state)
        IF_IDLE   : if (run)    if_state <= IF_IR_MT;
        IF_IRMT   : if (run)    if_state <= IF_IR_NEW;
                    else        if_state <= IF_IDLE;
        IF_IR_NEW : if (run) 
                    begin  
                        if (dec_i2) if_state <= IF_I2;
                        if (dec_n2) if_state <= IF_N2;
                        if (dec_n1) if_state <= IF_N1;
                    end
                    else            if_state <= IF_IDLE; 
        IF_I2     : begin  
                        if (dec_i2n2)      if_state <= IF_N2;
                        else if (dec_i2n1) if_state <= IF_N1;
                        else if (dec_ni3 ) if_state <= IF_N_I3;
                        else if (hazard  ) if_state <= IF_MT;
                        else               if_state <= IF_IR_NEW;
                    end
                    else    if_state <= IF_IDLE;        
        IF_N2     :        if_state <= IF_N1;
        IF_N1     :       if_state <= hazard ? IF_MT : IF_IR_NEW;
        IF_I3     :      if_state <= hazard ? IF_MT : IF_IR_NEW;
        IF_N_I3   :     if_state <= hazard ? IF_MT : IF_IR_NEW;
        default:       if_state <= IF_IDLE;
        endcase
    end
end    

always @(posedge clk or posedge rst)
    if (rst )                 ir <= NOP;
    else if (!ir_wait)
        if (( if_state == IF_IR_MT ) | 
            ( if_state == IF_N1    ) |
            ( if_state == IF_I3    ) |
            ( if_i2_done           )   ) ir <= dat_i;

always @(posedge clk or posedge rst)        
    if (rst )   ir_grp <= SET_STD;
    else if (!ir_wait)
    begin
        if (( if_state == IF_IR_MT ) |     // alwaya clear on entry to IR+NEW
            ( if_state == IF_N1    ) |
            ( if_state == IF_I3    ) |
            ( if_i2_done           )   ) ir_grp <= SET_STD;
        if  (if_state == IF_IR_NEW)
        begin
            if (ir == CBgrp )   ir_grp <= SET_CB;
            if (ir == DDgrp )   ir_grp <= SET_DD;
            if (ir == EDgrp )   ir_grp <= SET_ED;
            if (ir == FDgrp )   ir_grp <= SET_FD;
        end
        if  (if_state == IF_IR_NEW)
        begin
            if (ir == DDCBgrp ) ir_grp <= SET_DDCB;
            if (ir == FDCBgrp ) ir_grp <= SET_FDCB;
        end
        
    end

endmodule