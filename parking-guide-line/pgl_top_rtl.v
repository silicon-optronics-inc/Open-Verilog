// +FHDR -----------------------------------------------------------------------
// Copyright (c) Silicon Optronics. Inc. 2015
//
// File Name:           pgl_top_rtl.v
// Author:              Humphrey Lin
// Version:             $Revision$
// Last Modified On:    $Date$
// Last Modified By:    $Author$
//
// File Description:    Parking Guideline Top module
//
// Clock Domain:
// -FHDR -----------------------------------------------------------------------

module  pgl_top

    #(
      parameter             XWID        = 10,
      parameter             YWID        = 10,
      parameter             PGL_SEG     = 10,   // Available PGL dash segment
      parameter             CUTSK_NUM   =  9    // CU task number
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

output      [ 7:0]          pgl_data_y_o,       // Y data after PGL blending
output      [ 7:0]          pgl_data_c_o,       // C data after PGL blending

//----------------------------------------------//
// Input declaration                            //
//----------------------------------------------//
input                       pgl_fstr_i,
input                       pgl_vstr_i,         //
input                       pgl_vend_i,         //
input                       pgl_hstr_i,         //
input                       pgl_hend_i,         //
input                       pgl_dvld_i,         //

input       [ 7:0]          pgl_data_y_i,       // Data Y
input       [ 7:0]          pgl_data_c_i,       // Data Cb/Cr

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

input                       reg_pgl_mono_lr,    // PGL mono style color palette @ Left/right
input                       reg_pgl_mono_ctr,   // PGL mono style color palette @ center
input       [ 1:0]          reg_pgl_type_ctr,   // PGL line type @ center
input       [ 1:0]          reg_pgl_colr_ctr,   // PGL line color @ center
input       [ 7:0]          reg_pgl_trsp,       // PGL transparency factor
input                       reg_pgl_evw_lim,    // PGL width limit to even value
input                       reg_pgl_kill_lft,   // Erase left PGL
input                       reg_pgl_kill_rgt,   // Erase right PGL

input       [ 3:0]          reg_pgl_palt_yrto,  // Y color palette saturation decreasing ratio
input       [ 3:0]          reg_pgl_palt_crto,  // UV color palette brightness decreasing ratio
input                       reg_pgl_mirror,     // right PGL line mirrored by left line
input       [ 7:0]          reg_pgl_len_ctr,    // PGL total length of center line
input       [ 3:0]          reg_pgl_hln_m0,     // PGL multiplying factor 0 for horizontal-type line width
input       [ 3:0]          reg_pgl_hln_m1,     // PGL multiplying factor 1 for horizontal-type line width
input       [ 1:0]          reg_pgl_aa_twg,     // PGL anti-alias line edge color transpancy weighting

input       [ 3:0]          reg_pgl_wwg_lft,    // PGL width weighting for left line
input       [ 7:0]          reg_pgl_ybnd_lft,   // PGL Y bound point for left line
input       [ 7:0]          reg_pgl_slpwg_lft,  // PGL slope weighting for left line
input       [ 7:0]          reg_pgl_slp_lft,    // PGL slope for left line
input       [ 7:0]          reg_pgl_xstr_lft,   // PGL x-start point for left line

input       [ 3:0]          reg_pgl_wwg_rgt,    // PGL width weighting for right line
input       [ 7:0]          reg_pgl_ybnd_rgt,   // PGL Y bound point for right line
input       [ 7:0]          reg_pgl_slpwg_rgt,  // PGL slope weighting for right line
input       [ 7:0]          reg_pgl_slp_rgt,    // PGL slope for right line
input       [ 7:0]          reg_pgl_xstr_rgt,   // PGL x-start point for right line

input       [ 7:0]          reg_pgl_ystr_ctr,   // PGL Y-start point for center line
input       [ 4:0]          reg_pgl_wid_ctr,    // PGL width for center line
input       [ 3:0]          reg_pgl_wwg_ctr,    // PGL width weighting for center line
input       [ 4:0]          reg_pgl_hgt_ctr,    // PGL dash height for center line
input       [ 3:0]          reg_pgl_hwg_ctr,    // PGL height weighting for center line
input       [ 4:0]          reg_pgl_blk_ctr,    // PGL blanking height for center line
input       [ 7:0]          reg_pgl_xstr_ctr,   // PGL x-start point for center line

