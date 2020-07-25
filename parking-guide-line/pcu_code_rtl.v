// +FHDR -----------------------------------------------------------------------
// Copyright (c) Silicon Optronics. Inc. 2015
//
// File Name:           pcu_code_rtl.v
// Author:              Humphrey Lin
// Version:             $Revision$
// Last Modified On:    $Date$
// Last Modified By:    $Author$
//
// File Description:    CU code for Parking Guideline
//
// Clock Domain:
// -FHDR -----------------------------------------------------------------------

module  pcu_code

    #(
      parameter             NUM0_SZ     = 1,
      parameter             NUM1_SZ     = 1,
      parameter             ALU_SZ      = 1,
      parameter             PC_NUM      = 1,

      parameter             T0_PC       = 0,
      parameter             T1_PC       = 0,
      parameter             T2_PC       = 0,
      parameter             T3_PC       = 0,
      parameter             T4_PC       = 0,
      parameter             T5_PC       = 0,
      parameter             T6_PC       = 0,
      parameter             T7_PC       = 0,
      parameter             T8_PC       = 0

     )
(
//----------------------------------------------//
// Output declaration                           //
//----------------------------------------------//
output      [ 1:0]          opcode,             // 0: +, 1: -, 2: *, 3: /
output      [NUM0_SZ-1:0]   num_0,              // input number 0
output      [NUM1_SZ-1:0]   num_1,              // input number 1

output reg  [ 7:0]          cu_pgl_palt_yr,     // Y color palette: red
output reg  [ 7:0]          cu_pgl_palt_yg,     // Y color palette: green
output reg  [ 7:0]          cu_pgl_palt_yy,     // Y color palette: yellow
output reg  [ 7:0]          cu_pgl_palt_yb,     // Y color palette: blue
output reg  [ 7:0]          cu_pgl_palt_bw0,    // Y color palette: white
output reg  [ 7:0]          cu_pgl_palt_ur,     // U color palette: red
output reg  [ 7:0]          cu_pgl_palt_ug,     // U color palette: green
output reg  [ 7:0]          cu_pgl_palt_uy,     // U color palette: yellow
output reg  [ 7:0]          cu_pgl_palt_ub,     // U color palette: blue
output reg  [ 7:0]          cu_pgl_palt_vr,     // V color palette: red
output reg  [ 7:0]          cu_pgl_palt_vg,     // V color palette: green
output reg  [ 7:0]          cu_pgl_palt_vy,     // V color palette: yellow
output reg  [ 7:0]          cu_pgl_palt_vb,     // V color palette: blue
output reg  [ 8:0]          cu_pgl_aa_trsp,     // PGL anti-alias line edge color transpancy
output reg  [ 8:0]          cu_pgl_aa_cmpl,     // complement of cu_pgl_aa_trsp
output reg  [ 8:0]          cu_pgl_trsp_cmpl,   // complement of reg_pgl_trsp
output reg  [ 8:0]          cu_pgl_hln0_wid,    // PGL line width of horizontal type 0
output reg  [ 8:0]          cu_pgl_hln1_wid,    // PGL line width of horizontal type 1
output reg  [ 9:0]          cu_pgl_hwwg_lft,    // width weighting of horizontal type on left line
output reg  [ 9:0]          cu_pgl_hwwg_rgt,    // width weighting of horizontal type on right line

output reg                  cu_y0_lft_eq,       // y_p1 == start point of left line, reg_pgl_ystr0_lft
output reg                  cu_y0_lft_csgb,     // comparing sign bit: sign(y_p1 - reg_pgl_ystr0_lft)
output reg                  cu_ystr_lft_csgb,   // comparing sign bit: sign(y_p1 - cu_ystr_lft)
output reg                  cu_ystr_lft_eq,     // y_p1 == cu_ystr_lft
output reg                  cu_yend_lft_eq,     // y_p1 == end point of current segment @ left
output reg                  cu_yend_lft_csgb,   // comparing sign bit: sign(y_p1 - cu_yend_lft)
output reg                  cu_ybnd_lft_csgb,   // sign(y_p1 - reg_pgl_ybnd_lft)
output reg                  cu_y0_rgt_eq,       // y_p1 == start point of left line, reg_pgl_ystr0_rgt
output reg                  cu_y0_rgt_csgb,     // comparing sign bit: sign(y_p1 - reg_pgl_ystr0_rgt)
output reg                  cu_ystr_rgt_csgb,   // comparing sign bit: sign(y_p1 - cu_ystr_rgt)
output reg                  cu_ystr_rgt_eq,     // y_p1 == cu_ystr_rgt
output reg                  cu_yend_rgt_eq,     // y_p1 == end point of current segment @ left
output reg                  cu_yend_rgt_csgb,   // comparing sign bit: sign(y_p1 - cu_yend_rgt)
output reg                  cu_ybnd_rgt_csgb,   // sign(y_p1 - reg_pgl_ybnd_rgt)
output reg                  cu_y0_ctr_csgb,     // comparing sign bit: sign(y_p1 - reg_pgl_ystr_ctr)
output reg                  cu_ystr_ctr_eq,     // y_p1 == start point of current segment @ center
output reg                  cu_ystr_ctr_csgb,   // comparing sign bit: sign(y_p1 - cu_ystr_ctr)
output reg                  cu_yend_ctr_eq,     // y_p1 == end point of current segment @ center
output reg                  cu_yend_ctr_csgb,   // comparing sign bit: sign(y_p1 - cu_yend_ctr)
output reg                  cu_vend_ctr_csgb,   // sign(y_p1 - reg_pgl_vend_ctr )

output      [ 9:0]          cu_xstr_lft,        // x-start point @ left
output reg  [ 9:0]          cu_xstr_a1_lft,     // x-start point+1 @ left
output      [ 9:0]          cu_xend_lft,        // x-end point @ left
output reg  [ 9:0]          cu_xend_a1_lft,     // x-end point @+1 left
output      [ 9:0]          cu_xstr_rgt,        // x-start point @ right
output reg  [ 9:0]          cu_xstr_a1_rgt,     // x-start point+1 @ right
output      [ 9:0]          cu_xend_rgt,        // x-end point @ right
output reg  [ 9:0]          cu_xend_a1_rgt,     // x-end point+1 @ right
output      [ 8:0]          cu_xstr_ctr,        // x-start point @ center
output reg  [ 8:0]          cu_xstr_a1_ctr,     // x-start point+1 @ center
output      [ 8:0]          cu_xend_ctr,        // x-end point @ center
output reg  [ 8:0]          cu_xend_a1_ctr,     // x-end point+1 @ center


//----------------------------------------------//
// Input declaration                            //
//----------------------------------------------//

input       [ALU_SZ -1:0]   prod_msb,           // operation product MSB
input       [NUM0_SZ-1:0]   prod_lsb,           // operation product LSB
input       [PC_NUM   :0]   cu_cmd_en,          // command enable
input                       op_rdy_sm,          // @ OP_RDY state

input                       fm_str,             // frame start

input       [ 7:0]          pgl_palt_yr,        // Y color palette: red
input       [ 7:0]          pgl_palt_yg,        // Y color palette: green
input       [ 7:0]          pgl_palt_yy,        // Y color palette: yellow
input       [ 7:0]          pgl_palt_yb,        // Y color palette: blue
input       [ 7:0]          pgl_palt_bw0,        // Y color palette: white
input       [ 8:0]          pgl_palt_ur,        // U color palette: red
input       [ 8:0]          pgl_palt_ug,        // U color palette: green
input       [ 8:0]          pgl_palt_uy,        // U color palette: yellow
input       [ 8:0]          pgl_palt_ub,        // U color palette: blue
input       [ 8:0]          pgl_palt_vr,        // V color palette: red
input       [ 8:0]          pgl_palt_vg,        // V color palette: green
input       [ 8:0]          pgl_palt_vy,        // V color palette: yellow
input       [ 8:0]          pgl_palt_vb,        // V color palette: blue
input       [ 5:0]          pgl_wwg_mul,        // PGL width weighting multiplier
input       [ 8:0]          pgl_wid_bs_lft,     // PGL width base @ left
input       [ 8:0]          pgl_wid_bs_rgt,     // PGL width base @ right
input       [ 9:0]          pgl_wwg_lft,        // PGL width weighting @ left
input       [ 9:0]          pgl_wwg_rgt,        // PGL width weighting @ right
input       [ 7:0]          pgl_ystr_lft,       // PGL y-start point for current segment @ left
input       [ 7:0]          pgl_ystr_rgt,       // PGL y-start point for current segment @ right
input       [ 5:0]          pgl_h_lft,          // PGL height for current segment @ left
input       [ 5:0]          pgl_h_rgt,          // PGL height for current segment @ right
input       [ 9:0]          pgl_vcnt,           // PGL v-counter

input       [ 3:0]          reg_pgl_palt_yrto,  // Y color palette saturation decreasing ratio
input       [ 3:0]          reg_pgl_palt_crto,  // UV color palette brightness decreasing ratio
input                       reg_pgl_mirror,     // right PGL line mirrored by left line
input       [ 7:0]          reg_pgl_len_ctr,    // PGL total length of center line
input       [ 5:0]          reg_pgl_vln_wid,    // PGL vertical-type line width
input       [ 3:0]          reg_pgl_hln_m0,     // PGL multiplying factor 0 for horizontal-type line width
input       [ 3:0]          reg_pgl_hln_m1,     // PGL multiplying factor 1 for horizontal-type line width
input       [ 7:0]          reg_pgl_trsp,       // PGL transparency factor
input       [ 1:0]          reg_pgl_aa_twg,     // PGL anti-alias line edge color transpancy weighting
input                       reg_pgl_evw_lim,    // PGL width limit to even value

input       [ 3:0]          reg_pgl_wwg_lft,    // PGL width weighting for left line
input       [ 7:0]          reg_pgl_ystr0_lft,  // PGL Y-start point for dash-segment 0 @ left
input       [ 7:0]          reg_pgl_ybnd_lft,   // PGL Y bound point for left line
input       [ 7:0]          reg_pgl_slpwg_lft,  // PGL slope weighting for left line
input       [ 7:0]          reg_pgl_slp_lft,    // PGL slope for left line
input       [ 7:0]          reg_pgl_xstr_lft,   // PGL x-start point for left line

input       [ 3:0]          reg_pgl_wwg_rgt,    // PGL width weighting for right line
input       [ 7:0]          reg_pgl_ystr0_rgt,  // PGL Y-start point for dash-segment 0 @ right
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
// Local Parameter                              //
//----------------------------------------------//

localparam                  LR_XSFT     = 7'h60;

localparam                  OP_ADD      = 2'b00,
                            OP_SUB      = 2'b01,
                            OP_MUL      = 2'b10,
                            OP_DIV      = 2'b11;

localparam                  ZERO        = 1'b0;
localparam                  FREE_STATE  = 1'b0;

//----------------------------------------------//
// Register declaration                         //
//----------------------------------------------//
reg         [27:0]          cu_tmp0;            // temp register 0 for CU operation
reg         [27:0]          cu_tmp1;            // temp register 1 for CU operation
reg         [27:0]          cu_tmp2;            // temp register 2 for CU operation
reg         [27:0]          cu_tmp3;            // temp register 3 for CU operation
reg         [ 8:0]          cu_yb0_dlt_lft;     // (Y bound - Y0) on left line
reg         [ 8:0]          cu_yb0_dlt_rgt;     // (Y bound - Y0) on right line
reg         [ 9:0]          cu_vend_ctr;        // Vertical end point of center line
reg         [ 9:0]          y_p1;               // y counter + 1
reg         [18:0]          cu_xstr_lft_shr;    // x-start point register shared with other CU operation
reg         [10:0]          cu_xend_lft_shr;    // x-end point register shared with other CU operation
reg         [16:0]          pgl_wid_lft;        // PGL width @ left
reg         [18:0]          cu_xstr_rgt_shr;    // x-start point register shared with other CU operation
reg         [18:0]          cu_xend_rgt_shr;    // x-end point register shared with other CU operation
reg         [16:0]          pgl_wid_rgt;        // PGL width @ right
reg         [ 9:0]          cu_xstr_ctr_shr;    // x-start point register shared with other CU operation
reg         [ 9:0]          cu_xend_ctr_shr;    // x-end point register shared with other CU operation
reg         [ 6:0]          pgl_wid_ctr;        // PGL width @ center
reg         [ 9:0]          cu_ystr_lft;        // y-start point @ left
reg         [ 9:0]          cu_yend_lft;        // y-end point @ left
reg         [ 9:0]          cu_ystr_rgt;        // y-start point @ right
reg         [ 9:0]          cu_yend_rgt;        // y-end point @ right
reg         [ 9:0]          cu_yend_ctr;        // y-end point @ center
reg         [ 9:0]          cu_ystr_ctr;        // y-start point @ center
reg                         cu_yb0_lft_csgb;    // comparing sign bit: sign(reg_pgl_ybnd_lft - reg_pgl_ystr0_lft)
reg                         cu_yb0_rgt_csgb;    // comparing sign bit: sign(reg_pgl_ybnd_rgt - reg_pgl_ystr0_rgt)
reg         [ 8:0]          cu_pgl_xstr_lft;    // reg_pgl_xstr_lft + 7'h60
reg         [ 8:0]          cu_pgl_xstr_rgt;    // reg_pgl_xstr_rgt + 7'h60
reg         [18:0]          xstr_tmp_lft;       // temp reg for mirror usage on right side

wire        [ 7:0]          cu_pgl_palt_yr_nxt;
wire        [ 7:0]          cu_pgl_palt_yg_nxt;
wire        [ 7:0]          cu_pgl_palt_yy_nxt;
wire        [ 7:0]          cu_pgl_palt_yb_nxt;
wire        [ 7:0]          cu_pgl_palt_bw0_nxt;
wire        [ 7:0]          cu_pgl_palt_ur_nxt;
wire        [ 7:0]          cu_pgl_palt_ug_nxt;
wire        [ 7:0]          cu_pgl_palt_uy_nxt;
wire        [ 7:0]          cu_pgl_palt_ub_nxt;
wire        [ 7:0]          cu_pgl_palt_vr_nxt;
wire        [ 7:0]          cu_pgl_palt_vg_nxt;
wire        [ 7:0]          cu_pgl_palt_vy_nxt;
wire        [ 7:0]          cu_pgl_palt_vb_nxt;
wire        [ 8:0]          cu_pgl_aa_trsp_nxt;
wire        [ 8:0]          cu_pgl_trsp_cmpl_nxt;
wire        [ 8:0]          cu_pgl_aa_cmpl_nxt;

wire                        cu_y0_lft_eq_nxt;
wire                        cu_y0_lft_csgb_nxt;
wire                        cu_ystr_lft_csgb_nxt;
wire                        cu_ystr_lft_eq_nxt;
wire                        cu_yend_lft_eq_nxt;
wire                        cu_yend_lft_csgb_nxt;
wire                        cu_ybnd_lft_csgb_nxt;
wire                        cu_y0_rgt_eq_nxt;
wire                        cu_y0_rgt_csgb_nxt;
wire                        cu_ystr_rgt_csgb_nxt;
wire                        cu_ystr_rgt_eq_nxt;
wire                        cu_yend_rgt_eq_nxt;
wire                        cu_yend_rgt_csgb_nxt;
wire                        cu_ybnd_rgt_csgb_nxt;

wire                        cu_y0_ctr_csgb_nxt;
wire                        cu_ystr_ctr_eq_nxt;
wire                        cu_ystr_ctr_csgb_nxt;
wire                        cu_yend_ctr_eq_nxt;
wire                        cu_yend_ctr_csgb_nxt;
wire                        cu_vend_ctr_csgb_nxt;

wire        [ 9:0]          cu_xstr_a1_lft_nxt;
wire        [ 9:0]          cu_xend_a1_lft_nxt;
wire        [ 9:0]          cu_xstr_a1_rgt_nxt;
wire        [ 9:0]          cu_xend_a1_rgt_nxt;
wire        [ 8:0]          cu_xstr_a1_ctr_nxt;
wire        [ 8:0]          cu_xend_a1_ctr_nxt;

wire        [27:0]          cu_tmp0_nxt;
wire        [27:0]          cu_tmp1_nxt;
wire        [27:0]          cu_tmp2_nxt;
wire        [27:0]          cu_tmp3_nxt;
wire        [ 8:0]          cu_yb0_dlt_lft_nxt;
wire        [ 8:0]          cu_yb0_dlt_rgt_nxt;
wire        [ 9:0]          cu_vend_ctr_nxt;
wire        [ 8:0]          cu_pgl_hln0_wid_nxt;
wire        [ 8:0]          cu_pgl_hln1_wid_nxt;
wire        [ 9:0]          cu_pgl_hwwg_lft_nxt;
wire        [ 9:0]          cu_pgl_hwwg_rgt_nxt;

wire        [ 9:0]          y_p1_nxt;
wire        [18:0]          cu_xstr_lft_shr_nxt;
wire        [10:0]          cu_xend_lft_shr_nxt;
wire        [16:0]          pgl_wid_lft_nxt;
wire        [18:0]          cu_xstr_rgt_shr_nxt;
wire        [18:0]          cu_xend_rgt_shr_nxt;
wire        [16:0]          pgl_wid_rgt_nxt;
wire        [ 9:0]          cu_xstr_ctr_shr_nxt;
wire        [ 9:0]          cu_xend_ctr_shr_nxt;
wire        [ 6:0]          pgl_wid_ctr_nxt;
wire        [ 9:0]          cu_ystr_lft_nxt;
wire        [ 9:0]          cu_yend_lft_nxt;
wire        [ 9:0]          cu_ystr_rgt_nxt;
wire        [ 9:0]          cu_yend_rgt_nxt;
wire        [ 9:0]          cu_yend_ctr_nxt;
wire        [ 9:0]          cu_ystr_ctr_nxt;
wire                        cu_yb0_lft_csgb_nxt;
wire                        cu_yb0_rgt_csgb_nxt;
wire        [ 8:0]          cu_pgl_xstr_lft_nxt;
wire        [ 8:0]          cu_pgl_xstr_rgt_nxt;
wire        [18:0]          xstr_tmp_lft_nxt;

//----------------------------------------------//
// Wire declaration                             //
//----------------------------------------------//
wire                        pgl_palt_ur_sgb;    // sign bit of pgl_palt_ur from U-Palette table
wire                        pgl_palt_ug_sgb;    // sign bit of pgl_palt_ug from U-Palette table
wire                        pgl_palt_uy_sgb;    // sign bit of pgl_palt_uy from U-Palette table
wire                        pgl_palt_ub_sgb;    // sign bit of pgl_palt_ub from U-Palette table
wire                        pgl_palt_vr_sgb;    // sign bit of pgl_palt_vr from V-Palette table
wire                        pgl_palt_vg_sgb;    // sign bit of pgl_palt_vg from V-Palette table
wire                        pgl_palt_vy_sgb;    // sign bit of pgl_palt_vy from V-Palette table
wire                        pgl_palt_vb_sgb;    // sign bit of pgl_palt_vb from V-Palette table
wire                        palt_ur_op;         // ADD or SUB operation for pgl_palt_ur
wire                        palt_ug_op;         // ADD or SUB operation for pgl_palt_ug
wire                        palt_uy_op;         // ADD or SUB operation for pgl_palt_uy
wire                        palt_ub_op;         // ADD or SUB operation for pgl_palt_ub
wire                        palt_vr_op;         // ADD or SUB operation for pgl_palt_vr
wire                        palt_vg_op;         // ADD or SUB operation for pgl_palt_vg
wire                        palt_vy_op;         // ADD or SUB operation for pgl_palt_vy
wire                        palt_vb_op;         // ADD or SUB operation for pgl_palt_vb
wire                        xstr_lft_op;        // ADD or SUB operation for
wire        [17:0]          xstr_cofst_lft;     // left side of x-start offset on curve line
wire        [17:0]          xstr_cofst_rgt;     // right side of x-start offset on curve line
wire        [17:0]          xstr_l2r;           // Mux of left/right x-start
wire        [16:0]          pgl_wid_l2r;        // Mux of left/right PGL width
wire        [ 7:0]          pgl_ystr_l2r;       // Mux of PGL y-start point for current segment
wire        [ 5:0]          pgl_h_l2r;          // Mux of PGL height for current segment
wire        [ 7:0]          pgl_ystr0_l2r;      // Mux of PGL Y-start point for dash-segment 0
wire        [ 7:0]          pgl_ybnd_l2r;       // Mux of PGL Y bound point
wire        [ 7:0]          pgl_slpwg_l2r;      // Mux of PGL slope weighting
wire        [ 7:0]          pgl_slp_l2r;        // Mux of PGL slope
wire        [ 5:0]          palt_yrto;          // ratio of Y palette
wire        [ 5:0]          palt_crto;          // ratio of UV palette
wire        [ 7:0]          palt_ur_tmp;        //
wire        [ 7:0]          palt_ug_tmp;        //
wire        [ 7:0]          palt_uy_tmp;        //
wire        [ 7:0]          palt_ub_tmp;        //
wire        [ 7:0]          palt_vr_tmp;        //
wire        [ 7:0]          palt_vg_tmp;        //
wire        [ 7:0]          palt_vy_tmp;        //
wire        [ 7:0]          palt_vb_tmp;        //
wire        [ 2:0]          pgl_aa_k_cmpl;      // 4 [1.2] - reg_pgl_aa_twg [.2]
wire        [17:0]          cu_xstr_full_lft;   // x-start point with full fractional @ left
wire        [17:0]          cu_xend_full_rgt;   // x-end point with full fractional @ right
wire        [ 9:0]          cu_ydlt_lft;        // y_p1 - reg_pgl_ystr0_lft
wire        [ 9:0]          cu_ydlt_rgt;        // y_p1 - reg_pgl_ystr0_rgt
wire        [16:0]          wid_dlt_lft;        // PGL ydlt dependent width delta @ left
wire        [19:0]          ydlt_sqr_lft;       // (cu_ydlt_lft)^2
wire        [17:0]          xstr_cofst0_lft;    // x-start offset 0 at left curve line
wire        [ 9:0]          yyb_dlt_lft;        // y_p1 - reg_ybnd_lft
wire        [10:0]          yy0yb_dsum_lft;     // cu_ydlt_lft + yyb_dlt_lft
wire        [19:0]          xstr_cofst_item_lft;// (Y bound - Y0) * yy0yb_dsum_lft
wire        [17:0]          xstr_cofst1_lft;    // x-start offset 1 at left curve line
wire        [18:0]          xstr_part_lft;      // reg_pgl_xstr_lft + xstr_cofst_lft
wire        [17:0]          xstr_lofst_lft;     // x-start offset at left straight line
wire        [16:0]          wid_dlt_rgt;        // PGL ydlt dependent width delta @ right
wire        [19:0]          ydlt_sqr_rgt;       // (cu_ydlt_rgt)^2
wire        [17:0]          xstr_cofst0_rgt;    // x-start offset 0 at right curve line
wire        [ 9:0]          yyb_dlt_rgt;        // y_p1 - reg_ybnd_rgt
wire        [10:0]          yy0yb_dsum_rgt;     // cu_ydlt_rgt + yyb_dlt_rgt
wire        [19:0]          xstr_cofst_item_rgt;// (Y bound - Y0) * yy0yb_dsum_rgt
wire        [17:0]          xstr_cofst1_rgt;    // x-start offset 1 at right curve line
wire        [18:0]          xstr_part_rgt;      // reg_pgl_xstr_rgt + xstr_cofst_rgt
wire        [17:0]          xstr_lofst_rgt;     // x-start offset at right straight line
wire        [17:0]          xstr_tmp_rgt;       // x-start point related temp wire
wire        [ 9:0]          cu_ydlt_ctr;        // y_p1 - reg_pgl_ystr_ctr
wire        [ 5:0]          wid_dlt_ctr;        // PGL ydlt dependent width delta @ center
wire        [ 5:0]          hgt_dlt_ctr;        // PGL ydlt dependent height @ center
wire        [ 6:0]          pgl_hgt_ctr;        // PGL height at current segment @ center
wire        [ 6:0]          pgl_blk_ctr;        // PGL blanking length at current segment @ center

//
wire[ 1:0]                  opcode000;
wire[NUM0_SZ-1:0]           num_0_000;
wire[NUM1_SZ-1:0]           num_1_000;
wire[ 1:0]                  opcode001;
wire[NUM0_SZ-1:0]           num_0_001;
wire[NUM1_SZ-1:0]           num_1_001;
wire[ 1:0]                  opcode002;
wire[NUM0_SZ-1:0]           num_0_002;
wire[NUM1_SZ-1:0]           num_1_002;
wire[ 1:0]                  opcode003;
wire[NUM0_SZ-1:0]           num_0_003;
wire[NUM1_SZ-1:0]           num_1_003;
wire[ 1:0]                  opcode004;
wire[NUM0_SZ-1:0]           num_0_004;
wire[NUM1_SZ-1:0]           num_1_004;
wire[ 1:0]                  opcode005;
wire[NUM0_SZ-1:0]           num_0_005;
wire[NUM1_SZ-1:0]           num_1_005;
wire[ 1:0]                  opcode006;
wire[NUM0_SZ-1:0]           num_0_006;
wire[NUM1_SZ-1:0]           num_1_006;
wire[ 1:0]                  opcode007;
wire[NUM0_SZ-1:0]           num_0_007;
wire[NUM1_SZ-1:0]           num_1_007;
wire[ 1:0]                  opcode008;
wire[NUM0_SZ-1:0]           num_0_008;
wire[NUM1_SZ-1:0]           num_1_008;
wire[ 1:0]                  opcode009;
wire[NUM0_SZ-1:0]           num_0_009;
wire[NUM1_SZ-1:0]           num_1_009;
wire[ 1:0]                  opcode00a;
wire[NUM0_SZ-1:0]           num_0_00a;
wire[NUM1_SZ-1:0]           num_1_00a;
wire[ 1:0]                  opcode00b;
wire[NUM0_SZ-1:0]           num_0_00b;
wire[NUM1_SZ-1:0]           num_1_00b;
wire[ 1:0]                  opcode00c;
wire[NUM0_SZ-1:0]           num_0_00c;
wire[NUM1_SZ-1:0]           num_1_00c;
wire[ 1:0]                  opcode00d;
wire[NUM0_SZ-1:0]           num_0_00d;
wire[NUM1_SZ-1:0]           num_1_00d;
wire[ 1:0]                  opcode00e;
wire[NUM0_SZ-1:0]           num_0_00e;
wire[NUM1_SZ-1:0]           num_1_00e;
wire[ 1:0]                  opcode00f;
wire[NUM0_SZ-1:0]           num_0_00f;
wire[NUM1_SZ-1:0]           num_1_00f;
wire[ 1:0]                  opcode010;
wire[NUM0_SZ-1:0]           num_0_010;
wire[NUM1_SZ-1:0]           num_1_010;
wire[ 1:0]                  opcode011;
wire[NUM0_SZ-1:0]           num_0_011;
wire[NUM1_SZ-1:0]           num_1_011;
wire[ 1:0]                  opcode012;
wire[NUM0_SZ-1:0]           num_0_012;
wire[NUM1_SZ-1:0]           num_1_012;
wire[ 1:0]                  opcode013;
wire[NUM0_SZ-1:0]           num_0_013;
wire[NUM1_SZ-1:0]           num_1_013;
wire[ 1:0]                  opcode014;
wire[NUM0_SZ-1:0]           num_0_014;
wire[NUM1_SZ-1:0]           num_1_014;
wire[ 1:0]                  opcode015;
wire[NUM0_SZ-1:0]           num_0_015;
wire[NUM1_SZ-1:0]           num_1_015;
wire[ 1:0]                  opcode016;
wire[NUM0_SZ-1:0]           num_0_016;
wire[NUM1_SZ-1:0]           num_1_016;
wire[ 1:0]                  opcode017;
wire[NUM0_SZ-1:0]           num_0_017;
wire[NUM1_SZ-1:0]           num_1_017;
wire[ 1:0]                  opcode018;
wire[NUM0_SZ-1:0]           num_0_018;
wire[NUM1_SZ-1:0]           num_1_018;
wire[ 1:0]                  opcode019;
wire[NUM0_SZ-1:0]           num_0_019;
wire[NUM1_SZ-1:0]           num_1_019;
wire[ 1:0]                  opcode01a;
wire[NUM0_SZ-1:0]           num_0_01a;
wire[NUM1_SZ-1:0]           num_1_01a;
wire[ 1:0]                  opcode01b;
wire[NUM0_SZ-1:0]           num_0_01b;
wire[NUM1_SZ-1:0]           num_1_01b;
wire[ 1:0]                  opcode01c;
wire[NUM0_SZ-1:0]           num_0_01c;
wire[NUM1_SZ-1:0]           num_1_01c;
wire[ 1:0]                  opcode01d;
wire[NUM0_SZ-1:0]           num_0_01d;
wire[NUM1_SZ-1:0]           num_1_01d;
wire[ 1:0]                  opcode01e;
wire[NUM0_SZ-1:0]           num_0_01e;
wire[NUM1_SZ-1:0]           num_1_01e;
wire[ 1:0]                  opcode01f;
wire[NUM0_SZ-1:0]           num_0_01f;
wire[NUM1_SZ-1:0]           num_1_01f;
wire[ 1:0]                  opcode020;
wire[NUM0_SZ-1:0]           num_0_020;
wire[NUM1_SZ-1:0]           num_1_020;
wire[ 1:0]                  opcode021;
wire[NUM0_SZ-1:0]           num_0_021;
wire[NUM1_SZ-1:0]           num_1_021;
wire[ 1:0]                  opcode022;
wire[NUM0_SZ-1:0]           num_0_022;
wire[NUM1_SZ-1:0]           num_1_022;
wire[ 1:0]                  opcode023;
wire[NUM0_SZ-1:0]           num_0_023;
wire[NUM1_SZ-1:0]           num_1_023;
wire[ 1:0]                  opcode024;
wire[NUM0_SZ-1:0]           num_0_024;
wire[NUM1_SZ-1:0]           num_1_024;
wire[ 1:0]                  opcode025;
wire[NUM0_SZ-1:0]           num_0_025;
wire[NUM1_SZ-1:0]           num_1_025;

wire[ 1:0]                  opcode100;
wire[NUM0_SZ-1:0]           num_0_100;
wire[NUM1_SZ-1:0]           num_1_100;
wire[ 1:0]                  opcode101;
wire[NUM0_SZ-1:0]           num_0_101;
wire[NUM1_SZ-1:0]           num_1_101;
wire[ 1:0]                  opcode102;
wire[NUM0_SZ-1:0]           num_0_102;
wire[NUM1_SZ-1:0]           num_1_102;
wire[ 1:0]                  opcode103;
wire[NUM0_SZ-1:0]           num_0_103;
wire[NUM1_SZ-1:0]           num_1_103;
wire[ 1:0]                  opcode104;
wire[NUM0_SZ-1:0]           num_0_104;
wire[NUM1_SZ-1:0]           num_1_104;
wire[ 1:0]                  opcode105;
wire[NUM0_SZ-1:0]           num_0_105;
wire[NUM1_SZ-1:0]           num_1_105;
wire[ 1:0]                  opcode106;
wire[NUM0_SZ-1:0]           num_0_106;
wire[NUM1_SZ-1:0]           num_1_106;
wire[ 1:0]                  opcode107;
wire[NUM0_SZ-1:0]           num_0_107;
wire[NUM1_SZ-1:0]           num_1_107;
wire[ 1:0]                  opcode108;
wire[NUM0_SZ-1:0]           num_0_108;
wire[NUM1_SZ-1:0]           num_1_108;
wire[ 1:0]                  opcode109;
wire[NUM0_SZ-1:0]           num_0_109;
wire[NUM1_SZ-1:0]           num_1_109;
wire[ 1:0]                  opcode10a;
wire[NUM0_SZ-1:0]           num_0_10a;
wire[NUM1_SZ-1:0]           num_1_10a;
wire[ 1:0]                  opcode10b;
wire[NUM0_SZ-1:0]           num_0_10b;
wire[NUM1_SZ-1:0]           num_1_10b;
wire[ 1:0]                  opcode10c;
wire[NUM0_SZ-1:0]           num_0_10c;
wire[NUM1_SZ-1:0]           num_1_10c;
wire[ 1:0]                  opcode10d;
wire[NUM0_SZ-1:0]           num_0_10d;
wire[NUM1_SZ-1:0]           num_1_10d;
wire[ 1:0]                  opcode10e;
wire[NUM0_SZ-1:0]           num_0_10e;
wire[NUM1_SZ-1:0]           num_1_10e;
wire[ 1:0]                  opcode10f;
wire[NUM0_SZ-1:0]           num_0_10f;
wire[NUM1_SZ-1:0]           num_1_10f;

wire[ 1:0]                  opcode200;
wire[NUM0_SZ-1:0]           num_0_200;
wire[NUM1_SZ-1:0]           num_1_200;
wire[ 1:0]                  opcode201;
wire[NUM0_SZ-1:0]           num_0_201;
wire[NUM1_SZ-1:0]           num_1_201;
wire[ 1:0]                  opcode202;
wire[NUM0_SZ-1:0]           num_0_202;
wire[NUM1_SZ-1:0]           num_1_202;
wire[ 1:0]                  opcode203;
wire[NUM0_SZ-1:0]           num_0_203;
wire[NUM1_SZ-1:0]           num_1_203;
wire[ 1:0]                  opcode204;
wire[NUM0_SZ-1:0]           num_0_204;
wire[NUM1_SZ-1:0]           num_1_204;
wire[ 1:0]                  opcode205;
wire[NUM0_SZ-1:0]           num_0_205;
wire[NUM1_SZ-1:0]           num_1_205;
wire[ 1:0]                  opcode206;
wire[NUM0_SZ-1:0]           num_0_206;
wire[NUM1_SZ-1:0]           num_1_206;
wire[ 1:0]                  opcode207;
wire[NUM0_SZ-1:0]           num_0_207;
wire[NUM1_SZ-1:0]           num_1_207;
wire[ 1:0]                  opcode208;
wire[NUM0_SZ-1:0]           num_0_208;
wire[NUM1_SZ-1:0]           num_1_208;
wire[ 1:0]                  opcode209;
wire[NUM0_SZ-1:0]           num_0_209;
wire[NUM1_SZ-1:0]           num_1_209;
wire[ 1:0]                  opcode20a;
wire[NUM0_SZ-1:0]           num_0_20a;
wire[NUM1_SZ-1:0]           num_1_20a;
wire[ 1:0]                  opcode20b;
wire[NUM0_SZ-1:0]           num_0_20b;
wire[NUM1_SZ-1:0]           num_1_20b;
wire[ 1:0]                  opcode20c;
wire[NUM0_SZ-1:0]           num_0_20c;
wire[NUM1_SZ-1:0]           num_1_20c;
wire[ 1:0]                  opcode20d;
wire[NUM0_SZ-1:0]           num_0_20d;
wire[NUM1_SZ-1:0]           num_1_20d;
wire[ 1:0]                  opcode20e;
wire[NUM0_SZ-1:0]           num_0_20e;
wire[NUM1_SZ-1:0]           num_1_20e;
wire[ 1:0]                  opcode20f;
wire[NUM0_SZ-1:0]           num_0_20f;
wire[NUM1_SZ-1:0]           num_1_20f;
wire[ 1:0]                  opcode210;
wire[NUM0_SZ-1:0]           num_0_210;
wire[NUM1_SZ-1:0]           num_1_210;

wire[ 1:0]                  opcode300;
wire[NUM0_SZ-1:0]           num_0_300;
wire[NUM1_SZ-1:0]           num_1_300;
wire[ 1:0]                  opcode301;
wire[NUM0_SZ-1:0]           num_0_301;
wire[NUM1_SZ-1:0]           num_1_301;
wire[ 1:0]                  opcode302;
wire[NUM0_SZ-1:0]           num_0_302;
wire[NUM1_SZ-1:0]           num_1_302;
wire[ 1:0]                  opcode303;
wire[NUM0_SZ-1:0]           num_0_303;
wire[NUM1_SZ-1:0]           num_1_303;
wire[ 1:0]                  opcode304;
wire[NUM0_SZ-1:0]           num_0_304;
wire[NUM1_SZ-1:0]           num_1_304;
wire[ 1:0]                  opcode305;
wire[NUM0_SZ-1:0]           num_0_305;
wire[NUM1_SZ-1:0]           num_1_305;
wire[ 1:0]                  opcode306;
wire[NUM0_SZ-1:0]           num_0_306;
wire[NUM1_SZ-1:0]           num_1_306;
wire[ 1:0]                  opcode307;
wire[NUM0_SZ-1:0]           num_0_307;
wire[NUM1_SZ-1:0]           num_1_307;
wire[ 1:0]                  opcode308;
wire[NUM0_SZ-1:0]           num_0_308;
wire[NUM1_SZ-1:0]           num_1_308;
wire[ 1:0]                  opcode309;
wire[NUM0_SZ-1:0]           num_0_309;
wire[NUM1_SZ-1:0]           num_1_309;
wire[ 1:0]                  opcode30a;
wire[NUM0_SZ-1:0]           num_0_30a;
wire[NUM1_SZ-1:0]           num_1_30a;
wire[ 1:0]                  opcode30b;
wire[NUM0_SZ-1:0]           num_0_30b;
wire[NUM1_SZ-1:0]           num_1_30b;
wire[ 1:0]                  opcode30c;
wire[NUM0_SZ-1:0]           num_0_30c;
wire[NUM1_SZ-1:0]           num_1_30c;
wire[ 1:0]                  opcode30d;
wire[NUM0_SZ-1:0]           num_0_30d;
wire[NUM1_SZ-1:0]           num_1_30d;
wire[ 1:0]                  opcode30e;
wire[NUM0_SZ-1:0]           num_0_30e;
wire[NUM1_SZ-1:0]           num_1_30e;
wire[ 1:0]                  opcode30f;
wire[NUM0_SZ-1:0]           num_0_30f;
wire[NUM1_SZ-1:0]           num_1_30f;
wire[ 1:0]                  opcode310;
wire[NUM0_SZ-1:0]           num_0_310;
wire[NUM1_SZ-1:0]           num_1_310;

wire[ 1:0]                  opcode400;
wire[NUM0_SZ-1:0]           num_0_400;
wire[NUM1_SZ-1:0]           num_1_400;
wire[ 1:0]                  opcode401;
wire[NUM0_SZ-1:0]           num_0_401;
wire[NUM1_SZ-1:0]           num_1_401;
wire[ 1:0]                  opcode402;
wire[NUM0_SZ-1:0]           num_0_402;
wire[NUM1_SZ-1:0]           num_1_402;
wire[ 1:0]                  opcode403;
wire[NUM0_SZ-1:0]           num_0_403;
wire[NUM1_SZ-1:0]           num_1_403;
wire[ 1:0]                  opcode404;
wire[NUM0_SZ-1:0]           num_0_404;
wire[NUM1_SZ-1:0]           num_1_404;
wire[ 1:0]                  opcode405;
wire[NUM0_SZ-1:0]           num_0_405;
wire[NUM1_SZ-1:0]           num_1_405;
wire[ 1:0]                  opcode406;
wire[NUM0_SZ-1:0]           num_0_406;
wire[NUM1_SZ-1:0]           num_1_406;

wire[ 1:0]                  opcode500;
wire[NUM0_SZ-1:0]           num_0_500;
wire[NUM1_SZ-1:0]           num_1_500;
wire[ 1:0]                  opcode501;
wire[NUM0_SZ-1:0]           num_0_501;
wire[NUM1_SZ-1:0]           num_1_501;
wire[ 1:0]                  opcode502;
wire[NUM0_SZ-1:0]           num_0_502;
wire[NUM1_SZ-1:0]           num_1_502;

wire[ 1:0]                  opcode600;
wire[NUM0_SZ-1:0]           num_0_600;
wire[NUM1_SZ-1:0]           num_1_600;
wire[ 1:0]                  opcode601;
wire[NUM0_SZ-1:0]           num_0_601;
wire[NUM1_SZ-1:0]           num_1_601;
wire[ 1:0]                  opcode602;
wire[NUM0_SZ-1:0]           num_0_602;
wire[NUM1_SZ-1:0]           num_1_602;

wire[ 1:0]                  opcode700;
wire[NUM0_SZ-1:0]           num_0_700;
wire[NUM1_SZ-1:0]           num_1_700;
wire[ 1:0]                  opcode701;
wire[NUM0_SZ-1:0]           num_0_701;
wire[NUM1_SZ-1:0]           num_1_701;
wire[ 1:0]                  opcode702;
wire[NUM0_SZ-1:0]           num_0_702;
wire[NUM1_SZ-1:0]           num_1_702;

wire[ 1:0]                  opcode800;
wire[NUM0_SZ-1:0]           num_0_800;
wire[NUM1_SZ-1:0]           num_1_800;
wire[ 1:0]                  opcode801;
wire[NUM0_SZ-1:0]           num_0_801;
wire[NUM1_SZ-1:0]           num_1_801;
wire[ 1:0]                  opcode802;
wire[NUM0_SZ-1:0]           num_0_802;
wire[NUM1_SZ-1:0]           num_1_802;


//----------------------------------------------//
// Code Descriptions                            //
//----------------------------------------------//

//
assign  opcode = opcode000 |
                 opcode001 |
                 opcode002 |
                 opcode003 |
                 opcode004 |
                 opcode005 |
                 opcode006 |
                 opcode007 |
                 opcode008 |
                 opcode009 |
                 opcode00a |
                 opcode00b |
                 opcode00c |
                 opcode00d |
                 opcode00e |
                 opcode00f |
                 opcode010 |
                 opcode011 |
                 opcode012 |
                 opcode013 |
                 opcode014 |
                 opcode015 |
                 opcode016 |
                 opcode017 |
                 opcode018 |
                 opcode019 |
                 opcode01a |
                 opcode01b |
                 opcode01c |
                 opcode01d |
                 opcode01e |
                 opcode01f |
                 opcode020 |
                 opcode021 |
                 opcode022 |
                 opcode023 |
                 opcode024 |
                 opcode025 |

                 opcode100 |
                 opcode101 |
                 opcode102 |
                 opcode103 |
                 opcode104 |
                 opcode105 |
                 opcode106 |
                 opcode107 |
                 opcode108 |
                 opcode109 |
                 opcode10a |
                 opcode10b |
                 opcode10c |
                 opcode10d |
                 opcode10e |
                 opcode10f |

                 opcode200 |
                 opcode201 |
                 opcode202 |
                 opcode203 |
                 opcode204 |
                 opcode205 |
                 opcode206 |
                 opcode207 |
                 opcode208 |
                 opcode209 |
                 opcode20a |
                 opcode20b |
                 opcode20c |
                 opcode20d |
                 opcode20e |
                 opcode20f |
                 opcode210 |

                 opcode300 |
                 opcode301 |
                 opcode302 |
                 opcode303 |
                 opcode304 |
                 opcode305 |
                 opcode306 |
                 opcode307 |
                 opcode308 |
                 opcode309 |
                 opcode30a |
                 opcode30b |
                 opcode30c |
                 opcode30d |
                 opcode30e |
                 opcode30f |
                 opcode310 |

                 opcode400 |
                 opcode401 |
                 opcode402 |
                 opcode403 |
                 opcode404 |
                 opcode405 |
                 opcode406 |

                 opcode500 |
                 opcode501 |
                 opcode502 |

                 opcode600 |
                 opcode601 |
                 opcode602 |

                 opcode700 |
                 opcode701 |
                 opcode702 |

                 opcode800 |
                 opcode801 |
                 opcode802;

assign  num_0 =  num_0_000 |
                 num_0_001 |
                 num_0_002 |
                 num_0_003 |
                 num_0_004 |
                 num_0_005 |
                 num_0_006 |
                 num_0_007 |
                 num_0_008 |
                 num_0_009 |
                 num_0_00a |
                 num_0_00b |
                 num_0_00c |
                 num_0_00d |
                 num_0_00e |
                 num_0_00f |
                 num_0_010 |
                 num_0_011 |
                 num_0_012 |
                 num_0_013 |
                 num_0_014 |
                 num_0_015 |
                 num_0_016 |
                 num_0_017 |
                 num_0_018 |
                 num_0_019 |
                 num_0_01a |
                 num_0_01b |
                 num_0_01c |
                 num_0_01d |
                 num_0_01e |
                 num_0_01f |
                 num_0_020 |
                 num_0_021 |
                 num_0_022 |
                 num_0_023 |
                 num_0_024 |
                 num_0_025 |

                 num_0_100 |
                 num_0_101 |
                 num_0_102 |
                 num_0_103 |
                 num_0_104 |
                 num_0_105 |
                 num_0_106 |
                 num_0_107 |
                 num_0_108 |
                 num_0_109 |
                 num_0_10a |
                 num_0_10b |
                 num_0_10c |
                 num_0_10d |
                 num_0_10e |
                 num_0_10f |

                 num_0_200 |
                 num_0_201 |
                 num_0_202 |
                 num_0_203 |
                 num_0_204 |
                 num_0_205 |
                 num_0_206 |
                 num_0_207 |
                 num_0_208 |
                 num_0_209 |
                 num_0_20a |
                 num_0_20b |
                 num_0_20c |
                 num_0_20d |
                 num_0_20e |
                 num_0_20f |
                 num_0_210 |

                 num_0_300 |
                 num_0_301 |
                 num_0_302 |
                 num_0_303 |
                 num_0_304 |
                 num_0_305 |
                 num_0_306 |
                 num_0_307 |
                 num_0_308 |
                 num_0_309 |
                 num_0_30a |
                 num_0_30b |
                 num_0_30c |
                 num_0_30d |
                 num_0_30e |
                 num_0_30f |
                 num_0_310 |

                 num_0_400 |
                 num_0_401 |
                 num_0_402 |
                 num_0_403 |
                 num_0_404 |
                 num_0_405 |
                 num_0_406 |

                 num_0_500 |
                 num_0_501 |
                 num_0_502 |

                 num_0_600 |
                 num_0_601 |
                 num_0_602 |

                 num_0_700 |
                 num_0_701 |
                 num_0_702 |

                 num_0_800 |
                 num_0_801 |
                 num_0_802;

assign  num_1 =  num_1_000 |
                 num_1_001 |
                 num_1_002 |
                 num_1_003 |
                 num_1_004 |
                 num_1_005 |
                 num_1_006 |
                 num_1_007 |
                 num_1_008 |
                 num_1_009 |
                 num_1_00a |
                 num_1_00b |
                 num_1_00c |
                 num_1_00d |
                 num_1_00e |
                 num_1_00f |
                 num_1_010 |
                 num_1_011 |
                 num_1_012 |
                 num_1_013 |
                 num_1_014 |
                 num_1_015 |
                 num_1_016 |
                 num_1_017 |
                 num_1_018 |
                 num_1_019 |
                 num_1_01a |
                 num_1_01b |
                 num_1_01c |
                 num_1_01d |
                 num_1_01e |
                 num_1_01f |
                 num_1_020 |
                 num_1_021 |
                 num_1_022 |
                 num_1_023 |
                 num_1_024 |
                 num_1_025 |

                 num_1_100 |
                 num_1_101 |
                 num_1_102 |
                 num_1_103 |
                 num_1_104 |
                 num_1_105 |
                 num_1_106 |
                 num_1_107 |
                 num_1_108 |
                 num_1_109 |
                 num_1_10a |
                 num_1_10b |
                 num_1_10c |
                 num_1_10d |
                 num_1_10e |
                 num_1_10f |

                 num_1_200 |
                 num_1_201 |
                 num_1_202 |
                 num_1_203 |
                 num_1_204 |
                 num_1_205 |
                 num_1_206 |
                 num_1_207 |
                 num_1_208 |
                 num_1_209 |
                 num_1_20a |
                 num_1_20b |
                 num_1_20c |
                 num_1_20d |
                 num_1_20e |
                 num_1_20f |
                 num_1_210 |

                 num_1_300 |
                 num_1_301 |
                 num_1_302 |
                 num_1_303 |
                 num_1_304 |
                 num_1_305 |
                 num_1_306 |
                 num_1_307 |
                 num_1_308 |
                 num_1_309 |
                 num_1_30a |
                 num_1_30b |
                 num_1_30c |
                 num_1_30d |
                 num_1_30e |
                 num_1_30f |
                 num_1_310 |

                 num_1_400 |
                 num_1_401 |
                 num_1_402 |
                 num_1_403 |
                 num_1_404 |
                 num_1_405 |
                 num_1_406 |

                 num_1_500 |
                 num_1_501 |
                 num_1_502 |

                 num_1_600 |
                 num_1_601 |
                 num_1_602 |

                 num_1_700 |
                 num_1_701 |
                 num_1_702 |

                 num_1_800 |
                 num_1_801 |
                 num_1_802;


// for Color Palette calculation
assign  pgl_palt_ur_sgb = pgl_palt_ur[8];
assign  pgl_palt_ug_sgb = pgl_palt_ug[8];
assign  pgl_palt_uy_sgb = pgl_palt_uy[8];
assign  pgl_palt_ub_sgb = pgl_palt_ub[8];
assign  pgl_palt_vr_sgb = pgl_palt_vr[8];
assign  pgl_palt_vg_sgb = pgl_palt_vg[8];
assign  pgl_palt_vy_sgb = pgl_palt_vy[8];
assign  pgl_palt_vb_sgb = pgl_palt_vb[8];

assign  palt_ur_op = pgl_palt_ur_sgb ? OP_SUB : OP_ADD;
assign  palt_ug_op = pgl_palt_ug_sgb ? OP_SUB : OP_ADD;
assign  palt_uy_op = pgl_palt_uy_sgb ? OP_SUB : OP_ADD;
assign  palt_ub_op = pgl_palt_ub_sgb ? OP_SUB : OP_ADD;
assign  palt_vr_op = pgl_palt_vr_sgb ? OP_SUB : OP_ADD;
assign  palt_vg_op = pgl_palt_vg_sgb ? OP_SUB : OP_ADD;
assign  palt_vy_op = pgl_palt_vy_sgb ? OP_SUB : OP_ADD;
assign  palt_vb_op = pgl_palt_vb_sgb ? OP_SUB : OP_ADD;

assign  xstr_lft_op = cu_yb0_lft_csgb ? OP_SUB : OP_ADD;
assign  xstr_rgt_op = cu_yb0_rgt_csgb ? OP_SUB : OP_ADD;

assign  xstr_cofst_lft = cu_ybnd_lft_csgb ? xstr_cofst0_lft : xstr_cofst1_lft;
assign  xstr_cofst_rgt = cu_ybnd_rgt_csgb ? xstr_cofst0_rgt : xstr_cofst1_rgt;

assign  pgl_ystr_l2r   = reg_pgl_mirror ? pgl_ystr_lft      : pgl_ystr_rgt;
assign  pgl_h_l2r      = reg_pgl_mirror ? pgl_h_lft         : pgl_h_rgt;
assign  pgl_ystr0_l2r  = reg_pgl_mirror ? reg_pgl_ystr0_lft : reg_pgl_ystr0_rgt;
assign  pgl_ybnd_l2r   = reg_pgl_mirror ? reg_pgl_ybnd_lft  : reg_pgl_ybnd_rgt;
assign  pgl_slpwg_l2r  = reg_pgl_mirror ? reg_pgl_slpwg_lft : reg_pgl_slpwg_rgt;
assign  pgl_slp_l2r    = reg_pgl_mirror ? reg_pgl_slp_lft   : reg_pgl_slp_rgt;

assign  xstr_l2r       = reg_pgl_mirror ? xstr_tmp_lft      : xstr_tmp_rgt;
assign  pgl_wid_l2r    = reg_pgl_mirror ? pgl_wid_lft       : pgl_wid_rgt;

// ---------------------------------------------//
//            OP Code Begin                     //
// ---------------------------------------------//

// T0: Calculation @ frame start
// ===============================================
//   T0_PC+0: cu_vend_ctr [10.] =
//            reg_pgl_ystr_ctr [8.] + {reg_pgl_len_ctr, 1'b0} [9.]
assign  opcode000 = cu_cmd_en[T0_PC+7'h0] ? OP_ADD : {2{ZERO}};
assign  num_0_000 = cu_cmd_en[T0_PC+7'h0] ? {{NUM0_SZ- 8{1'b0}}, reg_pgl_ystr_ctr}      : {NUM0_SZ{FREE_STATE}};
assign  num_1_000 = cu_cmd_en[T0_PC+7'h0] ? {{NUM1_SZ- 9{1'b0}}, reg_pgl_len_ctr, 1'b0} : {NUM1_SZ{FREE_STATE}};

