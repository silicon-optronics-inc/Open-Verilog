// +FHDR -----------------------------------------------------------------------
// Copyright (c) Silicon Optronics. Inc. 2015
//
// File Name:           ip_cu_ctrl_rtl.v
// Author:              Humphrey Lin
// Version:             $Revision$
// Last Modified On:    $Date$
// Last Modified By:    $Author$
//
// File Description:    CU control module
//
// Parameters:
//
// Clock Domain:        pclk
// -FHDR -----------------------------------------------------------------------

module  ip_cu_ctrl

    #(
      parameter             ALU_SZ          = 1,
      parameter             EXD_SZ          = 1,

      parameter             TSK0_START_PC   = 0,
      parameter             TSK0_END_PC     = TSK0_START_PC+8'h0,
      parameter             TSK1_START_PC   = TSK0_END_PC  +8'h1,
      parameter             TSK1_END_PC     = TSK1_START_PC+8'h0,
      parameter             TSK2_START_PC   = TSK1_END_PC  +8'h1,
      parameter             TSK2_END_PC     = TSK2_START_PC+8'h0,
      parameter             TSK3_START_PC   = TSK2_END_PC  +8'h1,
      parameter             TSK3_END_PC     = TSK3_START_PC+8'h0,
      parameter             TSK4_START_PC   = TSK3_END_PC  +8'h1,
      parameter             TSK4_END_PC     = TSK4_START_PC+8'h0,
      parameter             TSK5_START_PC   = TSK4_END_PC  +8'h1,
      parameter             TSK5_END_PC     = TSK5_START_PC+8'h0,
      parameter             TSK6_START_PC   = TSK5_END_PC  +8'h1,
      parameter             TSK6_END_PC     = TSK6_START_PC+8'h0,
      parameter             TSK7_START_PC   = TSK6_END_PC  +8'h1,
      parameter             TSK7_END_PC     = TSK7_START_PC+8'h0,
      parameter             TSK8_START_PC   = TSK7_END_PC  +8'h1,
      parameter             TSK8_END_PC     = TSK8_START_PC+8'h0,
      parameter             TSK9_START_PC   = TSK8_END_PC  +8'h1,
      parameter             TSK9_END_PC     = TSK9_START_PC+8'h0,
      parameter             CUTSK_NUM       = 10,

      parameter             PC_NUM          = 1,// Max. PC number
      parameter             PC_SZ           = 1,// Program counter width
      parameter             CYC_SZ          = 1 // max cycle counter width of one math operator
     )
(
//----------------------------------------------//
// Output declaration                           //
//----------------------------------------------//

output reg  [CUTSK_NUM-1:0] cu_tsk_end,         // end of task operation
output reg                  cu_tsk_done,        // All CU tasks done; deasserted until next CU trigger
output                      op_act_sm,          // CU op active
output                      op_ini_sm,          // @ OP_INI state
output                      op_rdy_sm,          // @ OP_RDY state
output                      op_halt_sm,         // @ OP_HALT state
output                      add_en,             // Addition op enable
output                      sub_en,             // Subtraction op enable
output                      mul_en,             // Multiply op enable
output                      div_en,             // Division enable
output reg  [PC_NUM-1:0]    cu_cmd_en,          // command enable
output reg  [PC_SZ -1:0]    cu_pc,              // program counter

//----------------------------------------------//
// Input declaration                            //
//----------------------------------------------//

input       [9:0]           cu_tsk_trg,         // Task trigger
input       [1:0]           opcode,             // 0: +, 1: -, 2: *, 3: /
input                       pclk,               // ISP pixel clock
input                       prst_n              // active low reset for pclk domain
);

//----------------------------------------------//
// Local Parameter                              //
//----------------------------------------------//

localparam                  OP_ADD      = 2'b00,
                            OP_SUB      = 2'b01,
                            OP_MUL      = 2'b10,
                            OP_DIV      = 2'b11;