input                       pclk,               // pixel clock
input                       prst_n              // low active reset for pclk domain

);


//----------------------------------------------//
// Wire declaration                             //
//----------------------------------------------//
wire        [ 7:0]          cu_pgl_palt_yr;     // Y color palette: red
wire        [ 7:0]          cu_pgl_palt_yg;     // Y color palette: green
wire        [ 7:0]          cu_pgl_palt_yy;     // Y color palette: yellow
wire        [ 7:0]          cu_pgl_palt_yb;     // Y color palette: blue
wire        [ 7:0]          cu_pgl_palt_bw0;    // Y color palette: white
wire        [ 7:0]          cu_pgl_palt_ur;     // U color palette: red
wire        [ 7:0]          cu_pgl_palt_ug;     // U color palette: green
wire        [ 7:0]          cu_pgl_palt_uy;     // U color palette: yellow
wire        [ 7:0]          cu_pgl_palt_ub;     // U color palette: blue
wire        [ 7:0]          cu_pgl_palt_vr;     // V color palette: red
wire        [ 7:0]          cu_pgl_palt_vg;     // V color palette: green
wire        [ 7:0]          cu_pgl_palt_vy;     // V color palette: yellow
wire        [ 7:0]          cu_pgl_palt_vb;     // V color palette: blue
wire        [ 8:0]          cu_pgl_aa_trsp;     // PGL anti-alias line edge color transpancy
wire        [ 8:0]          cu_pgl_aa_cmpl;     // complement of cu_pgl_aa_trsp
wire        [ 8:0]          cu_pgl_trsp_cmpl;   // complement of reg_pgl_trsp

wire        [ 8:0]          cu_pgl_hln0_wid;    // PGL line width of horizontal type 0
wire        [ 8:0]          cu_pgl_hln1_wid;    // PGL line width of horizontal type 1
wire        [ 9:0]          cu_pgl_hwwg_lft;    // width weighting of horizontal type on left line
wire        [ 9:0]          cu_pgl_hwwg_rgt;    // width weighting of horizontal type on right line

