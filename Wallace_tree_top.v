`timescale 1ns/1ps
`default_nettype none

// -------------------------------------------------
// 16x16 Unsigned Wallace-Tree Multiplier (compact)
// -------------------------------------------------
module wallace16x16 (
    input  wire [15:0] a,
    input  wire [15:0] b,
    output wire [31:0] p
);
    // --- helper: 32-bit CSA (carry already left-shifted by 1) ---
    function [31:0] csa_sum;
        input [31:0] x, y, z;
        begin csa_sum = x ^ y ^ z; end
    endfunction

    function [31:0] csa_carry_shifted;
        input [31:0] x, y, z;
        begin csa_carry_shifted = ((x & y) | (y & z) | (x & z)) << 1; end
    endfunction

    // --- partial products (aligned) ---
    wire [31:0] pp0  = b[0]  ? {16'b0, a} << 0  : 32'b0;
    wire [31:0] pp1  = b[1]  ? {16'b0, a} << 1  : 32'b0;
    wire [31:0] pp2  = b[2]  ? {16'b0, a} << 2  : 32'b0;
    wire [31:0] pp3  = b[3]  ? {16'b0, a} << 3  : 32'b0;
    wire [31:0] pp4  = b[4]  ? {16'b0, a} << 4  : 32'b0;
    wire [31:0] pp5  = b[5]  ? {16'b0, a} << 5  : 32'b0;
    wire [31:0] pp6  = b[6]  ? {16'b0, a} << 6  : 32'b0;
    wire [31:0] pp7  = b[7]  ? {16'b0, a} << 7  : 32'b0;
    wire [31:0] pp8  = b[8]  ? {16'b0, a} << 8  : 32'b0;
    wire [31:0] pp9  = b[9]  ? {16'b0, a} << 9  : 32'b0;
    wire [31:0] pp10 = b[10] ? {16'b0, a} << 10 : 32'b0;
    wire [31:0] pp11 = b[11] ? {16'b0, a} << 11 : 32'b0;
    wire [31:0] pp12 = b[12] ? {16'b0, a} << 12 : 32'b0;
    wire [31:0] pp13 = b[13] ? {16'b0, a} << 13 : 32'b0;
    wire [31:0] pp14 = b[14] ? {16'b0, a} << 14 : 32'b0;
    wire [31:0] pp15 = b[15] ? {16'b0, a} << 15 : 32'b0;

    // -------------------------
    // Stage 1: 16 -> 11 rows
    // groups: (0,1,2) (3,4,5) (6,7,8) (9,10,11) (12,13,14) + pp15
    // -------------------------
    wire [31:0] s1_0 = csa_sum          (pp0 , pp1 , pp2 );
    wire [31:0] c1_0 = csa_carry_shifted(pp0 , pp1 , pp2 );
    wire [31:0] s1_1 = csa_sum          (pp3 , pp4 , pp5 );
    wire [31:0] c1_1 = csa_carry_shifted(pp3 , pp4 , pp5 );
    wire [31:0] s1_2 = csa_sum          (pp6 , pp7 , pp8 );
    wire [31:0] c1_2 = csa_carry_shifted(pp6 , pp7 , pp8 );
    wire [31:0] s1_3 = csa_sum          (pp9 , pp10, pp11);
    wire [31:0] c1_3 = csa_carry_shifted(pp9 , pp10, pp11);
    wire [31:0] s1_4 = csa_sum          (pp12, pp13, pp14);
    wire [31:0] c1_4 = csa_carry_shifted(pp12, pp13, pp14);
    wire [31:0] r1_10 = pp15;

    // rows after stage1: s1_0..4, c1_0..4, r1_10  => 11 rows

    // -------------------------
    // Stage 2: 11 -> 8 rows
    // groups: (s1_0,c1_0,s1_1) (c1_1,s1_2,c1_2) (s1_3,c1_3,s1_4) + c1_4, r1_10
    // -------------------------
    wire [31:0] s2_0 = csa_sum          (s1_0, c1_0, s1_1);
    wire [31:0] c2_0 = csa_carry_shifted(s1_0, c1_0, s1_1);
    wire [31:0] s2_1 = csa_sum          (c1_1, s1_2, c1_2);
    wire [31:0] c2_1 = csa_carry_shifted(c1_1, s1_2, c1_2);
    wire [31:0] s2_2 = csa_sum          (s1_3, c1_3, s1_4);
    wire [31:0] c2_2 = csa_carry_shifted(s1_3, c1_3, s1_4);
    wire [31:0] r2_6 = c1_4;
    wire [31:0] r2_7 = r1_10;

    // rows after stage2: s2_0,c2_0,s2_1,c2_1,s2_2,c2_2,r2_6,r2_7  => 8 rows

    // -------------------------
    // Stage 3: 8 -> 6 rows
    // groups: (s2_0,c2_0,s2_1) (c2_1,s2_2,c2_2) + r2_6, r2_7
    // -------------------------
    wire [31:0] s3_0 = csa_sum          (s2_0, c2_0, s2_1);
    wire [31:0] c3_0 = csa_carry_shifted(s2_0, c2_0, s2_1);
    wire [31:0] s3_1 = csa_sum          (c2_1, s2_2, c2_2);
    wire [31:0] c3_1 = csa_carry_shifted(c2_1, s2_2, c2_2);
    wire [31:0] r3_4 = r2_6;
    wire [31:0] r3_5 = r2_7;

    // rows after stage3: s3_0,c3_0,s3_1,c3_1,r3_4,r3_5  => 6 rows

    // -------------------------
    // Stage 4: 6 -> 4 rows
    // groups: (s3_0,c3_0,s3_1) (c3_1,r3_4,r3_5)
    // -------------------------
    wire [31:0] s4_0 = csa_sum          (s3_0, c3_0, s3_1);
    wire [31:0] c4_0 = csa_carry_shifted(s3_0, c3_0, s3_1);
    wire [31:0] s4_1 = csa_sum          (c3_1, r3_4, r3_5);
    wire [31:0] c4_1 = csa_carry_shifted(c3_1, r3_4, r3_5);

    // rows after stage4: s4_0,c4_0,s4_1,c4_1  => 4 rows

    // -------------------------
    // Stage 5: 4 -> 3 rows
    // groups: (s4_0,c4_0,s4_1) + c4_1
    // -------------------------
    wire [31:0] s5_0 = csa_sum          (s4_0, c4_0, s4_1);
    wire [31:0] c5_0 = csa_carry_shifted(s4_0, c4_0, s4_1);
    wire [31:0] r5_2 = c4_1;

    // rows after stage5: s5_0,c5_0,r5_2  => 3 rows

    // -------------------------
    // Stage 6: 3 -> 2 rows
    // group: (s5_0,c5_0,r5_2)
    // -------------------------
    wire [31:0] s6_0 = csa_sum          (s5_0, c5_0, r5_2);
    wire [31:0] c6_0 = csa_carry_shifted(s5_0, c5_0, r5_2);

    // final carry-propagate add
    assign p = s6_0 + c6_0;

endmodule

`default_nettype wire
