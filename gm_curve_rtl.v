// +FHDR -----------------------------------------------------------------------
// Copyright (c) Silicon Optronics. Inc. 2012
//
// File Name:           gm_curve_rtl.v
// Author:              Humphrey Lin
//
// File Description:    Gamma correction/User defined curve implementation
// Abbreviations:       gm: gamma
//
// Parameters:          LINEAR_CURVE = 1: Index==0x0, linear curve function
//                                        Index==0xf, near max-bended curve function
//                                   = 0: Index==0x0, max-bended curve function
//                                        Index==0xf, near linear curve function
//
// -FHDR -----------------------------------------------------------------------

module  gm_curve

#(
parameter                       DATI_SZ         = 10,
parameter                       DATO_SZ         =  8,       // precision: 8.2

parameter                       LINEAR_CURVE    = 0
 )

(
//----------------------------------------------------------//
// Output declaration                                       //
//----------------------------------------------------------//

output      [DATO_SZ+1:0]       px_o,                       // Gamma corrected pixel

//----------------------------------------------------------//
// Input declaration                                        //
//----------------------------------------------------------//

input       [DATI_SZ-1:0]       px_i,                       // pixel input
input                           gm_en,                      // GM enable switch
input       [DATO_SZ-1:0]       gm_seg_ypt1,                // GM curve output seg1 start point
input       [DATO_SZ-1:0]       gm_seg_ypt2,                // GM curve output seg2 start point
input       [DATO_SZ-1:0]       gm_seg_ypt3,                // GM curve output seg3 start point
input       [DATO_SZ-1:0]       gm_seg_ypt4,                // GM curve output seg4 start point
input       [DATO_SZ-1:0]       gm_seg_ypt5,                // GM curve output seg5 start point
input       [DATO_SZ-1:0]       gm_seg_ypt6,                // GM curve output seg6 start point
input       [DATO_SZ-1:0]       gm_seg_ypt7,                // GM curve output seg7 start point
input       [DATO_SZ-1:0]       gm_seg_ypt8,                // GM curve output seg8 start point
input       [DATO_SZ-1:0]       gm_seg_ypt9,                // GM curve output seg9 start point
input       [DATO_SZ-1:0]       gm_seg_ypt10,               // GM curve output seg10 start point
input       [DATO_SZ-1:0]       gm_seg_ypt11,               // GM curve output seg11 start point
input       [DATO_SZ-1:0]       gm_seg_ypt12,               // GM curve output seg12 start point
input       [DATO_SZ-1:0]       gm_seg_ypt13,               // GM curve output seg13 start point
input       [DATO_SZ-1:0]       gm_seg_ypt14,               // GM curve output seg14 start point
input       [DATO_SZ-1:0]       gm_seg_ypt15,               // GM curve output seg15 start point
input       [DATO_SZ-1:0]       gm_seg_ypt16,               // GM curve output seg16 start point
input       [3:0]               crv_knee_idx,               // GM curve knee segment index
input       [3:0]               crv_bot_idx,                // GM curve bottom index
input       [3:0]               crv_top_idx,                // GM curve top index

input                           pclk,                       // pixel clock
input                           prst_n                      // active low reset for pclk domain
);

//----------------------------------------------------------//
// Local Parameter                                          //
//----------------------------------------------------------//

localparam              GM_XPT01        =   8,
                        GM_XPT02        =   8+GM_XPT01,
                        GM_XPT03        =  16+GM_XPT02,
                        GM_XPT04        =  32+GM_XPT03,
                        GM_XPT05        =  32+GM_XPT04,
                        GM_XPT06        =  32+GM_XPT05,
                        GM_XPT07        =  32+GM_XPT06,
                        GM_XPT08        =  32+GM_XPT07,
                        GM_XPT09        =  64+GM_XPT08,
                        GM_XPT10        =  64+GM_XPT09,
                        GM_XPT11        =  64+GM_XPT10,
                        GM_XPT12        =  64+GM_XPT11,
                        GM_XPT13        =  64+GM_XPT12,
                        GM_XPT14        = 128+GM_XPT13,
                        GM_XPT15        = 128+GM_XPT14,
                        GM_XPT16        = 1'b1 << DATI_SZ;