wire                        cu_y0_lft_eq;       // y_p1 == start point of left line, reg_pgl_ystr0_lft
wire                        cu_y0_lft_csgb;     // comparing sign bit: sign(y_p1 - reg_pgl_ystr0_lft)
wire                        cu_ystr_lft_csgb;   // comparing sign bit: sign(y_p1 - cu_ystr_lft)
wire                        cu_ystr_lft_eq;     // y_p1 == cu_ystr_lft
wire                        cu_yend_lft_eq;     // y_p1 == end point of current segment @ left
wire                        cu_yend_lft_csgb;   // comparing sign bit: sign(y_p1 - cu_yend_lft)
wire                        cu_ybnd_lft_csgb;   // sign(y_p1 - reg_pgl_ybnd_lft)
wire                        cu_y0_rgt_eq;       // y_p1 == start point of left line, reg_pgl_ystr0_rgt
wire                        cu_y0_rgt_csgb;     // comparing sign bit: sign(y_p1 - reg_pgl_ystr0_rgt)
wire                        cu_ystr_rgt_csgb;   // comparing sign bit: sign(y_p1 - cu_ystr_rgt)
wire                        cu_ystr_rgt_eq;     // y_p1 == cu_ystr_rgt
wire                        cu_yend_rgt_eq;     // y_p1 == end point of current segment @ left
wire                        cu_yend_rgt_csgb;   // comparing sign bit: sign(y_p1 - cu_yend_rgt)
wire                        cu_ybnd_rgt_csgb;   // sign(y_p1 - reg_pgl_ybnd_rgt)
wire                        cu_y0_ctr_csgb;     // comparing sign bit: sign(y_p1 - reg_pgl_ystr_ctr)
wire                        cu_ystr_ctr_eq;     // y_p1 == start point of current segment @ center
wire                        cu_ystr_ctr_csgb;   // comparing sign bit: sign(y_p1 - cu_ystr_ctr)
wire                        cu_yend_ctr_eq;     // y_p1 == end point of current segment @ center
wire                        cu_yend_ctr_csgb;   // comparing sign bit: sign(y_p1 - cu_yend_ctr)
wire                        cu_vend_ctr_csgb;   // sign(y_p1 - reg_pgl_vend_ctr )
wire        [ 9:0]          cu_xstr_lft;        // x-start point @ left
wire        [ 9:0]          cu_xstr_a1_lft;     // x-start point+1 @ left
wire        [ 9:0]          cu_xend_lft;        // x-end point @ left
wire        [ 9:0]          cu_xend_a1_lft;     // x-end point @+1 left
wire        [ 9:0]          cu_xstr_rgt;        // x-start point @ right
wire        [ 9:0]          cu_xstr_a1_rgt;     // x-start point+1 @ right
wire        [ 9:0]          cu_xend_rgt;        // x-end point @ right
wire        [ 9:0]          cu_xend_a1_rgt;     // x-end point+1 @ right
wire        [ 8:0]          cu_xstr_ctr;        // x-start point @ center
wire        [ 8:0]          cu_xstr_a1_ctr;     // x-start point+1 @ center
wire        [ 8:0]          cu_xend_ctr;        // x-end point @ center
wire        [ 8:0]          cu_xend_a1_ctr;     // x-end point+1 @ center
wire        [ 7:0]          pgl_palt_yr;        // Y color palette: red
wire        [ 7:0]          pgl_palt_yg;        // Y color palette: green
wire        [ 7:0]          pgl_palt_yy;        // Y color palette: yellow
wire        [ 7:0]          pgl_palt_yb;        // Y color palette: blue
wire        [ 7:0]          pgl_palt_bw0;        // Y color palette: white
wire        [ 8:0]          pgl_palt_ur;        // U color palette: red
wire        [ 8:0]          pgl_palt_ug;        // U color palette: green
wire        [ 8:0]          pgl_palt_uy;        // U color palette: yellow
wire        [ 8:0]          pgl_palt_ub;        // U color palette: blue
wire        [ 8:0]          pgl_palt_vr;        // V color palette: red
wire        [ 8:0]          pgl_palt_vg;        // V color palette: green
wire        [ 8:0]          pgl_palt_vy;        // V color palette: yellow
wire        [ 8:0]          pgl_palt_vb;        // V color palette: blue
wire        [ 5:0]          pgl_wwg_mul;        // PGL width weighting multiplier
wire        [ 8:0]          pgl_wid_bs_lft;     // PGL width base @ left
wire        [ 8:0]          pgl_wid_bs_rgt;     // PGL width base @ right
wire        [ 9:0]          pgl_wwg_lft;        // PGL width weighting @ left
wire        [ 9:0]          pgl_wwg_rgt;        // PGL width weighting @ right
wire        [ 7:0]          pgl_ystr_lft;       // PGL y-start point for current segment @ left
wire        [ 7:0]          pgl_ystr_rgt;       // PGL y-start point for current segment @ right
wire        [ 5:0]          pgl_h_lft;          // PGL height for current segment @ left
wire        [ 5:0]          pgl_h_rgt;          // PGL height for current segment @ right

wire        [XWID-1:0]      pgl_hcnt;           // PGL h-counter
wire        [YWID-1:0]      pgl_vcnt;           // PGL v-counter
wire        [ 1:0]          pgl_colr_lft;       // PGL segment color index @ left
wire        [ 1:0]          pgl_colr_rgt;       // PGL segment color index @ right
wire        [ 1:0]          pgl_type_lft;       // PGL segment type @ left
wire        [ 1:0]          pgl_type_rgt;       // PGL segment type @ right
wire        [ 8:0]          pgl2cu_trg;         // PGL-to-CU trigger
wire        [CUTSK_NUM-1:0] cu_tsk_end;         // end of task operation

//----------------------------------------------//
// Code Descriptions                            //
//----------------------------------------------//

pgl_ctrl

#(
    .XWID                   (XWID),
    .YWID                   (YWID),
    .PGL_SEG                (PGL_SEG))

