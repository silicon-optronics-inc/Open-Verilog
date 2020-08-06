// +FHDR -----------------------------------------------------------------------
// Copyright (c) Silicon Optronics. Inc. 2020
//
// File Name:           ip_axi4m2v_s_rtl.v
// Author:              Humphrey Lin
//
// File Description:    1. AXI4 slave doing AXI4-stream to video conversion
//                      2. packet format [PACK8N = "P2B"]:
//                         byte4-to-pix8 : {P3, P2, P1, P0}
//                         byte4-to-pix10: msb8{P3, P2, P1, P0},
//                                         msb8{P6, P5, P4}, lsb2{P3, P2, P1, P0}
//                         byte4-to-pix12: msb8{P2}, lsb2{P1, P0}, msb8{P1, P0},
//                                         msb8{P5, P4}, lsb2{P3, P2}, msb8{P3}
//                         byte4-to-pix16: {P1, P0}, {P3, P2}
//
//                         packet format [PACK8N = "PAD"]:
//                         pixM-to-byteN : {{X{1'b0}}, .... ,pix2, pix1, pix0}
//                      3. Not yet implement VFBLK_SYN == "TRUE"
// -FHDR -----------------------------------------------------------------------

module axi4s2v_s

#(
parameter                       PXDW            = 10,       // pixel data width: 8, 10, 12, 16
parameter[ 1:0]                 PX_RATE         = 1,        // pixel number: 1, 2
parameter                       VODW            = PXDW*PX_RATE,// video output data width
parameter                       AIDW            = 32,       // AXI input data width 8*n, AIDW >= VODW

                                                            // "P2B": re-pack pixel to byte alligned format
                                                            //        PX_RATE==1 if AIDW = 32;
                                                            //        PX_RATE==2 if AIDW = 64
parameter                       PACK8N          = "P2B",    // "PAD": padding msb zero if VODW*m < AIDW
parameter                       FIFO_DEP        = 32,       // FIFO depth 2^N
parameter                       FIFO_CDC        = "ASYNC",  // "SYNC" or "ASYNC"
parameter                       FIFO_TYPE       = "FPGA_BLKRAM",

parameter[log2(FIFO_DEP)-1 : 0] FIFO_RDY_LVL    = FIFO_DEP/2,// FIFO queue up threshold before video output
parameter                       IMG_HWIN        = 1024,     // max image width

parameter[log2(IMG_HWIN)-2 : 0] VSYN_DLY        = 1,        // gap between in/out vsync. Max = 0.5 line
parameter                       VFBLK_SYN       = "FALSE",  // "TRUE": same time interval of vertical front
                                                            // blacking between input and output.
                                                            // "FALSE": follow i_vstr and fifo ready
parameter                       ILA_DBG_EN      = 0         // ILA debug enable/disable
 )

(
//----------------------------------------------------------//
// AXI4-Stream interface                                    //
//----------------------------------------------------------//
input       [AIDW-1:0]          tdata,
input                           tvalid,
input                           tlast,
output                          tready,
output                          tuser,                      // sof, to trigger another VDMA IP

input                           aclk,
input                           aresetn,                    // active-low reset

//----------------------------------------------------------//
// Native video output interface                            //
//----------------------------------------------------------//
output                          o_fstr,                     //
output                          o_fend,                     //
output reg                      o_vstr,                     //
output                          o_vend,                     //
output                          o_hstr,                     //
output                          o_hend,                     //
output                          o_href,                     //
output      [VODW-1:0]          o_pdat,                     // output pixel data

//----------------------------------------------------------//
// Native video timing input interface                      // External video timing generator
//----------------------------------------------------------//
input                           i_fstr,                     //
input                           i_fend,                     //
input                           i_vstr,                     //
input                           i_vend,                     //
input                           i_hstr,                     //
input                           i_hend,                     //
input                           i_href,                     //

input                           pclk,                       // pclk for input data domain
input                           prst_n,                     // reset @pclk clock domain

//----------------------------------------------------------//
// Common interface                                         //
//----------------------------------------------------------//
output      [ 4:0]              o_vcnv_sts                  // video conversion operating status
                                                            // [0]: FIFO level >= parameter specified FIFO level
                                                            // [1]: Video timing is launched but FIFO level is not meet
                                                            // [2]: Video timing is launched but FIFO is empty
                                                            // [3]: Video timing is launched but FIFO is empty
                                                            // [4]: FIFO is under flow
                                                            // [5]: i_fend is launched before o_vend
);

//----------------------------------------------------------//
// Local Parameter                                          //
//----------------------------------------------------------//

