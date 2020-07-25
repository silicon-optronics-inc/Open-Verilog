// +FHDR -----------------------------------------------------------------------
// Copyright (c) Silicon Optronics. Inc. 2015
//
// File Name:           pgl_ctrl_rtl.v
// Author:              Humphrey Lin
// Version:             $Revision$
// Last Modified On:    $Date$
// Last Modified By:    $Author$
//
// File Description:    Parking Guideline control module
//
// Clock Domain:
// -FHDR -----------------------------------------------------------------------

module  pgl_ctrl

    #(
      parameter             XWID        = 10,
      parameter             YWID        = 10,
      parameter             PGL_SEG     = 10
     )
(
//----------------------------------------------//
// Output declaration                           //
//----------------------------------------------//
output                      pgl_vstr_o,         //
output                      pgl_vend_o,         //
output                      pgl_hstr_o,         //
output                      pgl_hend_o,         //
output                      pgl_dvld_o,         //

output reg  [ 8:0]          pgl2cu_trg,         // PGL-to-CU trigger
output                      pgl_vld_lft,        // PGL valid @ left
output                      pgl_vld_rgt,        // PGL valid @ right
output                      pgl_vld_ctr,        // PGL valid @ center
output                      pgl_edge,           // PGL line edge indication
output reg  [ 1:0]          pgl_colr_lft,       // PGL segment color index @ left
output reg  [ 1:0]          pgl_colr_rgt,       // PGL segment color index @ right
output reg  [ 1:0]          pgl_type_lft,       // PGL segment type @ left
output reg  [ 1:0]          pgl_type_rgt,       // PGL segment type @ right
output      [ 5:0]          pgl_wwg_mul,        // PGL width weighting multiplier
output      [ 8:0]          pgl_wid_bs_lft,     // PGL width base @ left
output      [ 8:0]          pgl_wid_bs_rgt,     // PGL width base @ right
output      [ 9:0]          pgl_wwg_lft,        // PGL width weighting @ left
output      [ 9:0]          pgl_wwg_rgt,        // PGL width weighting @ right
output      [ 7:0]          pgl_ystr_lft,       // PGL y-start point for current segment @ left
output      [ 7:0]          pgl_ystr_rgt,       // PGL y-start point for current segment @ right
output      [ 5:0]          pgl_h_lft,          // PGL height for current segment @ left
output      [ 5:0]          pgl_h_rgt,          // PGL height for current segment @ right
output reg  [XWID-1:0]      pgl_hcnt,           // PGL h-counter
output reg  [YWID-1:0]      pgl_vcnt,           // PGL v-counter


//----------------------------------------------//
// Input declaration                            //
//----------------------------------------------//

input                       pgl_fstr_i,         //
input                       pgl_vstr_i,         //
input                       pgl_vend_i,         //
input                       pgl_hstr_i,         //
input                       pgl_hend_i,         //
input                       pgl_dvld_i,         //

input       [ 8:0]          cu2pgl_tsk_end,     // from CU, end of task

input       [ 8:0]          cu_pgl_hln0_wid,    // PGL line width of horizontal type 0
input       [ 8:0]          cu_pgl_hln1_wid,    // PGL line width of horizontal type 1
input       [ 9:0]          cu_pgl_hwwg_lft,    // width weighting of horizontal type on left line
input       [ 9:0]          cu_pgl_hwwg_rgt,    // width weighting of horizontal type on right line

input                       cu_y0_lft_csgb,     // comparing sign bit: sign(y_p1 - reg_pgl_ystr0_lft)
input                       cu_ystr_lft_csgb,   // comparing sign bit: sign(y_p1 - cu_ystr_lft)
input                       cu_ystr_lft_eq,     // y_p1 == cu_ystr_lft
input                       cu_yend_lft_csgb,   // comparing sign bit: sign(y_p1 - cu_yend_lft)
input                       cu_y0_lft_eq,       // y_p1 == start point of left line, reg_pgl_ystr0_lft
input                       cu_yend_lft_eq,     // y_p1 == end point of current segment @ left

input                       cu_y0_rgt_csgb,     // comparing sign bit: sign(y_p1 - reg_pgl_ystr0_rgt)
input                       cu_ystr_rgt_csgb,   // comparing sign bit: sign(y_p1 - cu_ystr_rgt)
input                       cu_ystr_rgt_eq,     // y_p1 == cu_ystr_rgt
input                       cu_yend_rgt_csgb,   // comparing sign bit: sign(y_p1 - cu_yend_rgt)
input                       cu_y0_rgt_eq,       // y_p1 == start point of left line, reg_pgl_ystr0_rgt
input                       cu_yend_rgt_eq,     // y_p1 == end point of current segment @ left

input                       cu_y0_ctr_csgb,     // comparing sign bit: sign(y_p1 - reg_pgl_ystr_ctr)
input                       cu_ystr_ctr_csgb,   // comparing sign bit: sign(y_p1 - cu_ystr_ctr)
input                       cu_yend_ctr_csgb,   // comparing sign bit: sign(y_p1 - cu_yend_ctr)
input                       cu_ystr_ctr_eq,     // y_p1 == start point of current segment @ center
input                       cu_yend_ctr_eq,     // y_p1 == end point of current segment @ center
input                       cu_vend_ctr_csgb,   // sign(y_p1 - reg_pgl_vend_ctr )

input       [ 9:0]          cu_xstr_lft,        // x-start point @ left
input       [ 9:0]          cu_xstr_a1_lft,     // x-start point+1 @ left
input       [ 9:0]          cu_xend_lft,        // x-end point @ left
input       [ 9:0]          cu_xend_a1_lft,     // x-end point @+1 left
input       [ 9:0]          cu_xstr_rgt,        // x-start point @ right
input       [ 9:0]          cu_xstr_a1_rgt,     // x-start point+1 @ right
input       [ 9:0]          cu_xend_rgt,        // x-end point @ right
input       [ 9:0]          cu_xend_a1_rgt,     // x-end point+1 @ right
input       [ 8:0]          cu_xstr_ctr,        // x-start point @ center
input       [ 8:0]          cu_xstr_a1_ctr,     // x-start point+1 @ center
input       [ 8:0]          cu_xend_ctr,        // x-end point @ center
input       [ 8:0]          cu_xend_a1_ctr,     // x-end point+1 @ center

input       [ 7:0]          reg_pgl_ystr0_lft,  // PGL Y-start point for segment 0 @ left
input       [ 7:0]          reg_pgl_ystr1_lft,  // PGL Y-start point for segment 1 @ left
input       [ 7:0]          reg_pgl_ystr2_lft,  // PGL Y-start point for segment 2 @ left
input       [ 7:0]          reg_pgl_ystr3_lft,  // PGL Y-start point for segment 3 @ left
input       [ 7:0]          reg_pgl_ystr4_lft,  // PGL Y-start point for segment 4 @ left
input       [ 7:0]          reg_pgl_ystr5_lft,  // PGL Y-start point for segment 5 @ left
input       [ 7:0]          reg_pgl_ystr6_lft,  // PGL Y-start point for segment 6 @ left
input       [ 7:0]          reg_pgl_ystr7_lft,  // PGL Y-start point for segment 7 @ left
input       [ 7:0]          reg_pgl_ystr8_lft,  // PGL Y-start point for segment 8 @ left
input       [ 7:0]          reg_pgl_ystr9_lft,  // PGL Y-start point for segment 9 @ left

input       [ 5:0]          reg_pgl_h0_lft,     // PGL height for segment 0 @ left
input       [ 5:0]          reg_pgl_h1_lft,     // PGL height for segment 1 @ left
input       [ 5:0]          reg_pgl_h2_lft,     // PGL height for segment 2 @ left
input       [ 5:0]          reg_pgl_h3_lft,     // PGL height for segment 3 @ left
input       [ 5:0]          reg_pgl_h4_lft,     // PGL height for segment 4 @ left
input       [ 5:0]          reg_pgl_h5_lft,     // PGL height for segment 5 @ left
input       [ 5:0]          reg_pgl_h6_lft,     // PGL height for segment 6 @ left
input       [ 5:0]          reg_pgl_h7_lft,     // PGL height for segment 7 @ left
input       [ 5:0]          reg_pgl_h8_lft,     // PGL height for segment 8 @ left
input       [ 5:0]          reg_pgl_h9_lft,     // PGL height for segment 9 @ left

input       [ 3:0]          reg_pgl_wwg_lft,    // PGL width weighting @ left

input       [ 7:0]          reg_pgl_ystr0_rgt,  // PGL Y-start point for segment 0 @ right
input       [ 7:0]          reg_pgl_ystr1_rgt,  // PGL Y-start point for segment 1 @ right
input       [ 7:0]          reg_pgl_ystr2_rgt,  // PGL Y-start point for segment 2 @ right
input       [ 7:0]          reg_pgl_ystr3_rgt,  // PGL Y-start point for segment 3 @ right
input       [ 7:0]          reg_pgl_ystr4_rgt,  // PGL Y-start point for segment 4 @ right
input       [ 7:0]          reg_pgl_ystr5_rgt,  // PGL Y-start point for segment 5 @ right
input       [ 7:0]          reg_pgl_ystr6_rgt,  // PGL Y-start point for segment 6 @ right
input       [ 7:0]          reg_pgl_ystr7_rgt,  // PGL Y-start point for segment 7 @ right
input       [ 7:0]          reg_pgl_ystr8_rgt,  // PGL Y-start point for segment 8 @ right
input       [ 7:0]          reg_pgl_ystr9_rgt,  // PGL Y-start point for segment 9 @ right

input       [ 5:0]          reg_pgl_h0_rgt,     // PGL height for segment 0 @ right
input       [ 5:0]          reg_pgl_h1_rgt,     // PGL height for segment 1 @ right
input       [ 5:0]          reg_pgl_h2_rgt,     // PGL height for segment 2 @ right
input       [ 5:0]          reg_pgl_h3_rgt,     // PGL height for segment 3 @ right
input       [ 5:0]          reg_pgl_h4_rgt,     // PGL height for segment 4 @ right
input       [ 5:0]          reg_pgl_h5_rgt,     // PGL height for segment 5 @ right
input       [ 5:0]          reg_pgl_h6_rgt,     // PGL height for segment 6 @ right
input       [ 5:0]          reg_pgl_h7_rgt,     // PGL height for segment 7 @ right
input       [ 5:0]          reg_pgl_h8_rgt,     // PGL height for segment 8 @ right
input       [ 5:0]          reg_pgl_h9_rgt,     // PGL height for segment 9 @ right

input       [ 3:0]          reg_pgl_wwg_rgt,    // PGL width weighting @ right

input       [ 1:0]          reg_pgl_type0,      // PGL segment 0 type
input       [ 1:0]          reg_pgl_type1,      // PGL segment 1 type
input       [ 1:0]          reg_pgl_type2,      // PGL segment 2 type
input       [ 1:0]          reg_pgl_type3,      // PGL segment 3 type
input       [ 1:0]          reg_pgl_type4,      // PGL segment 4 type
input       [ 1:0]          reg_pgl_type5,      // PGL segment 5 type
input       [ 1:0]          reg_pgl_type6,      // PGL segment 6 type
input       [ 1:0]          reg_pgl_type7,      // PGL segment 7 type
input       [ 1:0]          reg_pgl_type8,      // PGL segment 8 type
input       [ 1:0]          reg_pgl_type9,      // PGL segment 9 type

input       [ 1:0]          reg_pgl_colr0,      // PGL segment 0 color
input       [ 1:0]          reg_pgl_colr1,      // PGL segment 1 color
input       [ 1:0]          reg_pgl_colr2,      // PGL segment 2 color
input       [ 1:0]          reg_pgl_colr3,      // PGL segment 3 color
input       [ 1:0]          reg_pgl_colr4,      // PGL segment 4 color
input       [ 1:0]          reg_pgl_colr5,      // PGL segment 5 color
input       [ 1:0]          reg_pgl_colr6,      // PGL segment 6 color
input       [ 1:0]          reg_pgl_colr7,      // PGL segment 7 color
input       [ 1:0]          reg_pgl_colr8,      // PGL segment 8 color
input       [ 1:0]          reg_pgl_colr9,      // PGL segment 9 color

input                       reg_pgl_en,         // PGL enable
input                       reg_pgl_hwwg_opt,   // PGL horizontal-type line width weighting option
input       [ 5:0]          reg_pgl_vln_wid,    // PGL line with for vertical type line
input       [ 1:0]          reg_pgl_type_ctr,   // PGL line type @ center
input                       reg_pgl_evw_lim,    // PGL even width limitation
input                       reg_pgl_kill_lft,   // Erase left PGL
input                       reg_pgl_kill_rgt,   // Erase right PGL

input                       pclk,               // pixel clock
input                       prst_n              // low active reset for pclk domain
);

