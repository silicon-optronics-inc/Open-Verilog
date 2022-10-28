// +FHDR -----------------------------------------------------------------------
// Copyright (c) Silicon Optronics. Inc. 2022
//
// File Name:           ip_lms2rgb.v
// Author:              1.Willy Lin
//                      2.Martin Chen 
//                      3.Humphrey Lin
// Version:             1.0
// Last Modified On:    2022/10/28
//
// File Description:    LMS to RGB Converter
// Abbreviations:
// Parameters:          PRECISION: S 3.11
// Data precision :     input  :     8.6
//                      outupt :     8.0
// Consuming time :     3T  
// -FHDR -----------------------------------------------------------------------

module ip_lms2rgb 
   #(
    parameter CIIW    = 8,               //Accuracy Input Integer Width     //Accuracy can be reduced , but not improved 
    parameter CIPW    = 6,               //Accuracy Input Point Width       //Accuracy can be reduced , but not improved 
    parameter COIW    = 8,               //Accuracy Output Integer Width    //Accuracy can be reduced , but not improved 
    parameter COPW    = 0,               //Accuracy Output Point Width      //Accuracy can be reduced , but not improved 
    parameter CIW     = CIIW + CIPW,
    parameter COW     = COIW + COPW
    )
(
    
//----------------------------------------------//
// Output declaration                           //
//----------------------------------------------//
output    [COW-1:0]         o_data_r,
output    [COW-1:0]         o_data_g,
output    [COW-1:0]         o_data_b,
output                      o_hstr,
output                      o_hend,
output                      o_href,

//----------------------------------------------//
// Input declaration                            //
//----------------------------------------------//
input     [CIW-1:0]         i_data_l,
input     [CIW-1:0]         i_data_m,
input     [CIW-1:0]         i_data_s,
input                       i_hstr,
input                       i_hend,
input                       i_href,
input                       clk,
input                       rst_n
);

//----------------------------------------------//
// Local parameter                              //
//----------------------------------------------//
localparam [4:0]            SHIFT_BIT = (11 +CIPW -COPW);  
localparam [COW:0]          MAX_NUM   = (2**COW);

localparam [3:0]            DEL_NUM   = 3;
localparam [3:0]            DEL_TOL   = (DEL_NUM)*3-1;

//----------------------------------------------//
// Wire declaration                             //
//----------------------------------------------//
//-------------------------------------------------------------------------------------------- input
reg    [CIW-1:0]            i_data_l_dly;
reg    [CIW-1:0]            i_data_m_dly;
reg    [CIW-1:0]            i_data_s_dly;

reg                         i_hstr_dly;
reg                         i_hend_dly;
reg                         i_href_dly;

//-------------------------------------------------------------------------------------------- color convert
reg    [13 + CIW : 0]       l_x8349_stg_1;
reg    [13 + CIW : 0]       m_x6774_stg_1;
reg    [9  + CIW : 0]       s_x473_stg_1;
wire   [13 + CIW : 0]       l_x8349_stg_1_nxt;
wire   [13 + CIW : 0]       m_x6774_stg_1_nxt;
wire   [9  + CIW : 0]       s_x473_stg_1_nxt;
wire   [13 + CIW : 0]       l_x8349_stg_2;
wire   [13 + CIW : 0]       m_x6774_stg_2;
wire   [9  + CIW : 0]       s_x473_stg_2;
reg    [14 + CIW : 0]       r_x2048;
wire   [14 + CIW : 0]       r_x2048_nxt;
wire   [11 +CIPW -COPW-1:0] r_x2048_rnd;
reg    [COW    : 0]         r_x2048_sft;
wire   [COW    : 0]         r_x2048_sft_nxt;
wire   [COW -1 : 0]         o_data_r_nxt;

reg    [11 + CIW : 0]       l_x2598_stg_1;
reg    [12 + CIW : 0]       m_x5345_stg_1;
reg    [9  + CIW : 0]       s_x699_stg_1;
wire   [11 + CIW : 0]       l_x2598_stg_1_nxt;
wire   [12 + CIW : 0]       m_x5345_stg_1_nxt;
wire   [9  + CIW : 0]       s_x699_stg_1_nxt;
wire   [11 + CIW : 0]       l_x2598_stg_2;
wire   [12 + CIW : 0]       m_x5345_stg_2;
wire   [9  + CIW : 0]       s_x699_stg_2;
reg    [13 + CIW : 0]       g_x2048;
wire   [13 + CIW : 0]       g_x2048_nxt;
wire   [11 +CIPW -COPW-1:0] g_x2048_rnd;
reg    [COW    : 0]         g_x2048_sft;
wire   [COW    : 0]         g_x2048_sft_nxt;
wire   [COW -1 : 0]         o_data_g_nxt;