localparam              FIFO_AW         = log2(FIFO_DEP);
localparam              FIFO_DW         = AIDW;

localparam              PKD_SZ          = PXDW == 10 ? (PX_RATE == 1 ? 40 : 48) :
                                          PXDW == 12 ? (PX_RATE == 1 ? 24 : 32) : VODW;
//localparam              PKC_SZ          = AIDW/VODW + ((AIDW%VODW) != 0); // packet counter size
localparam              PKC_SZ          = AIDW/VODW;// packet counter size

localparam              PKC_DW          = log2(PKC_SZ);

localparam              XWID            = log2(IMG_HWIN);


localparam  [ 9:0]      VOTM_IDLE       = 10'b00_0000_0000,
                        VOTM_FSTR_DLY   = 10'b00_0000_0001,
                        VOTM_FSTR       = 10'b00_0000_0010,
                        VOTM_FVBLK      = 10'b00_0000_0100,
                        VOTM_HSTR       = 10'b00_0000_1000,
                        VOTM_HACT       = 10'b00_0001_0000,
                        VOTM_HEND       = 10'b00_0011_0000,
                        VOTM_HBLK       = 10'b00_0100_0000,
                        VOTM_BVBLK      = 10'b00_1000_0000,
                        VOTM_FEND_DLY   = 10'b01_0000_0000,
                        VOTM_FEND       = 10'b10_0000_0000;


//----------------------------------------------------------//
// REG/Wire declaration                                     //
//----------------------------------------------------------//

reg [ 9:0]              votm_cs;
reg [ 9:0]              votm_ns;
wire                    fstr_csm;
wire                    fend_csm;
wire                    hstr_csm;
wire                    hstr_nsm;
wire                    hact_csm;
wire                    hend_csm;
wire                    fvblk_csm;
wire                    bvblk_csm;
wire                    fstr_dly_csm;
wire                    fend_dly_csm;
wire                    hblk_csm;

wire                    fifo_rdy_nxt;
reg                     fifo_rdy;
wire                    sts_tm_nordy_nxt;
reg                     sts_tm_nordy;
wire                    sts_tm_empty_nxt;
reg                     sts_tm_empty;
wire                    sts_tm_noeof_nxt;
reg                     sts_tm_noeof;
wire                    sts_fifo_udf_nxt;
reg                     sts_fifo_udf;

wire                    tx_vld;                             // transimit valid: tvalid & tready

wire[FIFO_DW-1:0]       fifo_wd;

wire                    fifo_push;
wire[FIFO_AW-1:0]       fifo_waddr;

wire[FIFO_AW-1:0]       fifo_raddr;
wire                    fifo_pop_nxt;
reg                     fifo_pop;
reg [ 1:0]              fifo_pop_q;
wire[FIFO_AW  :0]       fifo_lvl;                           // FIFO level
wire                    fifo_full;
wire                    fifo_empty;

wire                    fifo_ren;
reg                     fifo_ren_q;
wire[FIFO_DW-1:0]       fifo_rd;
wire[FIFO_DW-1:0]       rd_que_nxt;
wire[FIFO_DW-1:0]       rd_que;
wire                    rd_vld;

wire                    pop_vstr;
wire                    pop_hstr;
wire                    pop_str;
reg [ 3:0]              pop_str_q;
wire                    pop_vld_nxt;
reg                     pop_vld;
wire                    pop_vld_exd_nxt;
reg                     pop_vld_exd;
wire                    pop_cyc_str;
reg [ 1:0]              pop_vld_q;
reg [VODW-1:0]          unpkd_nxt;
reg [VODW-1:0]          unpkd;


wire                    xi_cnt_inc;
wire                    xi_cnt_clr;
wire[XWID-1:0]          xi_cnt_nxt;
reg [XWID-1:0]          xi_cnt;
wire                    yi_cnt_inc;
wire                    yi_cnt_clr;
wire[XWID-1:0]          yi_cnt_nxt;
reg [XWID-1:0]          yi_cnt;
wire[XWID-1:0]          xyi_cnt;
wire                    xo_cnt_inc;
wire                    xo_cnt_clr;
wire[XWID-1:0]          xo_cnt_nxt;
reg [XWID-1:0]          xo_cnt;
reg [XWID-1:0]          xo_cnt_q[2:0];

wire[XWID-1:0]          hact_len_nxt;
reg [XWID-1:0]          hact_len;
wire[XWID-1:0]          vact_len_nxt;
reg [XWID-1:0]          vact_len;

