// +FHDR -----------------------------------------------------------------------
// Copyright (c) Silicon Optronics. Inc. 2012
//
// File Name:           ip_sincos_gen_rtl.v
// Author:              Humphrey Lin
//
// File Description:    a. Sine, Cosine generator by single-stage Modified CORDIC method
//                      b. Input degree
//                         deg  90: 0x08000
//                         deg 180: 0x10000
//                         deg 270: 0x18000
//                      c. Output value: "1" = 0x1000; "-1" = 0x3000 with 1 LSB error
//                      d. Latency: 2 clk cycles
//
// -FHDR -----------------------------------------------------------------------

module  ip_sincos_gen

#(
parameter                       PCSION          = 16+2,     // signed + 1.16
parameter                       DEG_WD         = 15+2      // 2 (quadrant) + 15 (degree)
 )

(
//----------------------------------------------------------//
// Output declaration                                       //
//----------------------------------------------------------//

output reg signed [PCSION-5 :0] sin_val,                    // sin value: PCISION-4
output reg signed [PCSION-5 :0] cos_val,                    // cos value: PCISION-4

//----------------------------------------------------------//
// Input declaration                                        //
//----------------------------------------------------------//

input             [DEG_WD-1:0]  theta,                      // degree.
input                           clk,                        // clk clock domain
input                           rst_n                       // active low reset @ clk clock domain
);

//----------------------------------------------------------//
// REG/Wire declaration                                     //
//----------------------------------------------------------//

reg  signed [17:0]              sin_itr_m4;                 // data for CORDIC iteration step 4 @ sin item
reg  signed [17:0]              sin_itr_n4;                 // data for CORDIC iteration step 4 @ sin item
reg  signed [17:0]              cos_itr_m4;                 // data for CORDIC iteration step 4 @ cos item
reg  signed [17:0]              cos_itr_n4;                 // data for CORDIC iteration step 4 @ cos item
reg  signed [PCSION-1:0]        cordic_k1;                  // CORDIC constant 1
reg  signed [PCSION-1:0]        cordic_k2;                  // CORDIC constant 2
reg         [1:0]               quadrant_q1;                //
// Combinational logic
reg  signed [17:0]              itr_m4_p;                   // s1.16; data for CORDIC iteration step 4
reg  signed [17:0]              itr_n4_p;                   // s1.16; data for CORDIC iteration step 4
reg  signed [17:0]              itr_m4_n;                   // s1.16; inverse data for CORDIC iteration step 4
reg  signed [17:0]              itr_n4_n;                   // s1.16; inverse data for CORDIC iteration step 4


wire        [DEG_WD-1:0]        theta_rad;                  // theta in radian (0~pi/2)
wire        [3:0]               tbl_idx;                    // index for Table of CORDIC iteration step 4
wire        [1:0]               quadrant;                   // 0: quadrant 1; 1: quadrant 2; 2: quadrant 3; 3: quadrant 4;
wire signed [PCSION-1:0]        k2_tmp0;                    // temp item 0 for cordic_k2
wire signed [PCSION-1:0]        k2_tmp1;                    // temp item 1 for cordic_k2
wire signed [PCSION-1:0]        k2_tmp2;                    // temp item 2 for cordic_k2
wire signed [PCSION-1:0]        k2_0;                       // item 0 for cordic_k2
wire signed [PCSION-1:0]        k2_1;                       // item 1 for cordic_k2
wire signed [PCSION-1:0]        k2_2;                       // item 2 for cordic_k2
wire signed [PCSION+18-1:0]     sin_prod;                   // result product of sin operation
wire signed [PCSION+18-1:0]     cos_prod;                   // result product of cos operation
wire                            sin_signbit;                // signed bit of sin_prod
wire                            cos_signbit;                // signed bit of cos_prod
wire                            sin_msb;                    // MSB (integer part) of sin_val
wire                            cos_msb;                    // MSB (integer part) of cos_val
wire signed [PCSION-1:0]        sin_val_trim;               // sin value trimming
wire signed [PCSION-1:0]        cos_val_trim;               // cos value trimming
wire signed [PCSION-1:0]        cordic_k1_nxt;
wire signed [PCSION-1:0]        cordic_k2_nxt;
wire signed [PCSION-1:0]        sin_val_nxt;
wire signed [PCSION-1:0]        cos_val_nxt;
wire signed [17:0]              sin_itr_m4_nxt;
wire signed [17:0]              sin_itr_n4_nxt;
wire signed [17:0]              cos_itr_m4_nxt;
wire signed [17:0]              cos_itr_n4_nxt;