pgl_ctrl (
    // output
    .pgl_vstr_o             (pgl_vstr_o),
    .pgl_vend_o             (pgl_vend_o),
    .pgl_hstr_o             (pgl_hstr_o),
    .pgl_hend_o             (pgl_hend_o),
    .pgl_dvld_o             (pgl_dvld_o),

    .pgl2cu_trg             (pgl2cu_trg),
    .pgl_vld_lft            (pgl_vld_lft),
    .pgl_vld_rgt            (pgl_vld_rgt),
    .pgl_vld_ctr            (pgl_vld_ctr),
    .pgl_edge               (pgl_edge),
    .pgl_colr_lft           (pgl_colr_lft),
    .pgl_colr_rgt           (pgl_colr_rgt),
    .pgl_type_lft           (pgl_type_lft),
    .pgl_type_rgt           (pgl_type_rgt),
    .pgl_wwg_mul            (pgl_wwg_mul),
    .pgl_wid_bs_lft         (pgl_wid_bs_lft),
    .pgl_wid_bs_rgt         (pgl_wid_bs_rgt),
    .pgl_wwg_lft            (pgl_wwg_lft),
    .pgl_wwg_rgt            (pgl_wwg_rgt),
    .pgl_ystr_lft           (pgl_ystr_lft),
    .pgl_ystr_rgt           (pgl_ystr_rgt),
    .pgl_h_lft              (pgl_h_lft),
    .pgl_h_rgt              (pgl_h_rgt),
    .pgl_hcnt               (pgl_hcnt),
    .pgl_vcnt               (pgl_vcnt),

    // input
    .pgl_fstr_i             (pgl_fstr_i),
    .pgl_vstr_i             (pgl_vstr_i),
    .pgl_vend_i             (pgl_vend_i),
    .pgl_hstr_i             (pgl_hstr_i),
    .pgl_hend_i             (pgl_hend_i),
    .pgl_dvld_i             (pgl_dvld_i),

    .cu2pgl_tsk_end         (cu_tsk_end),

    .cu_pgl_hln0_wid        (cu_pgl_hln0_wid),
    .cu_pgl_hln1_wid        (cu_pgl_hln1_wid),
    .cu_pgl_hwwg_lft        (cu_pgl_hwwg_lft),
    .cu_pgl_hwwg_rgt        (cu_pgl_hwwg_rgt),

    .cu_y0_lft_csgb         (cu_y0_lft_csgb),
    .cu_ystr_lft_csgb       (cu_ystr_lft_csgb),
    .cu_ystr_lft_eq         (cu_ystr_lft_eq),
    .cu_yend_lft_csgb       (cu_yend_lft_csgb),
    .cu_y0_lft_eq           (cu_y0_lft_eq),
    .cu_yend_lft_eq         (cu_yend_lft_eq),

    .cu_y0_rgt_csgb         (cu_y0_rgt_csgb),
    .cu_ystr_rgt_csgb       (cu_ystr_rgt_csgb),
    .cu_ystr_rgt_eq         (cu_ystr_rgt_eq),
    .cu_yend_rgt_csgb       (cu_yend_rgt_csgb),
    .cu_y0_rgt_eq           (cu_y0_rgt_eq),
    .cu_yend_rgt_eq         (cu_yend_rgt_eq),

    .cu_y0_ctr_csgb         (cu_y0_ctr_csgb),
    .cu_ystr_ctr_csgb       (cu_ystr_ctr_csgb),
    .cu_yend_ctr_csgb       (cu_yend_ctr_csgb),
    .cu_ystr_ctr_eq         (cu_ystr_ctr_eq),
    .cu_yend_ctr_eq         (cu_yend_ctr_eq),
    .cu_vend_ctr_csgb       (cu_vend_ctr_csgb),

    .cu_xstr_lft            (cu_xstr_lft),
    .cu_xstr_a1_lft         (cu_xstr_a1_lft),
    .cu_xend_lft            (cu_xend_lft),
    .cu_xend_a1_lft         (cu_xend_a1_lft),
    .cu_xstr_rgt            (cu_xstr_rgt),
    .cu_xstr_a1_rgt         (cu_xstr_a1_rgt),
    .cu_xend_rgt            (cu_xend_rgt),
    .cu_xend_a1_rgt         (cu_xend_a1_rgt),
    .cu_xstr_ctr            (cu_xstr_ctr),
    .cu_xstr_a1_ctr         (cu_xstr_a1_ctr),
    .cu_xend_ctr            (cu_xend_ctr),
    .cu_xend_a1_ctr         (cu_xend_a1_ctr),

    .reg_pgl_ystr0_lft      (reg_pgl_ystr0_lft),
    .reg_pgl_ystr1_lft      (reg_pgl_ystr1_lft),
    .reg_pgl_ystr2_lft      (reg_pgl_ystr2_lft),
    .reg_pgl_ystr3_lft      (reg_pgl_ystr3_lft),
    .reg_pgl_ystr4_lft      (reg_pgl_ystr4_lft),
    .reg_pgl_ystr5_lft      (reg_pgl_ystr5_lft),
    .reg_pgl_ystr6_lft      (reg_pgl_ystr6_lft),
    .reg_pgl_ystr7_lft      (reg_pgl_ystr7_lft),
    .reg_pgl_ystr8_lft      (reg_pgl_ystr8_lft),
    .reg_pgl_ystr9_lft      (reg_pgl_ystr9_lft),

    .reg_pgl_h0_lft         (reg_pgl_h0_lft),
    .reg_pgl_h1_lft         (reg_pgl_h1_lft),
    .reg_pgl_h2_lft         (reg_pgl_h2_lft),
    .reg_pgl_h3_lft         (reg_pgl_h3_lft),
    .reg_pgl_h4_lft         (reg_pgl_h4_lft),
    .reg_pgl_h5_lft         (reg_pgl_h5_lft),
    .reg_pgl_h6_lft         (reg_pgl_h6_lft),
    .reg_pgl_h7_lft         (reg_pgl_h7_lft),
    .reg_pgl_h8_lft         (reg_pgl_h8_lft),
    .reg_pgl_h9_lft         (reg_pgl_h9_lft),

    .reg_pgl_wwg_lft        (reg_pgl_wwg_lft),

    .reg_pgl_ystr0_rgt      (reg_pgl_ystr0_rgt),
    .reg_pgl_ystr1_rgt      (reg_pgl_ystr1_rgt),
    .reg_pgl_ystr2_rgt      (reg_pgl_ystr2_rgt),
    .reg_pgl_ystr3_rgt      (reg_pgl_ystr3_rgt),
    .reg_pgl_ystr4_rgt      (reg_pgl_ystr4_rgt),
    .reg_pgl_ystr5_rgt      (reg_pgl_ystr5_rgt),
    .reg_pgl_ystr6_rgt      (reg_pgl_ystr6_rgt),
    .reg_pgl_ystr7_rgt      (reg_pgl_ystr7_rgt),
    .reg_pgl_ystr8_rgt      (reg_pgl_ystr8_rgt),
    .reg_pgl_ystr9_rgt      (reg_pgl_ystr9_rgt),

    .reg_pgl_h0_rgt         (reg_pgl_h0_rgt),
    .reg_pgl_h1_rgt         (reg_pgl_h1_rgt),
    .reg_pgl_h2_rgt         (reg_pgl_h2_rgt),
    .reg_pgl_h3_rgt         (reg_pgl_h3_rgt),
    .reg_pgl_h4_rgt         (reg_pgl_h4_rgt),
    .reg_pgl_h5_rgt         (reg_pgl_h5_rgt),
    .reg_pgl_h6_rgt         (reg_pgl_h6_rgt),
    .reg_pgl_h7_rgt         (reg_pgl_h7_rgt),
    .reg_pgl_h8_rgt         (reg_pgl_h8_rgt),
    .reg_pgl_h9_rgt         (reg_pgl_h9_rgt),

    .reg_pgl_wwg_rgt        (reg_pgl_wwg_rgt),

    .reg_pgl_type0          (reg_pgl_type0),
    .reg_pgl_type1          (reg_pgl_type1),
    .reg_pgl_type2          (reg_pgl_type2),
    .reg_pgl_type3          (reg_pgl_type3),
    .reg_pgl_type4          (reg_pgl_type4),
    .reg_pgl_type5          (reg_pgl_type5),
    .reg_pgl_type6          (reg_pgl_type6),
    .reg_pgl_type7          (reg_pgl_type7),
    .reg_pgl_type8          (reg_pgl_type8),
    .reg_pgl_type9          (reg_pgl_type9),

    .reg_pgl_colr0          (reg_pgl_colr0),
    .reg_pgl_colr1          (reg_pgl_colr1),
    .reg_pgl_colr2          (reg_pgl_colr2),
    .reg_pgl_colr3          (reg_pgl_colr3),
    .reg_pgl_colr4          (reg_pgl_colr4),
    .reg_pgl_colr5          (reg_pgl_colr5),
    .reg_pgl_colr6          (reg_pgl_colr6),
    .reg_pgl_colr7          (reg_pgl_colr7),
    .reg_pgl_colr8          (reg_pgl_colr8),
    .reg_pgl_colr9          (reg_pgl_colr9),

    .reg_pgl_en             (reg_pgl_en),
    .reg_pgl_hwwg_opt       (reg_pgl_hwwg_opt),
    .reg_pgl_vln_wid        (reg_pgl_vln_wid),
    .reg_pgl_type_ctr       (reg_pgl_type_ctr),
    .reg_pgl_evw_lim        (reg_pgl_evw_lim),
    .reg_pgl_kill_lft       (reg_pgl_kill_lft),
    .reg_pgl_kill_rgt       (reg_pgl_kill_rgt),

    .pclk                   (pclk),
    .prst_n                 (prst_n)
    );


