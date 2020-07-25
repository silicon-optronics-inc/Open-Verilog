// +FHDR -----------------------------------------------------------------------
// Copyright (c) Silicon Optronics. Inc. 2015
//
// File Name:           pgl_dp_rtl.v
// Author:              Humphrey Lin
// Version:             $Revision$
// Last Modified On:    $Date$
// Last Modified By:    $Author$
//
// File Description:    Parking Guideline data-path module
//
// Clock Domain:
// -FHDR -----------------------------------------------------------------------

module  pgl_dp

    #(
      parameter             XWID        = 10
     )
(
//----------------------------------------------//
// Output declaration                           //
//----------------------------------------------//

output reg  [ 7:0]          pgl_data_y_o,       // Y data after PGL blending
output      [ 7:0]          pgl_data_c_o,       // C data after PGL blending
output      [ 7:0]          pgl_palt_yr,        // Y color palette table: red
output      [ 7:0]          pgl_palt_yg,        // Y color palette table: green
output      [ 7:0]          pgl_palt_yy,        // Y color palette table: yellow
output      [ 7:0]          pgl_palt_yb,        // Y color palette table: blue
output      [ 7:0]          pgl_palt_bw0,       // Y color palette table: white
output      [ 8:0]          pgl_palt_ur,        // U color palette table: red
output      [ 8:0]          pgl_palt_ug,        // U color palette table: green
output      [ 8:0]          pgl_palt_uy,        // U color palette table: yellow
output      [ 8:0]          pgl_palt_ub,        // U color palette table: blue
output      [ 8:0]          pgl_palt_vr,        // V color palette table: red
output      [ 8:0]          pgl_palt_vg,        // V color palette table: green
output      [ 8:0]          pgl_palt_vy,        // V color palette table: yellow
output      [ 8:0]          pgl_palt_vb,        // V color palette table: blue

//----------------------------------------------//
// Input declaration                            //
//----------------------------------------------//

input       [ 7:0]          pgl_data_y_i,       // Data Y
input       [ 7:0]          pgl_data_c_i,       // Data Cb/Cr
input       [XWID-1:0]      pgl_hcnt,           // PGL h-counter
input                       pgl_vld_lft,        // PGL valid @ left
input                       pgl_vld_rgt,        // PGL valid @ right
input                       pgl_vld_ctr,        // PGL valid @ center
input                       pgl_edge,           // PGL line edge
input       [ 1:0]          pgl_type_lft,       // PGL segment type @ left
input       [ 1:0]          pgl_type_rgt,       // PGL segment type @ right
input       [ 1:0]          pgl_colr_lft,       // PGL segment color index @ left
input       [ 1:0]          pgl_colr_rgt,       // PGL segment color index @ right

input       [ 7:0]          cu_pgl_palt_yr,     // Y color palette: red
input       [ 7:0]          cu_pgl_palt_yg,     // Y color palette: green
input       [ 7:0]          cu_pgl_palt_yy,     // Y color palette: yellow
input       [ 7:0]          cu_pgl_palt_yb,     // Y color palette: blue
input       [ 7:0]          cu_pgl_palt_bw0,    // Y color palette: white
input       [ 7:0]          cu_pgl_palt_ur,     // U color palette: red
input       [ 7:0]          cu_pgl_palt_ug,     // U color palette: green
input       [ 7:0]          cu_pgl_palt_uy,     // U color palette: yellow
input       [ 7:0]          cu_pgl_palt_ub,     // U color palette: blue
input       [ 7:0]          cu_pgl_palt_vr,     // V color palette: red
input       [ 7:0]          cu_pgl_palt_vg,     // V color palette: green
input       [ 7:0]          cu_pgl_palt_vy,     // V color palette: yellow
input       [ 7:0]          cu_pgl_palt_vb,     // V color palette: blue
input       [ 8:0]          cu_pgl_aa_trsp,     // PGL anti-alias line edge color transpancy
input       [ 8:0]          cu_pgl_aa_cmpl,     // complement of cu_pgl_aa_trsp
input       [ 8:0]          cu_pgl_trsp_cmpl,   // complement of reg_pgl_trsp

input                       reg_pgl_mono_lr,    // PGL mono style color palette @ Left/right
input                       reg_pgl_mono_ctr,   // PGL mono style color palette @ center
input       [ 1:0]          reg_pgl_colr_ctr,   // PGL line color @ center
input       [ 7:0]          reg_pgl_trsp,       // PGL transparency factor

input                       pclk,               // pixel clock
input                       prst_n              // low active reset for pclk domain
);

//----------------------------------------------//
// Local Parameter                              //
//----------------------------------------------//