wire                    ivfblk_tm_nxt;
reg                     ivfblk_tm;
wire                    ivbblk_tm_nxt;
reg                     ivbblk_tm;
wire                    ivsync_tm_nxt;
reg                     ivsync_tm;

wire                    fsyn_dly_eq;
wire                    hact_len_eq;
reg [ 3:0]              hact_len_eq_q;
wire[XWID-1:0]          ivstr2pop_dly_nxt;
reg [XWID-1:0]          ivstr2pop_dly;
wire                    pop2vo_sig;
wire                    hacto_end;

reg [PKD_SZ-1:0]        unpkd_msb_nxt;
reg [PKD_SZ-1:0]        unpkd_msb;
wire[ 7: 0]             unpkd_lsb_nxt;
reg [ 7: 0]             unpkd_lsb;
reg [ 7: 0]             upk_lsb_muxd;

wire                    pkt_cnt_inc;
wire                    pkt_cnt_clr;
wire[PKC_DW-1:0]        pkt_cnt_nxt;
reg [PKC_DW-1:0]        pkt_cnt;
reg [PKC_DW-1:0]        pkt_cnt_q[2:0];

wire                    sxa_fstr;
integer                 i;

//----------------------------------------------------------//
// Code Descriptions                                        //
//----------------------------------------------------------//

// AXI4-Stream interface
// =========================================================

// AXI4-stream io
// ---------------------------

assign  tx_vld = tvalid & tready;

assign  tready = ~fifo_full;
assign  tuser  = sxa_fstr;


// FIFO Write
// ---------------------------

assign  fifo_push = tx_vld;
assign  fifo_wd   = tdata;


// Video input timing
// =========================================================

assign  xi_cnt_inc  = i_href & ~i_hend;
assign  yi_cnt_inc  = i_hstr;

assign  xi_cnt_clr  = i_fstr | i_hstr;
assign  yi_cnt_clr  = i_fstr;

assign  xi_cnt_nxt  = (xi_cnt_inc ? xyi_cnt : xi_cnt) & {XWID{~xi_cnt_clr}};
assign  yi_cnt_nxt  = (yi_cnt_inc ? xyi_cnt : yi_cnt) & {XWID{~yi_cnt_clr}};

assign  xyi_cnt     = (yi_cnt_inc ? yi_cnt : xi_cnt) + 1'b1;

assign  hact_len_nxt= (i_hend ? xi_cnt : hact_len) | {XWID{i_hstr}};
assign  vact_len_nxt= (i_vend ? yi_cnt : vact_len) | {XWID{i_fstr}};

assign  ivfblk_tm_nxt = (i_fstr | ivfblk_tm) & ~i_vstr;
assign  ivbblk_tm_nxt = (i_vend | ivbblk_tm) & ~i_fend;
assign  ivsync_tm_nxt = (i_fend | ivsync_tm) & ~i_fstr;


// Video output timing
// =========================================================

assign  fsyn_dly_eq = xo_cnt == VSYN_DLY - 1;
assign  hact_len_eq = ivstr2pop_dly != 0 ? (xo_cnt == hact_len) : i_hend;