localparam                  CU_OP_IDLE  = 6'b00_0000,
                            OP_INI      = 6'b00_0011,
                            OP_ONGO     = 6'b00_0101,
                            OP_RDY      = 6'b00_1001,
                            OP_HALT     = 6'b01_0001,
                            OP_END      = 6'b10_0000;

//----------------------------------------------//
// Register declaration                         //
//----------------------------------------------//

reg          [5:0]          cu_op_cs;           // CU op current state
reg          [5:0]          cu_op_ns;           // CU op next state
reg          [PC_SZ-1:0]    pc_cnt;             // PC counter
reg          [CYC_SZ-1:0]   op_cyc_cnt;         // operator cycle counter
reg                         any_tsk_pc_end;     // @ one of task end PC

// combinational logic
reg          [CUTSK_NUM-1:0]tsk_pc_end;         // @Task end PC
reg          [PC_SZ-1:0]    cu_pc_nxt;          //
reg          [PC_NUM-1:0]   cu_cmd_en_nxt;      //
reg          [CUTSK_NUM-1:0]cu_tsk_end_nxt;     //

//----------------------------------------------//
// Wire declaration                             //
//----------------------------------------------//
genvar                      gen_i;

wire                        op_ongo_sm;         // @ OP_ONGO state
wire                        op_end_sm;          // @ OP_END state
wire                        op_final;           // Final op step
wire                        tsk_trg_any;        // any Task trigger input
wire                        pc_inc;             // program counter increment
wire         [CUTSK_NUM+1:0]pc_sel;             // program counter select
wire                        tri_load;           // Tri-state address load
wire         [PC_SZ*CUTSK_NUM-1:0]end_pc_ary;

wire                        any_tsk_pc_end_nxt; //
wire         [CYC_SZ-1:0]   op_cyc_cnt_nxt;     //
wire         [PC_SZ-1 :0]   pc_cnt_nxt;         //
wire                        cu_tsk_done_nxt;

//----------------------------------------------//
// Code Descriptions                            //
//----------------------------------------------//

assign  tsk_trg_any    = |cu_tsk_trg;

// Per Command operation
// -----------------------------------------------

assign  add_en  = opcode == OP_ADD;
assign  sub_en  = opcode == OP_SUB;
assign  mul_en  = opcode == OP_MUL;
assign  div_en  = opcode == OP_DIV;

assign  op_final  = ((add_en | sub_en) & op_ini_sm)      |
                    ( mul_en & (op_cyc_cnt == ALU_SZ-1)) |
                    ( div_en & (op_cyc_cnt == ALU_SZ+EXD_SZ-1));

assign  op_cyc_cnt_nxt = {CYC_SZ{~(op_rdy_sm | cu_tsk_trg[0])}} &
                         (op_ongo_sm ? op_cyc_cnt + 1'b1 :  op_cyc_cnt);

// command enable
always @* begin: cmd_en_mux
   integer i;

   for (i=0; i <= PC_NUM-1; i=i+1)
      cu_cmd_en_nxt[i] = cu_pc_nxt == i;
end

// PC
// -----------------------------------------------
assign  pc_inc     = op_rdy_sm & ~any_tsk_pc_end;
assign  pc_sel     = {tri_load, cu_tsk_trg, op_halt_sm};
assign  pc_cnt_nxt = pc_inc ? cu_pc + 1'b1 : pc_cnt;

assign  tri_load   = (~any_tsk_pc_end & op_rdy_sm) | op_end_sm;

always @* begin

   cu_pc_nxt = cu_pc;

   case (pc_sel)
   12'b0000_0000_0001: cu_pc_nxt = pc_cnt;
   12'b0000_0000_0010: cu_pc_nxt = TSK0_START_PC;
   12'b0000_0000_0100: cu_pc_nxt = TSK1_START_PC;
   12'b0000_0000_1000: cu_pc_nxt = TSK2_START_PC;
   12'b0000_0001_0000: cu_pc_nxt = TSK3_START_PC;
   12'b0000_0010_0000: cu_pc_nxt = TSK4_START_PC;
   12'b0000_0100_0000: cu_pc_nxt = TSK5_START_PC;
   12'b0000_1000_0000: cu_pc_nxt = TSK6_START_PC;
   12'b0001_0000_0000: cu_pc_nxt = TSK7_START_PC;
   12'b0010_0000_0000: cu_pc_nxt = TSK8_START_PC;
   12'b0100_0000_0000: cu_pc_nxt = TSK9_START_PC;
   12'b1000_0000_0000: cu_pc_nxt = {PC_SZ{1'b1}};
   endcase
