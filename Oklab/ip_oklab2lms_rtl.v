// +FHDR -----------------------------------------------------------------------
// Copyright (c) Silicon Optronics. Inc. 2022
//
// File Name:           ip_oklab2lms.v
// Author:              1.Willy Lin
//                      2.Martin Chen 
//                      3.Humphrey Lin
// Version:             1.0
// Last Modified On:    2022/10/28
//
// File Description:    OKLAB to LMS Converter
// Abbreviations:
// Parameters:          PRECISION:    S 3.11
// Data precision :     input  : L  :   3.10 
//                               AB : S 1.10
//                      outupt :        3.12
// Consuming time :     4T  
// -FHDR -----------------------------------------------------------------------

module ip_oklab2lms 
   #(
    parameter CIIW_L    = 3,                //LAB-L Accuracy Input Integer Width   //Accuracy can be reduced , but not improved 
    parameter CIPW_L    = 10,               //LAB-L Accuracy Input Point Width     //Accuracy can be reduced , but not improved 
    parameter CIIW_AB   = 2,                //LAB-AB Accuracy Input Integer Width  //Accuracy can be reduced , but not improved 
    parameter CIPW_AB   = 11,               //LAB-AB Accuracy Input Point Width    //Accuracy can be reduced , but not improved 
    parameter CIW_LAB   = 3,                //LAB Accuracy Output Integer Width    //Accuracy can be reduced , but not improved    
    parameter CPW_LAB   = 12,               //LAB Accuracy Output Point Width      //Accuracy can be reduced , but not improved        
    parameter CIW_L     = CIIW_L + CIPW_L,
    parameter CIW_AB    = CIIW_AB + CIPW_AB,
    parameter CIW_STG_1 = 6,                //stage1 multi Accuracy Integer Width  //Accuracy can be changed 
    parameter CPW_STG_1 = 8,                //stage1 multi Accuracy Point Width    //Accuracy can be changed 
    parameter COIW      = 8,                //LMS Accuracy Output Integer Width    //Accuracy can be reduced , but not improved 
    parameter COPW      = 6,                //LMS Accuracy Output Point Width      //Accuracy can be reduced , but not improved 
    parameter COW       = COIW + COPW
    )
(
    
//----------------------------------------------//
// Output declaration                           //
//----------------------------------------------//
output reg   [COW-1:0]    o_data_l,
output reg   [COW-1:0]    o_data_m,
output reg   [COW-1:0]    o_data_s,
output                    o_hstr,
output                    o_hend,
output                    o_href,

//----------------------------------------------//
// Input declaration                            //
//----------------------------------------------//
input        [CIW_L-1:0]  i_data_l,
input signed [CIW_AB-1:0] i_data_a_sgn,
input signed [CIW_AB-1:0] i_data_b_sgn,
input                     i_hstr,
input                     i_hend,
input                     i_href,
input                     clk,
input                     rst_n
);

//----------------------------------------------//
// Local parameter                              //
//----------------------------------------------//
localparam [4:0]    CW_LAB    = CIW_LAB + CPW_LAB;    //total precision for lab 
localparam [4:0]    SHIFT_BIT = (11 + 11 -CPW_LAB);   //CIPW_L and CIPW_AB will be fix to 11 

localparam [4:0]    CW_STG_1  = CIW_STG_1 + CPW_STG_1;//total precision for state1 multi

localparam [COW:0]  MAX_NUM   = (2**COW);

localparam [3:0]    DEL_NUM   = 4;
localparam [3:0]    DEL_TOL   = (DEL_NUM)*3-1;
//----------------------------------------------//
// Wire declaration                             //
//----------------------------------------------//
//-------------------------------------------------------------------------------------------- common
wire        [3:0]                    shift_bit_l;
wire        [3:0]                    shift_bit_ab;

//-------------------------------------------------------------------------------------------- color convert
wire        [11+11+CIIW_L  : 0]      l_x2048;       // CIPW_L and CIPW_AB will be fix to 11 
wire signed [10+11+CIIW_AB : 0]      a_x812_sgn;
wire signed [9 +11+CIIW_AB : 0]      b_x442_sgn;
wire        [12+11+CIIW_AB : 0]      l_x2048_o;
wire        [11+11-CPW_LAB-1:0]      l_x2048_o_rnd;
reg         [CW_LAB :0]              l_x2048_o_sft;
wire        [CW_LAB :0]              l_x2048_o_sft_nxt;