//----------------------------------------------//
// Local Parameter                              //
//----------------------------------------------//

//----------------------------------------------//
// Register declaration                         //
//----------------------------------------------//
reg         [ 1:0]          pgl_vstr_que;       //
reg         [ 1:0]          pgl_vend_que;       //
reg         [ 1:0]          pgl_hstr_que;       //
reg         [ 1:0]          pgl_hend_que;       //
reg         [ 1:0]          pgl_dvld_que;       //
reg                         ystr_lft_eq;        //
reg                         ystr_lft_csgb;      // comparing sign bit: sign(y_p1 - cu_ystr_lft)
reg                         yend_lft_csgb;      // comparing sign bit: sign(y_p1 - cu_yend_lft)
reg                         ystr_rgt_eq;        //
reg                         ystr_rgt_csgb;      // comparing sign bit: sign(y_p1 - cu_ystr_rgt)
reg                         yend_rgt_csgb;      // comparing sign bit: sign(y_p1 - cu_yend_rgt)
reg                         y0_ctr_csgb;        // comparing sign bit: sign(y_p1 - reg_pgl_ystr_ctr)
reg                         ystr_ctr_csgb;      // comparing sign bit: sign(y_p1 - cu_ystr_ctr)
reg                         yend_ctr_csgb;      // comparing sign bit: sign(y_p1 - cu_yend_ctr)
reg                         vend_ctr_csgb;      // comparing sign bit: sign(y_p1 - reg_pgl_vend_ctr )
reg         [ 9:0]          xstr_lft;           // x-start point @ left
reg         [ 9:0]          xstr_a1_lft;        // x-start point+1 @ left
reg         [ 9:0]          xend_lft;           // x-end point @ left
reg         [ 9:0]          xend_s1_lft;        // x-end point-1 @ left
reg         [ 9:0]          xstr_rgt;           // x-start point @ right
reg         [ 9:0]          xstr_a1_rgt;        // x-start point+1 @ right
reg         [ 9:0]          xend_rgt;           // x-end point @ right
reg         [ 9:0]          xend_s1_rgt;        // x-end point-1 @ right
reg         [ 8:0]          xstr_ctr;           // x-start point @ center
reg         [ 8:0]          xstr_a1_ctr;        // x-start point+1 @ center
reg         [ 8:0]          xend_ctr;           // x-end point @ center
reg         [ 8:0]          xend_s1_ctr;        // x-end point-1 @ center
reg         [PGL_SEG-1:0]   pgl_seg_lft;        // PGL dash-segment index @ left
reg         [PGL_SEG-1:0]   pgl_seg_rgt;        // PGL dash-segment index @ right
reg         [ 1:0]          ln_type_lft;        // line type @ left; not buffering by hend
reg         [ 1:0]          ln_type_rgt;        // line type @ right; not buffering by hend
reg                         cutrg5_flg;         // to CU task 5 flag
reg                         cutrg6_flg;         // to CU task 6 flag
reg                         pgl_vstr_i_q1;
reg                         pgl_dvld_i_q1;
reg                         cu2pgl_tsk4_end_q1;
reg                         cu2pgl_tsk4_end_q2;
reg                         cu2pgl_tsk5_end_q1;

