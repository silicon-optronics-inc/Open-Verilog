// +FHDR -----------------------------------------------------------------------
// Copyright (c) Silicon Optronics. Inc. 2020
//
// File Name:           ip_v2axi4s_m_rtl.v
// Author:              Humphrey Lin
//
// File Description:    1. video to AXI4-stream master
//                      2. input and output data bus width can be different,
//                         width of output data, tdata >= i_pdat
//                      3. packet format [PACK8N = "P2B"]:
//                         pix8-to-byte4 : {P3, P2, P1, P0}
//                         pix10-to-byte4: msb8{P3, P2, P1, P0},
//                                         msb8{P6, P5, P4}, lsb2{P3, P2, P1, P0}
//                         pix12-to-byte4: msb8{P2}, lsb2{P1, P0}, msb8{P1, P0},
//                                         msb8{P5, P4}, lsb2{P3, P2}, msb8{P3}
//                         pix16-to-byte4: {P1, P0}, {P3, P2}
// -FHDR -----------------------------------------------------------------------

module v2axi4s_m

#(
parameter                       PXDW            = 10,       // pixel data width: 8, 10, 12, 16
parameter[ 1:0]                 PX_RATE         = 1,        // pixel number: 1, 2
parameter                       VIDW            = PXDW*PX_RATE,// video input data width
parameter                       AODW            = 32,       // AXI output data width 8*n, AODW >= VIDW
parameter                       AUDW            = 3,        // AXI user defined sideband data width

                                                            // "P2B": re-pack pixel to byte alligned format
                                                            //        AODW = 32 if PX_RATE==1;
                                                            //        AODW = 64 if PX_RATE==2
parameter                       PACK8N          = "P2B",    // "PAD": padding msb zero if VIDW*n < AODW
parameter                       FIFO_DEP        = 8,        // FIFO depth 2^N
parameter                       FIFO_CDC        = "ASYNC",  // "SYNC" or "ASYNC"
parameter                       FIFO_TYPE       = "FPGA_BLKRAM",

parameter                       ILA_DBG_EN      = 0         // ILA debug enable/disable
 )

(
//----------------------------------------------------------//
// AXI4-Stream interface                                    //
//----------------------------------------------------------//
output      [AODW-1:0]          tdata,
output reg                      tvalid,
output                          tlast,
input                           tready,
output      [AUDW-1:0]          tuser,                      // {sof, sol, eol}

input                           aclk,
input                           aresetn,                    // active-low reset

//----------------------------------------------------------//
// Native video input interface                             //
//----------------------------------------------------------//
input                           i_fstr,                     //
input                           i_fend,                     //
input                           i_hstr,                     //
input                           i_hend,                     //
input                           i_href,                     //
input       [VIDW-1:0]          i_pdat,                     // input pixel data
input                           i_vin_en,                   // be treated as FIFO write enable
input                           pclk,                       // pclk for input data domain
input                           prst_n,                     // reset @pclk clock domain

//----------------------------------------------------------//
// Common interface                                         //
//----------------------------------------------------------//
output                          o_fifo_nfull,
output                          o_fifo_empty

);

//----------------------------------------------------------//
// Local Parameter                                          //
//----------------------------------------------------------//

localparam              QUE_DW          = PACK8N == "PAD" ? (AODW/VIDW)*VIDW : AODW;// Queue data width

localparam              FIFO_AW         = log2(FIFO_DEP);
localparam              FIFO_DW         = QUE_DW + 1;       // +1 for companion sync signal

localparam              PKD_SZ          = (PXDW < 16  ?  8 : // packet data size
                                           PXDW < 32  ? 16 : 32)*PX_RATE;

localparam              PKC_SZ          = AODW/(PKD_SZ/PX_RATE);      // packet counter size
localparam              PKC_DW          = log2(PKC_SZ);

//----------------------------------------------------------//
// REG/Wire declaration                                     //
//----------------------------------------------------------//

//
wire [VIDW-1:0]         pdat_mx;