wire signed [8 +11+CIIW_AB : 0]      a_x216_sgn;
wire signed [8 +11+CIIW_AB : 0]      b_x131_sgn;
wire        [12+11+CIIW_AB : 0]      m_x2048;
wire        [11+11-CPW_LAB-1:0]      m_x2048_rnd;
reg         [CW_LAB :0]              m_x2048_sft;
wire        [CW_LAB :0]              m_x2048_sft_nxt;

wire signed [8 +11+CIIW_AB : 0]      a_x183_sgn;
wire signed [12+11+CIIW_AB : 0]      b_x2645_sgn;
wire        [13+11+CIIW_AB : 0]      s_x2048;
wire        [11+11-CPW_LAB-1:0]      s_x2048_rnd;
reg         [CW_LAB :0]              s_x2048_sft;
wire        [CW_LAB :0]              s_x2048_sft_nxt;

//-------------------------------------------------------------------------------------------- cubic calculation 
wire        [CPW_LAB*2-1 :0]         stg_1_rnd;
wire        [CPW_STG_1+CPW_LAB-1 :0] stg_2_rnd;

wire        [CW_LAB-1 :0]            l_mul_stg_0_nxt;
wire        [CW_LAB-1 :0]            m_mul_stg_0_nxt;
wire        [CW_LAB-1 :0]            s_mul_stg_0_nxt;
reg         [CW_LAB-1 :0]            l_mul_stg_0;
reg         [CW_LAB-1 :0]            m_mul_stg_0;
reg         [CW_LAB-1 :0]            s_mul_stg_0;
reg         [CW_LAB-1 :0]            l_mul_stg_0_q;
reg         [CW_LAB-1 :0]            m_mul_stg_0_q;
reg         [CW_LAB-1 :0]            s_mul_stg_0_q;

wire        [CW_LAB+CW_LAB-1 :0]     l_mul_stg_1;
wire        [CW_LAB+CW_LAB-1 :0]     m_mul_stg_1;
wire        [CW_LAB+CW_LAB-1 :0]     s_mul_stg_1;

reg         [CW_STG_1-1 :0]          l_mul_stg_1_pt; //6.8
reg         [CW_STG_1-1 :0]          m_mul_stg_1_pt; //6.8
reg         [CW_STG_1-1 :0]          s_mul_stg_1_pt; //6.8

wire        [CW_STG_1-1 :0]          l_mul_stg_1_pt_nxt; //6.8
wire        [CW_STG_1-1 :0]          m_mul_stg_1_pt_nxt; //6.8
wire        [CW_STG_1-1 :0]          s_mul_stg_1_pt_nxt; //6.8

wire        [CW_STG_1 +CW_LAB-1 :0]  l_mul_stg_2; 
wire        [CW_STG_1 +CW_LAB-1 :0]  m_mul_stg_2; 
wire        [CW_STG_1 +CW_LAB-1 :0]  s_mul_stg_2; 

//-------------------------------------------------------------------------------------------- output
wire        [COW-1 :0]               o_data_l_nxt; //8.6
wire        [COW-1 :0]               o_data_m_nxt; //8.6
wire        [COW-1 :0]               o_data_s_nxt; //8.6

reg         [DEL_TOL:0]              out_que;
wire        [DEL_TOL:0]              out_que_nxt;
//----------------------------------------------//
// Code Descriptions                            //
//----------------------------------------------//
//-------------------------------------------------------------------------------------------- common
assign x2048_rnd           = 1'b1 << (SHIFT_BIT -1);

assign shift_bit_l         = 11 - CIPW_L;
assign shift_bit_ab        = 11 - CIPW_AB;

//-------------------------------------------------------------------------------------------- color convert
// 11 bit precision
// L = 1*L+ 0.396484375*a + 0.2158203125*b
// L = (2048/2048)*L+ (812/2048)*a + (442/2048)*b