// cu_pgl_palt_y = pgl_palt_y * (32 - reg_pgl_palt_yrto) >> 5
//
//   T0_PC+1: palt_yrto [1.5] =
//            32 [1.5] - {1'b0, reg_pgl_palt_yrto} [.5]
assign  opcode001 = cu_cmd_en[T0_PC+7'h1] ? OP_SUB : {2{ZERO}};
assign  num_0_001 = cu_cmd_en[T0_PC+7'h1] ? {{NUM0_SZ- 6{1'b0}}, 6'h20}                   : {NUM0_SZ{FREE_STATE}};
assign  num_1_001 = cu_cmd_en[T0_PC+7'h1] ? {{NUM1_SZ- 5{1'b0}}, 1'b0, reg_pgl_palt_yrto} : {NUM1_SZ{FREE_STATE}};

//   T0_PC+2: cu_pgl_palt_yr [8.] =
//            pgl_palt_yr [8.] * palt_yrto [1.5]
assign  opcode002 = cu_cmd_en[T0_PC+7'h2] ? OP_MUL : {2{ZERO}};
assign  num_0_002 = cu_cmd_en[T0_PC+7'h2] ? {{NUM0_SZ- 8{1'b0}}, pgl_palt_yr} : {NUM0_SZ{FREE_STATE}};
assign  num_1_002 = cu_cmd_en[T0_PC+7'h2] ? {{NUM1_SZ- 6{1'b0}}, palt_yrto}   : {NUM1_SZ{FREE_STATE}};

