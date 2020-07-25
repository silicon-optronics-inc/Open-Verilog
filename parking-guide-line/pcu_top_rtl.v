// +FHDR -----------------------------------------------------------------------
// Copyright (c) Silicon Optronics. Inc. 2015
//
// File Name:           pcu_top_rtl.v
// Author:              Humphrey Lin
// Version:             $Revision$
// Last Modified On:    $Date$
// Last Modified By:    $Author$
//
// File Description:    Parking Guideline CU top module
//
// Clock Domain:
// -FHDR -----------------------------------------------------------------------

module  pcu_top

    #(
      parameter             CUTSK_NUM   = 10
     )
(
//----------------------------------------------//
// Output declaration                           //
//----------------------------------------------//
output      [ 7:0]          cu_pgl_palt_yr,     // Y color palette: red
output      [ 7:0]          cu_pgl_palt_yg,     // Y color palette: green
output      [ 7:0]          cu_pgl_palt_yy,     // Y color palette: yellow
output      [ 7:0]          cu_pgl_palt_yb,     // Y color palette: blue
output      [ 7:0]          cu_pgl_palt_bw0,    // Y color palette: white
output      [ 7:0]          cu_pgl_palt_ur,     // U color palette: red
output      [ 7:0]          cu_pgl_palt_ug,     // U color palette: green
output      [ 7:0]          cu_pgl_palt_uy,     // U color palette: yellow
output      [ 7:0]          cu_pgl_palt_ub,     // U color palette: blue
output      [ 7:0]          cu_pgl_palt_vr,     // V color palette: red
output      [ 7:0]          cu_pgl_palt_vg,     // V color palette: green
output      [ 7:0]          cu_pgl_palt_vy,     // V color palette: yellow
output      [ 7:0]          cu_pgl_palt_vb,     // V color palette: blue
output      [ 8:0]          cu_pgl_aa_trsp,     // PGL anti-alias line edge color transpancy
output      [ 8:0]          cu_pgl_aa_cmpl,     // complement of cu_pgl_aa_trsp
output      [ 8:0]          cu_pgl_trsp_cmpl,   // complement of reg_pgl_trsp

output      [ 8:0]          cu_pgl_hln0_wid,    // PGL line width of horizontal type 0
output      [ 8:0]          cu_pgl_hln1_wid,    // PGL line width of horizontal type 1
output      [ 9:0]          cu_pgl_hwwg_lft,    // width weighting of horizontal type on left line
output      [ 9:0]          cu_pgl_hwwg_rgt,    // width weighting of horizontal type on right line

output                      cu_y0_lft_eq,       // y_p1 == start point of left line, reg_pgl_ystr0_lft
output                      cu_y0_lft_csgb,     // comparing sign bit: sign(y_p1 - reg_pgl_ystr0_lft)
output                      cu_ystr_lft_csgb,   // comparing sign bit: sign(y_p1 - cu_ystr_lft)
output                      cu_ystr_lft_eq,     // y_p1 == cu_ystr_lft
output                      cu_yend_lft_eq,     // y_p1 == end point of current segment @ left
output                      cu_yend_lft_csgb,   // comparing sign bit: sign(y_p1 - cu_yend_lft)
output                      cu_ybnd_lft_csgb,   // sign(y_p1 - reg_pgl_ybnd_lft)
output                      cu_y0_rgt_eq,       // y_p1 == start point of left line, reg_pgl_ystr0_rgt
output                      cu_y0_rgt_csgb,     // comparing sign bit: sign(y_p1 - reg_pgl_ystr0_rgt)
output                      cu_ystr_rgt_csgb,   // comparing sign bit: sign(y_p1 - cu_ystr_rgt)
output                      cu_ystr_rgt_eq,     // y_p1 == cu_ystr_rgt
output                      cu_yend_rgt_eq,     // y_p1 == end point of current segment @ left
output                      cu_yend_rgt_csgb,   // comparing sign bit: sign(y_p1 - cu_yend_rgt)
output                      cu_ybnd_rgt_csgb,   // sign(y_p1 - reg_pgl_ybnd_rgt)
output                      cu_y0_ctr_csgb,     // comparing sign bit: sign(y_p1 - reg_pgl_ystr_ctr)
output                      cu_ystr_ctr_eq,     // y_p1 == start point of current segment @ center
output                      cu_ystr_ctr_csgb,   // comparing sign bit: sign(y_p1 - cu_ystr_ctr)
output                      cu_yend_ctr_eq,     // y_p1 == end point of current segment @ center
output                      cu_yend_ctr_csgb,   // comparing sign bit: sign(y_p1 - cu_yend_ctr)
output                      cu_vend_ctr_csgb,   // sign(y_p1 - reg_pgl_vend_ctr )

output      [ 9:0]          cu_xstr_lft,        // x-start point @ left
output      [ 9:0]          cu_xstr_a1_lft,     // x-start point+1 @ left
output      [ 9:0]          cu_xend_lft,        // x-end point @ left
output      [ 9:0]          cu_xend_a1_lft,     // x-end point @+1 left
output      [ 9:0]          cu_xstr_rgt,        // x-start point @ right
output      [ 9:0]          cu_xstr_a1_rgt,     // x-start point+1 @ right
output      [ 9:0]          cu_xend_rgt,        // x-end point @ right
output      [ 9:0]          cu_xend_a1_rgt,     // x-end point+1 @ right
output      [ 8:0]          cu_xstr_ctr,        // x-start point @ center
output      [ 8:0]          cu_xstr_a1_ctr,     // x-start point+1 @ center
output      [ 8:0]          cu_xend_ctr,        // x-end point @ center
output      [ 8:0]          cu_xend_a1_ctr,     // x-end point+1 @ center

output      [CUTSK_NUM-1:0] cu_tsk_end,         // end of task operation

//----------------------------------------------//
// Input declaration                            //
//----------------------------------------------//
input                       fm_str,             // frame start
input       [CUTSK_NUM-1:0] cu_tsk_trg,         // Task trigger

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
localparam                  ALU_SZ          = 20,
                            EXD_SZ          = 1;

localparam                  TSK0_START_PC   = 0,
                            TSK0_END_PC     = TSK0_START_PC+7'h25,
                            TSK1_START_PC   = TSK0_END_PC  +7'h1,
                            TSK1_END_PC     = TSK1_START_PC+7'hf,
                            TSK2_START_PC   = TSK1_END_PC  +7'h1,
                            TSK2_END_PC     = TSK2_START_PC+7'h10,
                            TSK3_START_PC   = TSK2_END_PC  +7'h1,
                            TSK3_END_PC     = TSK3_START_PC+7'h10,
                            TSK4_START_PC   = TSK3_END_PC  +7'h1,
                            TSK4_END_PC     = TSK4_START_PC+7'h6,
                            TSK5_START_PC   = TSK4_END_PC  +7'h1,
                            TSK5_END_PC     = TSK5_START_PC+7'h2,
                            TSK6_START_PC   = TSK5_END_PC  +7'h1,
                            TSK6_END_PC     = TSK6_START_PC+7'h2,
                            TSK7_START_PC   = TSK6_END_PC  +7'h1,
                            TSK7_END_PC     = TSK7_START_PC+7'h2,
                            TSK8_START_PC   = TSK7_END_PC  +7'h1,
                            TSK8_END_PC     = TSK8_START_PC+7'h2;

localparam                  PC_SZ           = 7,            // Program counter width
                            PC_NUM          = TSK8_END_PC,  // Total number of PC
                            CYC_SZ          = 5;            // max cycle counter width of one math operator

localparam                  NUM0_SZ         = ALU_SZ + EXD_SZ,
                            NUM1_SZ         = ALU_SZ;

//----------------------------------------------//
// Wire declaration                             //
//----------------------------------------------//
wire        [ 1:0]          opcode;             // 0: +, 1: -, 2: *, 3: /
wire        [NUM0_SZ-1:0]   num_0;              // input number 0
wire        [NUM1_SZ-1:0]   num_1;              // input number 1
wire        [ALU_SZ-1:0]    prod_msb;           // operation product MSB
wire        [ALU_SZ+EXD_SZ-1:0] prod_lsb;       // operation product LSB
wire        [PC_NUM  :0]    cu_cmd_en;
wire        [PC_SZ -1:0]    cu_pc;

//----------------------------------------------//
// Code Descriptions                            //
//----------------------------------------------//

pcu_code

#(
    .NUM0_SZ                (NUM0_SZ),
    .NUM1_SZ                (NUM1_SZ),
    .ALU_SZ                 (ALU_SZ),
    .PC_NUM                 (PC_NUM),
    .T0_PC                  (TSK0_START_PC),
    .T1_PC                  (TSK1_START_PC),
    .T2_PC                  (TSK2_START_PC),
    .T3_PC                  (TSK3_START_PC),
    .T4_PC                  (TSK4_START_PC),
    .T5_PC                  (TSK5_START_PC),
    .T6_PC                  (TSK6_START_PC),
    .T7_PC                  (TSK7_START_PC),
    .T8_PC                  (TSK8_START_PC))