wire        [ 1:0]          pgl_vstr_que_nxt;   //
wire        [ 1:0]          pgl_vend_que_nxt;   //
wire        [ 1:0]          pgl_hstr_que_nxt;   //
wire        [ 1:0]          pgl_hend_que_nxt;   //
wire        [ 1:0]          pgl_dvld_que_nxt;   //

wire        [ 1:0]          pgl_type_lft_nxt;   //
wire        [ 1:0]          pgl_type_rgt_nxt;   //
wire        [ 1:0]          pgl_colr_lft_nxt;   //
wire        [ 1:0]          pgl_colr_rgt_nxt;   //
wire        [XWID-1:0]      pgl_hcnt_nxt;       //
wire        [YWID-1:0]      pgl_vcnt_nxt;       //
wire        [ 8:0]          pgl2cu_trg_nxt;     //

wire                        ystr_lft_eq_nxt;    //
wire                        ystr_lft_csgb_nxt;  //
wire                        yend_lft_csgb_nxt;  //
wire                        ystr_rgt_eq_nxt;    //
wire                        ystr_rgt_csgb_nxt;  //
wire                        yend_rgt_csgb_nxt;  //
wire                        y0_ctr_csgb_nxt;    //
wire                        ystr_ctr_csgb_nxt;  //
wire                        yend_ctr_csgb_nxt;  //
wire                        vend_ctr_csgb_nxt;  //
wire        [ 9:0]          xstr_lft_nxt;       //
wire        [ 9:0]          xstr_a1_lft_nxt;    //
wire        [ 9:0]          xend_lft_nxt;       //
wire        [ 9:0]          xend_s1_lft_nxt;    //
wire        [ 9:0]          xstr_rgt_nxt;       //
wire        [ 9:0]          xstr_a1_rgt_nxt;    //
wire        [ 9:0]          xend_rgt_nxt;       //
wire        [ 9:0]          xend_s1_rgt_nxt;    //
wire        [ 8:0]          xstr_ctr_nxt;       //
wire        [ 8:0]          xstr_a1_ctr_nxt;    //
wire        [ 8:0]          xend_ctr_nxt;       //
wire        [ 8:0]          xend_s1_ctr_nxt;    //
wire        [PGL_SEG-1:0]   pgl_seg_lft_nxt;    //
wire        [PGL_SEG-1:0]   pgl_seg_rgt_nxt;    //
wire        [ 1:0]          ln_type_lft_nxt;    //
wire        [ 1:0]          ln_type_rgt_nxt;    //
wire                        cutrg5_flg_nxt;     //
wire                        cutrg6_flg_nxt;     //

