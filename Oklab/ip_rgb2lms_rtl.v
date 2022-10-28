// +FHDR -----------------------------------------------------------------------
// Copyright (c) Silicon Optronics. Inc. 2022
//
// File Name:           ip_rgb2lms_rtl.v
// Author:              1.Willy Lin
//                      2.Martin Chen 
//                      3.Humphrey Lin
// Version:             1.0
// Last Modified On:    2022/10/28
//
// File Description:    RGB to LMS Converter
// Abbreviations:
// Parameters:          PRECISION: S 1.12
// Data precision :     input  :     8.0
//                      outupt :     8.4
// Consuming time :     1T  
//
// -FHDR -----------------------------------------------------------------------

module ip_rgb2lms
    #(
         parameter   CIIW       = 8,             //Accuracy Input Integer Width  //Accuracy can be reduced , but not improved 
         parameter   CIPW       = 0,             //Accuracy Input Point Width    //Accuracy can be reduced , but not improved 
         parameter   COIW       = 8,             //Accuracy Output Integer Width //Accuracy can be reduced , but not improved 
         parameter   COPW       = 4,             //Accuracy Output Point Width   //Accuracy can be reduced , but not improved 
         parameter   CIW        = CIIW + CIPW,
         parameter   COW        = COIW + COPW
     )
(
//----------------------------------------------//
// Output declaration                           //
//----------------------------------------------//

output            [COW-1:0]   o_data_l,                      
output            [COW-1:0]   o_data_m,                     
output            [COW-1:0]   o_data_s,                    
output reg                    o_hstr,
output reg                    o_hend,
output reg                    o_href,

//----------------------------------------------//
// Input declaration                            //
//----------------------------------------------//

input             [CIW-1:0]   i_data_r,                      // input R
input             [CIW-1:0]   i_data_g,                      // input G
input             [CIW-1:0]   i_data_b,                      // input B
input                         i_hstr,
input                         i_hend,
input                         i_href,
input                         clk,
input                         rst_n
);

//----------------------------------------------//
// Local parameter                              //
//----------------------------------------------//
localparam [4:0]              SHIFT_BIT = (12 +CIPW -COPW);
localparam [COW:0]            MAX_NUM   = (2**COW);

//----------------------------------------------//
// Wire declaration                             //
//----------------------------------------------//
//-------------------------------------------------------------------------------------------- color space convert  
wire         [10 + CIW:0]     r_x1688;
wire         [11 + CIW:0]     g_x2197;
wire         [7  + CIW:0]     b_x211;
wire         [12 + CIW:0]     l_x4096;
wire         [12 + CIW-COW:0] l_x4096_rnd;
reg          [COW :0]         l_x4096_sft;
wire         [COW :0]         l_x4096_sft_nxt;
wire         [COW-1:0]        o_data_l;

wire         [9  + CIW:0]     r_x868;
wire         [11 + CIW:0]     g_x2788;
wire         [9  + CIW:0]     b_x440;
wire         [12 + CIW:0]     m_x4096;
wire         [12 + CIW-COW:0] m_x4096_rnd;
reg          [COW :0]         m_x4096_sft;
wire         [COW :0]         m_x4096_sft_nxt;
wire         [COW-1 :0]       o_data_m;

wire         [8  + CIW:0]     r_x362;
wire         [10 + CIW:0]     g_x1154;
wire         [11 + CIW:0]     b_x2580;
wire         [12 + CIW:0]     s_x4096;
wire         [12 + CIW-COW:0] s_x4096_rnd;
reg          [COW :0]         s_x4096_sft;
wire         [COW :0]         s_x4096_sft_nxt;
wire         [COW-1:0]        o_data_s;

//----------------------------------------------//
// Code Descriptions                            //
//----------------------------------------------//
//-------------------------------------------------------------------------------------------- color space convert  