pcu_code (
    // output
    .opcode                 (opcode),
    .num_0                  (num_0),
    .num_1                  (num_1),

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

    // input
    .prod_msb               (prod_msb),
    .prod_lsb               (prod_lsb),
    .cu_cmd_en              (cu_cmd_en),
    .op_rdy_sm              (op_rdy_sm),

    .fm_str                 (fm_str),

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


ip_cu_ctrl

#(
    .ALU_SZ                 (ALU_SZ),
    .EXD_SZ                 (EXD_SZ),
    .TSK0_START_PC          (TSK0_START_PC),
    .TSK0_END_PC            (TSK0_END_PC),
    .TSK1_START_PC          (TSK1_START_PC),
    .TSK1_END_PC            (TSK1_END_PC),
    .TSK2_START_PC          (TSK2_START_PC),
    .TSK2_END_PC            (TSK2_END_PC),
    .TSK3_START_PC          (TSK3_START_PC),
    .TSK3_END_PC            (TSK3_END_PC),
    .TSK4_START_PC          (TSK4_START_PC),
    .TSK4_END_PC            (TSK4_END_PC),
    .TSK5_START_PC          (TSK5_START_PC),
    .TSK5_END_PC            (TSK5_END_PC),
    .TSK6_START_PC          (TSK6_START_PC),
    .TSK6_END_PC            (TSK6_END_PC),
    .TSK7_START_PC          (TSK7_START_PC),
    .TSK7_END_PC            (TSK7_END_PC),
    .TSK8_START_PC          (TSK8_START_PC),
    .TSK8_END_PC            (TSK8_END_PC),
    .CUTSK_NUM              (CUTSK_NUM),
    .PC_NUM                 (PC_NUM),
    .PC_SZ                  (PC_SZ),
    .CYC_SZ                 (CYC_SZ))