//   T0_PC+3: cu_pgl_palt_yg [8.] =
//            pgl_palt_yg [8.] * palt_yrto [1.5]
assign  opcode003 = cu_cmd_en[T0_PC+7'h3] ? OP_MUL : {2{ZERO}};
assign  num_0_003 = cu_cmd_en[T0_PC+7'h3] ? {{NUM0_SZ- 8{1'b0}}, pgl_palt_yg} : {NUM0_SZ{FREE_STATE}};
assign  num_1_003 = cu_cmd_en[T0_PC+7'h3] ? {{NUM1_SZ- 6{1'b0}}, palt_yrto}   : {NUM1_SZ{FREE_STATE}};

//   T0_PC+4: cu_pgl_palt_yy [8.] =
//            pgl_palt_yy [8.] * palt_yrto [1.5]
assign  opcode004 = cu_cmd_en[T0_PC+7'h4] ? OP_MUL : {2{ZERO}};
assign  num_0_004 = cu_cmd_en[T0_PC+7'h4] ? {{NUM0_SZ- 8{1'b0}}, pgl_palt_yy} : {NUM0_SZ{FREE_STATE}};
assign  num_1_004 = cu_cmd_en[T0_PC+7'h4] ? {{NUM1_SZ- 6{1'b0}}, palt_yrto}   : {NUM1_SZ{FREE_STATE}};

//   T0_PC+5: cu_pgl_palt_yb [8.] =
//            pgl_palt_yb [8.] * palt_yrto [1.5]
assign  opcode005 = cu_cmd_en[T0_PC+7'h5] ? OP_MUL : {2{ZERO}};
assign  num_0_005 = cu_cmd_en[T0_PC+7'h5] ? {{NUM0_SZ- 8{1'b0}}, pgl_palt_yb} : {NUM0_SZ{FREE_STATE}};
assign  num_1_005 = cu_cmd_en[T0_PC+7'h5] ? {{NUM1_SZ- 6{1'b0}}, palt_yrto}   : {NUM1_SZ{FREE_STATE}};

//   T0_PC+6: cu_pgl_palt_bw0 [8.] =
//            pgl_palt_bw0 [8.] * palt_yrto [1.5]
assign  opcode006 = cu_cmd_en[T0_PC+7'h6] ? OP_MUL : {2{ZERO}};
assign  num_0_006 = cu_cmd_en[T0_PC+7'h6] ? {{NUM0_SZ- 8{1'b0}}, pgl_palt_bw0} : {NUM0_SZ{FREE_STATE}};
assign  num_1_006 = cu_cmd_en[T0_PC+7'h6] ? {{NUM1_SZ- 6{1'b0}}, palt_yrto}   : {NUM1_SZ{FREE_STATE}};

// cu_pgl_palt_u = (pgl_palt_u * (32 - reg_pgl_palt_crto) >> 5) + 128
//
//   T0_PC+7: palt_crto [1.5] =
//            32 [1.5] - {1'b0, reg_pgl_palt_crto} [.5]
assign  opcode007 = cu_cmd_en[T0_PC+7'h7] ? OP_SUB : {2{ZERO}};
assign  num_0_007 = cu_cmd_en[T0_PC+7'h7] ? {{NUM0_SZ- 6{1'b0}}, 6'h20}                   : {NUM0_SZ{FREE_STATE}};
assign  num_1_007 = cu_cmd_en[T0_PC+7'h7] ? {{NUM1_SZ- 5{1'b0}}, 1'b0, reg_pgl_palt_crto} : {NUM1_SZ{FREE_STATE}};

//   T0_PC+8: palt_ur_tmp [8.] =
//            pgl_palt_ur [8.] * palt_crto [1.5]
assign  opcode008 = cu_cmd_en[T0_PC+7'h8] ? OP_MUL : {2{ZERO}};
assign  num_0_008 = cu_cmd_en[T0_PC+7'h8] ? {{NUM0_SZ- 8{1'b0}}, pgl_palt_ur[7:0]} : {NUM0_SZ{FREE_STATE}};
assign  num_1_008 = cu_cmd_en[T0_PC+7'h8] ? {{NUM1_SZ- 6{1'b0}}, palt_crto}        : {NUM1_SZ{FREE_STATE}};

//   T0_PC+9: cu_pgl_palt_ur [8.] =
//            128 [8.] +- palt_ur_tmp [8.]
assign  opcode009 = cu_cmd_en[T0_PC+7'h9] ? palt_ur_op : {2{ZERO}};
assign  num_0_009 = cu_cmd_en[T0_PC+7'h9] ? {{NUM0_SZ- 8{1'b0}}, 8'h80}       : {NUM0_SZ{FREE_STATE}};
assign  num_1_009 = cu_cmd_en[T0_PC+7'h9] ? {{NUM1_SZ- 8{1'b0}}, palt_ur_tmp} : {NUM1_SZ{FREE_STATE}};

//   T0_PC+a: palt_ug_tmp [8.] =
//            pgl_palt_ug [8.] * palt_crto [1.5]
assign  opcode00a = cu_cmd_en[T0_PC+7'ha] ? OP_MUL : {2{ZERO}};
assign  num_0_00a = cu_cmd_en[T0_PC+7'ha] ? {{NUM0_SZ- 8{1'b0}}, pgl_palt_ug[7:0]} : {NUM0_SZ{FREE_STATE}};
assign  num_1_00a = cu_cmd_en[T0_PC+7'ha] ? {{NUM1_SZ- 6{1'b0}}, palt_crto}         : {NUM1_SZ{FREE_STATE}};

//   T0_PC+b: cu_pgl_palt_ug [8.] =
//            128 [8.] +- palt_ug_tmp [8.]
assign  opcode00b = cu_cmd_en[T0_PC+7'hb] ? palt_ug_op : {2{ZERO}};
assign  num_0_00b = cu_cmd_en[T0_PC+7'hb] ? {{NUM0_SZ- 8{1'b0}}, 8'h80}       : {NUM0_SZ{FREE_STATE}};
assign  num_1_00b = cu_cmd_en[T0_PC+7'hb] ? {{NUM1_SZ- 8{1'b0}}, palt_ug_tmp} : {NUM1_SZ{FREE_STATE}};