assign  l_x2048            = (i_data_l <<(11 +shift_bit_l));
assign  a_x812_sgn         = (i_data_a_sgn <<(9 +shift_bit_ab)) + (i_data_a_sgn <<(8 +shift_bit_ab)) + (i_data_a_sgn <<(5 +shift_bit_ab)) + 
                             (i_data_a_sgn <<(3 +shift_bit_ab)) + (i_data_a_sgn <<(2 +shift_bit_ab));
assign  b_x442_sgn         = (i_data_b_sgn <<(8 +shift_bit_ab)) + (i_data_b_sgn <<(7 +shift_bit_ab)) + (i_data_b_sgn <<(5 +shift_bit_ab)) + 
                             (i_data_b_sgn <<(4 +shift_bit_ab)) + (i_data_b_sgn <<(3 +shift_bit_ab)) + (i_data_b_sgn <<(1 +shift_bit_ab));

assign  l_x2048_o          = $signed(l_x2048) + $signed(a_x812_sgn) + $signed(b_x442_sgn);
assign  l_x2048_o_rnd      = {1'b1,{(SHIFT_BIT -1){1'b0}}};
assign  l_x2048_o_sft_nxt  = (l_x2048_o) + (l_x2048_o_rnd)>>> SHIFT_BIT;
assign  l_mul_stg_0_nxt    = l_x2048_o_sft | {CW_LAB{l_x2048_o_sft[CW_LAB]}};


// M = 1*L+ -0.10546875*a + -0.06396484375*b
// M = (2048/2048)*L+ (-216/2048)*a + (-131/2048)*b

assign  a_x216_sgn         = (i_data_a_sgn <<(7 +shift_bit_ab)) + (i_data_a_sgn <<(6 +shift_bit_ab)) + (i_data_a_sgn <<(4 +shift_bit_ab)) + (i_data_a_sgn <<(3 +shift_bit_ab));
assign  b_x131_sgn         = (i_data_b_sgn <<(7 +shift_bit_ab)) + (i_data_b_sgn <<(1 +shift_bit_ab)) + (i_data_b_sgn <<(shift_bit_ab)) ;

assign  m_x2048            = $signed(l_x2048) - $signed(a_x216_sgn) - $signed(b_x131_sgn);
assign  m_x2048_rnd        = {1'b1,{(SHIFT_BIT -1){1'b0}}};
assign  m_x2048_sft_nxt    = (m_x2048) + (m_x2048_rnd)>>> SHIFT_BIT;
assign  m_mul_stg_0_nxt    = m_x2048_sft | {CW_LAB{m_x2048_sft[CW_LAB]}};


// S = 1*L+ -0.08935546875*a + -1.29150390625*b
// S = (2048/2048)*L+ (-183/2048)*a + (-2645/2048)*b

assign  a_x183_sgn         = (i_data_a_sgn <<(7 +shift_bit_ab)) + (i_data_a_sgn <<(5 +shift_bit_ab)) + (i_data_a_sgn <<(4 +shift_bit_ab)) +
                             (i_data_a_sgn <<(2 +shift_bit_ab)) + (i_data_a_sgn <<(1 +shift_bit_ab)) + (i_data_a_sgn <<(shift_bit_ab));
assign  b_x2645_sgn        = (i_data_b_sgn <<(11 +shift_bit_ab))+ (i_data_b_sgn <<(9 +shift_bit_ab)) + (i_data_b_sgn <<(6 +shift_bit_ab)) +
                             (i_data_b_sgn <<(4 +shift_bit_ab)) + (i_data_b_sgn <<(2 +shift_bit_ab)) + (i_data_b_sgn <<(shift_bit_ab));
                       
assign  s_x2048            = $signed(l_x2048) - $signed(a_x183_sgn) - $signed(b_x2645_sgn);
assign  s_x2048_rnd        = {1'b1,{(SHIFT_BIT -1){1'b0}}};
assign  s_x2048_sft_nxt    = (s_x2048) + (s_x2048_rnd)>>> SHIFT_BIT;
assign  s_mul_stg_0_nxt    = s_x2048_sft | {CW_LAB{s_x2048_sft[CW_LAB]}};


//-------------------------------------------------------------------------------------------- cubic calculation 
assign stg_1_rnd           = 1'b1 << (CPW_LAB*2-CPW_STG_1-1);
assign stg_2_rnd           = 1'b1 << (CPW_STG_1+CPW_LAB-COPW-1);