pgl_dp

#(
    .XWID                   (XWID))

pgl_dp (
    // output
    .pgl_data_y_o           (pgl_data_y_o),
    .pgl_data_c_o           (pgl_data_c_o),
    .pgl_palt_yr            (pgl_palt_yr),
    .pgl_palt_yg            (pgl_palt_yg),
    .pgl_palt_yy            (pgl_palt_yy),
    .pgl_palt_yb            (pgl_palt_yb),
    .pgl_palt_bw0           (pgl_palt_bw0),
    .pgl_palt_ur            (pgl_palt_ur),
    .pgl_palt_ug            (pgl_palt_ug),
    .pgl_palt_uy            (pgl_palt_uy),
    .pgl_palt_ub            (pgl_palt_ub),
    .pgl_palt_vr            (pgl_palt_vr),
    .pgl_palt_vg            (pgl_palt_vg),
    .pgl_palt_vy            (pgl_palt_vy),
    .pgl_palt_vb            (pgl_palt_vb),

    // input
    .pgl_data_y_i           (pgl_data_y_i),
    .pgl_data_c_i           (pgl_data_c_i),
    .pgl_hcnt               (pgl_hcnt),
    .pgl_vld_lft            (pgl_vld_lft),
    .pgl_vld_rgt            (pgl_vld_rgt),
    .pgl_vld_ctr            (pgl_vld_ctr),
    .pgl_edge               (pgl_edge),
    .pgl_type_lft           (pgl_type_lft),
    .pgl_type_rgt           (pgl_type_rgt),
    .pgl_colr_lft           (pgl_colr_lft),
    .pgl_colr_rgt           (pgl_colr_rgt),

    .cu_pgl_palt_yr         (cu_pgl_palt_yr),
    .cu_pgl_palt_yg         (cu_pgl_palt_yg),
    .cu_pgl_palt_yy         (cu_pgl_palt_yy),
    .cu_pgl_palt_yb         (cu_pgl_palt_yb),
    .cu_pgl_palt_bw0        (cu_pgl_palt_bw0),
    .cu_pgl_palt_ur         (cu_pgl_palt_ur),
    .cu_pgl_palt_ug         (cu_pgl_palt_ug),
    .cu_pgl_palt_uy         (cu_pgl_palt_uy),
    .cu_pgl_palt_ub         (cu_pgl_palt_ub),
    .cu_pgl_palt_vr         (cu_pgl_palt_vr),
    .cu_pgl_palt_vg         (cu_pgl_palt_vg),
    .cu_pgl_palt_vy         (cu_pgl_palt_vy),
    .cu_pgl_palt_vb         (cu_pgl_palt_vb),
    .cu_pgl_aa_trsp         (cu_pgl_aa_trsp),
    .cu_pgl_aa_cmpl         (cu_pgl_aa_cmpl),
    .cu_pgl_trsp_cmpl       (cu_pgl_trsp_cmpl),

    .reg_pgl_mono_lr        (reg_pgl_mono_lr),
    .reg_pgl_mono_ctr       (reg_pgl_mono_ctr),
    .reg_pgl_colr_ctr       (reg_pgl_colr_ctr),
    .reg_pgl_trsp           (reg_pgl_trsp),

    .pclk                   (pclk),
    .prst_n                 (prst_n)
    );


