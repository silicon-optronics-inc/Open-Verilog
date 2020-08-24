// +FHDR -----------------------------------------------------------------------
// Copyright (c) Silicon Optronics. Inc. 2020
//
// File Name:           ip_vtm_rtl.v
// Author:              Humphrey Lin
//
// File Description:    1. Native video timing generator
// -FHDR -----------------------------------------------------------------------

module vtm

#(
parameter[ 4:0]                 VSYNC           = 2,        // unit: 0.25(HWIN+HBLK); max: 32*0.25
parameter[ 4:0]                 FVBLK           = 4,        // unit: 0.25(HWIN+HBLK): max: 32*0.25
parameter                       HWIN            = 640,      // unit: pixel clock
parameter                       HBLK            = 160,      // unit: pixel clock
parameter                       VWIN            = 480,      // unit: HWIN+HBLK
parameter[ 4:0]                 BVBLK           = 4,        // unit: 0.25(HWIN+HBLK): max: 32*0.25

parameter                       FLEX_HBLK       = "FALSE"   // "TRUE": flexible h-blank length
 )

(
//----------------------------------------------------------//
// Native video output interface                            //
//----------------------------------------------------------//
output                          o_fstr,                     //
output                          o_fend,                     //
output                          o_vsyn,                     //
output                          o_vstr,                     //
output                          o_vend,                     //
output                          o_vref,                     //
output                          o_hstr,                     //
output                          o_hend,                     //
output                          o_href,                     //

//----------------------------------------------------------//
// Common interface                                         //
//----------------------------------------------------------//
input                           i_vtm_en,                   // video timing generator enable
input                           i_vtm_pau,                  // pause vtim during h-blank for "FLEX_HBLK"

input                           pclk,                       // pclk for input data domain
input                           prst_n                      // reset @pclk clock domain
);

//----------------------------------------------------------//
// Local Parameter                                          //
//----------------------------------------------------------//

localparam              XWID            = log2(HWIN);
localparam[XWID  :0]    IMG_HWIN        = HWIN;
localparam              YWID            = log2(VWIN);
localparam[YWID  :0]    IMG_VWIN        = VWIN;
localparam              HWID            = log2(HBLK);
localparam[HWID  :0]    IMG_HBLK        = HBLK;

localparam              QHWIN           = (HWIN + HBLK) >> 2;
localparam              QWID            = log2(QHWIN);
localparam[QWID  :0]    IMG_QHWIN       = QHWIN;

localparam              CWID            = XWID > YWID ? XWID : YWID;

localparam[11:0]        VTM_IDLE        = 12'b0000_0000_0000,
                        VTM_VSYN        = 12'b0000_0000_0001,
                        VTM_FSTR        = 12'b0000_0000_0011,
                        VTM_FVBLK       = 12'b0000_0000_0100,
                        VTM_VSTR        = 12'b0000_1000_1100,
                        VTM_HACT        = 12'b0001_0001_0000,
                        VTM_HEND        = 12'b0001_0011_0000,
                        VTM_HBLK        = 12'b0001_0100_0000,
                        VTM_HSTR        = 12'b0001_1100_0000,
                        VTM_VEND        = 12'b0011_0011_0000,
                        VTM_HBLK_LAST   = 12'b0001_0000_0000,
                        VTM_PRE_BVBLK   = 12'b0001_1000_0000,
                        VTM_BVBLK       = 12'b0100_0000_0000,
                        VTM_FEND        = 12'b1100_0000_0000;


//----------------------------------------------------------//
// REG/Wire declaration                                     //
//----------------------------------------------------------//

reg [11:0]              vtm_cs;
reg [11:0]              vtm_ns;
wire                    vsyn_csm;
wire                    fstr_csm;
wire                    fvblk_csm;
wire                    vstr_csm;
wire                    hact_csm;
wire                    hend_csm;
wire                    hblk_csm;
wire                    hstr_csm;
wire                    vact_csm;
wire                    vend_csm;
wire                    bvblk_csm;
wire                    fend_csm;

wire                    x_cnt_inc;
wire                    x_cnt_clr;
wire[CWID-1:0]          x_cnt_nxt;
reg [CWID-1:0]          x_cnt;
wire                    y_cnt_inc;
wire                    y_cnt_clr;
wire[CWID-1:0]          y_cnt_nxt;
reg [CWID-1:0]          y_cnt;
wire[CWID-1:0]          xy_cnt;

wire                    fm_cnt_inc;
wire                    fm_cnt_clr;
wire[ 7:0]              fm_cnt_nxt;
reg [ 7:0]              fm_cnt;

wire                    vsyn_len_eq;
wire                    fvblk_len_eq;
wire                    hwin_len_eq;
wire                    vwin_len_eq;
wire                    hblk_len_eq;
wire                    bvblk_len_eq;
wire                    qhwin_len_eq;

//----------------------------------------------------------//
// Code Descriptions                                        //
//----------------------------------------------------------//

assign  o_vsyn    = vsyn_csm;
assign  o_fstr    = fstr_csm;
assign  o_fend    = fend_csm;

assign  o_vstr    = vstr_csm;
assign  o_vend    = vend_csm;
assign  o_vref    = vact_csm;