localparam                  PALT_R      = 3'b000,   // Red
                            PALT_G      = 3'b001,   // Green
                            PALT_Y      = 3'b010,   // Yellow
                            PALT_B      = 3'b011,   // Blue
                            PALT_BW0    = 3'b100,   // White
                            PALT_BW1    = 3'b101,   // Gray 0
                            PALT_BW2    = 3'b110,   // Gray 1
                            PALT_BW3    = 3'b111;   // Black

//----------------------------------------------//
// Register declaration                         //
//----------------------------------------------//
reg         [ 7:0]          data_u_val;         // data U value after blending
reg         [ 7:0]          data_v_val;         // data V value after blending
reg         [ 8:0]          y_trsp;             // PGL-Y transpancy
reg         [ 8:0]          y_trsp_cmpl;        // PGL-Y transpancy complement (1.0 - pgl_trsp)
reg         [ 8:0]          c_trsp;             // PGL-C transpancy
reg         [ 8:0]          c_trsp_cmpl;        // PGL-C transpancy complement (1.0 - pgl_trsp)
reg         [ 7:0]          palt_y;             // current PGL palette Y value
reg         [ 7:0]          palt_u;             // current PGL palette U value
reg         [ 7:0]          palt_v;             // current PGL palette V value
reg         [ 7:0]          pgl_data_y_q1;      // 1T delay of pgl_data_y_i
reg         [ 7:0]          pgl_data_c_q1;      // 1T delay of pgl_data_c_i

//
reg         [ 7:0]          palt_y_nxt;         //
reg         [ 7:0]          palt_u_nxt;         //
reg         [ 7:0]          palt_v_nxt;         //
wire        [ 7:0]          pgl_data_y_o_nxt;   //
wire        [ 8:0]          y_trsp_nxt;         //
wire        [ 8:0]          y_trsp_cmpl_nxt;    //
wire        [ 8:0]          c_trsp_nxt;         //
wire        [ 8:0]          c_trsp_cmpl_nxt;    //

//----------------------------------------------//
// Wire declaration                             //
//----------------------------------------------//
wire        [16:0]          pgl_data_y_mix;     // PGL blending Y
wire        [16:0]          pgl_data_u_mix;     // PGL blending U
wire        [16:0]          pgl_data_v_mix;     // PGL blending U
wire                        pgl_vld;            // PGL valid interval
wire                        palt_mono;          // current PGL mono attribute
wire        [ 1:0]          palt_indx;          // current PGL color palette index
wire        [ 7:0]          pgl_palt_bw1;       // Y color palette table: black-white 1
wire        [ 7:0]          pgl_palt_bw2;       // Y color palette table: black-white 2
wire        [ 7:0]          pgl_palt_bw3;       // Y color palette table: black-white 3

wire        [ 7:0]          data_u_val_nxt;
wire        [ 7:0]          data_v_val_nxt;

//----------------------------------------------//
// Code Descriptions                            //
//----------------------------------------------//

// PGL overlapping
// 9.8 = 8. * 1.8 + 8. * 1.8
assign  pgl_data_y_mix   = pgl_data_y_q1 * y_trsp + palt_y * y_trsp_cmpl;
assign  pgl_data_y_o_nxt = {8{pgl_data_y_mix[16]}} | pgl_data_y_mix[8 +: 8];

assign  pgl_data_u_mix   = pgl_data_c_q1 * c_trsp + palt_u * c_trsp_cmpl;
assign  data_u_val_nxt   = {8{pgl_data_u_mix[16]}} | pgl_data_u_mix[8 +: 8];

assign  pgl_data_v_mix   = pgl_data_c_i  * c_trsp + palt_v * c_trsp_cmpl;
assign  data_v_val_nxt   = pgl_hcnt[0] ? {8{pgl_data_v_mix[16]}} | pgl_data_v_mix[8 +: 8] : data_v_val;

assign  pgl_data_c_o     = ~pgl_hcnt[0] ? data_u_val : data_v_val;

// PGL valid range
assign  pgl_vld = pgl_vld_lft | pgl_vld_rgt | pgl_vld_ctr;