pcu_top
#(
    .CUTSK_NUM              (CUTSK_NUM))

pcu_top (
    // output
    .cu_pgl_palt_yr         (cu_pgl_palt_yr),
    .cu_pgl_palt_yg         (cu_pgl_palt_yg),
    .cu_pgl_palt_yy         (cu_pgl_palt_yy),
    .cu_pgl_palt_yb         (cu_pgl_palt_yb),
    .cu_pgl_palt_bw0        (cu_pgl_palt_bw0),
    .cu_pgl_palt_ur         (cu_pgl_palt_ur),
    .cu_pgl_palt_ug         (cu_pgl_palt_ug),
    .cu_pgl_palt_uy         (cu_pgl_palt_uy),
    .cu_pgl_palt_ub         (cu_pgl_palt_ub),
    .cu_pgl_palt_vr         (cu_pgl_palt_vr),
    .cu_pgl_palt_vg         (cu_pgl_palt_vg),
    .cu_pgl_palt_vy         (cu_pgl_palt_vy),
    .cu_pgl_palt_vb         (cu_pgl_palt_vb),
    .cu_pgl_aa_trsp         (cu_pgl_aa_trsp),
    .cu_pgl_aa_cmpl         (cu_pgl_aa_cmpl),
    .cu_pgl_trsp_cmpl       (cu_pgl_trsp_cmpl),

    .cu_pgl_hln0_wid        (cu_pgl_hln0_wid),
    .cu_pgl_hln1_wid        (cu_pgl_hln1_wid),
    .cu_pgl_hwwg_lft        (cu_pgl_hwwg_lft),
    .cu_pgl_hwwg_rgt        (cu_pgl_hwwg_rgt),

    .cu_y0_lft_eq           (cu_y0_lft_eq),
    .cu_y0_lft_csgb         (cu_y0_lft_csgb),
    .cu_ystr_lft_csgb       (cu_ystr_lft_csgb),
    .cu_ystr_lft_eq         (cu_ystr_lft_eq),
    .cu_yend_lft_eq         (cu_yend_lft_eq),
    .cu_yend_lft_csgb       (cu_yend_lft_csgb),
    .cu_ybnd_lft_csgb       (cu_ybnd_lft_csgb),
    .cu_y0_rgt_eq           (cu_y0_rgt_eq),
    .cu_y0_rgt_csgb         (cu_y0_rgt_csgb),
    .cu_ystr_rgt_csgb       (cu_ystr_rgt_csgb),
    .cu_ystr_rgt_eq         (cu_ystr_rgt_eq),
    .cu_yend_rgt_eq         (cu_yend_rgt_eq),
    .cu_yend_rgt_csgb       (cu_yend_rgt_csgb),
    .cu_ybnd_rgt_csgb       (cu_ybnd_rgt_csgb),
    .cu_y0_ctr_csgb         (cu_y0_ctr_csgb),
    .cu_ystr_ctr_eq         (cu_ystr_ctr_eq),
    .cu_ystr_ctr_csgb       (cu_ystr_ctr_csgb),
    .cu_yend_ctr_eq         (cu_yend_ctr_eq),
    .cu_yend_ctr_csgb       (cu_yend_ctr_csgb),
    .cu_vend_ctr_csgb       (cu_vend_ctr_csgb),

    .cu_xstr_lft            (cu_xstr_lft),
    .cu_xstr_a1_lft         (cu_xstr_a1_lft),
    .cu_xend_lft            (cu_xend_lft),
    .cu_xend_a1_lft         (cu_xend_a1_lft),
    .cu_xstr_rgt            (cu_xstr_rgt),
    .cu_xstr_a1_rgt         (cu_xstr_a1_rgt),
    .cu_xend_rgt            (cu_xend_rgt),
    .cu_xend_a1_rgt         (cu_xend_a1_rgt),
    .cu_xstr_ctr            (cu_xstr_ctr),
    .cu_xstr_a1_ctr         (cu_xstr_a1_ctr),
    .cu_xend_ctr            (cu_xend_ctr),
    .cu_xend_a1_ctr         (cu_xend_a1_ctr),

    .cu_tsk_end             (cu_tsk_end),

    // input
    .fm_str                 (pgl_fstr_i),
    .cu_tsk_trg             (pgl2cu_trg),

    .pgl_palt_yr            (pgl_palt_yr),
    .pgl_palt_yg            (pgl_palt_yg),
    .pgl_palt_yy            (pgl_palt_yy),
    .pgl_palt_yb            (pgl_palt_yb),
    .pgl_palt_bw0           (pgl_palt_bw0),
    .pgl_palt_ur            (pgl_palt_ur),
    .pgl_palt_ug            (pgl_palt_ug),
    .pgl_palt_uy            (pgl_palt_uy),
    .pgl_palt_ub            (pgl_palt_ub),
    .pgl_palt_vr            (pgl_palt_vr),
    .pgl_palt_vg            (pgl_palt_vg),
    .pgl_palt_vy            (pgl_palt_vy),
    .pgl_palt_vb            (pgl_palt_vb),
    .pgl_wwg_mul            (pgl_wwg_mul),
    .pgl_wid_bs_lft         (pgl_wid_bs_lft),
    .pgl_wid_bs_rgt         (pgl_wid_bs_rgt),
    .pgl_wwg_lft            (pgl_wwg_lft),
    .pgl_wwg_rgt            (pgl_wwg_rgt),
    .pgl_ystr_lft           (pgl_ystr_lft),
    .pgl_ystr_rgt           (pgl_ystr_rgt),
    .pgl_h_lft              (pgl_h_lft),
    .pgl_h_rgt              (pgl_h_rgt),
    .pgl_vcnt               (pgl_vcnt),

    .reg_pgl_palt_yrto      (reg_pgl_palt_yrto),
    .reg_pgl_palt_crto      (reg_pgl_palt_crto),
    .reg_pgl_mirror         (reg_pgl_mirror),
    .reg_pgl_len_ctr        (reg_pgl_len_ctr),
    .reg_pgl_vln_wid        (reg_pgl_vln_wid),
    .reg_pgl_hln_m0         (reg_pgl_hln_m0),
    .reg_pgl_hln_m1         (reg_pgl_hln_m1),
    .reg_pgl_trsp           (reg_pgl_trsp),
    .reg_pgl_aa_twg         (reg_pgl_aa_twg),
    .reg_pgl_evw_lim        (reg_pgl_evw_lim),
    .reg_pgl_wwg_lft        (reg_pgl_wwg_lft),
    .reg_pgl_ystr0_lft      (reg_pgl_ystr0_lft),
    .reg_pgl_ybnd_lft       (reg_pgl_ybnd_lft),
    .reg_pgl_slpwg_lft      (reg_pgl_slpwg_lft),
    .reg_pgl_slp_lft        (reg_pgl_slp_lft),
    .reg_pgl_xstr_lft       (reg_pgl_xstr_lft),
    .reg_pgl_wwg_rgt        (reg_pgl_wwg_rgt),
    .reg_pgl_ystr0_rgt      (reg_pgl_ystr0_rgt),
    .reg_pgl_ybnd_rgt       (reg_pgl_ybnd_rgt),
    .reg_pgl_slpwg_rgt      (reg_pgl_slpwg_rgt),
    .reg_pgl_slp_rgt        (reg_pgl_slp_rgt),
    .reg_pgl_xstr_rgt       (reg_pgl_xstr_rgt),
    .reg_pgl_ystr_ctr       (reg_pgl_ystr_ctr),
    .reg_pgl_wid_ctr        (reg_pgl_wid_ctr),
    .reg_pgl_wwg_ctr        (reg_pgl_wwg_ctr),
    .reg_pgl_hgt_ctr        (reg_pgl_hgt_ctr),
    .reg_pgl_hwg_ctr        (reg_pgl_hwg_ctr),
    .reg_pgl_blk_ctr        (reg_pgl_blk_ctr),
    .reg_pgl_xstr_ctr       (reg_pgl_xstr_ctr),

    .pclk                   (pclk),
    .prst_n                 (prst_n)
    );

endmodule

