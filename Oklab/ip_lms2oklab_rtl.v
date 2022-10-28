// +FHDR -----------------------------------------------------------------------
// Copyright (c) Silicon Optronics. Inc. 2022
//
// File Name:           ip_lms2oklab.v
// Author:              1.Willy Lin
//                      2.Martin Chen 
//                      3.Humphrey Lin
// Version:             1.0
// Last Modified On:    2022/10/28
//
// File Description:    LMS to OKLAB Converter
// Abbreviations:
// Parameters:          PRECISION:    S 3.11
// Data precision :     input  :        8.4
//                      outupt : L  :   3.10
//                               AB : S 1.11
// Consuming time :     2T  
// -FHDR -----------------------------------------------------------------------

module ip_lms2oklab 
    #(
    parameter CIIW    = 8,                  //Accuracy Input Integer Width         //Accuracy can not be changed
    parameter CIPW    = 4,                  //Accuracy Input Point Width           //Accuracy can not be changed
    parameter COIW_L  = 3,                  //LAB-L Accuracy Output Integer Width  //Accuracy can be reduced , but not improved 
    parameter COPW_L  = 10,                 //LAB-L Accuracy Output Point Width    //Accuracy can be reduced , but not improved 
    parameter COIW_AB = 2,                  //LAB-AB Accuracy Output Integer Width //Accuracy can be reduced , but not improved 
    parameter COPW_AB = 11,                 //LAB-AB Accuracy Output Integer Width //Accuracy can be reduced , but not improved 
    parameter CIW     = CIIW + CIPW,
    parameter COW_L   = COIW_L + COPW_L,
    parameter COW_AB  = COIW_AB + COPW_AB
    )
(
//----------------------------------------------//
// Output declaration                           //
//----------------------------------------------//
output reg         [COW_L-1:0]  o_data_l,
output reg signed  [COW_AB-1:0] o_data_a_sgn,
output reg signed  [COW_AB-1:0] o_data_b_sgn,
output reg                      o_hstr,
output reg                      o_hend,
output reg                      o_href,

//----------------------------------------------//
// Input declaration                            //
//----------------------------------------------//
input              [CIW-1:0]    i_data_l,
input              [CIW-1:0]    i_data_m,
input              [CIW-1:0]    i_data_s,
input                           i_hstr,
input                           i_hend,
input                           i_href,
input                           clk,
input                           rst_n
);

//----------------------------------------------//
// Local parameter                              //
//----------------------------------------------//
localparam [4:0] CW_CUBE      = 14;
localparam [4:0] CW_CUBE_EX   = 14 +3;
localparam [4:0] SHIFT_BIT_L  = (11 + CW_CUBE -COPW_L );
localparam [4:0] SHIFT_BIT_A  = (11 + CW_CUBE -COPW_AB);
localparam [4:0] SHIFT_BIT_B  = (11 + CW_CUBE -COPW_AB);

//----------------------------------------------//
// Wire declaration                             //
//----------------------------------------------//
//-------------------------------------------------------------------------------------------- common
wire          [10 + CW_CUBE_EX-COW_L:0]   x4096_l_rnd;
wire          [10 + CW_CUBE_EX-COW_AB:0]  x4096_a_rnd;
wire          [10 + CW_CUBE_EX-COW_AB:0]  x4096_b_rnd;

//-------------------------------------------------------------------------------------------- color space convert  
wire          [9  + CW_CUBE_EX:0]         l_x431;
wire          [10 + CW_CUBE_EX:0]         a_x1625;
wire          [3  + CW_CUBE_EX:0]         b_x8;
wire          [11 + CW_CUBE_EX:0]         l_x4096;
wire          [COW_L- 1:0]                o_data_l_nxt;

wire          [12 + CW_CUBE_EX:0]         l_x4051;
wire          [13 + CW_CUBE_EX:0]         a_x4974;
wire          [10 + CW_CUBE_EX:0]         b_x923;
wire signed   [15 + CW_CUBE_EX:0]         a_x4096_sgn;
wire signed   [COW_AB:0]                  o_data_a_sgn_nxt;

wire          [5  + CW_CUBE_EX:0]         l_x53;
wire          [10 + CW_CUBE_EX:0]         a_x1603;
wire          [11 + CW_CUBE_EX:0]         b_x1656;
wire signed   [13 + CW_CUBE_EX:0]         b_x4096_sgn;
wire signed   [COW_AB:0]                  o_data_b_sgn_nxt;

//-------------------------------------------------------------------------------------------- lms2 cube root  
wire          [CW_CUBE-1:0]               data_l2root;
wire          [CW_CUBE-1:0]               data_m2root;
wire          [CW_CUBE-1:0]               data_s2root;
wire          [1:0]                       prcis_idx_l;
wire          [1:0]                       prcis_idx_m;
wire          [1:0]                       prcis_idx_s;
wire          [CW_CUBE_EX-1:0]            data_l2root_ex;
wire          [CW_CUBE_EX-1:0]            data_m2root_ex;
wire          [CW_CUBE_EX-1:0]            data_s2root_ex;

//-------------------------------------------------------------------------------------------- others 
reg                                       i_hstr_dly;
reg                                       i_hend_dly;
reg                                       i_href_dly;

//----------------------------------------------//
// Code Descriptions                            //
//----------------------------------------------//
//-------------------------------------------------------------------------------------------- common