//   T0_PC+c: palt_uy_tmp [8.] =
//            pgl_palt_uy [8.] * palt_crto [1.5]
assign  opcode00c = cu_cmd_en[T0_PC+7'hc] ? OP_MUL : {2{ZERO}};
assign  num_0_00c = cu_cmd_en[T0_PC+7'hc] ? {{NUM0_SZ- 8{1'b0}}, pgl_palt_uy[7:0]} : {NUM0_SZ{FREE_STATE}};
assign  num_1_00c = cu_cmd_en[T0_PC+7'hc] ? {{NUM1_SZ- 6{1'b0}}, palt_crto}        : {NUM1_SZ{FREE_STATE}};

//   T0_PC+d: cu_pgl_palt_uy [8.] =
//            128 [8.] +- palt_uy_tmp [8.]
assign  opcode00d = cu_cmd_en[T0_PC+7'hd] ? palt_uy_op : {2{ZERO}};
assign  num_0_00d = cu_cmd_en[T0_PC+7'hd] ? {{NUM0_SZ- 8{1'b0}}, 8'h80}       : {NUM0_SZ{FREE_STATE}};
assign  num_1_00d = cu_cmd_en[T0_PC+7'hd] ? {{NUM1_SZ- 8{1'b0}}, palt_uy_tmp} : {NUM1_SZ{FREE_STATE}};

//   T0_PC+e: palt_ub_tmp [8.] =
//            pgl_palt_ub [8.] * palt_crto [1.5]
assign  opcode00e = cu_cmd_en[T0_PC+7'he] ? OP_MUL : {2{ZERO}};
assign  num_0_00e = cu_cmd_en[T0_PC+7'he] ? {{NUM0_SZ- 8{1'b0}}, pgl_palt_ub[7:0]} : {NUM0_SZ{FREE_STATE}};
assign  num_1_00e = cu_cmd_en[T0_PC+7'he] ? {{NUM1_SZ- 6{1'b0}}, palt_crto}        : {NUM1_SZ{FREE_STATE}};

//   T0_PC+f: cu_pgl_palt_ub [8.] =
//            128 [8.] +- palt_tmp_ub [8.]
assign  opcode00f = cu_cmd_en[T0_PC+7'hf] ? palt_ub_op : {2{ZERO}};
assign  num_0_00f = cu_cmd_en[T0_PC+7'hf] ? {{NUM0_SZ- 8{1'b0}}, 8'h80}       : {NUM0_SZ{FREE_STATE}};
assign  num_1_00f = cu_cmd_en[T0_PC+7'hf] ? {{NUM1_SZ- 8{1'b0}}, palt_ub_tmp} : {NUM1_SZ{FREE_STATE}};

//   T0_PC+10: palt_vr_tmp [8.] =
//            pgl_palt_vr [8.] * palt_crto [1.5]
assign  opcode010 = cu_cmd_en[T0_PC+7'h10] ? OP_MUL : {2{ZERO}};
assign  num_0_010 = cu_cmd_en[T0_PC+7'h10] ? {{NUM0_SZ- 8{1'b0}}, pgl_palt_vr[7:0]} : {NUM0_SZ{FREE_STATE}};
assign  num_1_010 = cu_cmd_en[T0_PC+7'h10] ? {{NUM1_SZ- 6{1'b0}}, palt_crto}        : {NUM1_SZ{FREE_STATE}};

//   T0_PC+11: cu_pgl_palt_vr [8.] =
//            128 [8.] +- palt_vr_tmp [8.]
assign  opcode011 = cu_cmd_en[T0_PC+7'h11] ? palt_vr_op : {2{ZERO}};
assign  num_0_011 = cu_cmd_en[T0_PC+7'h11] ? {{NUM0_SZ- 8{1'b0}}, 8'h80}       : {NUM0_SZ{FREE_STATE}};
assign  num_1_011 = cu_cmd_en[T0_PC+7'h11] ? {{NUM1_SZ- 8{1'b0}}, palt_vr_tmp} : {NUM1_SZ{FREE_STATE}};

//   T0_PC+12: palt_vg_tmp [8.] =
//            pgl_palt_vg [8.] * palt_crto [1.5]
assign  opcode012 = cu_cmd_en[T0_PC+7'h12] ? OP_MUL : {2{ZERO}};
assign  num_0_012 = cu_cmd_en[T0_PC+7'h12] ? {{NUM0_SZ- 8{1'b0}}, pgl_palt_vg[7:0]} : {NUM0_SZ{FREE_STATE}};
assign  num_1_012 = cu_cmd_en[T0_PC+7'h12] ? {{NUM1_SZ- 6{1'b0}}, palt_crto}        : {NUM1_SZ{FREE_STATE}};

//   T0_PC+13: cu_pgl_palt_vg [8.] =
//            128 [8.] +- palt_vg_tmp [8.]
assign  opcode013 = cu_cmd_en[T0_PC+7'h13] ? palt_vg_op : {2{ZERO}};
assign  num_0_013 = cu_cmd_en[T0_PC+7'h13] ? {{NUM0_SZ- 8{1'b0}}, 8'h80}       : {NUM0_SZ{FREE_STATE}};
assign  num_1_013 = cu_cmd_en[T0_PC+7'h13] ? {{NUM1_SZ- 8{1'b0}}, palt_vg_tmp} : {NUM1_SZ{FREE_STATE}};

//   T0_PC+14: palt_vy_tmp [8.] =
//            pgl_palt_vy [8.] * palt_crto [1.5]
assign  opcode014 = cu_cmd_en[T0_PC+7'h14] ? OP_MUL : {2{ZERO}};
assign  num_0_014 = cu_cmd_en[T0_PC+7'h14] ? {{NUM0_SZ- 8{1'b0}}, pgl_palt_vy[7:0]} : {NUM0_SZ{FREE_STATE}};
assign  num_1_014 = cu_cmd_en[T0_PC+7'h14] ? {{NUM1_SZ- 6{1'b0}}, palt_crto}        : {NUM1_SZ{FREE_STATE}};

//   T0_PC+15: cu_pgl_palt_vy [8.] =
//            128 [8.] +- palt_vy_tmp [8.]
assign  opcode015 = cu_cmd_en[T0_PC+7'h15] ? palt_vy_op : {2{ZERO}};
assign  num_0_015 = cu_cmd_en[T0_PC+7'h15] ? {{NUM0_SZ- 8{1'b0}}, 8'h80}       : {NUM0_SZ{FREE_STATE}};
assign  num_1_015 = cu_cmd_en[T0_PC+7'h15] ? {{NUM1_SZ- 8{1'b0}}, palt_vy_tmp} : {NUM1_SZ{FREE_STATE}};

//   T0_PC+16: palt_vb_tmp [8.] =
//            pgl_palt_vb [8.] * palt_crto [1.5]
assign  opcode016 = cu_cmd_en[T0_PC+7'h16] ? OP_MUL : {2{ZERO}};
assign  num_0_016 = cu_cmd_en[T0_PC+7'h16] ? {{NUM0_SZ- 8{1'b0}}, pgl_palt_vb[7:0]} : {NUM0_SZ{FREE_STATE}};
assign  num_1_016 = cu_cmd_en[T0_PC+7'h16] ? {{NUM1_SZ- 6{1'b0}}, palt_crto}        : {NUM1_SZ{FREE_STATE}};

//   T0_PC+17: cu_pgl_palt_vb [8.] =
//            128 [8.] +- palt_vb_tmp [8.]
assign  opcode017 = cu_cmd_en[T0_PC+7'h17] ? palt_vb_op : {2{ZERO}};
assign  num_0_017 = cu_cmd_en[T0_PC+7'h17] ? {{NUM0_SZ- 8{1'b0}}, 8'h80}       : {NUM0_SZ{FREE_STATE}};
assign  num_1_017 = cu_cmd_en[T0_PC+7'h17] ? {{NUM1_SZ- 8{1'b0}}, palt_vb_tmp} : {NUM1_SZ{FREE_STATE}};

// cu_pgl_aa_trsp [1.8] =
// 256 [1.8] - (cu_pgl_trsp_cmpl [1.8] * (4 - reg_pgl_aa_twg [.2])) >> 2
//
//   T0_PC+18: cu_pgl_trsp_cmpl [1.8] =
//            256 [1.8] - reg_pgl_trsp [.8]
assign  opcode018 = cu_cmd_en[T0_PC+7'h18] ? OP_SUB : {2{ZERO}};
assign  num_0_018 = cu_cmd_en[T0_PC+7'h18] ? {{NUM0_SZ- 9{1'b0}}, 9'h100}       : {NUM0_SZ{FREE_STATE}};
assign  num_1_018 = cu_cmd_en[T0_PC+7'h18] ? {{NUM1_SZ- 8{1'b0}}, reg_pgl_trsp} : {NUM1_SZ{FREE_STATE}};

//   T0_PC+19: pgl_aa_k_cmpl [1.2] = 4 [1.2] - reg_pgl_aa_twg [.2]
assign  opcode019 = cu_cmd_en[T0_PC+7'h19] ? OP_SUB : {2{ZERO}};
assign  num_0_019 = cu_cmd_en[T0_PC+7'h19] ? {{NUM0_SZ- 3{1'b0}}, 3'b100}         : {NUM0_SZ{FREE_STATE}};
assign  num_1_019 = cu_cmd_en[T0_PC+7'h19] ? {{NUM1_SZ- 2{1'b0}}, reg_pgl_aa_twg} : {NUM1_SZ{FREE_STATE}};

//   T0_PC+1a: cu_pgl_aa_cmpl [1.8] =
//             cu_pgl_trsp_cmpl [1.8] *  pgl_aa_k_cmpl [1.2]
assign  opcode01a = cu_cmd_en[T0_PC+7'h1a] ? OP_MUL : {2{ZERO}};
assign  num_0_01a = cu_cmd_en[T0_PC+7'h1a] ? {{NUM0_SZ- 9{1'b0}}, cu_pgl_trsp_cmpl} : {NUM0_SZ{FREE_STATE}};
assign  num_1_01a = cu_cmd_en[T0_PC+7'h1a] ? {{NUM1_SZ- 3{1'b0}}, pgl_aa_k_cmpl}    : {NUM1_SZ{FREE_STATE}};

//   T0_PC+1b: cu_pgl_aa_trsp [1.8] =
//            256 [1.8] - cu_pgl_aa_cmpl [1.8]
assign  opcode01b = cu_cmd_en[T0_PC+7'h1b] ? OP_SUB : {2{ZERO}};
assign  num_0_01b = cu_cmd_en[T0_PC+7'h1b] ? {{NUM0_SZ- 9{1'b0}}, 9'h100}         : {NUM0_SZ{FREE_STATE}};
assign  num_1_01b = cu_cmd_en[T0_PC+7'h1b] ? {{NUM1_SZ- 9{1'b0}}, cu_pgl_aa_cmpl} : {NUM1_SZ{FREE_STATE}};

//
//   T0_PC+1c: cu_pgl_hln0_wid [9.] =
//            reg_pgl_vln_wid [6.] * reg_pgl_hln_m0 [3.1]
assign  opcode01c = cu_cmd_en[T0_PC+7'h1c] ? OP_MUL : {2{ZERO}};
assign  num_0_01c = cu_cmd_en[T0_PC+7'h1c] ? {{NUM0_SZ- 6{1'b0}}, reg_pgl_vln_wid} : {NUM0_SZ{FREE_STATE}};
assign  num_1_01c = cu_cmd_en[T0_PC+7'h1c] ? {{NUM1_SZ- 4{1'b0}}, reg_pgl_hln_m0}  : {NUM1_SZ{FREE_STATE}};

//   T0_PC+1d: cu_pgl_hln1_wid [9.] =
//            reg_pgl_vln_wid [6.] * reg_pgl_hln_m1 [4.]
assign  opcode01d = cu_cmd_en[T0_PC+7'h1d] ? OP_MUL : {2{ZERO}};
assign  num_0_01d = cu_cmd_en[T0_PC+7'h1d] ? {{NUM0_SZ- 6{1'b0}}, reg_pgl_vln_wid} : {NUM0_SZ{FREE_STATE}};
assign  num_1_01d = cu_cmd_en[T0_PC+7'h1d] ? {{NUM1_SZ- 4{1'b0}}, reg_pgl_hln_m1}  : {NUM1_SZ{FREE_STATE}};

//
//   T0_PC+1e: cu_pgl_hwwg_lft [2.8] =
//            pgl_wwg_mul [6.] * reg_pgl_wwg_lft [.8]   // max. reg_pgl_wwg_lft = 15/256
assign  opcode01e = cu_cmd_en[T0_PC+7'h1e] ? OP_MUL : {2{ZERO}};
assign  num_0_01e = cu_cmd_en[T0_PC+7'h1e] ? {{NUM0_SZ- 6{1'b0}}, pgl_wwg_mul}           : {NUM0_SZ{FREE_STATE}};
assign  num_1_01e = cu_cmd_en[T0_PC+7'h1e] ? {{NUM1_SZ- 8{1'b0}}, 4'h0, reg_pgl_wwg_lft} : {NUM1_SZ{FREE_STATE}};

//   T0_PC+1f: cu_pgl_hwwg_rgt [2.8] =
//            pgl_wwg_mul [6.] * reg_pgl_wwg_rgt [.8]   // max. reg_pgl_wwg_rgt = 15/256
assign  opcode01f = cu_cmd_en[T0_PC+7'h1f] ? OP_MUL : {2{ZERO}};
assign  num_0_01f = cu_cmd_en[T0_PC+7'h1f] ? {{NUM0_SZ- 6{1'b0}}, pgl_wwg_mul}           : {NUM0_SZ{FREE_STATE}};
assign  num_1_01f = cu_cmd_en[T0_PC+7'h1f] ? {{NUM1_SZ- 8{1'b0}}, 4'h0, reg_pgl_wwg_rgt} : {NUM1_SZ{FREE_STATE}};

//
//   T0_PC+20: cu_yb0_dlt_lft [9.] =
//            {reg_pgl_ybnd_lft,1'b0} [9.] - reg_pgl_ystr0_lft[8.]
assign  opcode020 = cu_cmd_en[T0_PC+7'h20] ? OP_SUB : {2{ZERO}};
assign  num_0_020 = cu_cmd_en[T0_PC+7'h20] ? {{NUM0_SZ- 9{1'b0}}, reg_pgl_ybnd_lft, 1'b0} : {NUM0_SZ{FREE_STATE}};
assign  num_1_020 = cu_cmd_en[T0_PC+7'h20] ? {{NUM1_SZ- 8{1'b0}}, reg_pgl_ystr0_lft}      : {NUM1_SZ{FREE_STATE}};

//   T0_PC+21: cu_yb0_dlt_lft [9.] =
//            reg_pgl_ystr0_lft[8.] - {reg_pgl_ybnd_lft,1'b0} [9.]
assign  opcode021 = cu_cmd_en[T0_PC+7'h21] ? OP_SUB : {2{ZERO}};
assign  num_0_021 = cu_cmd_en[T0_PC+7'h21] ? {{NUM0_SZ- 8{1'b0}}, reg_pgl_ystr0_lft}      : {NUM0_SZ{FREE_STATE}};
assign  num_1_021 = cu_cmd_en[T0_PC+7'h21] ? {{NUM1_SZ- 9{1'b0}}, reg_pgl_ybnd_lft, 1'b0} : {NUM1_SZ{FREE_STATE}};

//   T0_PC+22: cu_yb0_dlt_rgt [9.] =
//            {reg_pgl_ybnd_rgt,1'b0} [9.] - reg_pgl_ystr0_rgt[8.]
assign  opcode022 = cu_cmd_en[T0_PC+7'h22] ? OP_SUB : {2{ZERO}};
assign  num_0_022 = cu_cmd_en[T0_PC+7'h22] ? {{NUM0_SZ- 9{1'b0}}, pgl_ybnd_l2r, 1'b0} : {NUM0_SZ{FREE_STATE}};
assign  num_1_022 = cu_cmd_en[T0_PC+7'h22] ? {{NUM1_SZ- 8{1'b0}}, pgl_ystr0_l2r}      : {NUM1_SZ{FREE_STATE}};

//   T0_PC+23: cu_yb0_dlt_rgt [9.] =
//            reg_pgl_ystr0_rgt[8.] - {reg_pgl_ybnd_rgt,1'b0} [9.]
assign  opcode023 = cu_cmd_en[T0_PC+7'h23] ? OP_SUB : {2{ZERO}};
assign  num_0_023 = cu_cmd_en[T0_PC+7'h23] ? {{NUM0_SZ- 8{1'b0}}, pgl_ystr0_l2r}      : {NUM0_SZ{FREE_STATE}};
assign  num_1_023 = cu_cmd_en[T0_PC+7'h23] ? {{NUM1_SZ- 9{1'b0}}, pgl_ybnd_l2r, 1'b0} : {NUM1_SZ{FREE_STATE}};

//   T0_PC+24: cu_pgl_xstr_lft [9.] =
//             reg_pgl_xstr_lft[8.] + LR_XSFT
assign  opcode024 = cu_cmd_en[T0_PC+7'h24] ? OP_ADD : {2{ZERO}};
assign  num_0_024 = cu_cmd_en[T0_PC+7'h24] ? {{NUM0_SZ- 8{1'b0}}, reg_pgl_xstr_lft} : {NUM0_SZ{FREE_STATE}};
assign  num_1_024 = cu_cmd_en[T0_PC+7'h24] ? {{NUM1_SZ- 7{1'b0}}, LR_XSFT}          : {NUM1_SZ{FREE_STATE}};

//   T0_PC+25: cu_pgl_xstr_rgt [9.] =
//             reg_pgl_xstr_rgt[8.] + LR_XSFT
assign  opcode025 = cu_cmd_en[T0_PC+7'h25] ? OP_ADD : {2{ZERO}};
assign  num_0_025 = cu_cmd_en[T0_PC+7'h25] ? {{NUM0_SZ- 8{1'b0}}, reg_pgl_xstr_rgt} : {NUM0_SZ{FREE_STATE}};
assign  num_1_025 = cu_cmd_en[T0_PC+7'h25] ? {{NUM1_SZ- 7{1'b0}}, LR_XSFT}          : {NUM1_SZ{FREE_STATE}};


// T1: Per Line calculation @ hend
// ===============================================
//   T1_PC+0: y_p1 [10.] =
//            pgl_vcnt [10.] + 1'b1
assign  opcode100 = cu_cmd_en[T1_PC+7'h0] ? OP_ADD : {2{ZERO}};
assign  num_0_100 = cu_cmd_en[T1_PC+7'h0] ? {{NUM0_SZ- 10{1'b0}}, pgl_vcnt} : {NUM0_SZ{FREE_STATE}};
assign  num_1_100 = cu_cmd_en[T1_PC+7'h0] ? {{NUM1_SZ-  1{1'b0}}, 1'b1}     : {NUM1_SZ{FREE_STATE}};

//   T1_PC+1: dummy
assign  opcode101 = cu_cmd_en[T1_PC+7'h1] ? OP_ADD : {2{ZERO}};
assign  num_0_101 = cu_cmd_en[T1_PC+7'h1] ? {{NUM0_SZ {1'b0}}} : {NUM0_SZ{FREE_STATE}};
assign  num_1_101 = cu_cmd_en[T1_PC+7'h1] ? {{NUM1_SZ {1'b0}}} : {NUM1_SZ{FREE_STATE}};

//   T1_PC+2: dummy
assign  opcode102 = cu_cmd_en[T1_PC+7'h2] ? OP_ADD : {2{ZERO}};
assign  num_0_102 = cu_cmd_en[T1_PC+7'h2] ? {{NUM0_SZ {1'b0}}} : {NUM0_SZ{FREE_STATE}};
assign  num_1_102 = cu_cmd_en[T1_PC+7'h2] ? {{NUM1_SZ {1'b0}}} : {NUM1_SZ{FREE_STATE}};