// PGL transpancy
assign  y_trsp_nxt = pgl_vld ?                (pgl_edge ? cu_pgl_aa_trsp : {1'b0, reg_pgl_trsp})  : 9'h100;
assign  c_trsp_nxt = pgl_vld & ~pgl_hcnt[0] ? (pgl_edge ? cu_pgl_aa_trsp : {1'b0, reg_pgl_trsp})  : 9'h100;

assign  y_trsp_cmpl_nxt = pgl_vld                ? (pgl_edge ? cu_pgl_aa_cmpl : cu_pgl_trsp_cmpl) : 9'h0;
assign  c_trsp_cmpl_nxt = pgl_vld & ~pgl_hcnt[0] ? (pgl_edge ? cu_pgl_aa_cmpl : cu_pgl_trsp_cmpl) : 9'h0;

// PGL Color
assign  palt_mono = ((pgl_vld_lft | pgl_vld_rgt) & reg_pgl_mono_lr) |
                     (pgl_vld_ctr & reg_pgl_mono_ctr);
assign  palt_indx = ({2{pgl_vld_lft}} & pgl_colr_lft) |
                    ({2{pgl_vld_rgt}} & pgl_colr_rgt) |
                    ({2{pgl_vld_ctr}} & reg_pgl_colr_ctr);

always @* begin: plat_mux

   palt_y_nxt = 0;
   palt_u_nxt = 0;
   palt_v_nxt = 0;

   case ({palt_mono, palt_indx})
   PALT_R: begin
           palt_y_nxt = cu_pgl_palt_yr;
           palt_u_nxt = cu_pgl_palt_ur;
           palt_v_nxt = cu_pgl_palt_vr;
           end
   PALT_G: begin
           palt_y_nxt = cu_pgl_palt_yg;
           palt_u_nxt = cu_pgl_palt_ug;
           palt_v_nxt = cu_pgl_palt_vg;
           end
   PALT_Y: begin
           palt_y_nxt = cu_pgl_palt_yy;
           palt_u_nxt = cu_pgl_palt_uy;
           palt_v_nxt = cu_pgl_palt_vy;
           end
   PALT_B: begin
           palt_y_nxt = cu_pgl_palt_yb;
           palt_u_nxt = cu_pgl_palt_ub;
           palt_v_nxt = cu_pgl_palt_vb;
           end
   PALT_BW0: begin
           palt_y_nxt = cu_pgl_palt_bw0;
           palt_u_nxt = 128;
           palt_v_nxt = 128;
           end
   PALT_BW1: begin
           palt_y_nxt = pgl_palt_bw1;
           palt_u_nxt = 128;
           palt_v_nxt = 128;
           end
   PALT_BW2: begin
           palt_y_nxt = pgl_palt_bw2;
           palt_u_nxt = 128;
           palt_v_nxt = 128;
           end
   PALT_BW3: begin
           palt_y_nxt = pgl_palt_bw3;
           palt_u_nxt = 128;
           palt_v_nxt = 128;
           end
   endcase
end

// Color Palette Table
// -----------------------------------------------
assign  pgl_palt_yr  = 8'h5b;
assign  pgl_palt_ur  = 9'h134;
assign  pgl_palt_vr  = 9'h6d;
assign  pgl_palt_yg  = 8'h95;
assign  pgl_palt_ug  = 9'h157;
assign  pgl_palt_vg  = 9'h16e;
assign  pgl_palt_yy  = 8'hd5;
assign  pgl_palt_uy  = 9'h17b;
assign  pgl_palt_vy  = 9'h14;
assign  pgl_palt_yb  = 8'h53;
assign  pgl_palt_ub  = 9'h5a;
assign  pgl_palt_vb  = 9'h13d;

assign  pgl_palt_bw0 = 8'hff;
assign  pgl_palt_bw1 = 8'ha0;
assign  pgl_palt_bw2 = 8'h50;
assign  pgl_palt_bw3 = 8'h00;

// ---------- Sequential Logic -----------------//

always @(posedge pclk or negedge prst_n) begin
   if (~prst_n) begin
      pgl_data_y_o      <= 0;
      data_u_val        <= 0;
      data_v_val        <= 0;
      y_trsp            <= 0;
      y_trsp_cmpl       <= 0;
      c_trsp            <= 0;
      c_trsp_cmpl       <= 0;
      palt_y            <= 0;
      palt_u            <= 0;
      palt_v            <= 0;
      pgl_data_y_q1     <= 0;
      pgl_data_c_q1     <= 0;
   end
   else begin
      pgl_data_y_o      <= pgl_data_y_o_nxt;
      data_u_val        <= data_u_val_nxt;
      data_v_val        <= data_v_val_nxt;
      y_trsp            <= y_trsp_nxt;
      y_trsp_cmpl       <= y_trsp_cmpl_nxt;
      c_trsp            <= c_trsp_nxt;
      c_trsp_cmpl       <= c_trsp_cmpl_nxt;
      palt_y            <= palt_y_nxt;
      palt_u            <= palt_u_nxt;
      palt_v            <= palt_v_nxt;
      pgl_data_y_q1     <= pgl_data_y_i;
      pgl_data_c_q1     <= pgl_data_c_i;
   end
end


endmodule