localparam              SEG00           = 16'b0000_0000_0000_0001,
                        SEG01           = 16'b0000_0000_0000_0010,
                        SEG02           = 16'b0000_0000_0000_0100,
                        SEG03           = 16'b0000_0000_0000_1000,
                        SEG04           = 16'b0000_0000_0001_0000,
                        SEG05           = 16'b0000_0000_0010_0000,
                        SEG06           = 16'b0000_0000_0100_0000,
                        SEG07           = 16'b0000_0000_1000_0000,
                        SEG08           = 16'b0000_0001_0000_0000,
                        SEG09           = 16'b0000_0010_0000_0000,
                        SEG10           = 16'b0000_0100_0000_0000,
                        SEG11           = 16'b0000_1000_0000_0000,
                        SEG12           = 16'b0001_0000_0000_0000,
                        SEG13           = 16'b0010_0000_0000_0000,
                        SEG14           = 16'b0100_0000_0000_0000,
                        SEG15           = 16'b1000_0000_0000_0000;


//----------------------------------------------------------//
// REG/Wire declaration                                     //
//----------------------------------------------------------//

reg [DATO_SZ+1:0]       px_o;                               // Gamma corrected pixel
reg [DATI_SZ-1:0]       px_i_q1;                            // px_i CK 1T
reg [DATI_SZ-1:0]       px_i_q2;                            // px_i CK 1T
reg [ 2:0]              sft_idx_q1;                         // sft_idx CK 1T
reg [ 7:0]              pxi_dx_q1;                          // pxi_dx CK 1T
reg [ 7:0]              seg_dy_q1;                          // seg_dy CK 1T
reg [DATO_SZ-1:0]       ypt_str_q1;                         // y start point of segment n
reg [ 3:0]              crv_idx_q1;                         //
reg [ 3:0]              crv_idx_q2;                         //

// Combinational logic
reg [DATI_SZ-1:0]       xpt_str;                            // x start point of segment n
reg [DATO_SZ-1:0]       ypt_str;                            // y start point of segment n
reg [DATO_SZ-1:0]       ypt_end;                            // y end point of segment n
reg [ 2:0]              sft_idx;                            // shift index
reg [ 3:0]              seg_idx;                            // segment index
reg [ 5:0]              round_bit;                          // rounding bit
reg [DATO_SZ+1:0]       pxo_dy;                             // delta of pixel output to Y-segment start pt

reg [DATO_SZ+2:0]       crv_result_q1;                       // Curve result


wire[15:0]              seg_sel;                            // segment select
wire[ 3:0]              crv_idx;                            // curve index
wire[ 7:0]              pxi_dx;                             // delta of pixel input to X-segment start pt
wire[ 7:0]              seg_dy;                             // width of Y-segment n
wire[15:0]              crv_prod;                           // Curve product
wire[DATO_SZ+2  :0]     crv_result;                         // Curve result
wire[DATO_SZ+5+1:0]     px_itp;                             // pixel interpolation
wire[DATO_SZ+1:0]       px_o_nxt;                           //

//----------------------------------------------------------//
// Code Descriptions                                        //
//----------------------------------------------------------//

// In/Out segment select

assign  seg_sel = {px_i >= GM_XPT15,
                   px_i >= GM_XPT14 && px_i < GM_XPT15,
                   px_i >= GM_XPT13 && px_i < GM_XPT14,
                   px_i >= GM_XPT12 && px_i < GM_XPT13,
                   px_i >= GM_XPT11 && px_i < GM_XPT12,
                   px_i >= GM_XPT10 && px_i < GM_XPT11,
                   px_i >= GM_XPT09 && px_i < GM_XPT10,
                   px_i >= GM_XPT08 && px_i < GM_XPT09,
                   px_i >= GM_XPT07 && px_i < GM_XPT08,
                   px_i >= GM_XPT06 && px_i < GM_XPT07,
                   px_i >= GM_XPT05 && px_i < GM_XPT06,
                   px_i >= GM_XPT04 && px_i < GM_XPT05,
                   px_i >= GM_XPT03 && px_i < GM_XPT04,
                   px_i >= GM_XPT02 && px_i < GM_XPT03,
                   px_i >= GM_XPT01 && px_i < GM_XPT02,
                                       px_i < GM_XPT01};
