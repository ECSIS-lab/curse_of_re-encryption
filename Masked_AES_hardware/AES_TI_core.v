/* -----------------------------------------------------------------------------------------
 Masked AES hardware macro based on 2-share threshold implementation

  This circuit works only with AES_Comp.
  Compatibility for another cipher module may be provided in future release.

  File name   : AES_TI_core.v
  Version     : 2.1
  Created     : December 1, 2016
  Last update : October 4, 2021
  Desgined by : Rei Ueno

  Copyright (C) 2021 Tohoku University

  By using this code, you agree to the following terms and conditions.

  This code is copyrighted by Tohoku University ("us").

  Permission is hereby granted to copy, reproduce, redistribute or
  otherwise use this code as long as: there is no monetary profit gained
  specifically from the use or reproduction of this code, it is not sold,
  rented, traded or otherwise marketed, and this copyright notice is
  included prominently in any copy made.

  We shall not be liable for any damages, including without limitation
  direct, indirect, incidental, special or consequential damages arising
  from the use of this code.

  When you publish any results arising from the use of this code, we will
  appreciate it if you can cite our paper.

  Rei Ueno, Naofumi Homma, and Takafumi Aoki,
  "Towards More DPA-Resistant AES Hardware Architecture Based on Threshold Implementation,"
  In: Silvain Guilley (eds.) International Workshop on Constructive Side-Channel Analysis and Secure Design (COSADE),
  pp. 50--64, Lecture Note in Computer Science, Vol. 10348, Springer,
  doi: https://doi.org/10.1007/978-3-319-64647-3_4
----------------------------------------------------------------------------------------- */

/* ---------------------------------------------------------------------------------------------------
 About this architecture:

 This architecture completes one block encryption within 219 clock cycles.
 The I/O and behavior of this arcthiecture basically follow the SASEBO AES core at
 http://www.aoki.ecei.tohoku.ac.jp/crypto/
 except for the number of encryption clock cylces and trigger.
 Although the original architecture presented in the above paper has byte-serial I/O for data and key,
 we employ a 128-bit wise I/O for the ease of trace acquisition.

 The initial masking is performed immediately after data input, and unmasking is performed just before data output.
 This arcthiecture does NOT protect the round key and key scheduling datapath, as it causes no DPA leakage.
 (However it of course causes leakage for the TVLA or input distinguishing attack unless the key is fixed.)
 Roundness is generated using four 128-bit XOR-shifts (each of which generates 32-bit randomness per clock)
 with a hard-coded seed.

 The linear mappings in this architecture is optimized using a technique named "multiplicative-offset."
 See https://ieeexplore.ieee.org/document/8922779 .

 To use this AES core, you require a non-masked S-box hardware (for mudule "GF_INV_8") provided at
 https://faculty.nps.edu/drcanrig/pub/index.html .
 If you use this non-masked S-box, you MUST follow the terms and considtions specified for its use.
---------------------------------------------------------------------------------------------------- */