//----------------------------------------------//
// Wire declaration                             //
//----------------------------------------------//
wire        [XWID-1:0]      pgl_hvcnt;          // PGL h-/v-counter
wire        [XWID-1:0]      cnt_mux;            // counter mux between hcnt & vcnt
wire                        hcnt_inc;           // pgl_hcnt INC
wire                        hcnt_clr;           // pgl_hcnt CLR
wire                        vcnt_inc;           // pgl_vcnt INC
wire                        vcnt_clr;           // pgl_vcnt CLR
wire                        xstr_eq_lft;        // pgl_hcnt == xstr_lft
wire                        xstr_a1_eq_lft;     // pgl_hcnt == xstr_a1_lft
wire                        xend_eq_lft;        // pgl_hcnt == xend_lft
wire                        xend_s1_eq_lft;     // pgl_hcnt == xend_s1_lft
wire                        xstr_eq_rgt;        // pgl_hcnt == xstr_rgt
wire                        xstr_a1_eq_rgt;     // pgl_hcnt == xstr_a1_rgt
wire                        xend_eq_rgt;        // pgl_hcnt == xend_rgt
wire                        xend_s1_eq_rgt;     // pgl_hcnt == xend_s1_rgt
wire                        xstr_eq_ctr;        // pgl_hcnt == xstr_ctr
wire                        xstr_a1_eq_ctr;     // pgl_hcnt == xstr_a1_ctr
wire                        xend_eq_ctr;        // pgl_hcnt == xend_ctr
wire                        xend_s1_eq_ctr;     // pgl_hcnt == xend_s1_ctr
wire                        pgl_edge_lft;       // PGL line edge indication @ left
wire                        pgl_edge_rgt;       // PGL line edge indication @ right
wire                        pgl_edge_ctr;       // PGL line edge indication @ center

//----------------------------------------------//
// Code Descriptions                            //
//----------------------------------------------//
// sync, data vliad timing
assign  pgl_vstr_o = pgl_vstr_que[1];
assign  pgl_vend_o = pgl_vend_que[1];
assign  pgl_hstr_o = pgl_hstr_que[1];
assign  pgl_hend_o = pgl_hend_que[1];
assign  pgl_dvld_o = pgl_dvld_que[1];

assign  pgl_vstr_que_nxt = {pgl_vstr_que[0], pgl_vstr_i};
assign  pgl_vend_que_nxt = {pgl_vend_que[0], pgl_vend_i};
assign  pgl_hstr_que_nxt = {pgl_hstr_que[0], pgl_hstr_i};
assign  pgl_hend_que_nxt = {pgl_hend_que[0], pgl_hend_i};
assign  pgl_dvld_que_nxt = {pgl_dvld_que[0], pgl_dvld_i};

// H-/V-counter
assign  cnt_mux = pgl_hstr_i ? pgl_vcnt : pgl_hcnt;
assign  pgl_hvcnt = cnt_mux + 1'b1;

assign  hcnt_inc = pgl_dvld_i | pgl_dvld_i_q1;
assign  hcnt_clr = pgl_hstr_i | pgl_vstr_i_q1;
assign  pgl_hcnt_nxt = {XWID{~hcnt_clr}} & (hcnt_inc ? pgl_hvcnt : pgl_hcnt);

assign  vcnt_inc = pgl_hstr_i;
assign  vcnt_clr = pgl_vstr_i_q1;
assign  pgl_vcnt_nxt = {YWID{~vcnt_clr}} & (vcnt_inc ? pgl_hvcnt : pgl_vcnt);


// PGL valid range
// -----------------------------------------------
assign  xstr_eq_lft    = pgl_hcnt == xstr_lft;
assign  xstr_a1_eq_lft = pgl_hcnt == xstr_a1_lft;
assign  xend_eq_lft    = pgl_hcnt == xend_lft;
assign  xend_s1_eq_lft = pgl_hcnt == xend_s1_lft;

assign  xstr_eq_rgt    = pgl_hcnt == xstr_rgt;
assign  xstr_a1_eq_rgt = pgl_hcnt == xstr_a1_rgt;
assign  xend_eq_rgt    = pgl_hcnt == xend_rgt;
assign  xend_s1_eq_rgt = pgl_hcnt == xend_s1_rgt;

assign  xstr_eq_ctr    = pgl_hcnt == xstr_ctr;
assign  xstr_a1_eq_ctr = pgl_hcnt == xstr_a1_ctr;
assign  xend_eq_ctr    = pgl_hcnt == xend_ctr;
assign  xend_s1_eq_ctr = pgl_hcnt == xend_s1_ctr;