always @* begin

             ypt_str = 0;
             ypt_end = 0;
             xpt_str = 0;
             sft_idx = 0;
             seg_idx = 0;

   case(seg_sel) // synopsys full_case
   SEG00: begin
             ypt_str = 0;
             ypt_end = gm_seg_ypt1;
             xpt_str = 0;
             sft_idx = 1;               // delat-X = 8
             seg_idx = 0;
          end
   SEG01: begin
             ypt_str = gm_seg_ypt1;
             ypt_end = gm_seg_ypt2;
             xpt_str = GM_XPT01;
             sft_idx = 1;               // delat-X = 8
             seg_idx = 1;
          end
   SEG02: begin
             ypt_str = gm_seg_ypt2;
             ypt_end = gm_seg_ypt3;
             xpt_str = GM_XPT02;
             sft_idx = 2;               // delat-X = 16
             seg_idx = 2;
          end
   SEG03: begin
             ypt_str = gm_seg_ypt3;
             ypt_end = gm_seg_ypt4;
             xpt_str = GM_XPT03;
             sft_idx = 3;               // delat-X = 32
             seg_idx = 3;
          end
   SEG04: begin
             ypt_str = gm_seg_ypt4;
             ypt_end = gm_seg_ypt5;
             xpt_str = GM_XPT04;
             sft_idx = 3;               // delat-X = 32
             seg_idx = 4;
          end
   SEG05: begin
             ypt_str = gm_seg_ypt5;
             ypt_end = gm_seg_ypt6;
             xpt_str = GM_XPT05;
             sft_idx = 3;               // delat-X = 32
             seg_idx = 5;
          end
   SEG06: begin
             ypt_str = gm_seg_ypt6;
             ypt_end = gm_seg_ypt7;
             xpt_str = GM_XPT06;
             sft_idx = 3;               // delat-X = 32
             seg_idx = 6;
          end
   SEG07: begin
             ypt_str = gm_seg_ypt7;
             ypt_end = gm_seg_ypt8;
             xpt_str = GM_XPT07;
             sft_idx = 3;               // delat-X = 32
             seg_idx = 7;
          end
   SEG08: begin
             ypt_str = gm_seg_ypt8;
             ypt_end = gm_seg_ypt9;
             xpt_str = GM_XPT08;
             sft_idx = 4;               // delat-X = 64
             seg_idx = 8;
          end
   SEG09: begin
             ypt_str = gm_seg_ypt9;
             ypt_end = gm_seg_ypt10;
             xpt_str = GM_XPT09;
             sft_idx = 4;               // delat-X = 64
             seg_idx = 9;
          end
   SEG10: begin
             ypt_str = gm_seg_ypt10;
             ypt_end = gm_seg_ypt11;
             xpt_str = GM_XPT10;
             sft_idx = 4;               // delat-X = 64
             seg_idx = 10;
          end
   SEG11: begin
             ypt_str = gm_seg_ypt11;
             ypt_end = gm_seg_ypt12;
             xpt_str = GM_XPT11;
             sft_idx = 4;               // delat-X = 64
             seg_idx = 11;
          end
   SEG12: begin
             ypt_str = gm_seg_ypt12;
             ypt_end = gm_seg_ypt13;
             xpt_str = GM_XPT12;
             sft_idx = 4;               // delat-X = 64
             seg_idx = 12;
          end
   SEG13: begin
             ypt_str = gm_seg_ypt13;
             ypt_end = gm_seg_ypt14;
             xpt_str = GM_XPT13;
             sft_idx = 5;               // delat-X = 128
             seg_idx = 13;
          end
   SEG14: begin
             ypt_str = gm_seg_ypt14;
             ypt_end = gm_seg_ypt15;
             xpt_str = GM_XPT14;
             sft_idx = 5;               // delat-X = 128
             seg_idx = 14;
          end
   SEG15: begin
             ypt_str = gm_seg_ypt15;
             ypt_end = gm_seg_ypt16;
             xpt_str = GM_XPT15;
             sft_idx = 6;               // delat-X = 256
             seg_idx = 15;
          end
   endcase
end

// X, Y delta value

