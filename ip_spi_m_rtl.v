// +FHDR -----------------------------------------------------------------------
// Copyright (c) Silicon Optronics. Inc. 2014
//
// File Name:           ip_spi_m_rtl.v
// Author:              Humphrey Lin
// Version:             $Revision$
// Last Modified On:    $Date$
// Last Modified By:    $Author$
//
// File Description:    SPI master
//                      Please take care frequency range of spi_clk
// Clock Domain: clk
// -FHDR -----------------------------------------------------------------------

module  ip_spi_m

(
//----------------------------------------------//
// Output declaration                           //
//----------------------------------------------//

output reg              spi_cs = 1,
output reg              spi_sck,
output                  spi_sdo,
output                  spi_done,               // end of one SPI sequence

//----------------------------------------------//
// Input declaration                            //
//----------------------------------------------//

input                   reg_spi_fire,           // fire SPI sequence. Auto clear at the end of one sequence
input [ 3:0]            reg_spi_cmd,
input [11:0]            reg_spi_data,
input [ 1:0]            reg_spi_data_fm,        // 0: 8 bit; 1: 10 bit; 2: 12 bit

input                   clk,
input                   rst_n,
input                   rst_sn
);

//----------------------------------------------//
// Local Parameter                              //
//----------------------------------------------//

localparam      SPI_IDLE        = 5'b0_0001,
                SPI_START       = 5'b0_0000,
                SPI_CMD         = 5'b0_0100,
                SPI_CMD_CLK     = 5'b0_0110,
                SPI_DATA        = 5'b0_1000,
                SPI_DATA_CLK    = 5'b0_1010,
                SPI_END         = 5'b1_0000;

//----------------------------------------------//
// Register declaration                         //
//----------------------------------------------//

reg   [ 4:0]            spim_cs;                // SPI master state machine
reg   [ 4:0]            spim_ns;                // SPI master next state
reg   [ 3:0]            bit_cnt;                // bit counter
reg   [23:0]            spi_que;
reg                     spi_fire_cksyn_q;

//----------------------------------------------//
// Wire declaration                             //
//----------------------------------------------//

wire                    spi_idle_nsm;           // @ SPI_IDLE next state
wire                    spi_cmd_sm;             // @ SPI_CMD  current state
wire                    spi_data_sm;            // @ SPI_DATA current state
wire                    spi_data_nsm;           // @ SPI_DATA next state
wire                    spi_clk_sm;             // @ SPI_CLK current state
wire                    spi_clk_nsm;            // @ SPI_CLK next state
wire                    spi_end_sm;             // @ SPI_END current state
wire  [15:0]            spi_data;
wire                    spi_fire;               // fire SPI sequence
wire                    bit_cnt_rst;
wire                    reg_spi_fire_cksyn;

wire  [ 3:0]            bit_cnt_nxt;
wire  [23:0]            spi_que_nxt;


//----------------------------------------------//
// Code Descriptions                            //
//----------------------------------------------//

assign  spi_fire = reg_spi_fire_cksyn & ~spi_fire_cksyn_q;
assign  spi_done = spi_end_sm;                  // spi_done is used to clear reg_spi_fire

// Split F.F. from State machine to move "spi_cs", "spi_sck" to FPGA IOB
assign  spi_cs_nxt  = spi_idle_nsm;
assign  spi_sck_nxt = spi_clk_nsm;
assign  spi_sdo     = spi_que[23];                  // MSB first

assign  spi_data = {{ 8{reg_spi_data_fm == 0}} & reg_spi_data[ 7:0], 8'h0} |
                   {{10{reg_spi_data_fm == 1}} & reg_spi_data[ 9:0], 6'h0} |
                   {{12{reg_spi_data_fm == 2}} & reg_spi_data[11:0], 4'h0};

assign  spi_que_nxt = spi_fire   ? {reg_spi_cmd, 4'h0,spi_data} :
                      spi_clk_sm ? {spi_que[22:0], 1'b0}        : spi_que;

assign  bit_cnt_rst = spi_fire | (spi_cmd_sm & spi_data_nsm);
assign  bit_cnt_nxt = (bit_cnt + spi_sck) & {4{~bit_cnt_rst}};


// ---------- State Machine --------------------//

assign  spi_idle_nsm = spim_ns[0];
assign  spi_clk_sm   = spim_cs[1];
assign  spi_clk_nsm  = spim_ns[1];
assign  spi_cmd_sm   = spim_cs[2];
assign  spi_data_sm  = spim_cs[3];
assign  spi_data_nsm = spim_ns[3];
assign  spi_end_sm   = spim_cs[4];

always @* begin: SPI_MASTER_FSM

   spim_ns = spim_cs;

   case (spim_cs)

   SPI_IDLE:
      if (spi_fire)
         spim_ns = SPI_START;

   SPI_START:
         spim_ns = SPI_CMD;

   SPI_CMD:
         spim_ns = SPI_CMD_CLK;

   SPI_CMD_CLK:
         spim_ns = bit_cnt == 7  ? SPI_DATA : SPI_CMD;

   SPI_DATA:
         spim_ns = SPI_DATA_CLK;

   SPI_DATA_CLK:
         spim_ns = bit_cnt == 15 ? SPI_END  : SPI_DATA;

   SPI_END:
         spim_ns = SPI_IDLE;

   endcase
end

always @(posedge clk or negedge rst_sn) begin
   if (~rst_sn) begin
      spim_cs   <= SPI_IDLE;
   end
   else begin
      spim_cs   <= spim_ns;
   end
end


// ---------- Sequential Logic -----------------//

always @(posedge clk or negedge rst_n) begin
   if (~rst_n) begin
      spi_cs            <= 1;
      spi_sck           <= 0;
      bit_cnt           <= 0;
      spi_que           <= 0;
      spi_fire_cksyn_q  <= 0;
   end
   else begin
      spi_cs            <= spi_cs_nxt;
      spi_sck           <= spi_sck_nxt;
      bit_cnt           <= bit_cnt_nxt;
      spi_que           <= spi_que_nxt;
      spi_fire_cksyn_q  <= reg_spi_fire_cksyn;
   end
end

ip_sync2 #(.DWID(1)) sync2_spifire(
        //outpu
        .ffq            (reg_spi_fire_cksyn),
        //input
        .ffd            (reg_spi_fire),
        .sync_clk       (clk),
        .sync_rst_n     (rst_n)
        );

endmodule