assign  o_hstr    = hstr_csm & (fvblk_csm | hblk_csm);
assign  o_hend    = hend_csm;
assign  o_href    = hact_csm;

// H-/V-counter
assign  x_cnt_inc  = vtm_cs != VTM_IDLE & ~(FLEX_HBLK == "TRUE" & (hblk_csm & i_vtm_pau));
assign  y_cnt_inc  = qhwin_len_eq | (vact_csm & hend_csm);

assign  x_cnt_clr  = qhwin_len_eq | hstr_csm | hend_csm | fend_csm;
assign  y_cnt_clr  = fstr_csm | vstr_csm | vend_csm | fend_csm;

assign  x_cnt_nxt  = (x_cnt_inc ? xy_cnt : x_cnt) & {CWID{~x_cnt_clr}};
assign  y_cnt_nxt  = (y_cnt_inc ? xy_cnt : y_cnt) & {CWID{~y_cnt_clr}};

assign  xy_cnt     = (y_cnt_inc ? y_cnt : x_cnt) + 1'b1;

assign  vsyn_len_eq  = y_cnt == VSYNC-1 && x_cnt == IMG_QHWIN-2;
assign  fvblk_len_eq = y_cnt == FVBLK-1 && x_cnt == IMG_QHWIN-2;
assign  hwin_len_eq  = x_cnt == IMG_HWIN-2;
assign  vwin_len_eq  = y_cnt == IMG_VWIN-1;
assign  hblk_len_eq  = x_cnt == IMG_HBLK-2;
assign  bvblk_len_eq = y_cnt == BVBLK-1 && x_cnt == IMG_QHWIN-2;
assign  qhwin_len_eq = x_cnt == QHWIN-1 & (vsyn_csm | fvblk_csm | bvblk_csm);


// frame counter. No load, only used for debug
assign  fm_cnt_inc = fend_csm;
assign  fm_cnt_clr = ~i_vtm_en;
assign  fm_cnt_nxt = (fm_cnt_inc ? fm_cnt + 1'b1 : fm_cnt) & {8{~fm_cnt_clr}};

// State machine
// ---------------------------

assign  vsyn_csm  = vtm_cs[ 0];
assign  fstr_csm  = vtm_cs[ 1];
assign  fvblk_csm = vtm_cs[ 2];
assign  vstr_csm  = vtm_cs[ 3];
assign  hact_csm  = vtm_cs[ 4];
assign  hend_csm  = vtm_cs[ 5];
assign  hblk_csm  = vtm_cs[ 6];
assign  hstr_csm  = vtm_cs[ 7];
assign  vact_csm  = vtm_cs[ 8];
assign  vend_csm  = vtm_cs[ 9];
assign  bvblk_csm = vtm_cs[10];
assign  fend_csm  = vtm_cs[11];


always @* begin: VTM_FSM

   vtm_ns = vtm_cs;

   case (vtm_cs)

   VTM_IDLE:
     if (i_vtm_en)
        vtm_ns = VTM_VSYN;

   VTM_VSYN:
     if (vsyn_len_eq)
        vtm_ns = VTM_FSTR;

   VTM_FSTR:
        vtm_ns = VTM_FVBLK;

   VTM_FVBLK:
     if (fvblk_len_eq)
        vtm_ns = VTM_VSTR;

   VTM_VSTR:
        vtm_ns = VTM_HACT;

   VTM_HSTR:
        vtm_ns = VTM_HACT;

   VTM_HACT:
     if (hwin_len_eq)
        vtm_ns = vwin_len_eq ? VTM_VEND : VTM_HEND;

   VTM_HEND:
        vtm_ns = VTM_HBLK;

   VTM_VEND:
        vtm_ns = VTM_HBLK_LAST;

   VTM_HBLK:
     if (hblk_len_eq)
        vtm_ns = VTM_HSTR;

   VTM_HBLK_LAST:
     if (hblk_len_eq)
        vtm_ns = VTM_PRE_BVBLK;

   VTM_PRE_BVBLK:
        vtm_ns = VTM_BVBLK;

   VTM_BVBLK:
     if (bvblk_len_eq)
        vtm_ns = VTM_FEND;

   VTM_FEND:
     if(i_vtm_en)
         vtm_ns = VTM_VSYN;
     else
         vtm_ns = VTM_IDLE;

   endcase
end

`always_ff(pclk, prst_n) begin
   if (~prst_n)
      vtm_cs        <= VTM_IDLE;
   else
      vtm_cs        <= vtm_ns;
end


// Sequential Logic
// -----------------------------------------------

`always_ff(pclk, prst_n) begin
   if(~prst_n) begin
      x_cnt         <= 0;
      y_cnt         <= 0;
      fm_cnt        <= 0;
   end
   else begin
      x_cnt         <= x_cnt_nxt;
      y_cnt         <= y_cnt_nxt;
      fm_cnt        <= fm_cnt_nxt;
   end
end


// Function
// -----------------------------------------------

function integer log2;
   input integer value;
   begin
      log2 = 0;
      while (2**log2 < value)
         log2 = log2 + 1;
   end
endfunction


endmodule