assign  crv_idx = (seg_idx  < crv_knee_idx) | (&crv_knee_idx) ? crv_bot_idx : crv_top_idx;
assign  pxi_dx  = px_i    - xpt_str;
assign  seg_dy  = ypt_end - ypt_str;

// Gamma curve operation
// 8. * 8.
assign  crv_prod   = pxi_dx_q1 * seg_dy_q1 + round_bit;

// 9.2 = 8.2. + 8.2
assign  crv_result = {ypt_str_q1,2'h0} + pxo_dy;

// 9.6 = 8.2 * 1.4 + 8.2 * .4
generate
   if (LINEAR_CURVE) begin: gen_px_itp_0
      assign  px_itp =                                          px_i_q2      [0 +: DATO_SZ+2]  * (5'b10000-crv_idx_q2) +
                       ({DATO_SZ+2{crv_result_q1[DATO_SZ+2]}} | crv_result_q1[0 +: DATO_SZ+2]) * crv_idx_q2 + 4'b1000;
   end
   else begin: gen_px_itp_1
      assign  px_itp = ({DATO_SZ+2{crv_result_q1[DATO_SZ+2]}} | crv_result_q1[0 +: DATO_SZ+2]) * (5'b10000-crv_idx_q2) +
                                                                px_i_q2      [0 +: DATO_SZ+2]  * crv_idx_q2 + 4'b1000;
   end
endgenerate

assign  px_o_nxt = gm_en ? px_itp[4 +: DATO_SZ+2] | {DATO_SZ+2{px_itp[DATO_SZ+2+4]}} : px_i_q2[0 +: DATO_SZ+2];


always @* begin

   round_bit = 0;

   case (sft_idx_q1) // synopsys full_case
   0: round_bit = 1'b0;
   1: round_bit = 1'b1;         // delat-X = 8
   2: round_bit = 2'b10;        // delat-X = 16
   3: round_bit = 3'b100;       // delat-X = 32
   4: round_bit = 4'b1000;      // delat-X = 64
   5: round_bit = 5'b10000;     // delat-X = 128
   6: round_bit = 6'b100000;    // delat-X = 256
   endcase
end

always @* begin

   pxo_dy = 0;

   case (sft_idx_q1) // synopsys full_case
   0: pxo_dy = crv_prod[0 +: DATO_SZ+2] | {DATO_SZ+2{crv_prod[DATO_SZ+2]}};
   1: pxo_dy = crv_prod[1 +: DATO_SZ+2] | {DATO_SZ+2{crv_prod[DATO_SZ+3]}};
   2: pxo_dy = crv_prod[2 +: DATO_SZ+2] | {DATO_SZ+2{crv_prod[DATO_SZ+4]}};
   3: pxo_dy = crv_prod[3 +: DATO_SZ+2] | {DATO_SZ+2{crv_prod[DATO_SZ+5]}};
   4: pxo_dy = crv_prod[4 +: DATO_SZ+2] | {DATO_SZ+2{crv_prod[DATO_SZ+6]}};
   5: pxo_dy = crv_prod[5 +: DATO_SZ+2] | {DATO_SZ+2{crv_prod[DATO_SZ+7]}};
   6: pxo_dy = crv_prod[6 +: DATO_SZ+2];
   endcase

end

// Sequential Logic
// -----------------------------------------------

always @(posedge pclk or negedge prst_n) begin
   if (~prst_n) begin
      sft_idx_q1    <= 0;
      pxi_dx_q1     <= 0;
      seg_dy_q1     <= 0;
      ypt_str_q1    <= 0;
      crv_result_q1 <= 0;
      px_i_q1       <= 0;
      px_i_q2       <= 0;
      crv_idx_q1    <= 0;
      crv_idx_q2    <= 0;
      px_o          <= 0;
   end
   else begin
      sft_idx_q1    <= sft_idx;
      pxi_dx_q1     <= pxi_dx;
      seg_dy_q1     <= seg_dy;
      ypt_str_q1    <= ypt_str;
      crv_result_q1 <= crv_result;
      px_i_q1       <= px_i;
      px_i_q2       <= px_i_q1;
      crv_idx_q1    <= crv_idx;
      crv_idx_q2    <= crv_idx_q1;
      px_o          <= px_o_nxt;
   end
end

endmodule