assign  xo_cnt_inc  = fstr_dly_csm | pop_vld | fend_dly_csm;
assign  xo_cnt_clr  = i_fstr | pop_str | o_vend;
assign  xo_cnt_nxt  = (xo_cnt_inc ? xo_cnt + 1'b1 : xo_cnt) & {XWID{~xo_cnt_clr}};


//video conversion operating status
// ---------------------------

assign  o_vcnv_sts = {sts_tm_noeof,
                      sts_fifo_udf,
                      sts_tm_empty,
                      sts_tm_nordy,
                      fifo_rdy};

assign  fifo_rdy_nxt     = ((fifo_lvl > FIFO_RDY_LVL) | fifo_rdy) & ~o_vend;

assign  sts_tm_nordy_nxt = ((i_hstr & ~fifo_rdy)   | sts_tm_nordy) & ~i_fend;
assign  sts_tm_empty_nxt = ((i_hstr &  fifo_empty) | sts_tm_empty) & ~i_fend;
assign  sts_fifo_udf_nxt = ((fifo_empty & pop_vld) | sts_fifo_udf) & ~i_fend;
assign  sts_tm_noeof_nxt = ((~bvblk_csm & i_fend)  | sts_tm_noeof) & ~i_vend;

// State machine
// ---------------------------

assign  o_fstr     = fstr_csm;
assign  o_fend     = fend_csm;
assign  o_vstr_nxt = fvblk_csm & hstr_nsm;
assign  o_vend     = hend_csm & (ivbblk_tm | ivsync_tm);
assign  o_hstr     = hstr_csm;
assign  o_hend     = hend_csm;
assign  o_href     = hact_csm;

assign  fstr_csm     = votm_cs[1];
assign  fend_csm     = votm_cs[9];
assign  hstr_csm     = votm_cs[3];
assign  hstr_nsm     = votm_ns[3];
assign  hact_csm     = votm_cs[4];
assign  hend_csm     = votm_cs[5];

assign  fvblk_csm    = votm_cs[2];
assign  bvblk_csm    = votm_cs[7];
assign  fstr_dly_csm = votm_cs[0];
assign  fend_dly_csm = votm_cs[8];
assign  hblk_csm     = votm_cs[6];


always @* begin: VO_TM_FSM

   votm_ns = votm_cs;

   case (votm_cs)

   VOTM_IDLE:
      if (i_fstr)
         votm_ns = VSYN_DLY != 0 ? VOTM_FSTR_DLY : VOTM_FSTR;

   VOTM_FSTR_DLY:
      if (fsyn_dly_eq)
         votm_ns = VOTM_FSTR;

   VOTM_FSTR:
         votm_ns = VOTM_FVBLK;

   VOTM_FVBLK:
      if (pop2vo_sig)
         votm_ns = VOTM_HSTR;

   VOTM_HSTR:
         votm_ns = VOTM_HACT;

   VOTM_HACT:
      if (hacto_end)
         votm_ns = VOTM_HEND;

   VOTM_HEND:
      if (ivbblk_tm & ~i_fend)      // o_vend is before i_fend
         votm_ns = VOTM_BVBLK;
      else if (ivsync_tm | i_fend)  // o_vend is after i_fend
         votm_ns = VOTM_FEND_DLY;
      else
         votm_ns = VOTM_HBLK;

   VOTM_HBLK:
      if (pop2vo_sig)
         votm_ns = VOTM_HSTR;

   VOTM_BVBLK:
      if (i_fend)
         votm_ns = VSYN_DLY != 0 ? VOTM_FEND_DLY : VOTM_FEND;

   VOTM_FEND_DLY:
      if (fsyn_dly_eq)
         votm_ns = VOTM_FEND;

   VOTM_FEND:
         votm_ns = VOTM_IDLE;

   endcase
end

`always_ff(pclk, prst_n) begin
   if (~prst_n)
      votm_cs       <= VOTM_IDLE;
   else
      votm_cs       <= votm_ns;
end


// FIFO Read
// ---------------------------

assign  fifo_ren = fifo_rdy;

    // read data valid is 2T latency behind fifo_pop
assign  rd_vld   = fifo_pop_q[1];


assign  pop_vstr = (ivfblk_tm & fifo_ren & i_vstr) | (~ivfblk_tm & (fifo_ren & ~fifo_ren_q));
assign  pop_hstr = hblk_csm & (ivstr2pop_dly != 0 ? xi_cnt == ivstr2pop_dly : i_hstr);
assign  pop_str  = pop_vstr | pop_hstr;

assign  pop_vld_nxt = (pop_str | pop_vld) & ~((hact_len_eq | pop_vld_exd) & pop_cyc_str);
    // pop cycle extend due to HWIN is not multiple of pop cycle length at some cases
assign  pop_vld_exd_nxt = ((hact_len_eq & ~pop_cyc_str) | pop_vld_exd) & ~pop_cyc_str;

    // latch delay value from i_vstr to pop_vstr;
    // the value is used for the reference of delay from i_hstr to pop_hstr
assign  ivstr2pop_dly_nxt = pop_vstr ? xi_cnt : ivstr2pop_dly;
    // from fifo_pop to video output signal indication
assign  pop2vo_sig = PACK8N == "P2B" && PXDW == 10 && PX_RATE == 1 ? pop_str_q[3]     : pop_str_q[2];
assign  hacto_end  = PACK8N == "P2B" && PXDW == 10 && PX_RATE == 1 ? hact_len_eq_q[3] : hact_len_eq_q[2];

// Data Un-packing
// ---------------------------

generate

if (PACK8N == "P2B") begin: gen_pack_p2b

case(PXDW)

// ---------------------------
   5'd10: begin

      if (PX_RATE == 1) begin: gen_px1
// PX_RATE == 1
always @* begin

   unpkd_msb_nxt = 0;

   case(xo_cnt_q[2][3:0])
   4'b0000: unpkd_msb_nxt = {       fifo_rd[ 0 +: 32], unpkd_msb[ 8 +:  8]};

   4'b0100: unpkd_msb_nxt = { 8'h0, fifo_rd[ 8 +: 24], unpkd_msb[ 8 +:  8]};
   4'b0101: unpkd_msb_nxt = { 8'h0, fifo_rd[ 0 +:  8], unpkd_msb[ 8 +: 24]};

   4'b1000: unpkd_msb_nxt = {16'h0, fifo_rd[16 +: 16], unpkd_msb[ 8 +:  8]};
   4'b1001: unpkd_msb_nxt = { 8'h0, fifo_rd[ 0 +: 16], unpkd_msb[ 8 +: 16]};

   4'b1100: unpkd_msb_nxt = {24'h0, fifo_rd[24 +:  8], unpkd_msb[ 8 +:  8]};
   4'b1101: unpkd_msb_nxt = { 8'h0, fifo_rd[ 0 +: 24], unpkd_msb[ 8 +:  8]};

   default: unpkd_msb_nxt = { 8'h0, unpkd_msb[39: 8]};

   endcase
end

assign  unpkd_lsb_nxt = xo_cnt_q[2][1:0] == 1 ? upk_lsb_muxd : {2'h0, unpkd_lsb[7 : 2]};

always @* begin

   upk_lsb_muxd = 0;

   case(xo_cnt_q[2][3:2])
   2'b00: upk_lsb_muxd = fifo_rd[8*0 +:  8];
   2'b01: upk_lsb_muxd = fifo_rd[8*1 +:  8];
   2'b10: upk_lsb_muxd = fifo_rd[8*2 +:  8];
   2'b11: upk_lsb_muxd = fifo_rd[8*3 +:  8];
   endcase
end

assign  pop_cyc_str  = xo_cnt_nxt[3:0] ==  0;

assign  fifo_pop_nxt = (xo_cnt_nxt[3:0] ==  0 ||
                        xo_cnt_nxt[3:0] ==  1 ||
                        xo_cnt_nxt[3:0] ==  5 ||
                        xo_cnt_nxt[3:0] ==  9 ||
                        xo_cnt_nxt[3:0] == 13) & pop_vld & ~fifo_empty;
assign  o_pdat       = {unpkd_msb[7:0], unpkd_lsb[1:0]};

      end
      else  begin: gen_px2
// PX_RATE == 2
always @* begin

   unpkd_msb_nxt = 0;

   case(xo_cnt_q[2][3:0])
   4'b0000: unpkd_msb_nxt = {16'h0,             fifo_rd[ 0 +: 32]};
   4'b0001: unpkd_msb_nxt = { 8'h0,             fifo_rd[40 +: 24], unpkd_msb[16 +: 16]};

   4'b0011: unpkd_msb_nxt = {fifo_rd[16 +: 32], fifo_rd[ 0 +:  8], unpkd_msb[16 +:  8]};
   4'b0101: unpkd_msb_nxt = {24'h0,             fifo_rd[56 +:  8], unpkd_msb[16 +: 16]};

   4'b0110: unpkd_msb_nxt = {16'h0,             fifo_rd[ 0 +: 24], unpkd_msb[16 +:  8]};
   4'b0111: unpkd_msb_nxt = {                   fifo_rd[32 +: 32], unpkd_msb[16 +: 16]};

   4'b1010: unpkd_msb_nxt = {16'h0,             fifo_rd[ 8 +: 32]};
   4'b1011: unpkd_msb_nxt = {16'h0,             fifo_rd[48 +: 16], unpkd_msb[16 +: 16]};

   4'b1101: unpkd_msb_nxt = {                   fifo_rd[24 +: 32], fifo_rd  [ 0 +: 16]};

   default: unpkd_msb_nxt = {16'h0, unpkd_msb[47:16]};

   endcase
end

assign  unpkd_lsb_nxt = xo_cnt_q[2][0] == 0 ? upk_lsb_muxd : {4'h0, unpkd_lsb[7 : 4]};

always @* begin

   upk_lsb_muxd = 0;

   case(xo_cnt_q[2][3:1])
   3'b000: upk_lsb_muxd = fifo_rd[8*4 +:  8];
   3'b001: upk_lsb_muxd = fifo_rd[8*1 +:  8];
   3'b010: upk_lsb_muxd = fifo_rd[8*6 +:  8];
   3'b011: upk_lsb_muxd = fifo_rd[8*3 +:  8];
   3'b100: upk_lsb_muxd = fifo_rd[8*0 +:  8];
   3'b101: upk_lsb_muxd = fifo_rd[8*5 +:  8];
   3'b110: upk_lsb_muxd = fifo_rd[8*2 +:  8];
   3'b111: upk_lsb_muxd = fifo_rd[8*7 +:  8];
   endcase
end

assign  pop_cyc_str  = xo_cnt_nxt[3:0] ==  0;

assign  fifo_pop_nxt = (xo_cnt_nxt[3:0] ==  0 ||
                        xo_cnt_nxt[3:0] ==  2 ||
                        xo_cnt_nxt[3:0] ==  6 ||
                        xo_cnt_nxt[3:0] ==  8 ||
                        xo_cnt_nxt[3:0] == 12) & pop_vld & ~fifo_empty;
assign  o_pdat       = {unpkd_msb[15: 8], unpkd_lsb[3:2],
                        unpkd_msb[ 7: 0], unpkd_lsb[1:0]};

      end

   end

// ---------------------------
   5'd12: begin

      if (PX_RATE == 1) begin: gen_px1
// PX_RATE == 1
always @* begin

   unpkd_msb_nxt = 0;

   case(xo_cnt_q[2][2:0])
   3'b000: unpkd_msb_nxt  = {8'h0, fifo_rd[ 0 +: 16]};
   3'b001: unpkd_msb_nxt  = {8'h0, fifo_rd[24 +:  8], unpkd_msb[ 8 +:  8]};

   3'b011: unpkd_msb_nxt  = {      fifo_rd[16 +: 16], fifo_rd  [ 0 +:  8]};
   3'b110: unpkd_msb_nxt  = {8'h0, fifo_rd[ 8 +: 16]};

   default: unpkd_msb_nxt = {8'h0, unpkd_msb[23: 8]};

   endcase
end

assign  unpkd_lsb_nxt = xo_cnt_q[2][0] == 0 ? upk_lsb_muxd : {4'h0, unpkd_lsb[7 : 4]};

always @* begin

   upk_lsb_muxd = 0;

   case(xo_cnt_q[2][2:1])
   2'b00: upk_lsb_muxd = fifo_rd[8*2 +:  8];
   2'b01: upk_lsb_muxd = fifo_rd[8*1 +:  8];
   2'b10: upk_lsb_muxd = fifo_rd[8*0 +:  8];
   2'b11: upk_lsb_muxd = fifo_rd[8*3 +:  8];
   endcase
end

assign  pop_cyc_str  = xo_cnt_nxt[2:0] ==  0;

assign  fifo_pop_nxt = (xo_cnt_nxt[2:0] ==  0 ||
                        xo_cnt_nxt[2:0] ==  2 ||
                        xo_cnt_nxt[2:0] ==  4) & pop_vld & ~fifo_empty;
assign  o_pdat       = {unpkd_msb[7:0], unpkd_lsb[3:0]};

      end
      else  begin: gen_px2
// PX_RATE == 2
always @* begin

   unpkd_msb_nxt = 0;

   case(xo_cnt_q[2][2:0])
   3'b000: unpkd_msb_nxt  = {16'h0, fifo_rd[ 0 +: 16]};
   3'b001: unpkd_msb_nxt  = {       fifo_rd[48 +: 16], fifo_rd  [24 +: 16]};

   3'b011: unpkd_msb_nxt  = {16'h0, fifo_rd[ 8 +: 16]};
   3'b100: unpkd_msb_nxt  = { 8'h0, fifo_rd[56 +:  8], fifo_rd  [32 +: 16]};

   3'b101: unpkd_msb_nxt  = {16'h0, fifo_rd[ 0 +:  8], unpkd_msb[16 +:  8]};
   3'b110: unpkd_msb_nxt  = {       fifo_rd[40 +: 16], fifo_rd  [16 +: 16]};

   default: unpkd_msb_nxt = {16'h0, unpkd_msb[31:16]};

   endcase
end

assign  unpkd_lsb_nxt = upk_lsb_muxd;

always @* begin

   upk_lsb_muxd = 0;

   case(xo_cnt_q[2][2:0])
   3'b000: upk_lsb_muxd = fifo_rd[8*2 +:  8];
   3'b001: upk_lsb_muxd = fifo_rd[8*5 +:  8];
   3'b010: upk_lsb_muxd = fifo_rd[8*0 +:  8];
   3'b011: upk_lsb_muxd = fifo_rd[8*3 +:  8];
   3'b100: upk_lsb_muxd = fifo_rd[8*6 +:  8];
   3'b101: upk_lsb_muxd = fifo_rd[8*1 +:  8];
   3'b110: upk_lsb_muxd = fifo_rd[8*4 +:  8];
   3'b111: upk_lsb_muxd = fifo_rd[8*7 +:  8];
   endcase
end

assign  pop_cyc_str  = xo_cnt_nxt[2:0] ==  0;

assign  fifo_pop_nxt = (xo_cnt_nxt[2:0] ==  0 ||
                        xo_cnt_nxt[2:0] ==  2 ||
                        xo_cnt_nxt[2:0] ==  5) & pop_vld & ~fifo_empty;
assign  o_pdat       = {unpkd_msb[15: 8], unpkd_lsb[7:4],
                        unpkd_msb[ 7: 0], unpkd_lsb[3:0]};

      end

   end

// ---------------------------

   default: begin // PXDW == 8, 16

always @*
      unpkd_nxt = fifo_rd[xo_cnt_q[2][PKC_DW-1:0]*VODW +: VODW];
//   unpkd_nxt = xo_cnt_q[1][log2(AIDW/VODW)-1:0] == 0 ? fifo_rd : {{VODW{1'b0}}, unpkd[FIFO_DW-1:VODW]};

assign  pop_cyc_str  = xo_cnt_nxt[PKC_DW-1:0] == 0;
assign  fifo_pop_nxt = (pop_cyc_str & pop_vld) & ~fifo_empty;
assign  o_pdat       = unpkd;

   end

endcase

end // gen_pack_p2b
else begin: gen_pack_pad

assign  pkt_cnt_inc = pop_vld;
assign  pkt_cnt_clr = pop_str | (pkt_cnt == PKC_SZ-1);
assign  pkt_cnt_nxt = (pkt_cnt_inc ? pkt_cnt + 1'b1 : pkt_cnt) & {PKC_DW{~pkt_cnt_clr}};

always @*
      unpkd_nxt = fifo_rd[pkt_cnt_q[2]*VODW +: VODW];

assign  pop_cyc_str  = pkt_cnt_nxt == 0;
assign  fifo_pop_nxt = pop_cyc_str & pop_vld & ~fifo_empty;
assign  o_pdat       = unpkd;

end

endgenerate


generate
if (FIFO_CDC == "ASYNC") begin: gen_cdc

ip_cdcpus #(.IN_TYPE        ("PULSE"),
            .SAMPLE_EDGE    ("RISE"))
fstri_sx (
            // output
            .pus_ckosyn     (sxa_fstr),
            // input
            .in_cki         (fstr_csm),
            .clki           (pclk),
            .clko           (aclk),
            .irst_n         (prst_n),
            .orst_n         (aresetn));

end
else begin: gen_wire

assign  sxa_fstr = fstr_csm;

end
endgenerate


// Sequential Logic
// -----------------------------------------------
/*
`always_ff(aclk, aresetn) begin
   if(~aresetn) begin
      fifo_push     <= 0;
      fifo_wd       <= 0;
   end
   else begin
      fifo_push     <= fifo_push_nxt;
      fifo_wd       <= fifo_wd_nxt;
   end
end
*/

`always_ff(pclk, prst_n) begin
   if(~prst_n) begin
      xi_cnt        <= 0;
      yi_cnt        <= 0;
      hact_len      <= 0;
      vact_len      <= 0;
      ivfblk_tm     <= 0;
      ivbblk_tm     <= 0;
      ivsync_tm     <= 0;
      xo_cnt        <= 0;
      o_vstr        <= 0;
      fifo_rdy      <= 0;
      sts_fifo_udf  <= 0;
      sts_tm_nordy  <= 0;
      sts_tm_empty  <= 0;
      sts_fifo_udf  <= 0;
      sts_tm_noeof  <= 0;
      pop_vld       <= 0;
      pop_vld_exd   <= 0;
      fifo_pop      <= 0;
      unpkd         <= 0;
      ivstr2pop_dly <= 0;
      unpkd_msb     <= 0;
      unpkd_lsb     <= 0;
      pkt_cnt       <= 0;
      fifo_ren_q    <= 0;
      hact_len_eq_q <= 0;
      pop_str_q     <= 0;
      pop_vld_q     <= 0;
      fifo_pop_q    <= 0;
      xo_cnt_q[0]   <= 0;
      xo_cnt_q[1]   <= 0;
      xo_cnt_q[2]   <= 0;
      pkt_cnt_q[0]  <= 0;
      pkt_cnt_q[1]  <= 0;
      pkt_cnt_q[2]  <= 0;
   end
   else begin
      xi_cnt        <= xi_cnt_nxt;
      yi_cnt        <= yi_cnt_nxt;
      hact_len      <= hact_len_nxt;
      vact_len      <= vact_len_nxt;
      ivfblk_tm     <= ivfblk_tm_nxt;
      ivbblk_tm     <= ivbblk_tm_nxt;
      ivsync_tm     <= ivsync_tm_nxt;
      xo_cnt        <= xo_cnt_nxt;
      o_vstr        <= o_vstr_nxt;
      fifo_rdy      <= fifo_rdy_nxt;
      sts_fifo_udf  <= sts_fifo_udf_nxt;
      sts_tm_nordy  <= sts_tm_nordy_nxt;
      sts_tm_empty  <= sts_tm_empty_nxt;
      sts_fifo_udf  <= sts_fifo_udf_nxt;
      sts_tm_noeof  <= sts_tm_noeof_nxt;
      pop_vld       <= pop_vld_nxt;
      pop_vld_exd   <= pop_vld_exd_nxt;
      fifo_pop      <= fifo_pop_nxt;
      unpkd         <= unpkd_nxt;
      ivstr2pop_dly <= ivstr2pop_dly_nxt;
      unpkd_msb     <= unpkd_msb_nxt;
      unpkd_lsb     <= unpkd_lsb_nxt;
      pkt_cnt       <= pkt_cnt_nxt;
      fifo_ren_q    <= fifo_ren;
      hact_len_eq_q <= {hact_len_eq_q[2], hact_len_eq_q[1], hact_len_eq_q[0], hact_len_eq};
      pop_str_q     <= {pop_str_q[2], pop_str_q[1], pop_str_q[0], pop_str};
      pop_vld_q     <= {pop_vld_q[0], pop_vld};
      fifo_pop_q    <= {fifo_pop_q[0], fifo_pop};
      xo_cnt_q[0]   <= xo_cnt;
      xo_cnt_q[1]   <= xo_cnt_q[0];
      xo_cnt_q[2]   <= xo_cnt_q[1];
      pkt_cnt_q[0]  <= pkt_cnt;
      pkt_cnt_q[1]  <= pkt_cnt_q[0];
      pkt_cnt_q[2]  <= pkt_cnt_q[1];
   end
end



//----------------------------------------------------------//
// Module Instance                                          //
//----------------------------------------------------------//

ip_fifo_ctrl
#(          .FIFO_DEP       (FIFO_DEP),
            .FIFO_CDC       (FIFO_CDC),
            .DEP_CAL_EN     (1))

fifo_ctrl (

            //output
            .waddr          (fifo_waddr),
            .raddr          (fifo_raddr),
            .ff_nfull       (),
            .ff_full        (fifo_full),
            .ff_nempty      (),
            .ff_empty       (fifo_empty),
            .fifo_lvl_rck   (fifo_lvl),
            .fifo_free_wck  (),

            //input
            .push           (fifo_push),
            .pop            (fifo_pop),
            .wflush         (sxa_fstr),
            .rflush         (i_fstr),
            .wclk           (aclk),
            .rclk           (pclk),
            .wrst_n         (aresetn),
            .rrst_n         (prst_n)
            );


ip_fmem
#(          .MEM_DEP        (FIFO_DEP),
            .MEM_DW         (FIFO_DW),
            .MEM_TYPE       (FIFO_TYPE),
            .FFO_EN         (1))

fifo_ram (

            //output
            .doa            (),
            .dob            (fifo_rd),

            //input
            .wea            (fifo_push),
            .ena            (fifo_push),
            .enb            (fifo_ren),
            .clra           (1'b0),
            .clrb           (1'b0),
            .addra          (fifo_waddr),
            .addrb          (fifo_raddr),
            .dia            (fifo_wd),
            .clka           (aclk),
            .clkb           (pclk),
            .arst_n         (aresetn),
            .brst_n         (prst_n)
            );


//----------------------------------------------------------//
// Debuging Probe                                           //
//----------------------------------------------------------//
// Note: clock signal connected to the debug core should be clean and free-running.

generate

if (ILA_DBG_EN) begin: gen_ila

dbg_ila_8x8   csi_obuf_ila (
  .clk              (),
  .probe0           (),
  .probe1           (),
  .probe2           (),
  .probe3           (),
  .probe4           (),
  .probe5           (),
  .probe6           (),
  .probe7           ()
);
end
endgenerate


// Function
// -----------------------------------------------

function integer log2;
   input integer value;
   begin
      log2 = 0;
      while (2**log2 < value)
         log2 = log2 + 1;
   end
endfunction


endmodule