reg    [10 + CIW : 0]       m_x1441_stg_1;
reg    [12 + CIW : 0]       s_x3497_stg_1;
reg    [3  + CIW : 0]       l_x9_stg_1;
wire   [10 + CIW : 0]       m_x1441_stg_1_nxt;
wire   [12 + CIW : 0]       s_x3497_stg_1_nxt;
wire   [3  + CIW : 0]       l_x9_stg_1_nxt;
wire   [10 + CIW : 0]       m_x1441_stg_2;
wire   [12 + CIW : 0]       s_x3497_stg_2;
wire   [3  + CIW : 0]       l_x9_stg_2;
reg    [13 + CIW : 0]       b_x2048;
wire   [13 + CIW : 0]       b_x2048_nxt;
wire   [11 +CIPW -COPW-1:0] b_x2048_rnd;
reg    [COW    : 0]         b_x2048_sft;
wire   [COW    : 0]         b_x2048_sft_nxt;
wire   [COW -1 : 0]         o_data_b_nxt;

//-------------------------------------------------------------------------------------------- output
reg    [DEL_TOL:0]          out_que;
wire   [DEL_TOL:0]          out_que_nxt;

//----------------------------------------------//
// Code Descriptions                            //
//----------------------------------------------//

//-------------------------------------------------------------------------------------------- color convert
//In order to reduce the gate count, it must be divided into two parts 

// 11 bit precision 
// R = 4.07666015625*L+ -3.3076171875*M + 0.23095703125*S
// R = (8349/2048)*L+ (-6774/2048)*M + (473/2048)*S

//add stage 1 
assign  l_x8349_stg_1_nxt  = (i_data_l << 13);  
assign  m_x6774_stg_1_nxt  = (i_data_m << 13);
assign  s_x473_stg_1_nxt   = (i_data_s << 9);

assign  l_x8349_stg_2      = l_x8349_stg_1 + (i_data_l_dly << 7)  + (i_data_l_dly << 5) - (i_data_l_dly << 1) - (i_data_l_dly << 0);
assign  m_x6774_stg_2      = m_x6774_stg_1 - (i_data_m_dly << 10) - (i_data_m_dly << 8) - (i_data_m_dly << 7) - (i_data_m_dly << 3) - (i_data_m_dly << 1);
assign  s_x473_stg_2       = s_x473_stg_1  - (i_data_s_dly << 5)  - (i_data_s_dly << 2) - (i_data_s_dly << 1) - (i_data_s_dly << 0);

assign  r_x2048_nxt        = l_x8349_stg_2 - m_x6774_stg_2 + s_x473_stg_2;
assign  r_x2048_rnd        = {1'b1,{(SHIFT_BIT -1){1'b0}}};
assign  r_x2048_sft_nxt    = ((r_x2048) + (r_x2048_rnd)>>> SHIFT_BIT);
assign  o_data_r           = r_x2048_sft | {COW{r_x2048_sft[COW]}};

// G = -1.2685546875*L+ 2.60986328125*M + -0.34130859375*S
// G = (-2598/2048)*L+ (5345/2048)*M + (-699/2048)*S

assign  l_x2598_stg_1_nxt  = (i_data_l << 11);
assign  m_x5345_stg_1_nxt  = (i_data_m << 12);
assign  s_x699_stg_1_nxt   = (i_data_s << 9);

assign  l_x2598_stg_2      = l_x2598_stg_1 + (i_data_l_dly << 9)  + (i_data_l_dly << 5) + (i_data_l_dly << 2) + (i_data_l_dly << 1);
assign  m_x5345_stg_2      = m_x5345_stg_1 + (i_data_m_dly << 10) + (i_data_m_dly << 7) + (i_data_m_dly << 6) + (i_data_m_dly << 5) + (i_data_m_dly << 0);
assign  s_x699_stg_2       = s_x699_stg_1  + (i_data_s_dly << 7)  + (i_data_s_dly << 6) - (i_data_s_dly << 2) - (i_data_s_dly << 0);