reg [ 1:0]              vi_hcnt_lsb;                        // pixel counter on LSB part
wire[ 1:0]              vi_hcnt_lsb_nxt;
wire                    vi_hcnt_lsb_inc;
wire                    vi_hcnt_lsb_clr;

reg                     hsyn_mark;                          // h-line sync marker to indicate hstr or hend
wire                    hsyn_mark_nxt;
reg                     fm_vin_en;                          // frame input enable
wire                    fm_vin_en_nxt;


reg [PKC_DW-1:0]        pkt_cnt;                            // packet counter
wire[PKC_DW-1:0]        pkt_cnt_nxt;
wire                    pkt_cnt_inc;
wire                    pkt_cnt_clr;

reg [ 7:0]              pkt_lsb;                            // LSB-part packet
wire[ 7:0]              pkt_lsb_nxt;
reg                     lsb_lat_en;
wire                    lsb_lat_en_nxt;
wire                    pkt_lsb_vld_nxt;
reg                     pkt_lsb_vld;

wire                    pkt_cyc_end;
wire                    pkt_vld;
reg [ 7:0]              pkt_ovf_dat;
wire[ 7:0]              pkt_ovf_dat_nxt;
reg                     pkt_ovf_vld;
wire                    pkt_ovf_vld_nxt;

reg [QUE_DW-1:0]        px_que;                             // pixel que
reg [QUE_DW-1:0]        px_que_nxt;

wire[FIFO_DW-1:0]       fifo_wd;
reg                     fifo_push;
wire                    fifo_push_nxt;
wire[FIFO_AW-1:0]       fifo_waddr;

//
wire[FIFO_AW-1:0]       fifo_raddr;
wire                    fifo_empty;
wire[FIFO_DW-1:0]       fifo_rd;

reg                     fifo_pop_en;
wire                    fifo_pop_en_nxt;
wire                    fifo_pop;
reg [1:0]               fifo_pop_q;
wire[1:0]               fifo_pop_q_nxt;
reg [1:0]               tready_q;
wire[1:0]               tready_q_nxt;
wire                    tready_f;
wire                    tready_f_q;

reg                     fifo_ren;
wire                    fifo_ren_nxt;

wire                    rd_vld;                             // read data valid

reg                     que0_vld;
wire                    que0_vld_nxt;
reg                     que1_vld;
wire                    que1_vld_nxt;

reg [FIFO_DW-1:0]       rd_que[0:1];
wire[FIFO_DW-1:0]       rd_que_nxt[0:1];

reg                     que_sel;
wire                    que_sel_nxt;

reg [FIFO_DW-1:0]       stm_dat;                            // stream data
wire[FIFO_DW-1:0]       stm_dat_nxt;
wire                    stm_scode;                          // stream sync code

wire                    tvalid_nxt;
wire                    tx_vld;                             // transimit valid: tvalid & tready

reg                     lact;                               // line active
wire                    lact_nxt;
reg                     sof;                                // start of frame
wire                    sof_nxt;
reg                     sol;                                // start of line
wire                    sol_nxt;
reg                     eol;                                // end of line
wire                    eol_nxt;

wire                    sxa_fstr;
wire                    sxa_fend;
wire                    sxa_hstr;
wire                    sxa_hend;

wire[4:0]               pkt_md;                             // for monitor module reference

//----------------------------------------------------------//
// Code Descriptions                                        //
//----------------------------------------------------------//


// Packing input data
// =========================================================

// pixel input reference signals
// ---------------------------