assign  x4096_l_rnd      = 1'b1 << SHIFT_BIT_L -1;
assign  x4096_a_rnd      = 1'b1 << SHIFT_BIT_A -1;
assign  x4096_b_rnd      = 1'b1 << SHIFT_BIT_B -1;

//-------------------------------------------------------------------------------------------- color space convert  
// 11 bit precision 
// L = 0.21044921875*L+ 0.79345703125*M + -0.00390625*S
// L = (431/2048)*L+ (1625/2048)*M + (-8/2048)*S

assign  l_x431           = (data_l2root_ex <<9)  - (data_l2root_ex <<6) - (data_l2root_ex <<4) - data_l2root_ex;
assign  a_x1625          = (data_m2root_ex <<10) + (data_m2root_ex <<9) + (data_m2root_ex <<6) + (data_m2root_ex <<4) + (data_m2root_ex <<3) + data_m2root_ex;
assign  b_x8             = (data_s2root_ex <<3);

assign  l_x4096          = l_x431 + a_x1625 - b_x8;
assign  o_data_l_nxt     = (l_x4096) + (x4096_l_rnd) >>> SHIFT_BIT_L;


// a = 1.97802734375*L+ -2.4287109375*M + 0.45068359375*S
// a = (4051/2048)*L+ (-4974/2048)*M + (923/2048)*S

assign  l_x4051          = (data_l2root_ex <<12) - (data_l2root_ex <<5)  - (data_l2root_ex <<4)  + (data_l2root_ex <<1) + data_l2root_ex;
assign  a_x4974          = (data_m2root_ex <<13) - (data_m2root_ex <<12) + (data_m2root_ex <<10) - (data_m2root_ex <<7) - (data_m2root_ex <<4) - (data_m2root_ex <<1);
assign  b_x923           = (data_s2root_ex <<10) - (data_s2root_ex <<7)  + (data_s2root_ex <<5)  - (data_s2root_ex <<2) - data_s2root_ex ;

assign  a_x4096_sgn      = $signed(l_x4051 - a_x4974 + b_x923);
assign  o_data_a_sgn_nxt = (a_x4096_sgn) + (x4096_a_rnd) >>> SHIFT_BIT_A;


// b = 0.02587890625*L+ 0.78271484375*M + -0.80859375*S
// b = (53/2048)*L+ (1603/2048)*M + (-1656/2048)*S

assign  l_x53            = (data_l2root_ex <<5)  + (data_l2root_ex <<4) + (data_l2root_ex <<2) + data_l2root_ex;
assign  a_x1603          = (data_m2root_ex <<10) + (data_m2root_ex <<9) + (data_m2root_ex <<6) + (data_m2root_ex <<1) + data_m2root_ex;
assign  b_x1656          = (data_s2root_ex <<11) - (data_s2root_ex <<8) - (data_s2root_ex <<7) - (data_s2root_ex <<3);

assign  b_x4096_sgn      = $signed(l_x53 + a_x1603 - b_x1656);
assign  o_data_b_sgn_nxt = (b_x4096_sgn) + (x4096_b_rnd) >>> SHIFT_BIT_B;

//-------------------------------------------------------------------------------------------- cube root 
assign data_l2root_ex    = data_l2root << prcis_idx_l;
assign data_m2root_ex    = data_m2root << prcis_idx_m;
assign data_s2root_ex    = data_s2root << prcis_idx_s;

//================================================================================
//  module instantiation
//================================================================================

cube_lut_12_14
cube_lut_12_14_l(
    .o_data         ( data_l2root ),
    .o_prcis_idx    ( prcis_idx_l),
    
    .i_data         ( i_data_l ),
    .clk            ( clk    ),
    .rst_n          ( rst_n  )
);

cube_lut_12_14  
cube_lut_12_14_m(
    .o_data         ( data_m2root ),
    .o_prcis_idx    ( prcis_idx_m),
    
    .i_data         ( i_data_m ),
    .clk            ( clk    ),
    .rst_n          ( rst_n  )
);

cube_lut_12_14
cube_lut_12_14_s(
    .o_data         ( data_s2root ),
    .o_prcis_idx    ( prcis_idx_s),
    
    .i_data         ( i_data_s ),
    .clk            ( clk    ),
    .rst_n          ( rst_n  )
);

always@(posedge clk or negedge rst_n)begin
    if (!rst_n) begin
    //--------------------------------------- common
        i_hstr_dly   <= 0;
        i_hend_dly   <= 0;
        i_href_dly   <= 0;
        
    //--------------------------------------- output
        o_hstr       <= 0;
        o_hend       <= 0;
        o_href       <= 0;
        o_data_l     <= 0;
        o_data_a_sgn <= 0;
        o_data_b_sgn <= 0;
        
    end
    else begin
    //--------------------------------------- common
        i_hstr_dly   <= i_hstr;
        i_hend_dly   <= i_hend;
        i_href_dly   <= i_href;
        
    //--------------------------------------- output
        o_hstr       <= i_hstr_dly;
        o_hend       <= i_hend_dly;
        o_href       <= i_href_dly;
        o_data_l     <= o_data_l_nxt;
        o_data_a_sgn <= o_data_a_sgn_nxt;
        o_data_b_sgn <= o_data_b_sgn_nxt;
    end
end
endmodule