pcu_ctrl (
    // output
    .cu_tsk_end             (cu_tsk_end),
    .op_act_sm              (op_act_sm),
    .op_ini_sm              (op_ini_sm),
    .op_rdy_sm              (op_rdy_sm),
    .op_halt_sm             (op_halt_sm),
    .add_en                 (add_en),
    .sub_en                 (sub_en),
    .mul_en                 (mul_en),
    .div_en                 (div_en),
    .cu_cmd_en              (cu_cmd_en),
    .cu_pc                  (cu_pc),

    // input
    .cu_tsk_trg             ({{10-CUTSK_NUM{1'b0}},cu_tsk_trg}),
    .opcode                 (opcode),
    .pclk                   (pclk),
    .prst_n                 (prst_n)
    );


ip_cu_dp

    #(
    .ALU_SZ                 (ALU_SZ),
    .EXD_SZ                 (EXD_SZ))

pcu_dp (
    // output
    .prod_msb               (prod_msb),
    .prod_lsb               (prod_lsb),

    // input
    .num_0                  (num_0),
    .num_1                  (num_1),
    .op_ini_sm              (op_ini_sm),
    .op_rdy_sm              (op_rdy_sm),
    .op_act_sm              (op_act_sm),
    .op_halt_sm             (op_halt_sm),
    .add_en                 (add_en),
    .sub_en                 (sub_en),
    .mul_en                 (mul_en),
    .div_en                 (div_en),
    .pclk                   (pclk),
    .prst_n                 (prst_n)
    );

endmodule