//   T1_PC+3: dummy
assign  opcode103 = cu_cmd_en[T1_PC+7'h3] ? OP_ADD : {2{ZERO}};
assign  num_0_103 = cu_cmd_en[T1_PC+7'h3] ? {{NUM0_SZ {1'b0}}} : {NUM0_SZ{FREE_STATE}};
assign  num_1_103 = cu_cmd_en[T1_PC+7'h3] ? {{NUM1_SZ {1'b0}}} : {NUM1_SZ{FREE_STATE}};

//   T1_PC+4: cu_y0_lft_eq [1.]; cu_y0_lft_csgb [1.] =
//            y_p1 [10.] - reg_pgl_ystr0_lft [8.]
assign  opcode104 = cu_cmd_en[T1_PC+7'h4] ? OP_SUB : {2{ZERO}};
assign  num_0_104 = cu_cmd_en[T1_PC+7'h4] ? {{NUM0_SZ- 10{1'b0}}, y_p1}              : {NUM0_SZ{FREE_STATE}};
assign  num_1_104 = cu_cmd_en[T1_PC+7'h4] ? {{NUM1_SZ-  8{1'b0}}, reg_pgl_ystr0_lft} : {NUM1_SZ{FREE_STATE}};

//   T1_PC+5: cu_ystr_lft_csgb [1.] =
//            y_p1 [10.] - cu_ystr_lft [10.]
assign  opcode105 = cu_cmd_en[T1_PC+7'h5] ? OP_SUB : {2{ZERO}};
assign  num_0_105 = cu_cmd_en[T1_PC+7'h5] ? {{NUM0_SZ- 10{1'b0}}, y_p1}        : {NUM0_SZ{FREE_STATE}};
assign  num_1_105 = cu_cmd_en[T1_PC+7'h5] ? {{NUM1_SZ- 10{1'b0}}, cu_ystr_lft} : {NUM1_SZ{FREE_STATE}};

//   T1_PC+6: cu_yend_lft_eq [1.] =
//            y_p1 [10.] - cu_yend_lft [10.]
assign  opcode106 = cu_cmd_en[T1_PC+7'h6] ? OP_SUB : {2{ZERO}};
assign  num_0_106 = cu_cmd_en[T1_PC+7'h6] ? {{NUM0_SZ- 10{1'b0}}, y_p1}        : {NUM0_SZ{FREE_STATE}};
assign  num_1_106 = cu_cmd_en[T1_PC+7'h6] ? {{NUM1_SZ- 10{1'b0}}, cu_yend_lft} : {NUM1_SZ{FREE_STATE}};

//   T1_PC+7: cu_ybnd_lft_csgb[1.] =
//            y_p1 [10.] - {reg_pgl_ybnd_lft,1'b0} [9.]
assign  opcode107 = cu_cmd_en[T1_PC+7'h7] ? OP_SUB : {2{ZERO}};
assign  num_0_107 = cu_cmd_en[T1_PC+7'h7] ? {{NUM0_SZ- 10{1'b0}}, y_p1}                   : {NUM0_SZ{FREE_STATE}};
assign  num_1_107 = cu_cmd_en[T1_PC+7'h7] ? {{NUM1_SZ-  9{1'b0}}, reg_pgl_ybnd_lft, 1'b0} : {NUM1_SZ{FREE_STATE}};

//   T1_PC+8: cu_y0_rgt_eq [1.]; cu_y0_rgt_csgb [1.] =
//            y_p1 [10.] - reg_pgl_ystr0_rgt [8.]
assign  opcode108 = cu_cmd_en[T1_PC+7'h8] ? OP_SUB : {2{ZERO}};
assign  num_0_108 = cu_cmd_en[T1_PC+7'h8] ? {{NUM0_SZ- 10{1'b0}}, y_p1}          : {NUM0_SZ{FREE_STATE}};
assign  num_1_108 = cu_cmd_en[T1_PC+7'h8] ? {{NUM1_SZ-  8{1'b0}}, pgl_ystr0_l2r} : {NUM1_SZ{FREE_STATE}};

//   T1_PC+9: cu_ystr_rgt_csgb [1.] =
//            y_p1 [10.] - cu_ystr_rgt [10.]
assign  opcode109 = cu_cmd_en[T1_PC+7'h9] ? OP_SUB : {2{ZERO}};
assign  num_0_109 = cu_cmd_en[T1_PC+7'h9] ? {{NUM0_SZ- 10{1'b0}}, y_p1}        : {NUM0_SZ{FREE_STATE}};
assign  num_1_109 = cu_cmd_en[T1_PC+7'h9] ? {{NUM1_SZ- 10{1'b0}}, cu_ystr_rgt} : {NUM1_SZ{FREE_STATE}};

//   T1_PC+a: cu_yend_rgt_eq [1.] =
//            y_p1 [10.] - cu_yend_rgt [10.]
assign  opcode10a = cu_cmd_en[T1_PC+7'ha] ? OP_SUB : {2{ZERO}};
assign  num_0_10a = cu_cmd_en[T1_PC+7'ha] ? {{NUM0_SZ- 10{1'b0}}, y_p1}        : {NUM0_SZ{FREE_STATE}};
assign  num_1_10a = cu_cmd_en[T1_PC+7'ha] ? {{NUM1_SZ- 10{1'b0}}, cu_yend_rgt} : {NUM1_SZ{FREE_STATE}};

//   T1_PC+b: cu_ybnd_rgt_csgb[1.] =
//            y_p1 [10.] - {reg_pgl_ybnd_rgt,1'b0} [9.]
assign  opcode10b = cu_cmd_en[T1_PC+7'hb] ? OP_SUB : {2{ZERO}};
assign  num_0_10b = cu_cmd_en[T1_PC+7'hb] ? {{NUM0_SZ- 10{1'b0}}, y_p1}               : {NUM0_SZ{FREE_STATE}};
assign  num_1_10b = cu_cmd_en[T1_PC+7'hb] ? {{NUM1_SZ-  9{1'b0}}, pgl_ybnd_l2r, 1'b0} : {NUM1_SZ{FREE_STATE}};

//   T1_PC+c: cu_y0_ctr_csgb [1.] =
//            y_p1 [10.] - reg_pgl_ystr_ctr [8.]
assign  opcode10c = cu_cmd_en[T1_PC+7'hc] ? OP_SUB : {2{ZERO}};
assign  num_0_10c = cu_cmd_en[T1_PC+7'hc] ? {{NUM0_SZ- 10{1'b0}}, y_p1}             : {NUM0_SZ{FREE_STATE}};
assign  num_1_10c = cu_cmd_en[T1_PC+7'hc] ? {{NUM1_SZ-  8{1'b0}}, reg_pgl_ystr_ctr} : {NUM1_SZ{FREE_STATE}};

//   T1_PC+d: cu_ystr_ctr_eq [1.] =
//            y_p1 [10.] - cu_ystr_ctr [10.]
assign  opcode10d = cu_cmd_en[T1_PC+7'hd] ? OP_SUB : {2{ZERO}};
assign  num_0_10d = cu_cmd_en[T1_PC+7'hd] ? {{NUM0_SZ- 10{1'b0}}, y_p1}        : {NUM0_SZ{FREE_STATE}};
assign  num_1_10d = cu_cmd_en[T1_PC+7'hd] ? {{NUM1_SZ- 10{1'b0}}, cu_ystr_ctr} : {NUM1_SZ{FREE_STATE}};

//   T1_PC+e: cu_yend_ctr_eq [1.] =
//            y_p1 [10.] - cu_yend_ctr [10.]
assign  opcode10e = cu_cmd_en[T1_PC+7'he] ? OP_SUB : {2{ZERO}};
assign  num_0_10e = cu_cmd_en[T1_PC+7'he] ? {{NUM0_SZ- 10{1'b0}}, y_p1}        : {NUM0_SZ{FREE_STATE}};
assign  num_1_10e = cu_cmd_en[T1_PC+7'he] ? {{NUM1_SZ- 10{1'b0}}, cu_yend_ctr} : {NUM1_SZ{FREE_STATE}};

//   T1_PC+f: cu_vend_ctr_csgb [1.] =
//            y_p1 [10.] - cu_vend_ctr [10.]
assign  opcode10f = cu_cmd_en[T1_PC+7'hf] ? OP_SUB : {2{ZERO}};
assign  num_0_10f = cu_cmd_en[T1_PC+7'hf] ? {{NUM0_SZ- 10{1'b0}}, y_p1}        : {NUM0_SZ{FREE_STATE}};
assign  num_1_10f = cu_cmd_en[T1_PC+7'hf] ? {{NUM1_SZ- 10{1'b0}}, cu_vend_ctr} : {NUM1_SZ{FREE_STATE}};


// T2: Per Line Calculation for Left-PGL @ hend & ~cu_y0_lft_csgb [y_p1 >= y0]
// ===============================================
//   T2_PC+0: dummy
assign  opcode200 = cu_cmd_en[T2_PC+7'h0] ? OP_ADD : {2{ZERO}};
assign  num_0_200 = cu_cmd_en[T2_PC+7'h0] ? {{NUM0_SZ {1'b0}}} : {NUM0_SZ{FREE_STATE}};
assign  num_1_200 = cu_cmd_en[T2_PC+7'h0] ? {{NUM1_SZ {1'b0}}} : {NUM1_SZ{FREE_STATE}};

//   T2_PC+1: wid_dlt_lft [9.8] integer limit to 9 bits =
//            cu_ydlt_lft [10.] * pgl_wwg_lft[2.8]
assign  opcode201 = cu_cmd_en[T2_PC+7'h1] ? OP_MUL : {2{ZERO}};
assign  num_0_201 = cu_cmd_en[T2_PC+7'h1] ? {{NUM0_SZ- 10{1'b0}}, cu_ydlt_lft} : {NUM0_SZ{FREE_STATE}};
assign  num_1_201 = cu_cmd_en[T2_PC+7'h1] ? {{NUM1_SZ- 10{1'b0}}, pgl_wwg_lft} : {NUM1_SZ{FREE_STATE}};

//   T2_PC+2: pgl_wid_lft [9.8] integer limit to 9 bits =
//            pgl_wid_bs_lft [9.] + wid_dlt_lft [9.8]
assign  opcode202 = cu_cmd_en[T2_PC+7'h2] ? OP_ADD : {2{ZERO}};
assign  num_0_202 = cu_cmd_en[T2_PC+7'h2] ? {{NUM0_SZ-17{1'b0}}, pgl_wid_bs_lft,8'h0} : {NUM0_SZ{FREE_STATE}};
assign  num_1_202 = cu_cmd_en[T2_PC+7'h2] ? {{NUM1_SZ-17{1'b0}}, wid_dlt_lft}         : {NUM1_SZ{FREE_STATE}};

//   T2_PC+3: ydlt_sqr_lft [20.] =
//            cu_ydlt_lft [10.] * cu_ydlt_lft [10.]
assign  opcode203 = cu_cmd_en[T2_PC+7'h3] ? OP_MUL : {2{ZERO}};
assign  num_0_203 = cu_cmd_en[T2_PC+7'h3] ? {{NUM0_SZ- 10{1'b0}}, cu_ydlt_lft} : {NUM0_SZ{FREE_STATE}};
assign  num_1_203 = cu_cmd_en[T2_PC+7'h3] ? {{NUM1_SZ- 10{1'b0}}, cu_ydlt_lft} : {NUM1_SZ{FREE_STATE}};

//   T2_PC+4: xstr_cofst0_lft[10.8] limit to 10.8 =
//            reg_pgl_slpwg_lft [.8] * ydlt_sqr_lft [20.]
assign  opcode204 = cu_cmd_en[T2_PC+7'h4] ? OP_MUL : {2{ZERO}};
assign  num_0_204 = cu_cmd_en[T2_PC+7'h4] ? {{NUM0_SZ-  8{1'b0}}, reg_pgl_slpwg_lft} : {NUM0_SZ{FREE_STATE}};
assign  num_1_204 = cu_cmd_en[T2_PC+7'h4] ? {{NUM1_SZ- 20{1'b0}}, ydlt_sqr_lft}      : {NUM1_SZ{FREE_STATE}};

//   T2_PC+5: yyb_dlt_lft [10.]
//            y_p1[10.] - {reg_pgl_ybnd_lft, 1'b0} [9.]
assign  opcode205 = cu_cmd_en[T2_PC+7'h5] ? OP_SUB : {2{ZERO}};
assign  num_0_205 = cu_cmd_en[T2_PC+7'h5] ? {{NUM0_SZ- 18{1'b0}}, y_p1, 8'h0}             : {NUM0_SZ{FREE_STATE}};
assign  num_1_205 = cu_cmd_en[T2_PC+7'h5] ? {{NUM1_SZ- 17{1'b0}}, reg_pgl_ybnd_lft, 9'h0} : {NUM1_SZ{FREE_STATE}};

//   T2_PC+6: yy0yb_dsum_lft [11.]
//            cu_ydlt_lft [10.] + yyb_dlt_lft [10.]
assign  opcode206 = cu_cmd_en[T2_PC+7'h6] ? OP_ADD : {2{ZERO}};
assign  num_0_206 = cu_cmd_en[T2_PC+7'h6] ? {{NUM0_SZ- 18{1'b0}}, cu_ydlt_lft, 8'h0} : {NUM0_SZ{FREE_STATE}};
assign  num_1_206 = cu_cmd_en[T2_PC+7'h6] ? {{NUM1_SZ- 18{1'b0}}, yyb_dlt_lft, 8'h0} : {NUM1_SZ{FREE_STATE}};

//   T2_PC+7: xstr_cofst_item_lft [20.] =
//            cu_yb0_dlt_lft [9.] * yy0yb_dsum_lft [11.]
assign  opcode207 = cu_cmd_en[T2_PC+7'h7] ? OP_MUL : {2{ZERO}};
assign  num_0_207 = cu_cmd_en[T2_PC+7'h7] ? {{NUM0_SZ-  9{1'b0}}, cu_yb0_dlt_lft} : {NUM0_SZ{FREE_STATE}};
assign  num_1_207 = cu_cmd_en[T2_PC+7'h7] ? {{NUM1_SZ- 11{1'b0}}, yy0yb_dsum_lft} : {NUM1_SZ{FREE_STATE}};

//   T2_PC+8: xstr_cofst1_lft[10.8] limit to 10.8 =
//            reg_pgl_slpwg_lft [.8] * xstr_cofst_item_lft [20.]
assign  opcode208 = cu_cmd_en[T2_PC+7'h8] ? OP_MUL : {2{ZERO}};
assign  num_0_208 = cu_cmd_en[T2_PC+7'h8] ? {{NUM0_SZ-  8{1'b0}}, reg_pgl_slpwg_lft}   : {NUM0_SZ{FREE_STATE}};
assign  num_1_208 = cu_cmd_en[T2_PC+7'h8] ? {{NUM1_SZ- 20{1'b0}}, xstr_cofst_item_lft} : {NUM1_SZ{FREE_STATE}};

//   T2_PC+9: xstr_part_lft [11.8]
//            {cu_pgl_xstr_lft,1'b0} [10.8] + xstr_cofst_lft[10.8]
assign  opcode209 = cu_cmd_en[T2_PC+7'h9] ? xstr_lft_op : {2{ZERO}};
assign  num_0_209 = cu_cmd_en[T2_PC+7'h9] ? {{NUM0_SZ- 18{1'b0}}, cu_pgl_xstr_lft, 9'h0} : {NUM0_SZ{FREE_STATE}};
assign  num_1_209 = cu_cmd_en[T2_PC+7'h9] ? {{NUM1_SZ- 18{1'b0}}, xstr_cofst_lft}        : {NUM1_SZ{FREE_STATE}};

//   T2_PC+a: xstr_lofst_lft[10.8] =
//            reg_pgl_slp_lft [.8] * cu_ydlt_lft [10.]
assign  opcode20a = cu_cmd_en[T2_PC+7'ha] ? OP_MUL : {2{ZERO}};
assign  num_0_20a = cu_cmd_en[T2_PC+7'ha] ? {{NUM0_SZ-  8{1'b0}}, reg_pgl_slp_lft} : {NUM0_SZ{FREE_STATE}};
assign  num_1_20a = cu_cmd_en[T2_PC+7'ha] ? {{NUM1_SZ- 10{1'b0}}, cu_ydlt_lft}     : {NUM1_SZ{FREE_STATE}};

//   T2_PC+b: cu_xstr_lft[10.] limit to 10 bits =
//            xstr_part_lft [11.8] - xstr_lofst_lft[10.8]
assign  opcode20b = cu_cmd_en[T2_PC+7'hb] ? OP_SUB : {2{ZERO}};
assign  num_0_20b = cu_cmd_en[T2_PC+7'hb] ? {{NUM0_SZ- 19{1'b0}}, xstr_part_lft}  : {NUM0_SZ{FREE_STATE}};
assign  num_1_20b = cu_cmd_en[T2_PC+7'hb] ? {{NUM1_SZ- 18{1'b0}}, xstr_lofst_lft} : {NUM1_SZ{FREE_STATE}};

//   T2_PC+c: cu_xend_lft[10.] limit to 10 bits =
//            cu_xstr_lft [10.8] + pgl_wid_lft [9.8]
assign  opcode20c = cu_cmd_en[T2_PC+7'hc] ? OP_ADD : {2{ZERO}};
assign  num_0_20c = cu_cmd_en[T2_PC+7'hc] ? {{NUM0_SZ- 18{1'b0}}, cu_xstr_full_lft} : {NUM0_SZ{FREE_STATE}};
assign  num_1_20c = cu_cmd_en[T2_PC+7'hc] ? {{NUM1_SZ- 17{1'b0}}, pgl_wid_lft}      : {NUM1_SZ{FREE_STATE}};

//   T2_PC+d: cu_xstr_lft [10.] =
//            cu_xstr_full_lft [10.8] - 192[8.8]
assign  opcode20d = cu_cmd_en[T2_PC+7'hd] ? OP_SUB : {2{ZERO}};
assign  num_0_20d = cu_cmd_en[T2_PC+7'hd] ? {{NUM0_SZ- 18{1'b0}}, cu_xstr_full_lft}     : {NUM0_SZ{FREE_STATE}};
assign  num_1_20d = cu_cmd_en[T2_PC+7'hd] ? {{NUM1_SZ- 16{1'b0}}, LR_XSFT, 1'b0, 8'h00} : {NUM1_SZ{FREE_STATE}};

//   T2_PC+e: cu_xend_lft [10.] =
//            cu_xend_lft [10.8] - 192[8.8]
assign  opcode20e = cu_cmd_en[T2_PC+7'he] ? OP_SUB : {2{ZERO}};
assign  num_0_20e = cu_cmd_en[T2_PC+7'he] ? {{NUM0_SZ- 18{1'b0}}, cu_xend_lft, 8'h00}   : {NUM0_SZ{FREE_STATE}};
assign  num_1_20e = cu_cmd_en[T2_PC+7'he] ? {{NUM1_SZ- 16{1'b0}}, LR_XSFT, 1'b0, 8'h00} : {NUM1_SZ{FREE_STATE}};

//   T2_PC+f: cu_xstr_a1_lft[10.] =
//            cu_xstr_lft [10.] + 1'b1 [1.]
assign  opcode20f = cu_cmd_en[T2_PC+7'hf] ? OP_ADD : {2{ZERO}};
assign  num_0_20f = cu_cmd_en[T2_PC+7'hf] ? {{NUM0_SZ- 10{1'b0}}, cu_xstr_lft} : {NUM0_SZ{FREE_STATE}};
assign  num_1_20f = cu_cmd_en[T2_PC+7'hf] ? {{NUM1_SZ-  1{1'b0}}, 1'b1}        : {NUM1_SZ{FREE_STATE}};

