// +FHDR -----------------------------------------------------------------------
// (C) Copyright. 2018
// SILICON OPTRONICS INC. ALL RIGHTS RESERVED
//
// File Name:           ip_pwr2_rtl.v
// Author:              Humphrey Lin
//
// File Description:    power of 2 calculation by muli-cycle operation
//
// -FHDR -----------------------------------------------------------------------

module ip_pwr2

#(
//------------------------------------------------------//
// Parameter Declaration                                //
//------------------------------------------------------//
parameter               IDWID       = 1,
parameter               ODWID       = 2**IDWID)

(
//------------------------------------------------------//
// Input Declaration                                    //
//------------------------------------------------------//
input                   i_cal_str,                      // calculation start, 1T
input [IDWID-1:0]       i_val,                          //

input                   clk,
input                   rst_n,

//------------------------------------------------------//
// Output Declaration                                   //
//------------------------------------------------------//
output[ODWID-1:0]       o_val,                          // 2^n output
output reg              o_val_vld,                      // 2^n output valid
output reg              o_val_upd                       // 1T data valid update
);

//------------------------------------------------------//
// Reg/Wire Declaration                                 //
//------------------------------------------------------//

reg   [IDWID-1:0]       mul2_cnt;
wire  [IDWID-1:0]       mul2_cnt_nxt;
wire                    mul2_cnt_dec;
wire                    mul2_cnt_set;
wire                    mul2_cnt_eq0;

reg   [ODWID-1:0]       val_mul2;
wire  [ODWID-1:0]       val_mul2_nxt;

reg                     cal_act;                        // calculation active
wire                    cal_act_nxt;
wire                    o_val_vld_nxt;
wire                    o_val_upd_nxt;

//------------------------------------------------------//
// Code Descriptions                                    //
//------------------------------------------------------//

// doing mil2 repeatly until down-counter mul2_cnt == 0

assign  cal_act_nxt   = ~cal_act ? i_cal_str : ~mul2_cnt_eq0;
assign  o_val_upd_nxt = cal_act & mul2_cnt_eq0;
assign  o_val_vld_nxt = (o_val_upd_nxt | o_val_vld) & ~i_cal_str;

assign  mul2_cnt_dec  = cal_act & ~mul2_cnt_eq0;
assign  mul2_cnt_set  = i_cal_str;
assign  mul2_cnt_nxt  = mul2_cnt_set ? i_val :
                        mul2_cnt_dec ? mul2_cnt - 1'b1 : mul2_cnt;
assign  mul2_cnt_eq0  = mul2_cnt == 0;

assign  o_val         = val_mul2;
assign  val_mul2_nxt  = i_cal_str    ? {{ODWID-1{1'b0}}, 1'b1} :
                        mul2_cnt_dec ? val_mul2 << 1 : val_mul2;


// ---------- Sequential Logic -------------------------//

always @(posedge clk or negedge rst_n) begin
  if (~rst_n) begin
     o_val_vld      <= 0;
     o_val_upd      <= 0;
     cal_act        <= 0;
     mul2_cnt       <= 0;
     val_mul2       <= 0;
  end
  else begin
     o_val_vld      <= o_val_vld_nxt;
     o_val_upd      <= o_val_upd_nxt;
     cal_act        <= cal_act_nxt;
     mul2_cnt       <= mul2_cnt_nxt;
     val_mul2       <= val_mul2_nxt;
  end
end



endmodule
