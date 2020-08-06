// +FHDR -----------------------------------------------------------------------
// Copyright (c) Silicon Optronics. Inc. 2015
//
// File Name:           ip_cu_dp_rtl.v
// Author:              Humphrey Lin
// Version:             $Revision$
// Last Modified On:    $Date$
// Last Modified By:    $Author$
//
// File Description:    CU Datapath of elementary operation module
// op = 0: ADD
// unsign (ALU_SZ+1.) = unsign (ALU_SZ.)  + unsign (ALU_SZ.)
// sum[ALU_SZ:0]      = num_0[ALU_SZ-1:0] + num_1[ALU_SZ-1:0]
//
// op = 1: SUB
// sign (ALU_SZ.)               = unsign (ALU_SZ-1.)      - unsign (ALU_SZ-1.)
// {sum[ALU_SZ],sum[ALU_SZ-1:0]}= {1'b,num_0[ALU_SZ-2:0]} - {1'b0,num_1[ALU_SZ-2:0]}
//
// op = 2: MULT
// unsign (ALU_SZ*2.)                         = unsign (ALU_SZ.)  * unsign (ALU_SZ.)
// {prod[ALU_SZ*2-1:ALU_SZ],prod[ALU_SZ-1:0]} = num_0[ALU_SZ-1:0] * num_1[ALU_SZ-1:0]
//
// op = 3: DIV
// unsign (ALU_SZ+EXD_SZ.) = unsign (ALU_SZ+EXD_SZ.)   / unsign (ALU_SZ-1.)
// prod[ALU_SZ+EXD_SZ-1:0] = num_0[ALU_SZ+EXD_SZ-1:0]  / num_1[ALU_SZ-2:0]

// Abbreviations: CU: Calculation Unit
//
// Parameters:  ALU_SZ: Arithmetic operation width
//              EXD_SZ: Extended ALU width, defined for dividend on the Division
//
// -FHDR -----------------------------------------------------------------------

module  ip_cu_dp

    #(
      parameter             ALU_SZ      = 8,
      parameter             EXD_SZ      = 1,

    // local parameter
      parameter             NUM0_SZ     = ALU_SZ + EXD_SZ,
      parameter             NUM1_SZ     = ALU_SZ
     )
(
//----------------------------------------------//
// Output declaration                           //
//----------------------------------------------//

output reg[ALU_SZ-1:0]      prod_msb,           // operation product MSB
output reg[ALU_SZ+EXD_SZ-1:0] prod_lsb,         // operation product LSB

//----------------------------------------------//
// Input declaration                            //
//----------------------------------------------//

input [NUM0_SZ-1:0]         num_0,              // input number 0
input [NUM1_SZ-1:0]         num_1,              // input number 1
input                       op_ini_sm,          // @ OP_INI state
input                       op_rdy_sm,          // @ OP_RDY state
input                       op_act_sm,          // CU op active
input                       op_halt_sm,         // @ OP_HALT state
input                       add_en,             // Addition op enable
input                       sub_en,             // Subtraction op enable
input                       mul_en,             // Multiply op enable
input                       div_en,             // Division enable
input                       pclk,               // ISP pixel clock
input                       prst_n              // active low reset for pclk domain
);

//----------------------------------------------//
// Local Parameter                              //
//----------------------------------------------//

localparam                  OP_ADD      = 4'b0001,
                            OP_SUB      = 4'b0010,
                            OP_MUL      = 4'b0100,
                            OP_DIV      = 4'b1000;

//----------------------------------------------//
// Register declaration                         //
//----------------------------------------------//

reg [ALU_SZ-1:0]            prod_msb_src;       // source of product MSB
reg [ALU_SZ+EXD_SZ-1:0]     prod_lsb_src;       // source of product LSB

//----------------------------------------------//
// Wire declaration                             //
//----------------------------------------------//