//   T2_PC+10: cu_xend_a1_lft[10.] =
//            cu_xend_lft [10.] + 1'b1 [1.]
assign  opcode210 = cu_cmd_en[T2_PC+7'h10] ? OP_ADD : {2{ZERO}};
assign  num_0_210 = cu_cmd_en[T2_PC+7'h10] ? {{NUM0_SZ- 10{1'b0}}, cu_xend_lft} : {NUM0_SZ{FREE_STATE}};
assign  num_1_210 = cu_cmd_en[T2_PC+7'h10] ? {{NUM1_SZ-  1{1'b0}}, 1'b1}        : {NUM1_SZ{FREE_STATE}};


// T3: Per Line Calculation for Right-PGL @ hend & ~cu_y0_rgt_csgb [y_p1 >= y0]
// ===============================================
//   T3_PC+0: dummy
assign  opcode300 = cu_cmd_en[T3_PC+7'h0] ? OP_ADD : {2{ZERO}};
assign  num_0_300 = cu_cmd_en[T3_PC+7'h0] ? {{NUM0_SZ {1'b0}}} : {NUM0_SZ{FREE_STATE}};
assign  num_1_300 = cu_cmd_en[T3_PC+7'h0] ? {{NUM1_SZ {1'b0}}} : {NUM1_SZ{FREE_STATE}};

//   T3_PC+1: wid_dlt_rgt [9.8] integer limit to 9 bits =
//            cu_ydlt_rgt [10.] * pgl_wwg_rgt[2.8]
assign  opcode301 = cu_cmd_en[T3_PC+7'h1] ? OP_MUL : {2{ZERO}};
assign  num_0_301 = cu_cmd_en[T3_PC+7'h1] ? {{NUM0_SZ- 10{1'b0}}, cu_ydlt_rgt} : {NUM0_SZ{FREE_STATE}};
assign  num_1_301 = cu_cmd_en[T3_PC+7'h1] ? {{NUM1_SZ- 10{1'b0}}, pgl_wwg_rgt} : {NUM1_SZ{FREE_STATE}};

//   T3_PC+2: pgl_wid_rgt [9.8] integer limit to 9 bits =
//            pgl_wid_bs_rgt [9.] + wid_dlt_rgt [9.8]
assign  opcode302 = cu_cmd_en[T3_PC+7'h2] ? OP_ADD : {2{ZERO}};
assign  num_0_302 = cu_cmd_en[T3_PC+7'h2] ? {{NUM0_SZ-17{1'b0}}, pgl_wid_bs_rgt, 8'h0} : {NUM0_SZ{FREE_STATE}};
assign  num_1_302 = cu_cmd_en[T3_PC+7'h2] ? {{NUM1_SZ-17{1'b0}}, wid_dlt_rgt}          : {NUM1_SZ{FREE_STATE}};

//   T3_PC+3: ydlt_sqr_rgt [20.] =
//            cu_ydlt_rgt [10.] * cu_ydlt_rgt [10.]
assign  opcode303 = cu_cmd_en[T3_PC+7'h3] ? OP_MUL : {2{ZERO}};
assign  num_0_303 = cu_cmd_en[T3_PC+7'h3] ? {{NUM0_SZ- 10{1'b0}}, cu_ydlt_rgt} : {NUM0_SZ{FREE_STATE}};
assign  num_1_303 = cu_cmd_en[T3_PC+7'h3] ? {{NUM1_SZ- 10{1'b0}}, cu_ydlt_rgt} : {NUM1_SZ{FREE_STATE}};

//   T3_PC+4: xstr_cofst0_rgt[10.8] limit to 10.8 =
//            reg_pgl_slpwg_rgt [.8] * ydlt_sqr_rgt [20.]
assign  opcode304 = cu_cmd_en[T3_PC+7'h4] ? OP_MUL : {2{ZERO}};
assign  num_0_304 = cu_cmd_en[T3_PC+7'h4] ? {{NUM0_SZ-  8{1'b0}}, pgl_slpwg_l2r} : {NUM0_SZ{FREE_STATE}};
assign  num_1_304 = cu_cmd_en[T3_PC+7'h4] ? {{NUM1_SZ- 20{1'b0}}, ydlt_sqr_rgt}  : {NUM1_SZ{FREE_STATE}};

//   T3_PC+5: yyb_dlt_rgt [10.]
//            y_p1[10.] - {reg_pgl_ybnd_rgt, 1'b0} [9.]
assign  opcode305 = cu_cmd_en[T3_PC+7'h5] ? OP_SUB : {2{ZERO}};
assign  num_0_305 = cu_cmd_en[T3_PC+7'h5] ? {{NUM0_SZ- 10{1'b0}}, y_p1}               : {NUM0_SZ{FREE_STATE}};
assign  num_1_305 = cu_cmd_en[T3_PC+7'h5] ? {{NUM1_SZ-  9{1'b0}}, pgl_ybnd_l2r, 1'b0} : {NUM1_SZ{FREE_STATE}};

//   T3_PC+6: yy0yb_dsum_rgt [11.]
//            cu_ydlt_rgt [10.] + yyb_dlt_rgt [10.]
assign  opcode306 = cu_cmd_en[T3_PC+7'h6] ? OP_ADD : {2{ZERO}};
assign  num_0_306 = cu_cmd_en[T3_PC+7'h6] ? {{NUM0_SZ- 10{1'b0}}, cu_ydlt_rgt} : {NUM0_SZ{FREE_STATE}};
assign  num_1_306 = cu_cmd_en[T3_PC+7'h6] ? {{NUM1_SZ- 10{1'b0}}, yyb_dlt_rgt} : {NUM1_SZ{FREE_STATE}};

//   T3_PC+7: xstr_cofst_item_rgt [20.] =
//            cu_yb0_dlt_rgt [9.] * yy0yb_dsum_rgt [11.]
assign  opcode307 = cu_cmd_en[T3_PC+7'h7] ? OP_MUL : {2{ZERO}};
assign  num_0_307 = cu_cmd_en[T3_PC+7'h7] ? {{NUM0_SZ-  9{1'b0}}, cu_yb0_dlt_rgt} : {NUM0_SZ{FREE_STATE}};
assign  num_1_307 = cu_cmd_en[T3_PC+7'h7] ? {{NUM1_SZ- 11{1'b0}}, yy0yb_dsum_rgt} : {NUM1_SZ{FREE_STATE}};

//   T3_PC+8: xstr_cofst1_rgt[10.8] limit to 10.8 =
//            reg_pgl_slpwg_rgt [.8] * xstr_cofst_item_rgt [20.]
assign  opcode308 = cu_cmd_en[T3_PC+7'h8] ? OP_MUL : {2{ZERO}};
assign  num_0_308 = cu_cmd_en[T3_PC+7'h8] ? {{NUM0_SZ-  8{1'b0}}, pgl_slpwg_l2r}       : {NUM0_SZ{FREE_STATE}};
assign  num_1_308 = cu_cmd_en[T3_PC+7'h8] ? {{NUM1_SZ- 20{1'b0}}, xstr_cofst_item_rgt} : {NUM1_SZ{FREE_STATE}};

//   T3_PC+9: xstr_part_rgt [11.8]
//            {cu_pgl_xstr_rgt,1'b0} [10.8] + xstr_cofst_rgt[10.8]
assign  opcode309 = cu_cmd_en[T3_PC+7'h9] ? xstr_rgt_op : {2{ZERO}};
assign  num_0_309 = cu_cmd_en[T3_PC+7'h9] ? {{NUM0_SZ- 18{1'b0}}, cu_pgl_xstr_rgt, 9'h0} : {NUM0_SZ{FREE_STATE}};
assign  num_1_309 = cu_cmd_en[T3_PC+7'h9] ? {{NUM1_SZ- 18{1'b0}}, xstr_cofst_rgt}        : {NUM1_SZ{FREE_STATE}};

//   T3_PC+a: xstr_lofst_rgt[10.8] =
//            reg_pgl_slp_rgt [.8] * cu_ydlt_rgt [10.]
assign  opcode30a = cu_cmd_en[T3_PC+7'ha] ? OP_MUL : {2{ZERO}};
assign  num_0_30a = cu_cmd_en[T3_PC+7'ha] ? {{NUM0_SZ-  8{1'b0}}, pgl_slp_l2r} : {NUM0_SZ{FREE_STATE}};
assign  num_1_30a = cu_cmd_en[T3_PC+7'ha] ? {{NUM1_SZ- 10{1'b0}}, cu_ydlt_rgt} : {NUM1_SZ{FREE_STATE}};

//   T3_PC+b: xstr_tmp_rgt[10.8] limit to integer 10 bits =
//            xstr_part_rgt [11.8] - xstr_lofst_rgt[10.8]
assign  opcode30b = cu_cmd_en[T3_PC+7'hb] ? OP_SUB : {2{ZERO}};
assign  num_0_30b = cu_cmd_en[T3_PC+7'hb] ? {{NUM0_SZ- 19{1'b0}}, xstr_part_rgt}  : {NUM0_SZ{FREE_STATE}};
assign  num_1_30b = cu_cmd_en[T3_PC+7'hb] ? {{NUM1_SZ- 18{1'b0}}, xstr_lofst_rgt} : {NUM1_SZ{FREE_STATE}};

//   T3_PC+c: cu_xend_rgt[10.8] =
//            {reg_pgl_xstr_ctr,2'b0} [10.] - xstr_l2r [10.8]
assign  opcode30c = cu_cmd_en[T3_PC+7'hc] ? OP_SUB : {2{ZERO}};
assign  num_0_30c = cu_cmd_en[T3_PC+7'hc] ? {{NUM0_SZ- 18{1'b0}}, reg_pgl_xstr_ctr, 10'h0} : {NUM0_SZ{FREE_STATE}};
assign  num_1_30c = cu_cmd_en[T3_PC+7'hc] ? {{NUM1_SZ- 18{1'b0}}, xstr_l2r}                : {NUM1_SZ{FREE_STATE}};

//   T3_PC+d: cu_xend_rgt[10.8] =
//            cu_xend_rgt [10.8] + 192[8.8]
assign  opcode30d = cu_cmd_en[T3_PC+7'hd] ? OP_ADD : {2{ZERO}};
assign  num_0_30d = cu_cmd_en[T3_PC+7'hd] ? {{NUM0_SZ- 18{1'b0}}, cu_xend_full_rgt}     : {NUM0_SZ{FREE_STATE}};
assign  num_1_30d = cu_cmd_en[T3_PC+7'hd] ? {{NUM1_SZ- 16{1'b0}}, LR_XSFT, 1'b0, 8'h00} : {NUM1_SZ{FREE_STATE}};

//   T3_PC+e: cu_xstr_rgt[10.] =
//            cu_xend_rgt [10.8] - pgl_wid_l2r[9.8]
assign  opcode30e = cu_cmd_en[T3_PC+7'he] ? OP_SUB : {2{ZERO}};
assign  num_0_30e = cu_cmd_en[T3_PC+7'he] ? {{NUM0_SZ- 18{1'b0}}, cu_xend_full_rgt} : {NUM0_SZ{FREE_STATE}};
assign  num_1_30e = cu_cmd_en[T3_PC+7'he] ? {{NUM1_SZ- 17{1'b0}}, pgl_wid_l2r}      : {NUM1_SZ{FREE_STATE}};

//   T3_PC+f: cu_xstr_a1_rgt[10.] =
//            cu_xstr_rgt [10.] + 1'b1 [1.]
assign  opcode30f = cu_cmd_en[T3_PC+7'hf] ? OP_ADD : {2{ZERO}};
assign  num_0_30f = cu_cmd_en[T3_PC+7'hf] ? {{NUM0_SZ- 10{1'b0}}, cu_xstr_rgt} : {NUM0_SZ{FREE_STATE}};
assign  num_1_30f = cu_cmd_en[T3_PC+7'hf] ? {{NUM1_SZ-  1{1'b0}}, 1'b1}        : {NUM1_SZ{FREE_STATE}};

//   T3_PC+10: cu_xend_a1_rgt[10.] =
//            cu_xend_rgt [10.] + 1'b1 [1.]
assign  opcode310 = cu_cmd_en[T3_PC+7'h10] ? OP_ADD : {2{ZERO}};
assign  num_0_310 = cu_cmd_en[T3_PC+7'h10] ? {{NUM0_SZ- 10{1'b0}}, cu_xend_rgt} : {NUM0_SZ{FREE_STATE}};
assign  num_1_310 = cu_cmd_en[T3_PC+7'h10] ? {{NUM1_SZ-  1{1'b0}}, 1'b1}        : {NUM1_SZ{FREE_STATE}};


// T4: Per Line Calculation for Center-PGL @ hend & ~cu_ystr_ctr_csgb [y_p1 >= ystr]
// ===============================================
//   T4_PC+0: cu_ydlt_ctr [10.] =
//            y_p1 [10.] - reg_pgl_ystr_ctr [8.]
assign  opcode400 = cu_cmd_en[T4_PC+7'h0] ? OP_SUB : {2{ZERO}};
assign  num_0_400 = cu_cmd_en[T4_PC+7'h0] ? {{NUM0_SZ- 10{1'b0}}, y_p1}             : {NUM0_SZ{FREE_STATE}};
assign  num_1_400 = cu_cmd_en[T4_PC+7'h0] ? {{NUM1_SZ-  8{1'b0}}, reg_pgl_ystr_ctr} : {NUM1_SZ{FREE_STATE}};

//   T4_PC+1: wid_dlt_ctr [6.] =
//            cu_ydlt_ctr [10.] * reg_pgl_wwg_ctr [.8] // max reg_pgl_wwg_ctr = 15/256
assign  opcode401 = cu_cmd_en[T4_PC+7'h1] ? OP_MUL : {2{ZERO}};
assign  num_0_401 = cu_cmd_en[T4_PC+7'h1] ? {{NUM0_SZ- 10{1'b0}}, cu_ydlt_ctr}           : {NUM0_SZ{FREE_STATE}};
assign  num_1_401 = cu_cmd_en[T4_PC+7'h1] ? {{NUM1_SZ-  8{1'b0}}, 4'h0, reg_pgl_wwg_ctr} : {NUM1_SZ{FREE_STATE}};

//   T4_PC+2: pgl_wid_ctr [7.] =
//            reg_pgl_wid_ctr [5.] + wid_dlt_ctr [6.]
assign  opcode402 = cu_cmd_en[T4_PC+7'h2] ? OP_ADD : {2{ZERO}};
assign  num_0_402 = cu_cmd_en[T4_PC+7'h2] ? {{NUM0_SZ- 5{1'b0}}, reg_pgl_wid_ctr} : {NUM0_SZ{FREE_STATE}};
assign  num_1_402 = cu_cmd_en[T4_PC+7'h2] ? {{NUM1_SZ- 6{1'b0}}, wid_dlt_ctr}     : {NUM1_SZ{FREE_STATE}};

//   T4_PC+3: cu_xstr_ctr [9.] =
//            {reg_pgl_xstr_ctr, 1'b0} [9.] - pgl_wid_ctr [7.]
assign  opcode403 = cu_cmd_en[T4_PC+7'h3] ? OP_SUB : {2{ZERO}};
assign  num_0_403 = cu_cmd_en[T4_PC+7'h3] ? {{NUM0_SZ- 9{1'b0}}, reg_pgl_xstr_ctr, 1'b0} : {NUM0_SZ{FREE_STATE}};
assign  num_1_403 = cu_cmd_en[T4_PC+7'h3] ? {{NUM1_SZ- 7{1'b0}}, pgl_wid_ctr}            : {NUM1_SZ{FREE_STATE}};

//   T4_PC+4: cu_xend_ctr [9.] limit to 9 bits =
//            {reg_pgl_xstr_ctr, 1'b0} [9.] + pgl_wid_ctr [7.]
assign  opcode404 = cu_cmd_en[T4_PC+7'h4] ? OP_ADD : {2{ZERO}};
assign  num_0_404 = cu_cmd_en[T4_PC+7'h4] ? {{NUM0_SZ- 5{1'b0}}, reg_pgl_xstr_ctr, 1'b0} : {NUM0_SZ{FREE_STATE}};
assign  num_1_404 = cu_cmd_en[T4_PC+7'h4] ? {{NUM1_SZ- 6{1'b0}}, pgl_wid_ctr}            : {NUM1_SZ{FREE_STATE}};

//   T4_PC+5: cu_xstr_a1_ctr [9.] =
//            cu_xstr_ctr [9.] + 1'b1
assign  opcode405 = cu_cmd_en[T4_PC+7'h5] ? OP_ADD : {2{ZERO}};
assign  num_0_405 = cu_cmd_en[T4_PC+7'h5] ? {{NUM0_SZ- 9{1'b0}}, cu_xstr_ctr} : {NUM0_SZ{FREE_STATE}};
assign  num_1_405 = cu_cmd_en[T4_PC+7'h5] ? {{NUM1_SZ- 1{1'b0}}, 1'b1}        : {NUM1_SZ{FREE_STATE}};

//   T4_PC+6: cu_xend_a1_ctr [9.] =
//            cu_xend_ctr [9.] + 1'b1
assign  opcode406 = cu_cmd_en[T4_PC+7'h6] ? OP_ADD : {2{ZERO}};
assign  num_0_406 = cu_cmd_en[T4_PC+7'h6] ? {{NUM0_SZ- 9{1'b0}}, cu_xend_ctr} : {NUM0_SZ{FREE_STATE}};
assign  num_1_406 = cu_cmd_en[T4_PC+7'h6] ? {{NUM1_SZ- 1{1'b0}}, 1'b1}        : {NUM1_SZ{FREE_STATE}};


// T5: Calculation @ hend & (cu_yend_lft_eq | cu_y0_lft_eq)
// ===============================================
//   T5_PC+0: cu_ystr_lft [10.] limit to 10 bits =
//            cu_ystr_lft [10.] + pgl_ystr_lft [8.]
assign  opcode500 = cu_cmd_en[T5_PC+7'h0] ? OP_ADD : {2{ZERO}};
assign  num_0_500 = cu_cmd_en[T5_PC+7'h0] ? {{NUM0_SZ- 10{1'b0}}, cu_ystr_lft}  : {NUM0_SZ{FREE_STATE}};
assign  num_1_500 = cu_cmd_en[T5_PC+7'h0] ? {{NUM1_SZ-  8{1'b0}}, pgl_ystr_lft} : {NUM1_SZ{FREE_STATE}};

//   T5_PC+1: cu_yend_lft [10.] limit to 10 bits =
//            cu_ystr_lft [10.] + pgl_h_lft [6.]
assign  opcode501 = cu_cmd_en[T5_PC+7'h1] ? OP_ADD : {2{ZERO}};
assign  num_0_501 = cu_cmd_en[T5_PC+7'h1] ? {{NUM0_SZ- 10{1'b0}}, cu_ystr_lft} : {NUM0_SZ{FREE_STATE}};
assign  num_1_501 = cu_cmd_en[T5_PC+7'h1] ? {{NUM1_SZ-  6{1'b0}}, pgl_h_lft}   : {NUM1_SZ{FREE_STATE}};

//   T5_PC+2: cu_ystr_lft_eq [1.] =
//            y_p1 [10.] - cu_ystr_lft [10.]
assign  opcode502 = cu_cmd_en[T5_PC+7'h2] ? OP_SUB : {2{ZERO}};
assign  num_0_502 = cu_cmd_en[T5_PC+7'h2] ? {{NUM0_SZ- 10{1'b0}}, y_p1}        : {NUM0_SZ{FREE_STATE}};
assign  num_1_502 = cu_cmd_en[T5_PC+7'h2] ? {{NUM1_SZ- 10{1'b0}}, cu_ystr_lft} : {NUM1_SZ{FREE_STATE}};

// T6: Calculation @ hend & (cu_yend_rgt_eq | cu_y0_rgt_eq)
// ===============================================
//   T6_PC+0: cu_ystr_rgt [10.] limit to 10 bits =
//            cu_ystr_rgt [10.] + pgl_ystr_rgt [8.]
assign  opcode600 = cu_cmd_en[T6_PC+7'h0] ? OP_ADD : {2{ZERO}};
assign  num_0_600 = cu_cmd_en[T6_PC+7'h0] ? {{NUM0_SZ- 10{1'b0}}, cu_ystr_rgt}  : {NUM0_SZ{FREE_STATE}};
assign  num_1_600 = cu_cmd_en[T6_PC+7'h0] ? {{NUM1_SZ-  8{1'b0}}, pgl_ystr_l2r} : {NUM1_SZ{FREE_STATE}};