assign  vi_hcnt_lsb_inc = i_href;
assign  vi_hcnt_lsb_clr = i_hend;
assign  vi_hcnt_lsb_nxt = (vi_hcnt_lsb_inc ? vi_hcnt_lsb + 1'b1 : vi_hcnt_lsb) & {2{~vi_hcnt_lsb_clr}};

assign  hsyn_mark_nxt   = ~hsyn_mark ? i_hstr | i_hend : ~fifo_push;


// FIFO Write
// ---------------------------

assign  fm_vin_en_nxt = ((i_vin_en & i_fstr) | fm_vin_en) & ~(~i_vin_en & i_fstr);

assign  fifo_push_nxt = pkt_vld & fm_vin_en;
assign  fifo_wd       = {hsyn_mark, px_que};


// Data Packing
// ---------------------------

generate
if (PACK8N == "P2B") begin: gen_pack_p2b

assign  pkt_cnt_inc = i_href;
assign  pkt_cnt_clr = i_hend | pkt_cyc_end;
assign  pkt_cnt_nxt = (pkt_cnt_inc ? pkt_cnt + PX_RATE + lsb_lat_en : pkt_cnt) &
                      {PKC_DW{~pkt_cnt_clr}};

assign  pkt_cyc_end = (pkt_cnt == 3*PX_RATE-1) & lsb_lat_en & i_href;

// pkt_lsb_vld: i_hend is for PXDW=12 & PX_RATE=2
assign  pkt_lsb_vld_nxt = ~pkt_lsb_vld ? (lsb_lat_en & i_href) : ~((~lsb_lat_en | i_hend) & i_href);

assign  pkt_ovf_dat_nxt = PX_RATE == 2 ? pdat_mx[VIDW-1 -: 8] : 0;
assign  pkt_ovf_vld_nxt = PX_RATE == 2 ? pkt_cnt == 7 : 0;


case(PXDW)
   5'd8: begin
assign  pkt_md      = 8;
assign  pkt_lsb_nxt = 0;

assign  lsb_lat_en_nxt = 0;
assign  pkt_vld     = (pkt_cnt[PKC_DW-1 -: 2] == PKC_SZ/PX_RATE -1) & i_href;

always @*
   px_que_nxt = i_href ? {i_pdat[VIDW-1 -: PKD_SZ], px_que[QUE_DW-1 : PKD_SZ]} : px_que;

   end

   5'd10:begin
assign  pkt_md      = 10;
assign  pdat_mx     = PX_RATE == 2 ? {i_pdat[PXDW+2 +: 8],i_pdat[0+2 +: 8],i_pdat[PXDW +: 2],i_pdat[0 +: 2]} :
                                     i_pdat;

assign  pkt_lsb_nxt = i_href ? {pdat_mx[0 +: 2*PX_RATE], pkt_lsb[2*PX_RATE +: (8-2*PX_RATE)]} : pkt_lsb;

assign  lsb_lat_en_nxt = PX_RATE == 2 ? vi_hcnt_lsb_nxt[0] : vi_hcnt_lsb_nxt[1:0] == 3;
assign  pkt_vld     = ((pkt_cnt[PKC_DW-1 -: 2] == PKC_SZ/PX_RATE -1) | pkt_cyc_end) & i_href;

always @* begin

   px_que_nxt = 0;

   casez({i_href, pkt_ovf_vld_nxt, pkt_ovf_vld, pkt_lsb_vld, pkt_cyc_end}) // synopsys full_case
   5'b10000: px_que_nxt = {pdat_mx[VIDW-1          -: PKD_SZ],   px_que[QUE_DW-1 : PKD_SZ]};
   5'b11?00: px_que_nxt = {pdat_mx[VIDW-1-PKD_SZ/2 -: PKD_SZ/2], px_que[QUE_DW-1 : PKD_SZ/2]};

   5'b10010: px_que_nxt = {pdat_mx[VIDW-1          -: PKD_SZ],   pkt_lsb, px_que[QUE_DW-1 : PKD_SZ+8]};
   5'b11?10: px_que_nxt = {pdat_mx[VIDW-1-PKD_SZ/2 -: PKD_SZ/2], pkt_lsb, px_que[QUE_DW-1 : PKD_SZ/2+8]};

   5'b10100: px_que_nxt = {pdat_mx[VIDW-1 -: PKD_SZ], pkt_ovf_dat, px_que[QUE_DW-1 : PKD_SZ+8]};
   5'b10110: px_que_nxt = {pdat_mx[VIDW-1 -: PKD_SZ], pkt_lsb,     pkt_ovf_dat, px_que[QUE_DW-1 : PKD_SZ+16]};

   5'b100?1: px_que_nxt = {pkt_lsb_nxt, pdat_mx[VIDW-1 -: PKD_SZ], px_que[QUE_DW-1 : PKD_SZ+8]};

   5'b0????: px_que_nxt = px_que;
   endcase
end

   end

   5'd12:begin
assign  pkt_md      = 12;
assign  pdat_mx     = PX_RATE == 2 ? {i_pdat[PXDW+4 +: 8],i_pdat[0+4 +: 8],i_pdat[PXDW +: 4],i_pdat[0 +: 4]} :
                                      i_pdat;

assign  pkt_lsb_nxt = i_href ? (PX_RATE == 2 ? pdat_mx[0 +: 8] :
                                              {pdat_mx[0 +: 4], pkt_lsb[4 +: 4]}) : pkt_lsb;

assign  lsb_lat_en_nxt = PX_RATE == 2 ? (i_hstr | lsb_lat_en) & ~i_hend : vi_hcnt_lsb_nxt[0];
assign  pkt_vld     = ((pkt_cnt[PKC_DW-1 -: 2] == PKC_SZ/PX_RATE -1) | pkt_cyc_end) & i_href;

always @* begin

   px_que_nxt = 0;

   casez({i_href, pkt_ovf_vld_nxt, pkt_ovf_vld, pkt_lsb_vld, pkt_cyc_end}) // synopsys full_case
   5'b10000: px_que_nxt = {pdat_mx[VIDW-1          -: PKD_SZ],   px_que[QUE_DW-1 : PKD_SZ]};
   5'b11?00: px_que_nxt = {pdat_mx[VIDW-1-PKD_SZ/2 -: PKD_SZ/2], px_que[QUE_DW-1 : PKD_SZ/2]};

   5'b10010: px_que_nxt = {pdat_mx[VIDW-1          -: PKD_SZ],   pkt_lsb, px_que[QUE_DW-1 : PKD_SZ+8]};
   5'b11?10: px_que_nxt = {pdat_mx[VIDW-1-PKD_SZ/2 -: PKD_SZ/2], pkt_lsb, px_que[QUE_DW-1 : PKD_SZ/2+8]};

   5'b10100: px_que_nxt = {pdat_mx[VIDW-1 -: PKD_SZ], pkt_ovf_dat, px_que[QUE_DW-1 : PKD_SZ+8]};
   5'b10110: px_que_nxt = {pdat_mx[VIDW-1 -: PKD_SZ], pkt_lsb,     pkt_ovf_dat, px_que[QUE_DW-1 : PKD_SZ+16]};

   5'b1??01: px_que_nxt = {pkt_lsb_nxt, pdat_mx[VIDW-1 -: PKD_SZ], px_que[QUE_DW-1 : PKD_SZ+8]};
   5'b1??11: px_que_nxt = {pkt_lsb_nxt, pdat_mx[VIDW-1 -: PKD_SZ], pkt_lsb, px_que[QUE_DW-1 : PKD_SZ+16]};

   5'b0????: px_que_nxt = px_que;
   endcase
end

   end

   5'd16:begin
assign  pkt_md      = 16;
assign  pkt_lsb_nxt = 0;

assign  lsb_lat_en_nxt = 0;
assign  pkt_vld     = (pkt_cnt[PKC_DW-1 -: 1] == PKC_SZ/PX_RATE -1);

always @*
   px_que_nxt = {i_pdat[VIDW-1 -: PKD_SZ], px_que[QUE_DW-1 : PKD_SZ]};

   end
endcase

end // gen_pack_p2b

else begin: gen_pack_pad


assign  pkt_vld     = i_href;

assign  px_que_nxt  = {{QUE_DW-VIDW{1'b0}}, i_pdat};

assign  pkt_md      = 0;

end
endgenerate



// AXI4-Stream interface
// =========================================================

// FIFO Read
// ---------------------------

assign  o_fifo_empty    = fifo_empty;

assign  fifo_ren_nxt    = (fifo_pop_en_nxt | fifo_ren) & ~tlast;

assign  fifo_pop_en_nxt = ~fifo_empty & tready;
assign  fifo_pop        = fifo_pop_en & fifo_pop_en_nxt;    // delay 1-T after non-empty
assign  fifo_pop_q_nxt  = {fifo_pop_q[0], fifo_pop};

assign  tready_q_nxt  = {tready_q[0], tready};
assign  tready_f      = ~tready      & tready_q[0];
assign  tready_f_q    = ~tready_q[0] & tready_q[1];

assign  rd_vld          = fifo_pop_q[1];    // 2 clk latency due to SRAM read latency

    // queue to temporary store FIFO read data after pop disable
assign  que0_vld_nxt = ~que0_vld ? ~tready & rd_vld : ~(tready & ~que_sel);

assign  que1_vld_nxt = ~que1_vld ? que0_vld & rd_vld : ~(tready & que_sel);

assign  rd_que_nxt[0] = que0_vld_nxt & ~que0_vld ? fifo_rd : rd_que[0];
assign  rd_que_nxt[1] = que1_vld_nxt & ~que1_vld ? fifo_rd : rd_que[1];

assign  que_sel_nxt  = ~que_sel ? que0_vld & tready : ~tready;


// AXI4-stream output
// ---------------------------

assign  dato_vld   = (que0_vld & ~que_sel) | (que1_vld & que_sel) | rd_vld;
assign  tvalid_nxt = ~tvalid ? dato_vld & tready : ~(~dato_vld & tready);


assign  tx_vld     = tvalid & tready;

assign  stm_dat_nxt = tready ? (que0_vld & ~que_sel ? rd_que[0] :
                                que1_vld &  que_sel ? rd_que[1] :
                                rd_vld              ? fifo_rd   : stm_dat) : stm_dat;

assign  tdata = {{(AODW-(FIFO_DW-1)){1'b0}}, stm_dat[0 +: FIFO_DW-1]};

assign  stm_scode = stm_dat_nxt[FIFO_DW-1]; // ahead 1T to make F.F. output
assign  lact_nxt  = (sol | lact) & ~(sxa_fstr | eol);

assign  sof_nxt = (sxa_fstr | sof) & ~tx_vld;
// sol: // add rd_vld due to stm_scode is extended from prev end of line
assign  sol_nxt = ~sol ? ~lact & stm_scode & rd_vld : ~tx_vld;
assign  eol_nxt = ~eol ?  lact & stm_scode & ~stm_dat[FIFO_DW-1] : ~tx_vld;
assign  tuser = {sof, sol, eol};

assign  tlast = eol;

generate
if (FIFO_CDC == "ASYNC") begin: gen_cdc

ip_cdcpus #(.IN_TYPE        ("PULSE"),
            .SAMPLE_EDGE    ("RISE"))
fstri_sx (
            // output
            .pus_ckosyn     (sxa_fstr),
            // input
            .in_cki         (i_fstr),
            .clki           (pclk),
            .clko           (aclk),
            .irst_n         (prst_n),
            .orst_n         (aresetn));


ip_cdcpus #(.IN_TYPE        ("PULSE"),
            .SAMPLE_EDGE    ("RISE"))
fendi_sx (
            // output
            .pus_ckosyn     (sxa_fend),
            // input
            .in_cki         (i_fend),
            .clki           (pclk),
            .clko           (aclk),
            .irst_n         (prst_n),
            .orst_n         (aresetn));


ip_cdcpus #(.IN_TYPE        ("PULSE"),
            .SAMPLE_EDGE    ("RISE"))
hstri_sx (
            // output
            .pus_ckosyn     (sxa_hstr),
            // input
            .in_cki         (i_hstr),
            .clki           (pclk),
            .clko           (aclk),
            .irst_n         (prst_n),
            .orst_n         (aresetn));


ip_cdcpus #(.IN_TYPE        ("PULSE"),
            .SAMPLE_EDGE    ("RISE"))
hendi_sx (
            // output
            .pus_ckosyn     (sxa_hend),
            // input
            .in_cki         (i_hend),
            .clki           (pclk),
            .clko           (aclk),
            .irst_n         (prst_n),
            .orst_n         (aresetn));

end
else begin: gen_wire

assign  sxa_fstr = i_fstr;
assign  sxa_fend = i_fend;
assign  sxa_hstr = i_hstr;
assign  sxa_hend = i_hend;

end
endgenerate


// Sequential Logic
// -----------------------------------------------

`always_ff(pclk, prst_n) begin
   if(~prst_n) begin
      vi_hcnt_lsb       <= 0;
      fm_vin_en         <= 0;
      pkt_cnt           <= 0;
      hsyn_mark         <= 0;
      pkt_lsb           <= 0;
      lsb_lat_en        <= 0;
      pkt_lsb_vld       <= 0;
      pkt_ovf_dat       <= 0;
      pkt_ovf_vld       <= 0;
      px_que            <= 0;
      fifo_push         <= 0;
   end
   else begin
      vi_hcnt_lsb       <= vi_hcnt_lsb_nxt;
      fm_vin_en         <= fm_vin_en_nxt;
      pkt_cnt           <= pkt_cnt_nxt;
      hsyn_mark         <= hsyn_mark_nxt;
      pkt_lsb           <= pkt_lsb_nxt;
      lsb_lat_en        <= lsb_lat_en_nxt;
      pkt_lsb_vld       <= pkt_lsb_vld_nxt;
      pkt_ovf_dat       <= pkt_ovf_dat_nxt;
      pkt_ovf_vld       <= pkt_ovf_vld_nxt;
      px_que            <= px_que_nxt;
      fifo_push         <= fifo_push_nxt;
   end
end


`always_ff(aclk, aresetn) begin
   if(~aresetn) begin
      fifo_pop_en       <= 0;
      fifo_pop_q        <= 0;
      tready_q          <= 0;
      fifo_ren          <= 0;
      que0_vld          <= 0;
      que1_vld          <= 0;
      rd_que[0]         <= 0;
      rd_que[1]         <= 0;
      que_sel           <= 0;
      tvalid            <= 0;
      stm_dat           <= 0;
      sof               <= 0;
      sol               <= 0;
      eol               <= 0;
      lact              <= 0;
   end
   else begin
      fifo_pop_en       <= fifo_pop_en_nxt;
      fifo_pop_q        <= fifo_pop_q_nxt;
      tready_q          <= tready_q_nxt;
      fifo_ren          <= fifo_ren_nxt;
      que0_vld          <= que0_vld_nxt;
      que1_vld          <= que1_vld_nxt;
      rd_que[0]         <= rd_que_nxt[0];
      rd_que[1]         <= rd_que_nxt[1];
      que_sel           <= que_sel_nxt;
      stm_dat           <= stm_dat_nxt;
      tvalid            <= tvalid_nxt;
      sof               <= sof_nxt;
      sol               <= sol_nxt;
      eol               <= eol_nxt;
      lact              <= lact_nxt;
   end
end
//----------------------------------------------------------//
// Module Instance                                          //
//----------------------------------------------------------//

ip_fifo_ctrl
#(          .FIFO_DEP       (FIFO_DEP),
            .FIFO_CDC       (FIFO_CDC),
            .DEP_CAL_EN     (0))

fifo_ctrl (

            //output
            .waddr          (fifo_waddr),
            .raddr          (fifo_raddr),
            .ff_nfull       (o_fifo_nfull),
            .ff_full        (),
            .ff_nempty      (),
            .ff_empty       (fifo_empty),
            .fifo_lvl_rck   (),
            .fifo_free_wck  (),

            //input
            .push           (fifo_push),
            .pop            (fifo_pop),
            .wflush         (i_fstr),
            .rflush         (sxa_fstr),
            .wclk           (pclk),
            .rclk           (aclk),
            .wrst_n         (prst_n),
            .rrst_n         (aresetn)
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
            .clka           (pclk),
            .clkb           (aclk),
            .arst_n         (prst_n),
            .brst_n         (aresetn)
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