module AES_TI_core(Din0, Kin, Dout0, CLK, RSTn, Dvld, Kvld, BSY, EN, Drdy, Krdy, round9);
  input [127:0] Din0, Kin;
  output [127:0] Dout0;
  
  input CLK, RSTn, Drdy, Krdy, EN;
  
  output Dvld, BSY, Kvld,round9;
  
  wire [7:0] RoundData0, toSbox0, fromSbox00, fromSbox01, StateOut0;
  wire [7:0] RoundData1, ak, toSbox1, fromSbox10, fromSbox11, StateOut1;
  wire [7:0] RoundKey, KeyOut, forKS, RC, toKA;
  wire [127:0] Din0_comp, Din1_comp, Kin_comp, Kout_comp;
  wire [7:0] RC_comp, nonshared_Sbox_out;
  wire [1:0] funct;
  wire selXOR, KSen, aff_en;
  reg round9;
  reg Dvld, Kvld, BSY;
  reg [4:0] CNT;
  reg [10:0] ShiftReg;
  reg [7:0] Din0reg, Din1reg, Kinreg;
  reg Drdyreg;
  wire [7:0] l00, l01, l10, l11;
  wire [127:0] D0, D1;

  reg [31:0] RG00, RG01, RG02, RG03;
  reg [31:0] RG10, RG11, RG12, RG13;
  reg [31:0] RG20, RG21, RG22, RG23;
  reg [31:0] RG30, RG31, RG32, RG33;

  wire [31:0] WR0, TR0, WR1, TR1, WR2, TR2, WR3, TR3;

  wire [127:0] rnd;
  assign rnd = {WR3, WR2, WR1, WR0};
  assign Din1_comp = rnd;
  
  reg [7:0] m0, m1, m2, m3, m4, m5;

  iso16 iso_Din0 (.in0(Din0), .out0(Din0_comp));
  iso16 iso_Kin (.in0(Kin), .out0(Kin_comp));
  iso iso_RC (.in0(RC), .out0(RC_comp));

  StateArray_add SA0 (.SBin0(l00), .SBin1(l01), .SBout(StateOut0), .funct(funct),
                      .CLK(CLK), .RSTn(RSTn), .ENn(ShiftReg[9]), .EN(EN), .aff_en(aff_en),
                      .IDin(Din0_comp^Din1_comp), .Dout(D0), .Drdy(Drdy), .BSY(BSY), .fr(ShiftReg[0]|ShiftReg[10]), .maskin(m5));
  StateArray SA1 (.SBin0(l10), .SBin1(l11), .SBout(StateOut1), .funct(funct),
                  .CLK(CLK), .RSTn(RSTn), .ENn(ShiftReg[9]), .EN(EN), .aff_en(aff_en),
                  .IDin(Din1_comp), .Dout(D1), .Drdy(Drdy), .BSY(BSY), .fr(ShiftReg[0]|ShiftReg[10]), .maskin(m5));
  KeyArray KA0 (.SBin(toKA), .Kin(RoundKey), .RK(KeyOut), .SBout(forKS), .RC(RC_comp&{8{(CNT==14)}}),
                .selXOR(selXOR), .CLK(CLK), .RSTn(RSTn), .funct(KSen), .EN(EN), .BSY(BSY), .IKin(Kin_comp),
                .Krdy(Krdy), .Kout(Kout_comp), .KSen(ShiftReg[9]&((CNT==19)|(CNT==18))));
  
  assign RoundData0 = StateOut0;
  assign RoundData1 = StateOut1;
  assign RoundKey = KeyOut;
  assign ak = RoundData0 ^ RoundKey;
  assign KSen = ((CNT[4:1]==8)|(CNT[4:1]==7))&(~ShiftReg[10]);
  assign toSbox0 = ak;
  assign toSbox1 = RoundData1;
  assign aff_en = (~|CNT[4:2])|(ShiftReg[0]&((CNT==29)|(CNT==30)|(CNT==31)|(CNT==0)|(CNT==1))|ShiftReg[10]);
 
  wire [7:0] multmask, maskedin0, maskedin1, fS00, fS01, fS10, fS11;
  assign multmask = {rnd[71]|(~|rnd[71:64]), rnd[70:64]};
  
  inversion_TI inv (.in0(toSbox0), .in1(toSbox1), .out0(fromSbox00), .out1(fromSbox01),
                    .out2(fromSbox10), .out3(fromSbox11), .r(rnd[63:0]), .CLK(CLK));

  // wire key_gate;
  GF_INV_8 nonshared_inv (.in0(forKS&{8{KSen}}), .out0(nonshared_Sbox_out));
  affine iia (.in0(nonshared_Sbox_out), .out0(toKA));


  assign l00 = ShiftReg[10]? ak: fromSbox00;
  assign l01 = ({8{~ShiftReg[10]}})&fromSbox01;
  assign l10 = ShiftReg[10]? RoundData1: fromSbox10;
  assign l11 = ({8{~ShiftReg[10]}})&fromSbox11;

  wire f0, f1;
  assign f1 = (&CNT[3:0])&(~CNT[4])&(~ShiftReg[10]);
  assign f0 = CNT[4]&(~CNT[3]);
  assign funct = {f1, f0};
  assign selXOR = ShiftReg[10]? ~(CNT[0]&CNT[1]): ~(((CNT[0])&(~CNT[1]))|Drdyreg);
  assign RC = {ShiftReg[7],
               ShiftReg[6],
               ShiftReg[5]|ShiftReg[9],
               ShiftReg[4]|ShiftReg[8]|ShiftReg[9],
               ShiftReg[3]|ShiftReg[8],
               ShiftReg[2]|ShiftReg[9],
               ShiftReg[1]|ShiftReg[8]|ShiftReg[9],
               ShiftReg[0]|ShiftReg[8]};

  wire [127:0] gated_D0, gated_D1;
  // assign gated_D0 = D0&{128{~BSY}};
  // assign gated_D1 = D1&{128{~BSY}};
  assign gated_D0 = D0;
  assign gated_D1 = D1;
  inviso16 isoDout16_0 (.in0(gated_D0^gated_D1), .out0(Dout0));
  
  // XORshift
  assign TR0 = RG00 ^ (RG00 << 11);
  assign WR0 = (RG03 ^ (RG03 >> 19)) ^ (TR0 ^ (TR0 >> 8));
  assign TR1 = RG10 ^ (RG10 << 11);
  assign WR1 = (RG13 ^ (RG13 >> 19)) ^ (TR1 ^ (TR1 >> 8));
  assign TR2 = RG20 ^ (RG20 << 11);
  assign WR2 = (RG23 ^ (RG23 >> 19)) ^ (TR2 ^ (TR2 >> 8));
  assign TR3 = RG30 ^ (RG30 << 11);
  assign WR3 = (RG33 ^ (RG33 >> 19)) ^ (TR3 ^ (TR3 >> 8));

  initial begin
    RG00 <= 32'd123456789; RG01 <= 32'd362436069; RG02 <= 32'd521288629; RG03 <= 32'd88675123;
    RG10 <= 32'd141592653; RG11 <= 32'd589793238; RG12 <= 32'd462433832; RG13 <= 32'd79502884;
    RG20 <= 32'd413213562; RG21 <= 32'd373095048; RG22 <= 32'd87242096; RG23 <= 32'd98078569;
    RG30 <= 32'h89a01b2f; RG31 <= 32'h9fe9cb91; RG32 <= 32'hd9e6ab64; RG33 <= 32'ha723cecf;
  /*
     RG00 <= 32'd000000000; RG01 <= 32'd000000000; RG02 <= 32'd000000000; RG03 <=32'd000000000;
    RG10 <= 32'd000000000; RG11 <= 32'd000000000; RG12 <= 32'd000000000; RG13 <= 32'd000000000;
    RG20 <= 32'd000000000; RG21 <= 32'd000000000; RG22 <= 32'd000000000; RG23 <= 32'd000000000;
    RG30 <= 32'd000000000; RG31 <= 32'd000000000; RG32 <= 32'd000000000; RG33 <= 32'd000000000;
    */
  end

  always @(negedge CLK) begin
      RG00 <= RG01; RG01 <= RG02; RG02 <= RG03; RG03 <= WR0;
      RG10 <= RG11; RG11 <= RG12; RG12 <= RG13; RG13 <= WR1;
      RG20 <= RG21; RG21 <= RG22; RG22 <= RG23; RG23 <= WR2;
      RG30 <= RG31; RG31 <= RG32; RG32 <= RG33; RG33 <= WR3;
  end

  always @(posedge CLK) begin
    m0 <= multmask; m1 <= m0;
    if(round9==1'b1)begin
        round9=1'b0;
    end
    if (RSTn==0) begin
      CNT <= 30; Dvld <= 0; BSY <= 0; Kvld <= 0; Drdyreg <= 0;
      round9<=0;
      ShiftReg <= 11'b00000000001;
    end else if (EN==1) begin
      if (BSY==0) begin
        Dvld <= 0;
        if (Krdy) begin
          Kvld <= 1;
        end else if (Drdy) begin
          CNT <= 30; BSY <= 1; Kvld <= 0; Drdyreg <= 1;
          // Din0reg <= Din0_comp; Din1reg <= Din1_comp; Kinreg <= Kin_comp;
        end
      end else begin
        CNT <= CNT+1'b1;
        if(CNT==18 && ShiftReg[0]==1)begin
            round9<=1'b1;
        end
        if (CNT==17) begin
          Drdyreg <= 0;
        end
        if (ShiftReg[10]==1) begin
          if (CNT==15) begin
            Dvld <= 1;
            CNT <= 30; Dvld <= 1;
            ShiftReg <= {ShiftReg[9:0], ShiftReg[10]};
            BSY <= 0;
          end
        end else if (CNT==19) begin
          CNT <= 0;
          ShiftReg <= {ShiftReg[9:0], ShiftReg[10]};
        end
      end
    end
  end
endmodule // AES_core

module StateArray (SBin0, SBin1, SBout, funct, CLK, RSTn, ENn, EN, aff_en, IDin, Dout, BSY, Drdy, fr, maskin);
  input [127:0] IDin;
  output [127:0] Dout;
  input [7:0] SBin0, SBin1, maskin;
  output [7:0] SBout;
  // input CLK, RSTn, ENn, Drdy, EN, BSY; // ENn == 1 for bypassing MixColumns
  input CLK, RSTn, ENn, EN, aff_en, BSY, Drdy, fr; // ENn == 1 for bypassing MixColumns
  input [1:0] funct; // funct = 00 for AddRoundKey and SubBytes, 10 for ShiftRows, 01 for MixColumns
  reg [127:0] State;
  wire [31:0] MCout, Affout;
  wire [127:0] sr;
  wire [7:0] w03, w13, w23, w33, c, afs, aff, unmasked;
  reg [7:0] s;

  affine affine (.in0(State[103:96]^(s&{8{funct[0]}})), .out0(aff));

  assign afs = (aff_en==1'b0)? aff: State[103:96];
  MixColumns MC (.in0({aff, State[71:64], State[39:32], State[7:0]}), .out0(MCout), .out1(Affout));
  assign {w33, w23, w13, w03} = ({funct[0], ENn}==2'b10)? MCout:
                                ({funct[0], ENn}==2'b11)? Affout:
                                {SBin0, afs, State[71:64], State[39:32]};
  assign SBout = (fr&(~funct[0]))? State[7:0]: State[23:16];
  assign Dout = {State[7:0],   State[39:32], State[71:64], State[103:96],
                 State[15:8],  State[47:40], State[79:72], State[111:104],
                 State[23:16], State[55:48], State[87:80], State[119:112],
                 State[31:24], State[63:56], State[95:88], State[127:120]};

  // ShiftRows
  assign c = State[127:120] ^ (s&{8{~funct[0]}});
  assign sr[127:96] = {c, State[119:104], SBin0};
  assign sr[95:64]  = {State[87:72], aff, State[95:88]};
  assign sr[63:32]  = {State[47:40], State[71:48]};
  assign sr[31:0]   = State[39:8];

  always @(posedge CLK) begin
    if (RSTn==0) begin
      State <= 128'b0; s <= 0;
    end else if (EN==1) begin
      if (BSY==0) begin
        if (Drdy==1) begin
          State <= {IDin[7:0],   IDin[39:32], IDin[71:64], IDin[103:96],
                    IDin[15:8],  IDin[47:40], IDin[79:72], IDin[111:104],
                    IDin[23:16], IDin[55:48], IDin[87:80], IDin[119:112],
                    IDin[31:24], IDin[63:56], IDin[95:88], IDin[127:120]};
        end
      end else begin
        State <= (funct[1]==1'b0)? {w33, c, State[119:104], w23, State[95:72],
                                    w13, State[63:40], w03, State[31:8]}: // Shift register or MixColumns
                 sr; // ShiftRows
        if (~funct[0]) begin
          s <= SBin1;
        end else begin
          s <= 0;
        end
      end
    end
  end
endmodule // StateArray

module StateArray_add (SBin0, SBin1, SBout, funct, CLK, RSTn, ENn, EN, aff_en, IDin, Dout, BSY, Drdy, fr, maskin);
  input [127:0] IDin;
  output [127:0] Dout;
  input [7:0] SBin0, SBin1, maskin;
  output [7:0] SBout;
  // input CLK, RSTn, ENn, Drdy, EN, BSY; // ENn == 1 for bypassing MixColumns
  input CLK, RSTn, ENn, EN, aff_en, BSY, Drdy, fr; // ENn == 1 for bypassing MixColumns
  input [1:0] funct; // funct = 00 for AddRoundKey and SubBytes, 10 for ShiftRows, 01 for MixColumns
  reg [127:0] State;
  wire [31:0] MCout, Affout;
  wire [127:0] sr;
  wire [7:0] w03, w13, w23, w33, c, aff, afs, unmasked;
  reg [7:0] s;

  affine_add affine_add (.in0(State[103:96]^(s&{8{funct[0]}})), .out0(aff));

  assign afs = (aff_en==1'b0)? aff: State[103:96];
  MixColumns MC (.in0({aff, State[71:64], State[39:32], State[7:0]}), .out0(MCout), .out1(Affout));
  assign {w33, w23, w13, w03} = ({funct[0], ENn}==2'b10)? MCout:
                                ({funct[0], ENn}==2'b11)? Affout:
                                {SBin0, afs, State[71:64], State[39:32]};
  assign SBout = (fr&(~funct[0]))? State[7:0]: State[23:16];

  assign Dout = {State[7:0],   State[39:32], State[71:64], State[103:96],
                 State[15:8],  State[47:40], State[79:72], State[111:104],
                 State[23:16], State[55:48], State[87:80], State[119:112],
                 State[31:24], State[63:56], State[95:88], State[127:120]};

  // ShiftRows
  assign c = State[127:120] ^ (s&{8{~funct[0]}});
  assign sr[127:96] = {c, State[119:104], SBin0};
  assign sr[95:64]  = {State[87:72], aff, State[95:88]};
  assign sr[63:32]  = {State[47:40], State[71:48]};
  assign sr[31:0]   = State[39:8];


  always @(posedge CLK) begin
    if (RSTn==0) begin
      State <= 128'b0; s <= 0;
    end else if (EN==1) begin
      if (BSY==0) begin
        if (Drdy==1) begin
          State <= {IDin[7:0],   IDin[39:32], IDin[71:64], IDin[103:96],
                    IDin[15:8],  IDin[47:40], IDin[79:72], IDin[111:104],
                    IDin[23:16], IDin[55:48], IDin[87:80], IDin[119:112],
                    IDin[31:24], IDin[63:56], IDin[95:88], IDin[127:120]};
        end
      end else begin
        State <= (funct[1]==1'b0)? {w33, c, State[119:104], w23, State[95:72],
                                    w13, State[63:40], w03, State[31:8]}: // Shift register or MixColumns
                sr; // ShiftRows
                if (~funct[0]==1'b1) begin
                s <= SBin1;
        end else begin
          s <= 0;
        end
      end
    end
  end
endmodule // StateArray

module KeyArray (SBin, Kin, RK, SBout, RC, selXOR, CLK, RSTn, funct, EN, BSY, IKin, Krdy, Kout, KSen);
  input [7:0] SBin, Kin, RC;
  input [127:0] IKin;
  output [7:0] RK, SBout;
  input selXOR, CLK, RSTn, EN, BSY, Krdy, KSen;
  input [0:0] funct;
  reg [127:0] K;
  wire [7:0] w00, w30;

  output [127:0] Kout;

  assign w00 = (K[7:0] & {8{selXOR}}) ^ K[15:8];
  assign w30 = K[7:0] ^ RC ^ SBin;

  assign SBout = K[63:56];
  assign RK = K[7:0];

  assign Kout = {K[7:0],   K[39:32], K[71:64], K[103:96],
                 K[15:8],  K[47:40], K[79:72], K[111:104],
                 K[23:16], K[55:48], K[87:80], K[119:112],
                 K[31:24], K[63:56], K[95:88], K[127:120]};

  always @(posedge CLK) begin
    if (RSTn == 0) begin
      K <= 128'b0;
    end else if (EN==1) begin
      if (BSY==0) begin
        if (Krdy==1) begin
          K <= {IKin[7:0],   IKin[39:32], IKin[71:64], IKin[103:96],
                IKin[15:8],  IKin[47:40], IKin[79:72], IKin[111:104],
                IKin[23:16], IKin[55:48], IKin[87:80], IKin[119:112],
                IKin[31:24], IKin[63:56], IKin[95:88], IKin[127:120]};
        end
      end else if (KSen==1'b0) begin
        if (funct==1'b0) begin
          K <= {Kin, K[127:16], w00}; // horizontal shift (for AddRoundKey)
        end else begin
          K <= {K[31:8], w30, K[127:32]}; // vertical shift (when MixColumns)
        end
      end
    end
  end
endmodule // KeyArray


module inversion_TI (in0, in1, out0, out1, out2, out3, r, CLK);
  input [7:0] in0, in1;
  output [7:0] out0, out1, out2, out3;
  input [63:0] r;
  input CLK;
  reg [3:0] s0reg, s1reg, s2reg, s3reg, i0reg, i1reg, i2reg, i3reg, i4reg, i5reg, i6reg, i7reg,
            h00reg, h01reg, h10reg, h11reg, l00reg, l01reg, l10reg, l11reg;

  wire [3:0] s0, s1, s2, s3;
  Stage1 S1 (.in00(in0[3:0]), .in01(in1[3:0]), .in10(in0[7:4]), .in11(in1[7:4]),
             .out0(s0), .out1(s1), .out2(s2), .out3(s3), .r0(r[47:44]), .r1(r[43:40]), .r2(r[39:36]));

  wire [3:0] i0, i1, i2, i3, i4, i5, i6, i7;
  Stage2 S2 (.in0(s0reg), .in1(s1reg), .in2(s2reg), .in3(s3reg),
             .out0(i0), .out1(i1), .out2(i2), .out3(i3), .out4(i4), .out5(i5), .out6(i6), .out7(i7),
             .r0(r[35:32]), .r1(r[31:28]), .r2(r[27:24]), .r3(r[51:48]), .r4(r[55:52]), .r5(r[59:56]), .r6(r[63:60]));

  wire [3:0] t0, t1, t2, t3, u0, u1, u2, u3;
  Stage3 S3 (.inh0(h10reg), .inh1(h11reg), .inl0(l10reg), .inl1(l11reg),
             .in0(i0reg), .in1(i1reg), .in2(i2reg), .in3(i3reg),
             .in4(i4reg), .in5(i5reg), .in6(i6reg), .in7(i7reg),
             .out0(out0[7:4]), .out1(out1[7:4]), .out2(out2[7:4]), .out3(out3[7:4]),
             .out4(out0[3:0]), .out5(out1[3:0]), .out6(out2[3:0]), .out7(out3[3:0]),
             .r0(r[23:20]), .r1(r[19:16]), .r2(r[15:12]), .r3(r[11:8]), .r4(r[7:4]), .r5(r[3:0]));

  always @(posedge CLK) begin
    s0reg <= s0; s1reg <= s1; s2reg <= s2; s3reg <= s3;
    i0reg <= i0; i1reg <= i1; i2reg <= i2; i3reg <= i3; i4reg <= i4; i5reg <= i5; i6reg <= i6; i7reg <= i7;
    h00reg <= in0[7:4]; h01reg <= in1[7:4]; l00reg <= in0[3:0]; l01reg <= in1[3:0];
    h10reg <= h00reg; h11reg <= h01reg; l10reg <= l00reg; l11reg <= l01reg;
  end
endmodule // Sbox_TI

module MixColumns (in0, out0, out1);
  input [31:0] in0;
  output [31:0] out0, out1;
  wire [7:0] a3, a2, a1, a0, b3, b2, b1, b0, c1, c0,
             w3, w2, w1, w0, v3, v2, v1, v0;

  assign {a3, a2, a1, a0} = in0;

  assign b3 = a3 ^ a2; assign b2 = a2 ^ a1;
  assign b1 = a1 ^ a0; assign b0 = a0 ^ a3;


  // isomorphism + multiplication (b+1) + inverse isomorphism
  affine_bp1 beta0 (.in0(b0), .out0(v0));
  affine_bp1 beta1 (.in0(b1), .out0(v1));
  affine_bp1 beta2 (.in0(b2), .out0(v2));
  affine_bp1 beta3 (.in0(b3), .out0(v3));

  assign c0 = a0 ^ a1;
  assign c1 = a2 ^ a3;

  assign out0 = {a1^c1^v0, c0^a2^v3, c0^a3^v2, a0^c1^v1};
  assign out1 = {a3, a2, a1, a0};
endmodule // MixColumns

module affine_add (in0, out0);
  input [7:0] in0;
  output [7:0] out0;

  assign out0[0] = in0[4]^in0[5]^in0[6];
  assign out0[1] = in0[1]^in0[3]^in0[5];
  assign out0[2] = in0[1]^in0[5]^in0[7];
  assign out0[3] = in0[1]^in0[4]^in0[6];
  assign out0[4] = in0[2]^in0[3]^in0[4]^in0[5]^in0[6];
  assign out0[5] = in0[1]^in0[6];
  assign out0[6] = in0[2]^in0[6];
  assign out0[7] = in0[0]^in0[3]^in0[5]^in0[7];
endmodule // inviso

module affine (in0, out0);
  input [7:0] in0;
  output [7:0] out0;

  assign out0[0] = ~in0[4]^in0[5]^in0[6];
  assign out0[1] = in0[1]^in0[3]^in0[5];
  assign out0[2] = ~in0[1]^in0[5]^in0[7];
  assign out0[3] = ~in0[1]^in0[4]^in0[6];
  assign out0[4] = ~in0[2]^in0[3]^in0[4]^in0[5]^in0[6];
  assign out0[5] = in0[1]^in0[6];
  assign out0[6] = in0[2]^in0[6];
  assign out0[7] = in0[0]^in0[3]^in0[5]^in0[7];
endmodule // inviso

module affine_bp1 (in0, out0);
  input [7:0] in0;
  output [7:0] out0;

  assign out0[0] = in0[1]^in0[3]^in0[5]^in0[6];
  assign out0[1] = in0[0]^in0[1]^in0[2]^in0[3]^in0[4]^in0[5]^in0[7];
  assign out0[2] = in0[1]^in0[2]^in0[4];
  assign out0[3] = in0[0]^in0[1]^in0[3]^in0[5];
  assign out0[4] = in0[1]^in0[2]^in0[6];
  assign out0[5] = in0[0]^in0[1]^in0[3]^in0[7];
  assign out0[6] = in0[0]^in0[4]^in0[7];
  assign out0[7] = in0[1]^in0[5]^in0[6]^in0[7];
endmodule // inviso

module Stage3 (inh0, inh1, inl0, inl1, in0, in1, in2, in3, in4, in5, in6, in7,
               out0, out1, out2, out3, out4, out5, out6, out7, r0, r1, r2, r3, r4, r5);
  input [3:0] inh0, inh1, inl0, inl1,
              in0, in1, in2, in3, in4, in5, in6, in7;
  output [3:0] out0, out1, out2, out3, out4, out5, out6, out7;
  input [3:0] r0, r1, r2, r3, r4, r5;
  wire [3:0] a0, a1, z0, z1, z2, z3, z4, z5, z6, z7;

  // Compression
  assign a0 = in0 ^ in2 ^ in4 ^ in6;
  assign a1 = in1 ^ in3 ^ in5 ^ in7;

  wire [1:0] ff0, ff1;
  wire f0, f1, h0, l0, h1, l1;
  assign ff0 = a0[3:2] ^ a0[1:0];
  assign f0 = ^ff0;
  assign {h0, l0} = {a0[3]^a0[2], a0[1]^a0[0]};

  assign ff1 = a1[3:2] ^ a1[1:0];
  assign f1 = ^ff1;
  assign {h1, l1} = {a1[3]^a1[2], a1[1]^a1[0]};

  gf24mul_factoring mulf0 (.in0(inl0), .in1(a0), .ff(ff0), .f(f0), .h(h0), .l(l0), .out0(z0));
  gf24mul_factoring mulf1 (.in0(inl0), .in1(a1), .ff(ff1), .f(f1), .h(h1), .l(l1), .out0(z1));
  gf24mul_factoring mulf2 (.in0(inl1), .in1(a0), .ff(ff0), .f(f0), .h(h0), .l(l0), .out0(z2));
  gf24mul_factoring mulf3 (.in0(inl1), .in1(a1), .ff(ff1), .f(f1), .h(h1), .l(l1), .out0(z3));

  gf24mul_factoring mulf4 (.in0(inh0), .in1(a0), .ff(ff0), .f(f0), .h(h0), .l(l0), .out0(z4));
  gf24mul_factoring mulf5 (.in0(inh0), .in1(a1), .ff(ff1), .f(f1), .h(h1), .l(l1), .out0(z5));
  gf24mul_factoring mulf6 (.in0(inh1), .in1(a0), .ff(ff0), .f(f0), .h(h0), .l(l0), .out0(z6));
  gf24mul_factoring mulf7 (.in0(inh1), .in1(a1), .ff(ff1), .f(f1), .h(h1), .l(l1), .out0(z7));

  assign out0 = z0 ^ r0;
  assign out1 = z1 ^ r1;
  assign out2 = z2 ^ r2;
  assign out3 = z3 ^ r0 ^ r1 ^ r2;

  assign out4 = z4 ^ r3;
  assign out5 = z5 ^ r4;
  assign out6 = z6 ^ r5;
  assign out7 = z7 ^ r3 ^ r4 ^ r5;
endmodule // Stage3

module gf24mul_factoring (in0, in1, ff, f, h, l, out0);
  input [3:0] in0, in1;
  output [3:0] out0;
  input [1:0] ff;
  input f, h, l;
  wire [1:0] a0, a1, p0, p1, p2, b0;

  assign a1 = ff;
  assign a0 = in0[3:2] ^ in0[1:0];

  gf22mul_scl_factoring mulf0 (.in0(a0), .in1(a1), .f(f), .out0(p2));
  gf22mul_factoring mulf1 (.in0(in0[3:2]), .in1(in1[3:2]), .f(h), .out0(p1));
  gf22mul_factoring mulf2 (.in0(in0[1:0]), .in1(in1[1:0]), .f(l), .out0(p0));

  assign out0 = {p1^p2, p0^p2};
endmodule // gf24mul

module gf22mul_scl_factoring (in0, in1, f, out0);
  input [1:0] in0, in1;
  input f;
  output [1:0] out0;
  wire a0, a1, p0, p1, p2;

  assign {a1, a0} = {f, ^in0};
  assign {p2, p1, p0} = {~(a1&a0), ~(in1&in0)};
  assign out0 = {p2^p0, p1^p0};
endmodule // gf22mul

module gf22mul_factoring (in0, in1, f, out0);
  input [1:0] in0, in1;
  input f;
  output [1:0] out0;
  wire a0, a1, p0, p1, p2;

  assign {a1, a0} = {f, ^in0};
  assign {p2, p1, p0} = {~(a1&a0), ~(in1&in0)};
  assign out0 = {p2^p1, p2^p0};
endmodule // gf22mul


module Stage2 (in0, in1, in2, in3,
               out0, out1, out2, out3, out4, out5, out6, out7,
               r0, r1, r2, r3, r4, r5, r6);
  input [3:0] in0, in1, in2, in3;
  output [3:0] out0, out1, out2, out3, out4, out5, out6, out7;
  // input [3:0] r0, r1, r2, r3, r4, r5, r6;
  input [3:0] r0, r1, r2;
  input [3:0] r3, r4, r5, r6;
  wire a0, a1, a2, a3, b0, b1, b2, b3;
  wire aa02, aa03, aa12, aa13;
  wire ab02, ab03, ab12, ab13;
  wire ba02, ba03, ba12, ba13;
  wire bb02, bb03, bb12, bb13;
  wire aba013, aba123;
  wire abb012, abb013;
  wire baa012, baa013;
  wire bab013, bab123;
  wire aab123, bba123;
  wire [3:0] z000, z001, z010, z011, z100, z101, z110, z111;

  // Compression
  assign {a3, a2, a1, a0} = in0 ^ in1;
  assign {b3, b2, b1, b0} = in2 ^ in3;

  // Nonlinear layer
  /* assign aa01 = a0 & a1; assign ab01 = a0 & b1; assign ba01 = b0 & a1; assign bb01 = b0 & b1; */
  assign aa02 = a0 & a2;  assign ab02 = a0 & b2;  assign ba02 = b0 & a2;  assign bb02 = b0 & b2;
  assign aa03 = a0 & a3;  assign ab03 = a0 & b3;  assign ba03 = b0 & a3;  assign bb03 = b0 & b3;
  assign aa12 = a1 & a2;  assign ab12 = a1 & b2;  assign ba12 = b1 & a2;  assign bb12 = b1 & b2;
  assign aa13 = a1 & a3;  assign ab13 = a1 & b3;  assign ba13 = b1 & a3;  assign bb13 = b1 & b3;
  /* assign aa23 = a2 & a3;  assign ab23 = a2 & b3;  assign ba23 = b2 & a3;  assign bb23 = b2 & b3; */

  /* assign aaa012 = aa01&a2; assign aaa013 = aa13&a0; assign aaa023 = aa02&a3; assign aaa123 = aa23&a1; */
  /* assign aab012 = aa01&b2; assign aab013 = ab13&a0; assign aab023 = aa02&b3; */ assign aab123 = ab13&a2;
  /* assign aba012 = ab01&a2; */ assign aba013 = aa03&b1; /* assign aba023 = ab02&a3; */ assign aba123 = aa13&b2;
  assign abb012 = bb12&a0; assign abb013 = ab03&b1; /* assign abb023 = ab02&b3; assign abb123 = bb23&a1; */
  assign baa012 = aa12&b0; assign baa013 = ba03&a1; /* assign baa023 = ba02&a3; assign baa123 = aa23&b1; */
  /* assign bab012 = ba01&b2; */ assign bab013 = bb03&a1; /* assign bab023 = ba02&b3; */ assign bab123 = bb13&a2;
  /* assign bba012 = bb01&a2; assign bba013 = ba13&b0; assign bba023 = bb02&a3; */ assign bba123 = ba13&b2;
  /* assign bbb012 = bb01&b2; assign bbb013 = bb13&b0; assign bbb023 = bb02&b3; assign bbb123 = bb23&b1; */

  // // Linear layer
  assign z000 = {aa12|a0, aa13|a0, aa03|a2, aa13|a2};
  assign z001 = {ab12&(~a0), ab13&(~a0), ab03&(~a2), ab13&(~a2)^ab03};
  assign z010 = {b1&(~aa02^b3), aba013^ba12^aa02, a3&(~ab02^a1), aba123^ab02};
  assign z011 = {abb012^ba13, abb013^ab02^bb12, b3&(ab02^a1), b2&(ab13^b0)^bb03};
  assign z100 = {baa012^ab13, baa013^ba02^aa12, a3&(ba02^b1), a2&(ba13^a0)^aa03};
  assign z101 = {a1&(~bb02^a3), bab013^ab12^bb02, b3&(~ba02^b1), bab123^ba02};
  assign z110 = {ba12&(~b0), ba13&(~b0), ba03&(~b2), ba13&(~b2)^ba03};
  assign z111 = {bb12|b0, bb13|b0, bb03|b2, bb13|b2};

  // // Refreshing layer
  assign out0 = z000 ^ r0;
  assign out1 = z001 ^ r1;
  assign out2 = z010 ^ r2;
  assign out3 = z011 ^ r3;
  assign out4 = z100 ^ r4;
  assign out5 = z101 ^ r5;
  assign out6 = z110 ^ r6;
  assign out7 = z111 ^ r0 ^ r1 ^ r2 ^ r3 ^ r4 ^ r5 ^ r6;
endmodule // Stage2


module Stage1 (in00, in01, in10, in11, out0, out1, out2, out3, r0, r1, r2);
  input [3:0] in00, in01, in10, in11; // in0 = in00 + in01, in1 = in10 + in11
  output [3:0] out0, out1, out2, out3;
  input [3:0] r0, r1, r2; // fresh masks
  wire [3:0] p0, p1, p2, p3, s0, s1;

  gf24mul mul0 (.in0(in00), .in1(in10), .out0(p0));
  gf24mul mul1 (.in0(in00), .in1(in11), .out0(p1));
  gf24mul mul2 (.in0(in01), .in1(in10), .out0(p2));
  gf24mul mul3 (.in0(in01), .in1(in11), .out0(p3));

  SqSc SqSc0 (.in0(in00^in10), .out0(s0));
  SqSc SqSc1 (.in0(in01^in11), .out0(s1));

  assign out0 = p0 ^ r0 ^ s0;
  assign out1 = p1 ^ r1;
  assign out2 = p2 ^ (r0 ^ r1 ^ r2);
  assign out3 = p3 ^ s1 ^ r2;
endmodule // Stage1

module SqSc (in0, out0);
  input [3:0] in0;
  output [3:0] out0;
  wire [1:0] a, a2, b;

  assign a = in0[3:2] ^ in0[1:0];
  assign a2 = {a[0], a[1]};
  assign b = {in0[1]^in0[0], in0[0]};
  assign out0 = {a2, b};
endmodule // SqSc

module gf28mul (in0, in1, out0);
  input [7:0] in0, in1;
  output [7:0] out0;
  wire [3:0] a1, a0, p2, p1, p0, s0;
  
  assign a1 = in1[7:4] ^ in1[3:0];
  assign a0 = in0[7:4] ^ in0[3:0];
  
  gf24mul mul0 (.in0(a1), .in1(a0), .out0(p2));
  gf24mul mul1 (.in0(in0[7:4]), .in1(in1[7:4]), .out0(p1));
  gf24mul mul2 (.in0(in0[3:0]), .in1(in1[3:0]), .out0(p0));

  Scaler Sc (.in0(p2), .out0(s0));
  // gf24mul s9 (.in0(p2), .in1(4'h1), .out0(s0));
  assign out0 = {p1^s0, p0^s0};
endmodule

module Scaler (in0, out0);
  input [3:0] in0;
  output [3:0] out0;
  wire [1:0] a, a2, b;

  assign a = in0[3:2] ^ in0[1:0];
  assign b = {in0[0], in0[1] ^ in0[0]} ^ in0[3:2];
  assign out0 = {a, b};
endmodule // SqSc

module gf24mul (in0, in1, out0);
  input [3:0] in0, in1;
  output [3:0] out0;
  wire [1:0] a0, a1, p0, p1, p2;

  assign a1 = in1[3:2] ^ in1[1:0];
  assign a0 = in0[3:2] ^ in0[1:0];

  gf22mul_scaling mul0 (.in0(a1), .in1(a0), .out0(p2));
  gf22mul mul1 (.in0(in0[3:2]), .in1(in1[3:2]), .out0(p1));
  gf22mul mul2 (.in0(in0[1:0]), .in1(in1[1:0]), .out0(p0));

  assign out0 = {p1^p2, p0^p2};
endmodule // gf24mul

module gf22mul_scaling (in0, in1, out0);
  input [1:0] in0, in1;
  output [1:0] out0;
  wire a0, a1, p0, p1, p2;

  assign {a1, a0} = {^in1, ^in0};
  assign {p2, p1, p0} = {~(a1&a0), ~(in1&in0)};
  assign out0 = {p2^p0, p1^p0};
endmodule // gf22mul

module gf22mul (in0, in1, out0);
  input [1:0] in0, in1;
  output [1:0] out0;
  wire a0, a1, p0, p1, p2;

  assign {a1, a0} = {^in1, ^in0};
  assign {p2, p1, p0} = {~(a1&a0), ~(in1&in0)};
  assign out0 = {p2^p1, p2^p0};
endmodule // gf22mul


// c = 0b10000110 (0d86)
// input: PB, output: NB
module iso (in0, out0);
  input [7:0] in0;
  output [7:0] out0;

  assign out0[0] = in0[4]^in0[5];
  assign out0[1] = in0[1]^in0[3]^in0[4]^in0[6];
  assign out0[2] = in0[0]^in0[1]^in0[2]^in0[5]^in0[7];
  assign out0[3] = in0[4]^in0[5]^in0[7];
  assign out0[4] = in0[0]^in0[3];
  assign out0[5] = in0[1]^in0[4]^in0[5]^in0[7];
  assign out0[6] = in0[4]^in0[5]^in0[6]^in0[7];
  assign out0[7] = in0[0]^in0[4]^in0[5];
endmodule // iso

module inviso (in0, out0);
  input [7:0] in0;
  output [7:0] out0;

  assign out0[0] = in0[0]^in0[7];
  assign out0[1] = in0[3]^in0[5];
  assign out0[2] = in0[1]^in0[2]^in0[4]^in0[6];
  assign out0[3] = in0[0]^in0[4]^in0[7];
  assign out0[4] = in0[0]^in0[1]^in0[4]^in0[5]^in0[6]^in0[7];
  assign out0[5] = in0[1]^in0[4]^in0[5]^in0[6]^in0[7];
  assign out0[6] = in0[3]^in0[6];
  assign out0[7] = in0[0]^in0[3];
endmodule // inviso


module inversion_TI_test (in0, in1, out0, out1, r, CLK);
  input [7:0] in0, in1;
  output [7:0] out0, out1;
  input [63:0] r;
  input CLK;
  wire [7:0] c0, c1;
  reg [3:0] s0reg, s1reg, s2reg, s3reg, i0reg, i1reg, i2reg, i3reg, i4reg, i5reg, i6reg, i7reg,
            h00reg, h01reg, h10reg, h11reg, l00reg, l01reg, l10reg, l11reg,
            t0reg, t1reg, t2reg, t3reg, u0reg, u1reg, u2reg, u3reg;
  reg [7:0] c0reg, c1reg, c00reg, c11reg;

  iso iso0 (.in0(in0), .out0(c0));
  iso iso1 (.in0(in1), .out0(c1));

  wire [3:0] s0, s1, s2, s3;
  Stage1 S1 (.in00(c0reg[3:0]), .in01(c1reg[3:0]), .in10(c0reg[7:4]), .in11(c1reg[7:4]),
             .out0(s0), .out1(s1), .out2(s2), .out3(s3), .r0(r[47:44]), .r1(r[43:40]), .r2(r[39:36]));

  wire [3:0] i0, i1, i2, i3, i4, i5, i6, i7;
  Stage2 S2 (.in0(s0reg), .in1(s1reg), .in2(s2reg), .in3(s3reg),
             .out0(i0), .out1(i1), .out2(i2), .out3(i3), .out4(i4), .out5(i5), .out6(i6), .out7(i7),
             .r0(r[35:32]), .r1(r[31:28]), .r2(r[27:24]), .r3(r[51:48]), .r4(r[55:52]), .r5(r[59:56]), .r6(r[63:60]));

  wire [3:0] t0, t1, t2, t3, u0, u1, u2, u3;
  Stage3 S3 (.inh0(c00reg[7:4]), .inh1(c11reg[7:4]), .inl0(c00reg[3:0]), .inl1(c11reg[3:0]),
             .in0(i0), .in1(i1), .in2(i2), .in3(i3), .in4(i4), .in5(i5), .in6(i6), .in7(i7),
             .out0(t0), .out1(t1), .out2(t2), .out3(t3), .out4(u0), .out5(u1), .out6(u2), .out7(u3),
             .r0(r[23:20]), .r1(r[19:16]), .r2(r[15:12]), .r3(r[11:8]), .r4(r[7:4]), .r5(r[3:0]));
  affine iia0 (.in0({t0reg^t1reg, u0reg^u1reg}), .out0(out0));
  affine iia1 (.in0({t2reg^t3reg, u2reg^u3reg}), .out0(out1));

  always @(posedge CLK) begin
    s0reg <= s0; s1reg <= s1; s2reg <= s2; s3reg <= s3;
    i0reg <= i0; i1reg <= i1; i2reg <= i2; i3reg <= i3; i4reg <= i4; i5reg <= i5; i6reg <= i6;
    h00reg <= in0[7:4]; h01reg <= in0[7:4]; l00reg <= in0[3:0]; l01reg <= in0[3:0];
    h10reg <= h00reg; h11reg <= h01reg; l10reg <= l00reg; l11reg <= l01reg;
    t0reg <= t0; t1reg <= t1; t2reg <= t2; t3reg <= t3;
    u0reg <= u0; u1reg <= u1; u2reg <= u2; u3reg <= u3;
    c0reg <= c0; c1reg <= c1; c00reg <= c0reg; c11reg <= c1reg;
  end
endmodule // Sbox_TI

module inviso16 (in0, out0);
  input [127:0] in0;
  output [127:0] out0;

  inviso inviso0 (.in0(in0[7:0]), .out0(out0[7:0]));
  inviso inviso1 (.in0(in0[15:8]), .out0(out0[15:8]));
  inviso inviso2 (.in0(in0[23:16]), .out0(out0[23:16]));
  inviso inviso3 (.in0(in0[31:24]), .out0(out0[31:24]));
  inviso inviso4 (.in0(in0[39:32]), .out0(out0[39:32]));
  inviso inviso5 (.in0(in0[47:40]), .out0(out0[47:40]));
  inviso inviso6 (.in0(in0[55:48]), .out0(out0[55:48]));
  inviso inviso7 (.in0(in0[63:56]), .out0(out0[63:56]));
  inviso inviso8 (.in0(in0[71:64]), .out0(out0[71:64]));
  inviso inviso9 (.in0(in0[79:72]), .out0(out0[79:72]));
  inviso inviso10 (.in0(in0[87:80]), .out0(out0[87:80]));
  inviso inviso11 (.in0(in0[95:88]), .out0(out0[95:88]));
  inviso inviso12 (.in0(in0[103:96]), .out0(out0[103:96]));
  inviso inviso13 (.in0(in0[111:104]), .out0(out0[111:104]));
  inviso inviso14 (.in0(in0[119:112]), .out0(out0[119:112]));
  inviso inviso15 (.in0(in0[127:120]), .out0(out0[127:120]));
endmodule // inviso16

module iso16 (in0, out0);
  input [127:0] in0;
  output [127:0] out0;

  iso iso0 (.in0(in0[7:0]), .out0(out0[7:0]));
  iso iso1 (.in0(in0[15:8]), .out0(out0[15:8]));
  iso iso2 (.in0(in0[23:16]), .out0(out0[23:16]));
  iso iso3 (.in0(in0[31:24]), .out0(out0[31:24]));
  iso iso4 (.in0(in0[39:32]), .out0(out0[39:32]));
  iso iso5 (.in0(in0[47:40]), .out0(out0[47:40]));
  iso iso6 (.in0(in0[55:48]), .out0(out0[55:48]));
  iso iso7 (.in0(in0[63:56]), .out0(out0[63:56]));
  iso iso8 (.in0(in0[71:64]), .out0(out0[71:64]));
  iso iso9 (.in0(in0[79:72]), .out0(out0[79:72]));
  iso iso10 (.in0(in0[87:80]), .out0(out0[87:80]));
  iso iso11 (.in0(in0[95:88]), .out0(out0[95:88]));
  iso iso12 (.in0(in0[103:96]), .out0(out0[103:96]));
  iso iso13 (.in0(in0[111:104]), .out0(out0[111:104]));
  iso iso14 (.in0(in0[119:112]), .out0(out0[119:112]));
  iso iso15 (.in0(in0[127:120]), .out0(out0[127:120]));
endmodule // iso16