//   T6_PC+1: cu_yend_rgt [10.] limit to 10 bits =
//            cu_ystr_rgt [10.] + pgl_h_rgt [6.]
assign  opcode601 = cu_cmd_en[T6_PC+7'h1] ? OP_ADD : {2{ZERO}};
assign  num_0_601 = cu_cmd_en[T6_PC+7'h1] ? {{NUM0_SZ- 10{1'b0}}, cu_ystr_rgt} : {NUM0_SZ{FREE_STATE}};
assign  num_1_601 = cu_cmd_en[T6_PC+7'h1] ? {{NUM1_SZ-  6{1'b0}}, pgl_h_l2r}   : {NUM1_SZ{FREE_STATE}};

//   T6_PC+2: cu_ystr_rgt_eq [1.] =
//            y_p1 [10.] - cu_ystr_rgt [10.]
assign  opcode602 = cu_cmd_en[T6_PC+7'h2] ? OP_SUB : {2{ZERO}};
assign  num_0_602 = cu_cmd_en[T6_PC+7'h2] ? {{NUM0_SZ- 10{1'b0}}, y_p1}        : {NUM0_SZ{FREE_STATE}};
assign  num_1_602 = cu_cmd_en[T6_PC+7'h2] ? {{NUM1_SZ- 10{1'b0}}, cu_ystr_rgt} : {NUM1_SZ{FREE_STATE}};


// T7: Calculation @ hend & cu_ystr_ctr_eq
// ===============================================
//   T7_PC+0: hgt_dlt_ctr [6.] =
//            cu_ydlt_ctr [10.] * reg_pgl_hwg_ctr [.8] // max reg_pgl_hwg_ctr = 15/256
assign  opcode700 = cu_cmd_en[T7_PC+7'h0] ? OP_MUL : {2{ZERO}};
assign  num_0_700 = cu_cmd_en[T7_PC+7'h0] ? {{NUM0_SZ- 10{1'b0}}, cu_ydlt_ctr}           : {NUM0_SZ{FREE_STATE}};
assign  num_1_700 = cu_cmd_en[T7_PC+7'h0] ? {{NUM1_SZ-  8{1'b0}}, 4'h0, reg_pgl_hwg_ctr} : {NUM1_SZ{FREE_STATE}};

//   T7_PC+1: pgl_hgt_ctr [7.] =
//            reg_pgl_hgt_ctr [5.] + hgt_dlt_ctr [6.]
assign  opcode701 = cu_cmd_en[T7_PC+7'h1] ? OP_ADD : {2{ZERO}};
assign  num_0_701 = cu_cmd_en[T7_PC+7'h1] ? {{NUM0_SZ- 5{1'b0}}, reg_pgl_hgt_ctr} : {NUM0_SZ{FREE_STATE}};
assign  num_1_701 = cu_cmd_en[T7_PC+7'h1] ? {{NUM1_SZ- 6{1'b0}}, hgt_dlt_ctr}     : {NUM1_SZ{FREE_STATE}};

//   T7_PC+2: cu_yend_ctr [10.] =
//            cu_ystr_ctr [10.] + pgl_hgt_ctr [7.]
assign  opcode702 = cu_cmd_en[T7_PC+7'h2] ? OP_ADD : {2{ZERO}};
assign  num_0_702 = cu_cmd_en[T7_PC+7'h2] ? {{NUM0_SZ-10{1'b0}}, cu_ystr_ctr} : {NUM0_SZ{FREE_STATE}};
assign  num_1_702 = cu_cmd_en[T7_PC+7'h2] ? {{NUM1_SZ- 7{1'b0}}, pgl_hgt_ctr} : {NUM1_SZ{FREE_STATE}};


// T8: Calculation @ hend & cu_yend_ctr_eq
// ===============================================
//   T8_PC+0: hgt_dlt_ctr [6.] =
//            cu_ydlt_ctr [10.] * reg_pgl_hwg_ctr [.8] // max reg_pgl_hwg_ctr = 15/256
assign  opcode800 = cu_cmd_en[T8_PC+7'h0] ? OP_MUL : {2{ZERO}};
assign  num_0_800 = cu_cmd_en[T8_PC+7'h0] ? {{NUM0_SZ- 10{1'b0}}, cu_ydlt_ctr}           : {NUM0_SZ{FREE_STATE}};
assign  num_1_800 = cu_cmd_en[T8_PC+7'h0] ? {{NUM1_SZ-  8{1'b0}}, 4'h0, reg_pgl_hwg_ctr} : {NUM1_SZ{FREE_STATE}};

//   T8_PC+1: pgl_blk_ctr [7.] =
//            reg_pgl_blk_ctr [5.] + hgt_dlt_ctr [6.]
assign  opcode801 = cu_cmd_en[T8_PC+7'h1] ? OP_ADD : {2{ZERO}};
assign  num_0_801 = cu_cmd_en[T8_PC+7'h1] ? {{NUM0_SZ- 5{1'b0}}, reg_pgl_blk_ctr} : {NUM0_SZ{FREE_STATE}};
assign  num_1_801 = cu_cmd_en[T8_PC+7'h1] ? {{NUM1_SZ- 6{1'b0}}, hgt_dlt_ctr}     : {NUM1_SZ{FREE_STATE}};

//   T8_PC+2: cu_ystr_ctr [10.] =
//            cu_yend_ctr [10.] + pgl_blk_ctr [7.]
assign  opcode802 = cu_cmd_en[T8_PC+7'h2] ? OP_ADD : {2{ZERO}};
assign  num_0_802 = cu_cmd_en[T8_PC+7'h2] ? {{NUM0_SZ-10{1'b0}}, cu_yend_ctr} : {NUM0_SZ{FREE_STATE}};
assign  num_1_802 = cu_cmd_en[T8_PC+7'h2] ? {{NUM1_SZ- 7{1'b0}}, pgl_blk_ctr} : {NUM1_SZ{FREE_STATE}};



// ---------------------------------------------//
//            CU OP result                      //
// ---------------------------------------------//