wire[3:0]                   op_sel;             // operation select
wire[ALU_SZ-1:0]            a_src;              // Elementary Operation source A
wire[ALU_SZ-1:0]            b_src;              // Elementary Operation source B
wire signed[ALU_SZ:0]       a_src_sgn;          //
wire signed[ALU_SZ:0]       b_src_sgn;          //
wire signed[ALU_SZ+1:0]     sum_sgn;            // sum of a_src and b_src

wire[ALU_SZ-1:0]            prod_msb_nxt;       //
wire[ALU_SZ+EXD_SZ-1:0]     prod_lsb_nxt;       //

//----------------------------------------------//
// Code Descriptions                            //
//----------------------------------------------//

// ------- Elementary Operation (a+b, a-b)------//

assign  a_src_sgn = $signed({1'b0,a_src});
assign  b_src_sgn = sub_en | div_en ? -$signed({1'b0,b_src}) : $signed({1'b0,b_src});

assign  sum_sgn   = a_src_sgn + b_src_sgn;

// elementary op input: a, b source select
assign  a_src = ({ALU_SZ{(add_en | sub_en | mul_en)  & ~op_halt_sm}} & num_0[ALU_SZ-1:0]) |
                ({ALU_SZ{                   div_en}} & {1'b0,prod_msb[ALU_SZ-2:0]});

assign  b_src = ({ALU_SZ{(add_en | sub_en | div_en)  & ~op_halt_sm}} & num_1[ALU_SZ-1:0]) |
                ({ALU_SZ{                   mul_en}} & prod_msb[ALU_SZ-1:0]);

// elementary op product source select
assign  prod_lsb_nxt = op_act_sm & ~op_rdy_sm ? prod_lsb_src : prod_lsb;
assign  prod_msb_nxt = op_act_sm & ~op_rdy_sm ? prod_msb_src : prod_msb;

assign  op_sel = {div_en,mul_en,sub_en,add_en};

always @* begin
   case (op_sel)// synopsys full_case parallel_case infer_onehot_mux
   OP_ADD: prod_lsb_src = {{EXD_SZ-1{1'b0}}, $unsigned(sum_sgn[ALU_SZ  :0])};
   OP_SUB: prod_lsb_src = {{EXD_SZ  {1'b0}}, $unsigned(sum_sgn[ALU_SZ-1:0])};
   OP_MUL: prod_lsb_src = {{EXD_SZ  {1'b0}}, op_ini_sm   ? num_1  :
                                            {prod_lsb[0] ? sum_sgn[0] : prod_msb[0], prod_lsb[ALU_SZ-1:1]}};
   OP_DIV: prod_lsb_src = op_ini_sm ? {num_0   [NUM0_SZ-2:0],1'b0}  :
                                      {prod_lsb[ALU_SZ+EXD_SZ-2:0], (~sum_sgn[ALU_SZ+1]) & (num_0 != 0 && num_1 != 0)};
   endcase
end

always @* begin
   case (op_sel)// synopsys full_case parallel_case infer_onehot_mux
   OP_ADD,
   OP_SUB: prod_msb_src = 0;
   OP_MUL: prod_msb_src = op_ini_sm ? 0 :
                                      prod_lsb[0] ? $unsigned(sum_sgn[ALU_SZ:1]) : {1'b0, prod_msb[ALU_SZ-1:1]};
   OP_DIV: prod_msb_src = op_ini_sm ? {{(ALU_SZ-1){1'b0}}, num_0[NUM0_SZ-1]} :
                                      (sum_sgn [ALU_SZ+1] ?             // sign bit
                                      {prod_msb[ALU_SZ-2:0],           prod_lsb[ALU_SZ+EXD_SZ-1]} :
                                      {$unsigned(sum_sgn[ALU_SZ-2:0]), prod_lsb[ALU_SZ+EXD_SZ-1]});
   endcase
end

// ---------- Sequential Logic -----------------//

always @(posedge pclk or negedge prst_n) begin
   if (~prst_n) begin
      prod_lsb      <= 0;
      prod_msb      <= 0;
   end
   else begin
      prod_lsb      <= prod_lsb_nxt;
      prod_msb      <= prod_msb_nxt;
   end
end


endmodule