end

// Task end indication
// -----------------------------------------------
assign  end_pc_ary = {TSK9_END_PC[PC_SZ-1:0], TSK8_END_PC[PC_SZ-1:0],
                      TSK7_END_PC[PC_SZ-1:0], TSK6_END_PC[PC_SZ-1:0],
                      TSK5_END_PC[PC_SZ-1:0], TSK4_END_PC[PC_SZ-1:0],
                      TSK3_END_PC[PC_SZ-1:0], TSK2_END_PC[PC_SZ-1:0],
                      TSK1_END_PC[PC_SZ-1:0], TSK0_END_PC[PC_SZ-1:0]};

assign  any_tsk_pc_end_nxt = (|tsk_pc_end) & op_final;

always @* begin: per_task_end
   integer i;

   for (i=0; i < CUTSK_NUM; i=i+1)
      tsk_pc_end[i] = cu_pc == end_pc_ary[PC_SZ*i +: PC_SZ];
end

always @* begin: task_end
   integer i;

   for (i=0; i < CUTSK_NUM; i=i+1)
      cu_tsk_end_nxt[i] = op_end_sm & tsk_pc_end[i];
end

assign  cu_tsk_done_nxt = (cu_tsk_end[CUTSK_NUM-1] | cu_tsk_done) & ~tsk_trg_any;

// ---------- State Machine --------------------//

assign  op_act_sm  = cu_op_cs[0];
assign  op_ini_sm  = cu_op_cs[1];
assign  op_ongo_sm = cu_op_cs[2];
assign  op_rdy_sm  = cu_op_cs[3];
assign  op_halt_sm = cu_op_cs[4];
assign  op_end_sm  = cu_op_cs[5];

always @* begin: CU_OP_FSM

   cu_op_ns = cu_op_cs;

   case (cu_op_cs)

   CU_OP_IDLE:
      if (tsk_trg_any)
         cu_op_ns = OP_INI;

   OP_INI:
      if (op_final)
         cu_op_ns = OP_RDY;
      else
         cu_op_ns = OP_ONGO;

   OP_ONGO:
      if (op_final)
         cu_op_ns = OP_RDY;

   OP_RDY:
      if (any_tsk_pc_end)
         cu_op_ns = OP_END;
      else
         cu_op_ns = OP_HALT;

   OP_HALT:
         cu_op_ns = OP_INI;

   OP_END:
         cu_op_ns = CU_OP_IDLE;

   endcase

   if (tsk_trg_any)
      cu_op_ns = OP_INI;

end

always @(posedge pclk or negedge prst_n) begin
   if (~prst_n)
      cu_op_cs <= CU_OP_IDLE;
   else
      cu_op_cs <= cu_op_ns;
end

// ---------- Sequential Logic -----------------//

always @(posedge pclk or negedge prst_n) begin
   if (~prst_n) begin
      cu_tsk_end    <= 0;
      cu_pc         <= 0;
      op_cyc_cnt    <= 0;
      pc_cnt        <= 0;
      cu_cmd_en     <= 0;
      any_tsk_pc_end<= 0;
      cu_tsk_done   <= 0;
   end
   else begin
      cu_tsk_end    <= cu_tsk_end_nxt;
      cu_pc         <= cu_pc_nxt;
      op_cyc_cnt    <= op_cyc_cnt_nxt;
      pc_cnt        <= pc_cnt_nxt;
      cu_cmd_en     <= cu_cmd_en_nxt;
      any_tsk_pc_end<= any_tsk_pc_end_nxt;
      cu_tsk_done   <= cu_tsk_done_nxt;
   end
end


endmodule