assign  cu_tmp0_nxt       = op_rdy_sm & (cu_cmd_en[T0_PC+7'h01]  |
                                         cu_cmd_en[T0_PC+7'h07]  |
                                         cu_cmd_en[T2_PC+7'h01]  |
                                         cu_cmd_en[T2_PC+7'h03]  |
                                         cu_cmd_en[T2_PC+7'h04]  |
                                         cu_cmd_en[T2_PC+7'h09]  |
                                         cu_cmd_en[T4_PC+7'h01]  |
                                         cu_cmd_en[T7_PC+7'h00]  |
                                         cu_cmd_en[T8_PC+7'h00]) ? {prod_msb[28-ALU_SZ-1:0], prod_lsb[ALU_SZ-1:0]} : cu_tmp0;

assign  cu_tmp1_nxt       = op_rdy_sm & (cu_cmd_en[T0_PC+7'h08]  |
                                         cu_cmd_en[T0_PC+7'h0e]  |
                                         cu_cmd_en[T0_PC+7'h14]  |
                                         cu_cmd_en[T3_PC+7'h01]  |
                                         cu_cmd_en[T3_PC+7'h03]  |
                                         cu_cmd_en[T3_PC+7'h04]  |
                                         cu_cmd_en[T3_PC+7'h09]) ? {prod_msb[28-ALU_SZ-1:0], prod_lsb[ALU_SZ-1:0]} : cu_tmp1;

assign  cu_tmp2_nxt       = op_rdy_sm & (cu_cmd_en[T0_PC+7'h0a]  |
                                         cu_cmd_en[T0_PC+7'h10]  |
                                         cu_cmd_en[T0_PC+7'h16]  |
                                         cu_cmd_en[T2_PC+7'h07]  |
                                         cu_cmd_en[T2_PC+7'h08]  |
                                         cu_cmd_en[T2_PC+7'h0a]  |
                                         cu_cmd_en[T7_PC+7'h01]  |
                                         cu_cmd_en[T8_PC+7'h01]) ? {prod_msb[28-ALU_SZ-1:0], prod_lsb[ALU_SZ-1:0]} : cu_tmp2;

assign  cu_tmp3_nxt       = op_rdy_sm & (cu_cmd_en[T0_PC+7'h0c]  |
                                         cu_cmd_en[T0_PC+7'h12]  |
                                         cu_cmd_en[T0_PC+7'h19]  |
                                         cu_cmd_en[T3_PC+7'h07]  |
                                         cu_cmd_en[T3_PC+7'h08]  |
                                         cu_cmd_en[T3_PC+7'h0a]  |
                                         cu_cmd_en[T4_PC+7'h00]) ? {prod_msb[28-ALU_SZ-1:0], prod_lsb[ALU_SZ-1:0]} : cu_tmp3;

// T0_PC
// -----------------------------------------------
assign  cu_vend_ctr_nxt  = op_rdy_sm & cu_cmd_en[T0_PC+7'h0] ? prod_lsb[9:0] : cu_vend_ctr;

// T0_PC+7'h1
assign  palt_yrto = cu_tmp0[5:0];

assign  cu_pgl_palt_yr_nxt  = op_rdy_sm & cu_cmd_en[T0_PC+7'h2] ? prod_lsb[5 +: 8] : cu_pgl_palt_yr;

assign  cu_pgl_palt_yg_nxt  = op_rdy_sm & cu_cmd_en[T0_PC+7'h3] ? prod_lsb[5 +: 8] : cu_pgl_palt_yg;

assign  cu_pgl_palt_yy_nxt  = op_rdy_sm & cu_cmd_en[T0_PC+7'h4] ? prod_lsb[5 +: 8] : cu_pgl_palt_yy;

assign  cu_pgl_palt_yb_nxt  = op_rdy_sm & cu_cmd_en[T0_PC+7'h5] ? prod_lsb[5 +: 8] : cu_pgl_palt_yb;

assign  cu_pgl_palt_bw0_nxt = op_rdy_sm & cu_cmd_en[T0_PC+7'h6] ? prod_lsb[5 +: 8] : cu_pgl_palt_bw0;

// T0_PC+7'h7
assign  palt_crto = cu_tmp0[5:0];

// T0_PC+7'h8
assign  palt_ur_tmp = cu_tmp1[5 +: 8];

assign  cu_pgl_palt_ur_nxt = op_rdy_sm & cu_cmd_en[T0_PC+7'h09] ? prod_lsb[7:0] : cu_pgl_palt_ur;

// T0_PC+7'ha
assign  palt_ug_tmp = cu_tmp2[5 +: 8];

assign  cu_pgl_palt_ug_nxt = op_rdy_sm & cu_cmd_en[T0_PC+7'h0b] ? prod_lsb[7:0] : cu_pgl_palt_ug;

// T0_PC+7'hc
assign  palt_uy_tmp = cu_tmp3[5 +: 8];

assign  cu_pgl_palt_uy_nxt = op_rdy_sm & cu_cmd_en[T0_PC+7'h0d] ? prod_lsb[7:0] : cu_pgl_palt_uy;

// T0_PC+7'he
assign  palt_ub_tmp = cu_tmp1[5 +: 8];

assign  cu_pgl_palt_ub_nxt = op_rdy_sm & cu_cmd_en[T0_PC+7'h0f] ? prod_lsb[7:0] : cu_pgl_palt_ub;

// T0_PC+7'h10
assign  palt_vr_tmp = cu_tmp2[5 +: 8];

assign  cu_pgl_palt_vr_nxt = op_rdy_sm & cu_cmd_en[T0_PC+7'h11] ? prod_lsb[7:0] : cu_pgl_palt_vr;

// T0_PC+7'h12
assign  palt_vg_tmp = cu_tmp3[5 +: 8];

assign  cu_pgl_palt_vg_nxt = op_rdy_sm & cu_cmd_en[T0_PC+7'h13] ? prod_lsb[7:0] : cu_pgl_palt_vg;

// T0_PC+7'h14
assign  palt_vy_tmp = cu_tmp1[5 +: 8];

assign  cu_pgl_palt_vy_nxt = op_rdy_sm & cu_cmd_en[T0_PC+7'h15] ? prod_lsb[7:0] : cu_pgl_palt_vy;

// T0_PC+7'h16
assign  palt_vb_tmp = cu_tmp2[5 +: 8];

assign  cu_pgl_palt_vb_nxt = op_rdy_sm & cu_cmd_en[T0_PC+7'h17] ? prod_lsb[7:0] : cu_pgl_palt_vb;

assign  cu_pgl_trsp_cmpl_nxt = op_rdy_sm & cu_cmd_en[T0_PC+7'h18] ? prod_lsb[8:0] : cu_pgl_trsp_cmpl;

// T0_PC+7'h19
assign  pgl_aa_k_cmpl = cu_tmp3[2:0];

assign  cu_pgl_aa_cmpl_nxt   = op_rdy_sm & cu_cmd_en[T0_PC+7'h1a] ? prod_lsb[2 +: 9] : cu_pgl_aa_cmpl;

assign  cu_pgl_aa_trsp_nxt   = op_rdy_sm & cu_cmd_en[T0_PC+7'h1b] ? prod_lsb[8:0] : cu_pgl_aa_trsp;

//
assign  cu_pgl_hln0_wid_nxt = op_rdy_sm & cu_cmd_en[T0_PC+7'h1c] ? prod_lsb[1 +: 9] : cu_pgl_hln0_wid;

assign  cu_pgl_hln1_wid_nxt = op_rdy_sm & cu_cmd_en[T0_PC+7'h1d] ? prod_lsb[8:0] | {9{prod_lsb[9]}}  : cu_pgl_hln1_wid;

assign  cu_pgl_hwwg_lft_nxt = op_rdy_sm & cu_cmd_en[T0_PC+7'h1e] ? prod_lsb[9:0] : cu_pgl_hwwg_lft;

assign  cu_pgl_hwwg_rgt_nxt = op_rdy_sm & cu_cmd_en[T0_PC+7'h1f] ? prod_lsb[9:0] : cu_pgl_hwwg_rgt;

assign  cu_yb0_dlt_lft_nxt  = op_rdy_sm       & (cu_cmd_en[T0_PC+7'h20]  |
                              cu_yb0_lft_csgb &  cu_cmd_en[T0_PC+7'h21]) ? prod_lsb[8:0] : cu_yb0_dlt_lft;

assign  cu_yb0_lft_csgb_nxt = op_rdy_sm & cu_cmd_en[T0_PC+7'h20] ? prod_lsb[9] : cu_yb0_lft_csgb;

assign  cu_yb0_dlt_rgt_nxt  = op_rdy_sm       & (cu_cmd_en[T0_PC+7'h22]  |
                              cu_yb0_rgt_csgb &  cu_cmd_en[T0_PC+7'h23]) ? prod_lsb[8:0] : cu_yb0_dlt_rgt;

assign  cu_yb0_rgt_csgb_nxt = op_rdy_sm & cu_cmd_en[T0_PC+7'h22] ? prod_lsb[9] : cu_yb0_rgt_csgb;

assign  cu_pgl_xstr_lft_nxt = op_rdy_sm & cu_cmd_en[T0_PC+7'h24] ? prod_lsb[8:0] : cu_pgl_xstr_lft;

assign  cu_pgl_xstr_rgt_nxt = op_rdy_sm & cu_cmd_en[T0_PC+7'h25] ? prod_lsb[8:0] : cu_pgl_xstr_rgt;


// T1_PC
// -----------------------------------------------
assign  y_p1_nxt  = op_rdy_sm & cu_cmd_en[T1_PC+7'h0] ? prod_lsb[9:0] : y_p1;

// T1_PC+7'h1 ~ T1_PC+7'h3: dummy
// T1_PC+7'h4
assign  cu_y0_lft_eq_nxt     = op_rdy_sm & cu_cmd_en[T1_PC+7'h4] ? ~(|prod_lsb[0 +: 11]) : cu_y0_lft_eq;
assign  cu_y0_lft_csgb_nxt   = op_rdy_sm & cu_cmd_en[T1_PC+7'h4] ? prod_lsb[10]          : cu_y0_lft_csgb;

assign  cu_ydlt_lft          = cu_xstr_lft_shr[0 +: 10];

// T1_PC+7'h5
assign  cu_ystr_lft_csgb_nxt = op_rdy_sm & cu_cmd_en[T1_PC+7'h5] ? prod_lsb[10]       : cu_ystr_lft_csgb;

assign  cu_yend_lft_eq_nxt   = op_rdy_sm & cu_cmd_en[T1_PC+7'h6] ? ~(|prod_lsb[10:0]) : cu_yend_lft_eq;
assign  cu_yend_lft_csgb_nxt = op_rdy_sm & cu_cmd_en[T1_PC+7'h6] ? prod_lsb[10]       : cu_yend_lft_csgb;

assign  cu_ybnd_lft_csgb_nxt = op_rdy_sm & cu_cmd_en[T1_PC+7'h7] ? prod_lsb[10]       : cu_ybnd_lft_csgb;

// T1_PC+7'h8
assign  cu_y0_rgt_eq_nxt     = op_rdy_sm & cu_cmd_en[T1_PC+7'h8] ? ~(|prod_lsb[0 +: 11]) : cu_y0_rgt_eq;
assign  cu_y0_rgt_csgb_nxt   = op_rdy_sm & cu_cmd_en[T1_PC+7'h8] ? prod_lsb[10]       : cu_y0_rgt_csgb;

assign  cu_ydlt_rgt          = cu_xstr_rgt_shr[0 +: 10];

// T1_PC+7'h9
assign  cu_ystr_rgt_csgb_nxt = op_rdy_sm & cu_cmd_en[T1_PC+7'h9] ? prod_lsb[10]       : cu_ystr_rgt_csgb;

assign  cu_yend_rgt_eq_nxt   = op_rdy_sm & cu_cmd_en[T1_PC+7'ha] ? ~(|prod_lsb[10:0]) : cu_yend_rgt_eq;
assign  cu_yend_rgt_csgb_nxt = op_rdy_sm & cu_cmd_en[T1_PC+7'ha] ? prod_lsb[10]       : cu_yend_rgt_csgb;

assign  cu_ybnd_rgt_csgb_nxt = op_rdy_sm & cu_cmd_en[T1_PC+7'hb] ? prod_lsb[10]       : cu_ybnd_rgt_csgb;

// T1_PC+7'hc
assign  cu_y0_ctr_csgb_nxt   = op_rdy_sm & cu_cmd_en[T1_PC+7'hc] ? prod_lsb[10]       : cu_y0_ctr_csgb;

assign  cu_ystr_ctr_eq_nxt   = op_rdy_sm & cu_cmd_en[T1_PC+7'hd] ? ~(|prod_lsb[10:0]) : cu_ystr_ctr_eq;
assign  cu_ystr_ctr_csgb_nxt = op_rdy_sm & cu_cmd_en[T1_PC+7'hd] ? prod_lsb[10]       : cu_ystr_ctr_csgb;

assign  cu_yend_ctr_eq_nxt   = op_rdy_sm & cu_cmd_en[T1_PC+7'he] ? ~(|prod_lsb[10:0]) : cu_yend_ctr_eq;
assign  cu_yend_ctr_csgb_nxt = op_rdy_sm & cu_cmd_en[T1_PC+7'he] ? prod_lsb[10]       : cu_yend_ctr_csgb;

assign  cu_vend_ctr_csgb_nxt = op_rdy_sm & cu_cmd_en[T1_PC+7'hf] ? prod_lsb[10]       : cu_vend_ctr_csgb;

// T2_PC
// -----------------------------------------------
assign  cu_xstr_lft_shr_nxt = op_rdy_sm & (cu_cmd_en[T1_PC+7'h4]  |
                                           cu_cmd_en[T2_PC+7'hb]  |
                                           cu_cmd_en[T2_PC+7'hd]) ? prod_lsb[18:0]    : cu_xstr_lft_shr;

assign  cu_xend_lft_shr_nxt = op_rdy_sm & (cu_cmd_en[T2_PC+7'h5]  |
                                           cu_cmd_en[T2_PC+7'h6]  |
                                           cu_cmd_en[T2_PC+7'hc]  |
                                           cu_cmd_en[T2_PC+7'he]) ? prod_lsb[8 +: 11] : cu_xend_lft_shr;

// T2_PC+7'h0: dummy

// T2_PC+7'h1
assign  wid_dlt_lft = cu_tmp0[0 +: 17] | {17{|cu_tmp0[19:17]}};

assign  pgl_wid_lft_nxt = op_rdy_sm & cu_cmd_en[T2_PC+7'h2] ? prod_lsb[16:0] | {17{prod_lsb[17]}}: pgl_wid_lft;

// T2_PC+7'h3
assign  ydlt_sqr_lft = cu_tmp0[19:0];

// T2_PC+7'h4
assign  xstr_cofst0_lft = cu_tmp0[10 +: 18];

// T2_PC+7'h5
assign  yyb_dlt_lft = cu_xend_lft_shr[9:0];

// T2_PC+7'h6
assign  yy0yb_dsum_lft = cu_xend_lft_shr[10:0];

// T2_PC+7'h7
assign  xstr_cofst_item_lft = cu_tmp2[19:0];

// T2_PC+7'h8
assign  xstr_cofst1_lft = cu_tmp2[10 +: 18];

// T2_PC+7'h9
assign  xstr_part_lft = cu_tmp0[18:0];

// T2_PC+7'ha
assign  xstr_lofst_lft = cu_tmp2[0 +: 18];

// T2_PC+7'hb
assign  cu_xstr_full_lft = cu_xstr_lft_shr[17:0] & {18{~cu_xstr_lft_shr[18]}};
assign  xstr_tmp_lft_nxt = op_rdy_sm & cu_cmd_en[T2_PC+7'hb]  ? prod_lsb[17:0] : xstr_tmp_lft;

// T2_PC+7'hd
assign  cu_xstr_lft      = ({cu_xstr_lft_shr[9 +: 9], cu_xstr_lft_shr[8] & ~reg_pgl_evw_lim}) & {10{~cu_xstr_lft_shr[18]}};

// T2_PC+7'hc
// T2_PC+7'he
assign  cu_xend_lft      = ({cu_xend_lft_shr[9:1], cu_xend_lft_shr[0] & ~reg_pgl_evw_lim}) & {10{~cu_xend_lft_shr[10]}};

// T2_PC+7'hf
assign  cu_xstr_a1_lft_nxt = op_rdy_sm & cu_cmd_en[T2_PC+7'hf]  ? prod_lsb[9:0] : cu_xstr_a1_lft[9:0];

// T2_PC+7'h10
assign  cu_xend_a1_lft_nxt = op_rdy_sm & cu_cmd_en[T2_PC+7'h10] ? prod_lsb[9:0] : cu_xend_a1_lft[9:0];


// T3_PC
// -----------------------------------------------
assign  cu_xstr_rgt_shr_nxt = op_rdy_sm & (cu_cmd_en[T1_PC+7'h8]  |
                                           cu_cmd_en[T3_PC+7'hb]  |
                                           cu_cmd_en[T3_PC+7'he]) ? prod_lsb[18:0] : cu_xstr_rgt_shr;

assign  cu_xend_rgt_shr_nxt = op_rdy_sm & (cu_cmd_en[T3_PC+7'h5]  |
                                           cu_cmd_en[T3_PC+7'h6]  |
                                           cu_cmd_en[T3_PC+7'hc]  |
                                           cu_cmd_en[T3_PC+7'hd]) ? prod_lsb[18:0] : cu_xend_rgt_shr;
// T3_PC+7'h0: dummy

// T3_PC+7'h1
assign  wid_dlt_rgt = cu_tmp1[0 +: 17] | {17{|cu_tmp1[19:17]}};

assign  pgl_wid_rgt_nxt = op_rdy_sm & cu_cmd_en[T3_PC+7'h2] ? prod_lsb[16:0] | {17{prod_lsb[17]}}: pgl_wid_rgt;

// T3_PC+7'h3
assign  ydlt_sqr_rgt = cu_tmp1[19:0];

// T3_PC+7'h4
assign  xstr_cofst0_rgt = cu_tmp1[10 +: 18];

// T3_PC+7'h5
assign  yyb_dlt_rgt = cu_xend_rgt_shr[9:0];

// T3_PC+7'h6
assign  yy0yb_dsum_rgt = cu_xend_rgt_shr[10:0];

// T3_PC+7'h7
assign  xstr_cofst_item_rgt = cu_tmp3[19:0];

// T3_PC+7'h8
assign  xstr_cofst1_rgt = cu_tmp3[10 +: 18];

// T3_PC+7'h9
assign  xstr_part_rgt = cu_tmp1[18:0];

// T3_PC+7'ha
assign  xstr_lofst_rgt = cu_tmp3[0 +: 18];

// T3_PC+7'hb
assign  xstr_tmp_rgt = cu_xstr_rgt_shr[17:0] & {18{~cu_xstr_rgt_shr[18]}};

// T3_PC+7'hc
assign  cu_xend_full_rgt = cu_xend_rgt_shr[0 +: 18];

// T3_PC+7'hd
assign  cu_xend_rgt = {cu_xend_rgt_shr[9 +: 9], cu_xend_rgt_shr[8] & ~reg_pgl_evw_lim};

// T3_PC+7'he
assign  cu_xstr_rgt = {cu_xstr_rgt_shr[9 +: 9], cu_xstr_rgt_shr[8] & ~reg_pgl_evw_lim};

// T3_PC+7'hf
assign  cu_xstr_a1_rgt_nxt = op_rdy_sm & cu_cmd_en[T3_PC+7'hf] ? prod_lsb[9:0] : cu_xstr_a1_rgt[9:0];

// T3_PC+7'h10
assign  cu_xend_a1_rgt_nxt = op_rdy_sm & cu_cmd_en[T3_PC+7'h10] ? prod_lsb[9:0] | {10{prod_lsb[10]}} : cu_xend_a1_rgt[9:0];


// T4_PC
// -----------------------------------------------

assign  cu_xstr_ctr_shr_nxt = op_rdy_sm & cu_cmd_en[T4_PC+7'h3]  ? prod_lsb[9:0] : cu_xstr_ctr_shr;

assign  cu_xend_ctr_shr_nxt = op_rdy_sm & cu_cmd_en[T4_PC+7'h4] ? prod_lsb[9:0] : cu_xend_ctr_shr;

// T4_PC+7'h0
assign  cu_ydlt_ctr = cu_tmp3[9:0];

// T4_PC+7'h1
assign  wid_dlt_ctr = cu_tmp0[8 +: 6];

// T4_PC+7'h2
assign  pgl_wid_ctr_nxt = cu_ystr_ctr_eq &
                          op_rdy_sm & cu_cmd_en[T4_PC+7'h2] ? prod_lsb[6:0] : pgl_wid_ctr;

// T4_PC+7'h3
assign  cu_xstr_ctr = {cu_xstr_ctr_shr[8:1], cu_xstr_ctr_shr[0] & ~reg_pgl_evw_lim} | {9{cu_xstr_ctr_shr[9]}};

// T4_PC+7'h4
assign  cu_xend_ctr = {cu_xend_ctr_shr[8:1], cu_xend_ctr_shr[0] & ~reg_pgl_evw_lim} | {9{cu_xend_ctr_shr[9]}};

// T4_PC+7'h5
assign  cu_xstr_a1_ctr_nxt = op_rdy_sm & cu_cmd_en[T4_PC+7'h5] ? prod_lsb[8:0] : cu_xstr_a1_ctr;

// T4_PC+7'h6
assign  cu_xend_a1_ctr_nxt = op_rdy_sm & cu_cmd_en[T4_PC+7'h6] ? prod_lsb[8:0] : cu_xend_a1_ctr;


// T5_PC
// -----------------------------------------------
assign  cu_ystr_lft_nxt = {10{~fm_str}} &
                         (op_rdy_sm & cu_cmd_en[T5_PC+7'h0] ? prod_lsb[9:0] | {10{prod_lsb[10]}} : cu_ystr_lft);

assign  cu_yend_lft_nxt = {10{~fm_str}} &
                         (op_rdy_sm & cu_cmd_en[T5_PC+7'h1] ? prod_lsb[9:0] | {10{prod_lsb[10]}} : cu_yend_lft);

assign  cu_ystr_lft_eq_nxt = ~fm_str & (op_rdy_sm & cu_cmd_en[T5_PC+7'h2] ? ~(|prod_lsb[0 +: 11]) : cu_ystr_lft_eq);

// T6_PC
// -----------------------------------------------
assign  cu_ystr_rgt_nxt = {10{~fm_str}} &
                         (op_rdy_sm & cu_cmd_en[T6_PC+7'h0] ? prod_lsb[9:0] | {10{prod_lsb[10]}} : cu_ystr_rgt);

assign  cu_yend_rgt_nxt = {10{~fm_str}} &
                         (op_rdy_sm & cu_cmd_en[T6_PC+7'h1] ? prod_lsb[9:0] | {10{prod_lsb[10]}} : cu_yend_rgt);

assign  cu_ystr_rgt_eq_nxt = ~fm_str & (op_rdy_sm & cu_cmd_en[T6_PC+7'h2] ? ~(|prod_lsb[0 +: 11]) : cu_ystr_rgt_eq);

// T7_PC
// -----------------------------------------------
// T7_PC+7'h0, T8_PC+7'h0
assign  hgt_dlt_ctr = cu_tmp0[8 +: 6];

// T7_PC+7'h1
assign  pgl_hgt_ctr = cu_tmp2[6:0];

assign  cu_yend_ctr_nxt = {10{~fm_str}} &
                         (op_rdy_sm & cu_cmd_en[T7_PC+7'h2] ? prod_lsb[9:0] | {10{prod_lsb[10]}} : cu_yend_ctr);


// T8_PC
// -----------------------------------------------
// T8_PC+7'h0
//assign  hgt_dlt_ctr = cu_tmp0[8 +: 6];

// T8_PC+7'h1
assign  pgl_blk_ctr = cu_tmp2[6:0];

assign  cu_ystr_ctr_nxt = fm_str ? {2'b0, reg_pgl_ystr_ctr} :
                          op_rdy_sm & cu_cmd_en[T8_PC+7'h2] ? prod_lsb[9:0] | {10{prod_lsb[10]}} : cu_ystr_ctr;


// ---------- Sequential Logic -----------------//

always @(posedge pclk or negedge prst_n) begin
   if (~prst_n) begin
      cu_pgl_palt_yr    <= 0;
      cu_pgl_palt_yg    <= 0;
      cu_pgl_palt_yy    <= 0;
      cu_pgl_palt_yb    <= 0;
      cu_pgl_palt_bw0   <= 0;
      cu_pgl_palt_ur    <= 0;
      cu_pgl_palt_ug    <= 0;
      cu_pgl_palt_uy    <= 0;
      cu_pgl_palt_ub    <= 0;
      cu_pgl_palt_vr    <= 0;
      cu_pgl_palt_vg    <= 0;
      cu_pgl_palt_vy    <= 0;
      cu_pgl_palt_vb    <= 0;
      cu_pgl_aa_trsp    <= 0;
      cu_pgl_aa_cmpl    <= 0;
      cu_pgl_trsp_cmpl  <= 0;

      cu_pgl_hln0_wid   <= 0;
      cu_pgl_hln1_wid   <= 0;
      cu_pgl_hwwg_lft   <= 0;
      cu_pgl_hwwg_rgt   <= 0;
      cu_yb0_dlt_lft    <= 0;
      cu_yb0_dlt_rgt    <= 0;

      cu_y0_lft_eq      <= 0;
      cu_y0_lft_csgb    <= 0;
      cu_ystr_lft_csgb  <= 0;
      cu_ystr_lft_eq    <= 0;
      cu_yend_lft_eq    <= 0;
      cu_yend_lft_csgb  <= 0;
      cu_ybnd_lft_csgb  <= 0;
      cu_y0_rgt_eq      <= 0;
      cu_y0_rgt_csgb    <= 0;
      cu_ystr_rgt_csgb  <= 0;
      cu_ystr_rgt_eq    <= 0;
      cu_yend_rgt_eq    <= 0;
      cu_yend_rgt_csgb  <= 0;
      cu_ybnd_rgt_csgb  <= 0;
      cu_y0_ctr_csgb    <= 0;
      cu_ystr_ctr_eq    <= 0;
      cu_ystr_ctr_csgb  <= 0;
      cu_yend_ctr_eq    <= 0;
      cu_yend_ctr_csgb  <= 0;
      cu_vend_ctr_csgb  <= 0;
      cu_yb0_lft_csgb   <= 0;
      cu_yb0_rgt_csgb   <= 0;
      cu_xstr_a1_lft    <= 0;
      cu_xend_a1_lft    <= 0;
      cu_xstr_a1_rgt    <= 0;
      cu_xend_a1_rgt    <= 0;
      cu_xstr_a1_ctr    <= 0;
      cu_xend_a1_ctr    <= 0;
      cu_pgl_xstr_lft   <= 0;
      cu_pgl_xstr_rgt   <= 0;

      cu_tmp0           <= 0;
      cu_tmp1           <= 0;
      cu_tmp2           <= 0;
      cu_tmp3           <= 0;
      pgl_wid_lft       <= 0;
      pgl_wid_rgt       <= 0;
      pgl_wid_ctr       <= 0;
      cu_vend_ctr       <= 0;
      y_p1              <= 0;
      cu_xstr_lft_shr   <= 0;
      cu_xend_lft_shr   <= 0;
      xstr_tmp_lft      <= 0;
      cu_xstr_rgt_shr   <= 0;
      cu_xend_rgt_shr   <= 0;
      cu_xstr_ctr_shr   <= 0;
      cu_xend_ctr_shr   <= 0;
      cu_ystr_lft       <= 0;
      cu_yend_lft       <= 0;
      cu_ystr_rgt       <= 0;
      cu_yend_rgt       <= 0;
      cu_yend_ctr       <= 0;
      cu_ystr_ctr       <= 0;
   end
   else begin
      cu_pgl_palt_yr    <= cu_pgl_palt_yr_nxt;
      cu_pgl_palt_yg    <= cu_pgl_palt_yg_nxt;
      cu_pgl_palt_yy    <= cu_pgl_palt_yy_nxt;
      cu_pgl_palt_yb    <= cu_pgl_palt_yb_nxt;
      cu_pgl_palt_bw0   <= cu_pgl_palt_bw0_nxt;
      cu_pgl_palt_ur    <= cu_pgl_palt_ur_nxt;
      cu_pgl_palt_ug    <= cu_pgl_palt_ug_nxt;
      cu_pgl_palt_uy    <= cu_pgl_palt_uy_nxt;
      cu_pgl_palt_ub    <= cu_pgl_palt_ub_nxt;
      cu_pgl_palt_vr    <= cu_pgl_palt_vr_nxt;
      cu_pgl_palt_vg    <= cu_pgl_palt_vg_nxt;
      cu_pgl_palt_vy    <= cu_pgl_palt_vy_nxt;
      cu_pgl_palt_vb    <= cu_pgl_palt_vb_nxt;
      cu_pgl_aa_trsp    <= cu_pgl_aa_trsp_nxt;
      cu_pgl_aa_cmpl    <= cu_pgl_aa_cmpl_nxt;
      cu_pgl_trsp_cmpl  <= cu_pgl_trsp_cmpl_nxt;

      cu_pgl_hln0_wid   <= cu_pgl_hln0_wid_nxt;
      cu_pgl_hln1_wid   <= cu_pgl_hln1_wid_nxt;
      cu_pgl_hwwg_lft   <= cu_pgl_hwwg_lft_nxt;
      cu_pgl_hwwg_rgt   <= cu_pgl_hwwg_rgt_nxt;
      cu_yb0_dlt_lft    <= cu_yb0_dlt_lft_nxt;
      cu_yb0_dlt_rgt    <= cu_yb0_dlt_rgt_nxt;

      cu_y0_lft_eq      <= cu_y0_lft_eq_nxt;
      cu_y0_lft_csgb    <= cu_y0_lft_csgb_nxt;
      cu_ystr_lft_csgb  <= cu_ystr_lft_csgb_nxt;
      cu_ystr_lft_eq    <= cu_ystr_lft_eq_nxt;
      cu_yend_lft_eq    <= cu_yend_lft_eq_nxt;
      cu_yend_lft_csgb  <= cu_yend_lft_csgb_nxt;
      cu_ybnd_lft_csgb  <= cu_ybnd_lft_csgb_nxt;
      cu_y0_rgt_eq      <= cu_y0_rgt_eq_nxt;
      cu_y0_rgt_csgb    <= cu_y0_rgt_csgb_nxt;
      cu_ystr_rgt_csgb  <= cu_ystr_rgt_csgb_nxt;
      cu_ystr_rgt_eq    <= cu_ystr_rgt_eq_nxt;
      cu_yend_rgt_eq    <= cu_yend_rgt_eq_nxt;
      cu_yend_rgt_csgb  <= cu_yend_rgt_csgb_nxt;
      cu_ybnd_rgt_csgb  <= cu_ybnd_rgt_csgb_nxt;
      cu_y0_ctr_csgb    <= cu_y0_ctr_csgb_nxt;
      cu_ystr_ctr_eq    <= cu_ystr_ctr_eq_nxt;
      cu_ystr_ctr_csgb  <= cu_ystr_ctr_csgb_nxt;
      cu_yend_ctr_eq    <= cu_yend_ctr_eq_nxt;
      cu_yend_ctr_csgb  <= cu_yend_ctr_csgb_nxt;
      cu_vend_ctr_csgb  <= cu_vend_ctr_csgb_nxt;
      cu_yb0_lft_csgb   <= cu_yb0_lft_csgb_nxt;
      cu_yb0_rgt_csgb   <= cu_yb0_rgt_csgb_nxt;
      cu_xstr_a1_lft    <= cu_xstr_a1_lft_nxt;
      cu_xend_a1_lft    <= cu_xend_a1_lft_nxt;
      cu_xstr_a1_rgt    <= cu_xstr_a1_rgt_nxt;
      cu_xend_a1_rgt    <= cu_xend_a1_rgt_nxt;
      cu_xstr_a1_ctr    <= cu_xstr_a1_ctr_nxt;
      cu_xend_a1_ctr    <= cu_xend_a1_ctr_nxt;
      cu_pgl_xstr_lft   <= cu_pgl_xstr_lft_nxt;
      cu_pgl_xstr_rgt   <= cu_pgl_xstr_rgt_nxt;

      cu_tmp0           <= cu_tmp0_nxt;
      cu_tmp1           <= cu_tmp1_nxt;
      cu_tmp2           <= cu_tmp2_nxt;
      cu_tmp3           <= cu_tmp3_nxt;
      pgl_wid_lft       <= pgl_wid_lft_nxt;
      pgl_wid_rgt       <= pgl_wid_rgt_nxt;
      pgl_wid_ctr       <= pgl_wid_ctr_nxt;
      cu_vend_ctr       <= cu_vend_ctr_nxt;
      y_p1              <= y_p1_nxt;
      cu_xstr_lft_shr   <= cu_xstr_lft_shr_nxt;
      cu_xend_lft_shr   <= cu_xend_lft_shr_nxt;
      xstr_tmp_lft      <= xstr_tmp_lft_nxt;
      cu_xstr_rgt_shr   <= cu_xstr_rgt_shr_nxt;
      cu_xend_rgt_shr   <= cu_xend_rgt_shr_nxt;
      cu_xstr_ctr_shr   <= cu_xstr_ctr_shr_nxt;
      cu_xend_ctr_shr   <= cu_xend_ctr_shr_nxt;
      cu_ystr_lft       <= cu_ystr_lft_nxt;
      cu_yend_lft       <= cu_yend_lft_nxt;
      cu_ystr_rgt       <= cu_ystr_rgt_nxt;
      cu_yend_rgt       <= cu_yend_rgt_nxt;
      cu_yend_ctr       <= cu_yend_ctr_nxt;
      cu_ystr_ctr       <= cu_ystr_ctr_nxt;
   end
end


endmodule