assign  g_x2048_nxt        = -l_x2598_stg_2 + m_x5345_stg_2 - s_x699_stg_2;
assign  g_x2048_rnd        = {1'b1,{(SHIFT_BIT -1){1'b0}}};
assign  g_x2048_sft_nxt    = ((g_x2048) + (g_x2048_rnd)>>> SHIFT_BIT);
assign  o_data_g           = g_x2048_sft | {COW{g_x2048_sft[COW]}};


// B = -0.00439453125*L+ -0.70361328125*M + 1.70751953125*S
// B = (-9/2048)*L+ (-1441/2048)*M + (3497/2048)*S

assign  l_x9_stg_1_nxt     = (i_data_l << 3)  + (i_data_l << 0);
assign  m_x1441_stg_1_nxt  = (i_data_m << 10);
assign  s_x3497_stg_1_nxt  = (i_data_s << 12);

assign  l_x9_stg_2         = l_x9_stg_1;
assign  m_x1441_stg_2      = m_x1441_stg_1 + (i_data_m_dly << 8) + (i_data_m_dly << 7) + (i_data_m_dly << 5) + (i_data_m_dly << 0);
assign  s_x3497_stg_2      = s_x3497_stg_1 - (i_data_s_dly << 9) - (i_data_s_dly << 6) - (i_data_s_dly << 4) - (i_data_s_dly << 3) + (i_data_s_dly << 0);

assign  b_x2048_nxt        = -l_x9_stg_2 - m_x1441_stg_2 + s_x3497_stg_2;
assign  b_x2048_rnd        = {1'b1,{(SHIFT_BIT -1){1'b0}}};
assign  b_x2048_sft_nxt    = ((b_x2048) + (b_x2048_rnd)>>> SHIFT_BIT);
assign  o_data_b           = b_x2048_sft | {COW{b_x2048_sft[COW]}};

//-------------------------------------------------------------------------------------------- output
assign out_que_nxt         = {out_que[DEL_TOL:0] , i_hstr,i_href,i_hend};
assign o_hstr              = out_que[DEL_TOL];
assign o_href              = out_que[DEL_TOL-1];
assign o_hend              = out_que[DEL_TOL-2];

always@(posedge clk or negedge rst_n)begin
    if (!rst_n) begin
//-------------------------------------------------------------------------------------------- input
        i_data_l_dly  <= 0;
        i_data_m_dly  <= 0;
        i_data_s_dly  <= 0;
        
//-------------------------------------------------------------------------------------------- color convert
        r_x2048       <= 0;
        g_x2048       <= 0;
        b_x2048       <= 0;
        
        b_x2048_sft   <= 0;
        g_x2048_sft   <= 0;
        r_x2048_sft   <= 0;
        
        l_x8349_stg_1 <= 0;
        m_x6774_stg_1 <= 0;
        s_x473_stg_1  <= 0;
        l_x2598_stg_1 <= 0;
        m_x5345_stg_1 <= 0;
        s_x699_stg_1  <= 0;
        l_x9_stg_1    <= 0;
        m_x1441_stg_1 <= 0;
        s_x3497_stg_1 <= 0;
        
//-------------------------------------------------------------------------------------------- output
        out_que       <= 0;

    end
    else begin
//-------------------------------------------------------------------------------------------- input
        i_data_l_dly  <= i_data_l;
        i_data_m_dly  <= i_data_m;
        i_data_s_dly  <= i_data_s;
        
//-------------------------------------------------------------------------------------------- color convert
        r_x2048       <= r_x2048_nxt;
        g_x2048       <= g_x2048_nxt;
        b_x2048       <= b_x2048_nxt;
        
        b_x2048_sft   <= b_x2048_sft_nxt;
        g_x2048_sft   <= g_x2048_sft_nxt;
        r_x2048_sft   <= r_x2048_sft_nxt;
        
        l_x8349_stg_1 <= l_x8349_stg_1_nxt;
        m_x6774_stg_1 <= m_x6774_stg_1_nxt;
        s_x473_stg_1  <= s_x473_stg_1_nxt ;
        l_x2598_stg_1 <= l_x2598_stg_1_nxt;
        m_x5345_stg_1 <= m_x5345_stg_1_nxt;
        s_x699_stg_1  <= s_x699_stg_1_nxt ;
        l_x9_stg_1    <= l_x9_stg_1_nxt;
        m_x1441_stg_1 <= m_x1441_stg_1_nxt;
        s_x3497_stg_1 <= s_x3497_stg_1_nxt;
        
//-------------------------------------------------------------------------------------------- output
        out_que       <= out_que_nxt;

    end
end
endmodule