//----------------------------------------------------------//
// Code Descriptions                                        //
//----------------------------------------------------------//

// Convert theta into degreee with radian theta*0xc910
// + (1'b1 >> 15) for rounding
assign  theta_rad = ((theta[DEG_WD-3:0] << 1) +
                     (theta[DEG_WD-3:0])      +  (theta[DEG_WD-3:0] >> 3)  +
                     (theta[DEG_WD-3:0] >> 6) +  (theta[DEG_WD-3:0] >> 10) + (1'b1 >> 15)) >> 1;

assign  quadrant = theta[DEG_WD-1 : DEG_WD-2];

assign  tbl_idx = theta_rad[15:12];

always@* begin
   itr_m4_p = 0;
   itr_n4_p = 0;
case (tbl_idx) // synopsys full_case
4'b0000: begin itr_m4_p = 65366;  itr_n4_p = 4090;  end
4'b0001: begin itr_m4_p = 64346;  itr_n4_p = 12207; end
4'b0010: begin itr_m4_p = 62322;  itr_n4_p = 20134; end
4'b0011: begin itr_m4_p = 59325;  itr_n4_p = 27747; end
4'b0100: begin itr_m4_p = 55403;  itr_n4_p = 34927; end
4'b0101: begin itr_m4_p = 50616;  itr_n4_p = 41562; end
4'b0110: begin itr_m4_p = 45040;  itr_n4_p = 47548; end
4'b0111: begin itr_m4_p = 38760;  itr_n4_p = 52792; end
4'b1000: begin itr_m4_p = 31876;  itr_n4_p = 57213; end
4'b1001: begin itr_m4_p = 24494;  itr_n4_p = 60741; end
4'b1010: begin itr_m4_p = 16730;  itr_n4_p = 63320; end
4'b1011: begin itr_m4_p = 8705;   itr_n4_p = 64912; end
4'b1100: begin itr_m4_p = 544;    itr_n4_p = 65491; end
//useless items
//4'b1101: begin itr_m4_p = -7625;  itr_n4_p = 65048; end
//4'b1110: begin itr_m4_p = -15675; itr_n4_p = 63590; end
//4'b1111: begin itr_m4_p = -23481; itr_n4_p = 61139; end
endcase
end

always@* begin
   itr_m4_n = 0;
   itr_n4_n = 0;
case (tbl_idx) // synopsys full_case
4'b0000: begin itr_m4_n = -65366;  itr_n4_n = -4090;  end
4'b0001: begin itr_m4_n = -64346;  itr_n4_n = -12207; end
4'b0010: begin itr_m4_n = -62322;  itr_n4_n = -20134; end
4'b0011: begin itr_m4_n = -59325;  itr_n4_n = -27747; end
4'b0100: begin itr_m4_n = -55403;  itr_n4_n = -34927; end
4'b0101: begin itr_m4_n = -50616;  itr_n4_n = -41562; end
4'b0110: begin itr_m4_n = -45040;  itr_n4_n = -47548; end
4'b0111: begin itr_m4_n = -38760;  itr_n4_n = -52792; end
4'b1000: begin itr_m4_n = -31876;  itr_n4_n = -57213; end
4'b1001: begin itr_m4_n = -24494;  itr_n4_n = -60741; end
4'b1010: begin itr_m4_n = -16730;  itr_n4_n = -63320; end
4'b1011: begin itr_m4_n = -8705;   itr_n4_n = -64912; end
4'b1100: begin itr_m4_n = -544;    itr_n4_n = -65491; end
//useless items
//4'b1101: begin itr_m4_n = 7625;  itr_n4_n = -65048; end
//4'b1110: begin itr_m4_n = 15675; itr_n4_n = -63590; end
//4'b1111: begin itr_m4_n = 23481; itr_n4_n = -61139; end
endcase
end

// Original equation
//assign  cordic_k1 = $signed({1'b0,theta_rad[11:0], 1'b0}) - $signed({1'b0,12'hfff});
//assign  k2_tmp0 = $signed({1'b0, theta_rad[10:5], 1'b0}) - $signed({1'b0,6'h3f});
//assign  k2_tmp1 = $signed({1'b0, theta_rad[ 9:6], 1'b0}) - $signed({1'b0,4'hf});
//assign  k2_tmp2 = $signed({1'b0, theta_rad[ 8:7], 1'b0}) - $signed({1'b0,2'h3});
// Reduce to following equations

assign  cordic_k1_nxt = $signed({~theta_rad[11], theta_rad[10:0], 1'b1});

assign  k2_tmp0 = $signed({~theta_rad[10], theta_rad[9:5], 1'b1});
assign  k2_tmp1 = $signed({~theta_rad[ 9], theta_rad[8:6], 1'b1});
assign  k2_tmp2 = $signed({~theta_rad[ 8], theta_rad[  7], 1'b1});
assign  k2_0    = $signed(theta_rad[11] ? k2_tmp0 : -k2_tmp0);
assign  k2_1    = $signed(theta_rad[10] ? k2_tmp1 : -k2_tmp1);
assign  k2_2    = $signed(theta_rad[ 9] ? k2_tmp2 : -k2_tmp2);

assign  cordic_k2_nxt = $signed({1'b0, 1'b1, {(PCSION-2){1'b0}}} - (k2_0+k2_1+k2_2));

// Quadrant selection
// Quadrsnt 2: cos(90 +theta) = -sin(theta)
// Quadrsnt 3: sin(180+theta) = -sin(theta); cos(180+theta) = -cos(theta)
// Quadrsnt 4: sin(270+theta) = -cos(theta)

assign  sin_itr_m4_nxt = ^quadrant   ? $signed({1'b0,itr_m4_n}) : $signed({1'b0,itr_m4_p});
assign  sin_itr_n4_nxt = ^quadrant   ? $signed({1'b0,itr_n4_n}) : $signed({1'b0,itr_n4_p});
assign  cos_itr_m4_nxt = quadrant[1] ? $signed({1'b0,itr_m4_n}) : $signed({1'b0,itr_m4_p});
assign  cos_itr_n4_nxt = quadrant[1] ? $signed({1'b0,itr_n4_n}) : $signed({1'b0,itr_n4_p});

// Final Butterfly unit
// s1.(PCISION-2) * s1.16 + s1.(PCISION-2) * s1.16
assign  sin_prod = cordic_k1 * sin_itr_m4 + cordic_k2 * sin_itr_n4;
assign  cos_prod = cordic_k2 * cos_itr_m4 - cordic_k1 * cos_itr_n4;

assign  sin_signbit = sin_prod[PCSION+18-1];
assign  cos_signbit = cos_prod[PCSION+18-1];
assign  sin_msb     = sin_prod[PCSION-2+18-2];
assign  cos_msb     = cos_prod[PCSION-2+18-2];

assign  sin_val_trim = $signed(sin_prod[16+4 +: PCSION-4] & {2'b11, {PCSION-6{~(~sin_signbit & sin_msb)}}});
assign  cos_val_trim = $signed(cos_prod[16+4 +: PCSION-4] & {2'b11, {PCSION-6{~(~cos_signbit & cos_msb)}}});

// Quadrant selection
// Quadrsnt 2: sin( 90+theta) =  cos(theta); cos( 90+theta) = -sin(theta)
// Quadrsnt 4: sin(270+theta) = -cos(theta); cos(270+theta) =  sin(theta)

assign  sin_val_nxt = quadrant_q1 == 0 || quadrant_q1 == 2 ? sin_val_trim : cos_val_trim;
assign  cos_val_nxt = quadrant_q1 == 0 || quadrant_q1 == 2 ? cos_val_trim : sin_val_trim;


// Sequential Logic
// -----------------------------------------------

always@(posedge clk or negedge rst_n)begin
   if(~rst_n) begin
      sin_val       <= $signed({PCSION{1'b0}});
      cos_val       <= $signed({PCSION{1'b0}});
      sin_itr_m4    <= $signed({18{1'b0}});
      sin_itr_n4    <= $signed({18{1'b0}});
      cos_itr_m4    <= $signed({18{1'b0}});
      cos_itr_n4    <= $signed({18{1'b0}});
      cordic_k1     <= $signed({PCSION{1'b0}});
      cordic_k2     <= $signed({PCSION{1'b0}});
      quadrant_q1   <= 0;
   end
   else begin
      sin_val       <= sin_val_nxt;
      cos_val       <= cos_val_nxt;
      sin_itr_m4    <= sin_itr_m4_nxt;
      sin_itr_n4    <= sin_itr_n4_nxt;
      cos_itr_m4    <= cos_itr_m4_nxt;
      cos_itr_n4    <= cos_itr_n4_nxt;
      cordic_k1     <= cordic_k1_nxt;
      cordic_k2     <= cordic_k2_nxt;
      quadrant_q1   <= quadrant;
   end
end

endmodule
