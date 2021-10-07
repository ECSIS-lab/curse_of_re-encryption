/*-----------------------------------------
 Testbench for Tohoku AES hardware macro

 File name: AES_tb.v
 Version: Version 1.0
 Created: December 1, 2016
 Last update: December 1, 2016
 Designed by: Rei Ueno

 Copyright (c) Tohoku Univ.
-------------------------------------------*/

`timescale 1ns/1ps

module AES_tb;
  parameter CLOCK = 100;

  reg [127:0] PT;
  reg [127:0] IK;
  wire [127:0] CT, Kout;
  // wire [127:0] PT, IK;
  reg CLK, RSTn, Drdy, Krdy, EN;
  reg [7:0] Din, Kin;
  reg [511:0] rs;
  wire Dvld, Kvld, BSY, Rvld, trig;
  integer i, j0, j1;

  AES_TI_core AES (.Din0(PT), .Kin(IK), .Dout0(CT),
                .CLK(CLK), .RSTn(RSTn), .Drdy(Drdy), .Krdy(Krdy),
                .Dvld(Dvld), .Kvld(Kvld), .BSY(BSY), .EN(EN), .round9(trig));

  always #(CLOCK/2)
    CLK <= ~CLK;

  initial begin
    CLK <= 1;
    rs <= $random;

    // For encryption
    PT <= 128'h00112233445566778899aabbccddeeff;
    IK <= 128'h000102030405060708090a0b0c0d0e0f;

    // // Ciphertext and final round key for test vector
    // PT <= 128'h69c4e0d86a7b0430d8cdb78070b4c55a;
    // IK = 128'h13111d7fe3944a17f307a78b4d2b30c5;

    #(CLOCK/2)
    RSTn <= 0;  Din <= 0; Kin <= 0; EN <= 0; Drdy <= 0; Krdy <= 0;

    #(CLOCK)
    RSTn <= 1; Krdy <= 1; EN <= 1;

    #(CLOCK)
    Drdy <= 1; Krdy <= 0;
    #(CLOCK)
    Drdy <= 0;
    #(CLOCK*3)
    $display("Debug: %h", AES.l00^AES.l01^AES.l10^AES.l11);
    #(CLOCK*218)

    $display("Input data (Plaintext) : %h", PT);
    $display("Input key (First round key) : %h", IK);
    $display("Output data (Ciphertext): %h", CT);
    $finish;
  end // initial begin
endmodule // AES_tb

