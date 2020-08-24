// +FHDR -----------------------------------------------------------------------
// (C) Copyright. 2018
// SILICON OPTRONICS INC. ALL RIGHTS RESERVED
//
// File Name:           ip_log2int_rtl.v
// Author:              Humphrey Lin
//
// File Description:    integer-part of Log2 calculation by muli-cycle operation
//
// -FHDR -----------------------------------------------------------------------

module ip_log2int

#(
//------------------------------------------------------//
// Parameter Declaration                                //
//------------------------------------------------------//
parameter               IDWID       = 1,
parameter               ODWID       = log2(IDWID))

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
output[ODWID-1:0]       o_val,                          // log2 output
output reg              o_val_vld,                      // log2 output valid
output reg              o_val_upd                       // 1T data valid update
);

//------------------------------------------------------//
// Reg/Wire Declaration                                 //
//------------------------------------------------------//

reg   [ODWID-1:0]       div2_cnt;
wire  [ODWID-1:0]       div2_cnt_nxt;
wire                    div2_cnt_inc;

reg   [IDWID-1:0]       val_div2;
wire  [IDWID-1:0]       val_div2_nxt;
wire                    val_div2_eq0;

reg                     cal_act;                        // calculation active
wire                    cal_act_nxt;
wire                    o_val_vld_nxt;
wire                    o_val_upd_nxt;

//------------------------------------------------------//
// Code Descriptions                                    //
//------------------------------------------------------//

// doing div2 repeatly until value == 0

assign  cal_act_nxt   = ~cal_act ? i_cal_str : ~val_div2_eq0;
assign  o_val_upd_nxt = cal_act & val_div2_eq0;
assign  o_val_vld_nxt = (o_val_upd_nxt | o_val_vld) & ~i_cal_str;

assign  o_val         = div2_cnt;
assign  div2_cnt_inc  = cal_act & ~val_div2_eq0;
assign  div2_cnt_clr  = i_cal_str;
assign  div2_cnt_nxt  = (div2_cnt_inc ? div2_cnt + 1'b1 : div2_cnt) & {ODWID{~div2_cnt_clr}};

assign  val_div2_nxt  = i_cal_str    ? {1'b0,    i_val[IDWID-1:1]} :
                        div2_cnt_inc ? {1'b0, val_div2[IDWID-1:1]} : val_div2;
                        
assign  val_div2_eq0  = val_div2 == 0;


// ---------- Sequential Logic -------------------------//

always @(posedge clk or negedge rst_n) begin
  if (~rst_n) begin
     o_val_vld      <= 0;
     o_val_upd      <= 0;
     cal_act        <= 0;
     div2_cnt       <= 0;
     val_div2       <= 0;
  end
  else begin
     o_val_vld      <= o_val_vld_nxt;
     o_val_upd      <= o_val_upd_nxt;
     cal_act        <= cal_act_nxt;
     div2_cnt       <= div2_cnt_nxt;
     val_div2       <= val_div2_nxt;
  end
end

// -------------- Function -----------------------------//

function integer log2;
   input integer value;
   begin
      log2 = 0;
      while (2**log2 < value)
         log2 = log2 + 1;
   end
endfunction


endmodule