assign l_mul_stg_1         = l_mul_stg_0 * l_mul_stg_0 + stg_1_rnd; 
assign l_mul_stg_1_pt_nxt  = l_mul_stg_1[CW_LAB+CW_LAB-1 -: CW_STG_1]; //6.8
assign l_mul_stg_2         = l_mul_stg_1_pt * l_mul_stg_0_q + stg_2_rnd;      
assign o_data_l_nxt        = l_mul_stg_2[CW_STG_1 +CW_LAB-2 -: COW];   //8.6

assign m_mul_stg_1         = m_mul_stg_0 * m_mul_stg_0 + stg_1_rnd; 
assign m_mul_stg_1_pt_nxt  = m_mul_stg_1[CW_LAB+CW_LAB-1 -: CW_STG_1]; //6.8
assign m_mul_stg_2         = m_mul_stg_1_pt * m_mul_stg_0_q + stg_2_rnd;
assign o_data_m_nxt        = m_mul_stg_2[CW_STG_1 +CW_LAB-2 -: COW];   //8.6

assign s_mul_stg_1         = s_mul_stg_0 * s_mul_stg_0 + stg_1_rnd; 
assign s_mul_stg_1_pt_nxt  = s_mul_stg_1[CW_LAB+CW_LAB-1 -: CW_STG_1]; //6.8
assign s_mul_stg_2         = s_mul_stg_1_pt * s_mul_stg_0_q + stg_2_rnd; 
assign o_data_s_nxt        = s_mul_stg_2[CW_STG_1 +CW_LAB-2 -: COW];   //8.6

//-------------------------------------------------------------------------------------------- output 
assign out_que_nxt         = {out_que[DEL_TOL:0] , i_hstr,i_href,i_hend};
assign o_hstr              = out_que[DEL_TOL];
assign o_href              = out_que[DEL_TOL-1];
assign o_hend              = out_que[DEL_TOL-2];



always@(posedge clk or negedge rst_n)begin
    if (!rst_n) begin
//-------------------------------------------------------------------------------------------- color convert
        l_x2048_o_sft  <= 0;
        m_x2048_sft    <= 0;
        s_x2048_sft    <= 0;
        
//-------------------------------------------------------------------------------------------- cubic calculation 
        l_mul_stg_0    <= 0;
        m_mul_stg_0    <= 0;
        s_mul_stg_0    <= 0;
        l_mul_stg_0_q  <= 0;
        m_mul_stg_0_q  <= 0;
        s_mul_stg_0_q  <= 0;    
        l_mul_stg_1_pt <= 0;
        m_mul_stg_1_pt <= 0;
        s_mul_stg_1_pt <= 0;
        
//-------------------------------------------------------------------------------------------- output
        o_data_l       <= 0;
        o_data_m       <= 0;
        o_data_s       <= 0;
        out_que        <= 0;

    end
    else begin
//-------------------------------------------------------------------------------------------- color convert
        l_x2048_o_sft  <= l_x2048_o_sft_nxt;
        m_x2048_sft    <= m_x2048_sft_nxt;
        s_x2048_sft    <= s_x2048_sft_nxt;
        
//-------------------------------------------------------------------------------------------- cubic calculation 
        l_mul_stg_0    <= l_mul_stg_0_nxt;
        m_mul_stg_0    <= m_mul_stg_0_nxt;
        s_mul_stg_0    <= s_mul_stg_0_nxt;
        l_mul_stg_0_q  <= l_mul_stg_0;
        m_mul_stg_0_q  <= m_mul_stg_0;
        s_mul_stg_0_q  <= s_mul_stg_0; 
        l_mul_stg_1_pt <= l_mul_stg_1_pt_nxt;
        m_mul_stg_1_pt <= m_mul_stg_1_pt_nxt;
        s_mul_stg_1_pt <= s_mul_stg_1_pt_nxt;
        
//-------------------------------------------------------------------------------------------- output
        o_data_l       <= o_data_l_nxt;
        o_data_m       <= o_data_m_nxt;
        o_data_s       <= o_data_s_nxt;
        out_que        <= out_que_nxt;
        
    end
end
endmodule