assign  pgl_edge_lft = ( (xstr_eq_lft    | (xend_eq_lft    & ~pgl_vld_rgt)) |
                        ((xstr_a1_eq_lft | (xend_s1_eq_lft & ~pgl_vld_rgt)) & reg_pgl_evw_lim)) & pgl_vld_lft;

assign  pgl_edge_rgt = ( ((xstr_eq_rgt    & ~pgl_vld_lft) | xend_eq_rgt   ) |
                        (((xstr_a1_eq_rgt & ~pgl_vld_lft) | xend_s1_eq_rgt) & reg_pgl_evw_lim)) & pgl_vld_rgt;

assign  pgl_edge_ctr = ( (xstr_eq_ctr    | xend_eq_ctr   ) |
                        ((xstr_a1_eq_ctr | xend_s1_eq_ctr) & reg_pgl_evw_lim)) & pgl_vld_ctr;

assign  pgl_edge = pgl_edge_lft | pgl_edge_rgt | pgl_edge_ctr;

assign  pgl_vld_lft = ~reg_pgl_kill_lft & (pgl_type_lft != 0) &
                      ~ystr_lft_csgb & (yend_lft_csgb | ystr_lft_eq) &
                      (pgl_hcnt >= xstr_lft) & ((pgl_hcnt < xend_lft) | xend_eq_lft);

assign  pgl_vld_rgt = ~reg_pgl_kill_rgt & (pgl_type_rgt != 0) &
                      ~ystr_rgt_csgb & (yend_rgt_csgb | ystr_rgt_eq) &
                      (pgl_hcnt >= xstr_rgt) & ((pgl_hcnt < xend_rgt) | xend_eq_rgt);

assign  pgl_vld_ctr = (reg_pgl_type_ctr != 0) &
                      ((~ystr_ctr_csgb & yend_ctr_csgb & ~reg_pgl_type_ctr[1])  |   // dashed line
                       (~y0_ctr_csgb   &                  reg_pgl_type_ctr[1])) &   // solid line
                        vend_ctr_csgb  &
                      (pgl_hcnt >= xstr_ctr) & ((pgl_hcnt < xend_ctr) | xend_eq_ctr);

// to CU control Info
// -----------------------------------------------
assign  pgl_wwg_mul = reg_pgl_hwwg_opt ? reg_pgl_vln_wid : 6'h1;