// 12 bit precision 
// L = 0.412109375*R+ 0.536376953125*G + 0.051513671875*B
// L = (1688/4096)*R+ (2197/4096)*G + (211/4096)*B

assign  r_x1688           = (i_data_r <<10) + (i_data_r <<9) + (i_data_r <<7) + (i_data_r <<4) + (i_data_r <<3);
assign  g_x2197           = (i_data_g <<11) + (i_data_g <<7) + (i_data_g <<4) + (i_data_g <<2) + (i_data_g <<0);
assign  b_x211            = (i_data_b <<7)  + (i_data_b <<6) + (i_data_b <<4) + (i_data_b <<1) + (i_data_b <<0);

assign  l_x4096           = r_x1688 + g_x2197 + b_x211;
assign  l_x4096_rnd       = {1'b1,{(SHIFT_BIT -1){1'b0}}};
assign  l_x4096_sft_nxt   = (l_x4096) + (l_x4096_rnd)>>> SHIFT_BIT;
assign  o_data_l          = l_x4096_sft | {COW{l_x4096_sft[COW]}};


// M = 0.2119140625*R+ 0.6806640625*G + 0.107421875*B
// M = (868/4096)*R+ (2788/4096)*G + (440/4096)*B

assign  r_x868            = (i_data_r <<9)  + (i_data_r <<8) + (i_data_r <<6) + (i_data_r <<5) + (i_data_r <<2);
assign  g_x2788           = (i_data_g <<11) + (i_data_g <<9) + (i_data_g <<8) - (i_data_g <<5) + (i_data_g <<2);
assign  b_x440            = (i_data_b <<9)  - (i_data_b <<6) - (i_data_b <<3) ;

assign  m_x4096           = r_x868 + g_x2788 + b_x440;
assign  m_x4096_rnd       = {1'b1,{(SHIFT_BIT -1){1'b0}}};
assign  m_x4096_sft_nxt   = (m_x4096) + (m_x4096_rnd)>>> SHIFT_BIT;
assign  o_data_m          = m_x4096_sft | {COW{m_x4096_sft[COW]}};


// S = 0.08837890625*R+ 0.28173828125*G + 0.6298828125*B
// S = (362/4096)*R+ (1154/4096)*G + (2580/4096)*B

assign  r_x362            = (i_data_r <<8)  + (i_data_r <<6) + (i_data_r <<5) + (i_data_r <<3) + (i_data_r <<1);
assign  g_x1154           = (i_data_g <<10) + (i_data_g <<7) + (i_data_g <<1);
assign  b_x2580           = (i_data_b <<11) + (i_data_b <<9) + (i_data_b <<4) + (i_data_b <<2);

assign  s_x4096           = r_x362 + g_x1154 + b_x2580;
assign  s_x4096_rnd       = {1'b1,{(SHIFT_BIT -1){1'b0}}};
assign  s_x4096_sft_nxt   = (s_x4096) + (s_x4096_rnd)>>> SHIFT_BIT;
assign  o_data_s          = s_x4096_sft | {COW{s_x4096_sft[COW]}};


always@(posedge clk or negedge rst_n)begin
    if (!rst_n) begin
//-------------------------------------------------------------------------------------------- color space convert 
        l_x4096_sft      <= 0;
        m_x4096_sft      <= 0;
        s_x4096_sft      <= 0;

//-------------------------------------------------------------------------------------------- output
        o_hstr           <= 0;
        o_hend           <= 0;
        o_href           <= 0;
    end
    else begin
//-------------------------------------------------------------------------------------------- color space convert 
        l_x4096_sft      <= l_x4096_sft_nxt;
        m_x4096_sft      <= m_x4096_sft_nxt;
        s_x4096_sft      <= s_x4096_sft_nxt;

//-------------------------------------------------------------------------------------------- output
        o_hstr           <= i_hstr;
        o_hend           <= i_hend;
        o_href           <= i_href;
    end
end




endmodule