assign  pgl_wid_bs_lft = ln_type_lft[1] ? (ln_type_lft[0] ? cu_pgl_hln1_wid : cu_pgl_hln0_wid) :
                                           {3'h0,reg_pgl_vln_wid};
assign  pgl_wid_bs_rgt = ln_type_rgt[1] ? (ln_type_rgt[0] ? cu_pgl_hln1_wid : cu_pgl_hln0_wid) :
                                           {3'h0,reg_pgl_vln_wid};

assign  pgl_wwg_lft = ln_type_lft[1] ? cu_pgl_hwwg_lft : {6'h0,reg_pgl_wwg_lft};

assign  pgl_wwg_rgt = ln_type_rgt[1] ? cu_pgl_hwwg_rgt : {6'h0,reg_pgl_wwg_rgt};


// PGL segment data selection
// -----------------------------------------------

assign  pgl_ystr_lft =     ({8{pgl_seg_lft[0]}} & reg_pgl_ystr0_lft) |
                           ({8{pgl_seg_lft[1]}} & reg_pgl_ystr1_lft) |
                           ({8{pgl_seg_lft[2]}} & reg_pgl_ystr2_lft) |
                           ({8{pgl_seg_lft[3]}} & reg_pgl_ystr3_lft) |
                           ({8{pgl_seg_lft[4]}} & reg_pgl_ystr4_lft) |
                           ({8{pgl_seg_lft[5]}} & reg_pgl_ystr5_lft) |
                           ({8{pgl_seg_lft[6]}} & reg_pgl_ystr6_lft) |
                           ({8{pgl_seg_lft[7]}} & reg_pgl_ystr7_lft) |
                           ({8{pgl_seg_lft[8]}} & reg_pgl_ystr8_lft) |
                           ({8{pgl_seg_lft[9]}} & reg_pgl_ystr9_lft);

assign  pgl_h_lft =        ({6{pgl_seg_lft[0]}} & reg_pgl_h0_lft) |
                           ({6{pgl_seg_lft[1]}} & reg_pgl_h1_lft) |
                           ({6{pgl_seg_lft[2]}} & reg_pgl_h2_lft) |
                           ({6{pgl_seg_lft[3]}} & reg_pgl_h3_lft) |
                           ({6{pgl_seg_lft[4]}} & reg_pgl_h4_lft) |
                           ({6{pgl_seg_lft[5]}} & reg_pgl_h5_lft) |
                           ({6{pgl_seg_lft[6]}} & reg_pgl_h6_lft) |
                           ({6{pgl_seg_lft[7]}} & reg_pgl_h7_lft) |
                           ({6{pgl_seg_lft[8]}} & reg_pgl_h8_lft) |
                           ({6{pgl_seg_lft[9]}} & reg_pgl_h9_lft);

assign  ln_type_lft_nxt =  ({2{pgl_seg_lft[0]}} & reg_pgl_type0) |
                           ({2{pgl_seg_lft[1]}} & reg_pgl_type1) |
                           ({2{pgl_seg_lft[2]}} & reg_pgl_type2) |
                           ({2{pgl_seg_lft[3]}} & reg_pgl_type3) |
                           ({2{pgl_seg_lft[4]}} & reg_pgl_type4) |
                           ({2{pgl_seg_lft[5]}} & reg_pgl_type5) |
                           ({2{pgl_seg_lft[6]}} & reg_pgl_type6) |
                           ({2{pgl_seg_lft[7]}} & reg_pgl_type7) |
                           ({2{pgl_seg_lft[8]}} & reg_pgl_type8) |
                           ({2{pgl_seg_lft[9]}} & reg_pgl_type9);
assign  pgl_type_lft_nxt = pgl_hend_i ? ln_type_lft : pgl_type_lft;

assign  pgl_colr_lft_nxt = pgl_hend_i ?
                           ({2{pgl_seg_lft[0]}} & reg_pgl_colr0) |
                           ({2{pgl_seg_lft[1]}} & reg_pgl_colr1) |
                           ({2{pgl_seg_lft[2]}} & reg_pgl_colr2) |
                           ({2{pgl_seg_lft[3]}} & reg_pgl_colr3) |
                           ({2{pgl_seg_lft[4]}} & reg_pgl_colr4) |
                           ({2{pgl_seg_lft[5]}} & reg_pgl_colr5) |
                           ({2{pgl_seg_lft[6]}} & reg_pgl_colr6) |
                           ({2{pgl_seg_lft[7]}} & reg_pgl_colr7) |
                           ({2{pgl_seg_lft[8]}} & reg_pgl_colr8) |
                           ({2{pgl_seg_lft[9]}} & reg_pgl_colr9) : pgl_colr_lft;


assign  pgl_ystr_rgt =     ({8{pgl_seg_rgt[0]}} & reg_pgl_ystr0_rgt) |
                           ({8{pgl_seg_rgt[1]}} & reg_pgl_ystr1_rgt) |
                           ({8{pgl_seg_rgt[2]}} & reg_pgl_ystr2_rgt) |
                           ({8{pgl_seg_rgt[3]}} & reg_pgl_ystr3_rgt) |
                           ({8{pgl_seg_rgt[4]}} & reg_pgl_ystr4_rgt) |
                           ({8{pgl_seg_rgt[5]}} & reg_pgl_ystr5_rgt) |
                           ({8{pgl_seg_rgt[6]}} & reg_pgl_ystr6_rgt) |
                           ({8{pgl_seg_rgt[7]}} & reg_pgl_ystr7_rgt) |
                           ({8{pgl_seg_rgt[8]}} & reg_pgl_ystr8_rgt) |
                           ({8{pgl_seg_rgt[9]}} & reg_pgl_ystr9_rgt);

assign  pgl_h_rgt =        ({6{pgl_seg_rgt[0]}} & reg_pgl_h0_rgt) |
                           ({6{pgl_seg_rgt[1]}} & reg_pgl_h1_rgt) |
                           ({6{pgl_seg_rgt[2]}} & reg_pgl_h2_rgt) |
                           ({6{pgl_seg_rgt[3]}} & reg_pgl_h3_rgt) |
                           ({6{pgl_seg_rgt[4]}} & reg_pgl_h4_rgt) |
                           ({6{pgl_seg_rgt[5]}} & reg_pgl_h5_rgt) |
                           ({6{pgl_seg_rgt[6]}} & reg_pgl_h6_rgt) |
                           ({6{pgl_seg_rgt[7]}} & reg_pgl_h7_rgt) |
                           ({6{pgl_seg_rgt[8]}} & reg_pgl_h8_rgt) |
                           ({6{pgl_seg_rgt[9]}} & reg_pgl_h9_rgt);

assign  ln_type_rgt_nxt = ({2{pgl_seg_rgt[0]}} & reg_pgl_type0) |
                          ({2{pgl_seg_rgt[1]}} & reg_pgl_type1) |
                          ({2{pgl_seg_rgt[2]}} & reg_pgl_type2) |
                          ({2{pgl_seg_rgt[3]}} & reg_pgl_type3) |
                          ({2{pgl_seg_rgt[4]}} & reg_pgl_type4) |
                          ({2{pgl_seg_rgt[5]}} & reg_pgl_type5) |
                          ({2{pgl_seg_rgt[6]}} & reg_pgl_type6) |
                          ({2{pgl_seg_rgt[7]}} & reg_pgl_type7) |
                          ({2{pgl_seg_rgt[8]}} & reg_pgl_type8) |
                          ({2{pgl_seg_rgt[9]}} & reg_pgl_type9);
assign  pgl_type_rgt_nxt = pgl_hend_i ? ln_type_rgt : pgl_type_rgt;

assign  pgl_colr_rgt_nxt = pgl_hend_i ?
                           ({2{pgl_seg_rgt[0]}} & reg_pgl_colr0) |
                           ({2{pgl_seg_rgt[1]}} & reg_pgl_colr1) |
                           ({2{pgl_seg_rgt[2]}} & reg_pgl_colr2) |
                           ({2{pgl_seg_rgt[3]}} & reg_pgl_colr3) |
                           ({2{pgl_seg_rgt[4]}} & reg_pgl_colr4) |
                           ({2{pgl_seg_rgt[5]}} & reg_pgl_colr5) |
                           ({2{pgl_seg_rgt[6]}} & reg_pgl_colr6) |
                           ({2{pgl_seg_rgt[7]}} & reg_pgl_colr7) |
                           ({2{pgl_seg_rgt[8]}} & reg_pgl_colr8) |
                           ({2{pgl_seg_rgt[9]}} & reg_pgl_colr9) : pgl_colr_rgt;

// PGL segment counter
// -----------------------------------------------
assign  pgl_seg_lft_nxt[PGL_SEG-1:1] = {PGL_SEG-1{~pgl_vend_o}} &
                                       (cu2pgl_tsk_end[1] & cu_yend_lft_eq ? pgl_seg_lft[PGL_SEG-2:0] : pgl_seg_lft[PGL_SEG-1:1]);
assign  pgl_seg_lft_nxt[0]           = (pgl_fstr_i | pgl_seg_lft[0]) & ~(cu2pgl_tsk_end[1] & cu_yend_lft_eq);

assign  pgl_seg_rgt_nxt[PGL_SEG-1:1] = {PGL_SEG-1{~pgl_vend_o}} &
                                       (cu2pgl_tsk_end[1] & cu_yend_rgt_eq ? pgl_seg_rgt[PGL_SEG-2:0] : pgl_seg_rgt[PGL_SEG-1:1]);
assign  pgl_seg_rgt_nxt[0]           = (pgl_fstr_i | pgl_seg_rgt[0]) & ~(cu2pgl_tsk_end[1] & cu_yend_rgt_eq);

// CU data buffering
// -----------------------------------------------
// due to CU data for PGL are calculated from h-start
assign  ystr_lft_eq_nxt   = (pgl_hend_i ? cu_ystr_lft_eq   : ystr_lft_eq)   & ~pgl_fstr_i;
assign  ystr_lft_csgb_nxt =  pgl_hend_i ? cu_ystr_lft_csgb : ystr_lft_csgb;
assign  yend_lft_csgb_nxt = (pgl_hend_i ? cu_yend_lft_csgb : yend_lft_csgb) & ~pgl_fstr_i;
assign  ystr_rgt_eq_nxt   = (pgl_hend_i ? cu_ystr_rgt_eq   : ystr_rgt_eq)   & ~pgl_fstr_i;
assign  ystr_rgt_csgb_nxt =  pgl_hend_i ? cu_ystr_rgt_csgb : ystr_rgt_csgb;
assign  yend_rgt_csgb_nxt = (pgl_hend_i ? cu_yend_rgt_csgb : yend_rgt_csgb) & ~pgl_fstr_i;
assign  y0_ctr_csgb_nxt   =  pgl_hend_i ? cu_y0_ctr_csgb   : y0_ctr_csgb;
assign  ystr_ctr_csgb_nxt =  pgl_hend_i ? cu_ystr_ctr_csgb : ystr_ctr_csgb;
assign  yend_ctr_csgb_nxt = (pgl_hend_i ? cu_yend_ctr_csgb : yend_ctr_csgb) |
                            (pgl_hstr_i & cu_ystr_ctr_eq);
assign  vend_ctr_csgb_nxt =  pgl_hend_i ? cu_vend_ctr_csgb : vend_ctr_csgb;

assign  xstr_lft_nxt      = pgl_hend_i ? cu_xstr_lft      : xstr_lft;
assign  xstr_a1_lft_nxt   = pgl_hend_i ? cu_xstr_a1_lft   : xstr_a1_lft;
assign  xend_lft_nxt      = pgl_hend_i ? (reg_pgl_evw_lim ? cu_xend_a1_lft : cu_xend_lft) : xend_lft;
assign  xend_s1_lft_nxt   = pgl_hend_i ? cu_xend_lft      : xend_s1_lft;    // for reg_pgl_evw_lim = 1
assign  xstr_rgt_nxt      = pgl_hend_i ? cu_xstr_rgt      : xstr_rgt;
assign  xstr_a1_rgt_nxt   = pgl_hend_i ? cu_xstr_a1_rgt   : xstr_a1_rgt;
assign  xend_rgt_nxt      = pgl_hend_i ? (reg_pgl_evw_lim ? cu_xend_a1_rgt : cu_xend_rgt) : xend_rgt;
assign  xend_s1_rgt_nxt   = pgl_hend_i ? cu_xend_rgt      : xend_s1_rgt;    // for reg_pgl_evw_lim = 1
assign  xstr_ctr_nxt      = pgl_hend_i ? cu_xstr_ctr      : xstr_ctr;
assign  xstr_a1_ctr_nxt   = pgl_hend_i ? cu_xstr_a1_ctr   : xstr_a1_ctr;
assign  xend_ctr_nxt      = pgl_hend_i ? (reg_pgl_evw_lim ? cu_xend_a1_ctr : cu_xend_ctr) : xend_ctr;
assign  xend_s1_ctr_nxt   = pgl_hend_i ? cu_xend_ctr      : xend_s1_ctr;    // for reg_pgl_evw_lim = 1

// CU related control
// CU is planned to be launched at hstr to get more calculation time
// -----------------------------------------------

// Color palette
assign  pgl2cu_trg_nxt[0] = pgl_fstr_i & reg_pgl_en;

// comparision on Y-start, y-end
assign  pgl2cu_trg_nxt[1] = pgl_hstr_i & reg_pgl_en;

// left: x-start, x-end
assign  pgl2cu_trg_nxt[2] = cu2pgl_tsk_end[1] & (~cu_y0_lft_csgb | ~cu_y0_rgt_csgb | ~cu_y0_ctr_csgb);

// right: x-start, x-end
assign  pgl2cu_trg_nxt[3] = cu2pgl_tsk_end[2];

// center: x-start, x-end
assign  pgl2cu_trg_nxt[4] = cu2pgl_tsk_end[3];

// left: y-start, y-end
assign  pgl2cu_trg_nxt[5] = cu2pgl_tsk_end[4] & (cu_yend_lft_eq | cu_y0_lft_eq);
assign  cutrg5_flg_nxt    = (pgl2cu_trg_nxt[5] | cutrg5_flg) & ~pgl_hend_o;

// right: y-start, y-end
assign  pgl2cu_trg_nxt[6] = (cutrg5_flg ? cu2pgl_tsk_end[5]  :
                                          cu2pgl_tsk4_end_q1) & (cu_yend_rgt_eq | cu_y0_rgt_eq);
assign  cutrg6_flg_nxt    = (pgl2cu_trg_nxt[6] | cutrg6_flg) & ~pgl_hend_o;

// center: y-end
assign  pgl2cu_trg_nxt[7] = (cutrg6_flg ? cu2pgl_tsk_end[6]  :
                             cutrg5_flg ? cu2pgl_tsk5_end_q1 :
                                          cu2pgl_tsk4_end_q2) & cu_ystr_ctr_eq;
// center: y-start; impossible to launch task 7 and task 8 at the same time
assign  pgl2cu_trg_nxt[8] = (cutrg6_flg ? cu2pgl_tsk_end[6]  :
                             cutrg5_flg ? cu2pgl_tsk5_end_q1 :
                                          cu2pgl_tsk4_end_q2) & cu_yend_ctr_eq;


// ---------- Sequential Logic -----------------//

always @(posedge pclk or negedge prst_n) begin
   if (~prst_n) begin
      pgl_colr_lft      <= 0;
      pgl_colr_rgt      <= 0;
      pgl_type_lft      <= 0;
      pgl_type_rgt      <= 0;
      pgl_hcnt          <= 0;
      pgl_vcnt          <= 0;
      pgl2cu_trg        <= 0;
      pgl_vstr_que      <= 0;
      pgl_vend_que      <= 0;
      pgl_hstr_que      <= 0;
      pgl_hend_que      <= 0;
      pgl_dvld_que      <= 0;
      ystr_lft_eq       <= 0;
      ystr_lft_csgb     <= 0;
      yend_lft_csgb     <= 0;
      ystr_rgt_eq       <= 0;
      ystr_rgt_csgb     <= 0;
      yend_rgt_csgb     <= 0;
      y0_ctr_csgb       <= 0;
      ystr_ctr_csgb     <= 0;
      yend_ctr_csgb     <= 0;
      vend_ctr_csgb     <= 0;
      xstr_lft          <= 0;
      xstr_a1_lft       <= 0;
      xend_lft          <= 0;
      xend_s1_lft       <= 0;
      xstr_rgt          <= 0;
      xstr_a1_rgt       <= 0;
      xend_rgt          <= 0;
      xend_s1_rgt       <= 0;
      xstr_ctr          <= 0;
      xstr_a1_ctr       <= 0;
      xend_ctr          <= 0;
      xend_s1_ctr       <= 0;
      pgl_seg_lft       <= 0;
      pgl_seg_rgt       <= 0;
      ln_type_lft       <= 0;
      ln_type_rgt       <= 0;
      cutrg5_flg        <= 0;
      cutrg6_flg        <= 0;
      pgl_vstr_i_q1     <= 0;
      pgl_dvld_i_q1     <= 0;
      cu2pgl_tsk4_end_q1<= 0;
      cu2pgl_tsk4_end_q2<= 0;
      cu2pgl_tsk5_end_q1<= 0;
   end
   else begin
      pgl_colr_lft      <= pgl_colr_lft_nxt;
      pgl_colr_rgt      <= pgl_colr_rgt_nxt;
      pgl_type_lft      <= pgl_type_lft_nxt;
      pgl_type_rgt      <= pgl_type_rgt_nxt;
      pgl_hcnt          <= pgl_hcnt_nxt;
      pgl_vcnt          <= pgl_vcnt_nxt;
      pgl2cu_trg        <= pgl2cu_trg_nxt;
      pgl_vstr_que      <= pgl_vstr_que_nxt;
      pgl_vend_que      <= pgl_vend_que_nxt;
      pgl_hstr_que      <= pgl_hstr_que_nxt;
      pgl_hend_que      <= pgl_hend_que_nxt;
      pgl_dvld_que      <= pgl_dvld_que_nxt;
      ystr_lft_eq       <= ystr_lft_eq_nxt;
      ystr_lft_csgb     <= ystr_lft_csgb_nxt;
      yend_lft_csgb     <= yend_lft_csgb_nxt;
      ystr_rgt_eq       <= ystr_rgt_eq_nxt;
      ystr_rgt_csgb     <= ystr_rgt_csgb_nxt;
      yend_rgt_csgb     <= yend_rgt_csgb_nxt;
      y0_ctr_csgb       <= y0_ctr_csgb_nxt;
      ystr_ctr_csgb     <= ystr_ctr_csgb_nxt;
      yend_ctr_csgb     <= yend_ctr_csgb_nxt;
      vend_ctr_csgb     <= vend_ctr_csgb_nxt;
      xstr_lft          <= xstr_lft_nxt;
      xstr_a1_lft       <= xstr_a1_lft_nxt;
      xend_lft          <= xend_lft_nxt;
      xend_s1_lft       <= xend_s1_lft_nxt;
      xstr_rgt          <= xstr_rgt_nxt;
      xstr_a1_rgt       <= xstr_a1_rgt_nxt;
      xend_rgt          <= xend_rgt_nxt;
      xend_s1_rgt       <= xend_s1_rgt_nxt;
      xstr_ctr          <= xstr_ctr_nxt;
      xstr_a1_ctr       <= xstr_a1_ctr_nxt;
      xend_ctr          <= xend_ctr_nxt;
      xend_s1_ctr       <= xend_s1_ctr_nxt;
      pgl_seg_lft       <= pgl_seg_lft_nxt;
      pgl_seg_rgt       <= pgl_seg_rgt_nxt;
      ln_type_lft       <= ln_type_lft_nxt;
      ln_type_rgt       <= ln_type_rgt_nxt;
      cutrg5_flg        <= cutrg5_flg_nxt;
      cutrg6_flg        <= cutrg6_flg_nxt;
      pgl_vstr_i_q1     <= pgl_vstr_i;
      pgl_dvld_i_q1     <= pgl_dvld_i;
      cu2pgl_tsk4_end_q1<= cu2pgl_tsk_end[4];
      cu2pgl_tsk4_end_q2<= cu2pgl_tsk4_end_q1;
      cu2pgl_tsk5_end_q1<= cu2pgl_tsk_end[5];
   end
end


endmodule
