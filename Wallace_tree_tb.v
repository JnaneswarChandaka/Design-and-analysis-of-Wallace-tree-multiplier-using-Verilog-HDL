
`timescale 1ns/1ps
`default_nettype none

module tb_wallace16x16_multi;
    reg  [15:0] a, b;
    wire [31:0] p;
    integer i;

    // Instantiate DUT
    wallace16x16 uut (
        .a(a),
        .b(b),
        .p(p)
    );

    // Test vectors: {a, b, expected_product}
    reg [15:0] A_vec [0:3];
    reg [15:0] B_vec [0:3];
    reg [31:0] Exp_vec [0:3];

    initial begin
        // Define test cases
        A_vec[0] = 16'd12;  B_vec[0] = 16'd12;  Exp_vec[0] = 32'd144;  // 12x12
        A_vec[1] = 16'd15;  B_vec[1] = 16'd10;  Exp_vec[1] = 32'd150;  // 15x10
        A_vec[2] = 16'd25;  B_vec[2] = 16'd4;   Exp_vec[2] = 32'd100;  // optional extra
        A_vec[3] = 16'd255; B_vec[3] = 16'd255; Exp_vec[3] = 32'd65025;// stress test

        $display("=============================================");
        $display("  16x16 Wallace Tree Multiplier Verification ");
        $display("=============================================");

        for (i = 0; i < 4; i = i + 1) begin
            a = A_vec[i];
            b = B_vec[i];
            #5; // wait for propagation

            $display("\nTest %0d:", i);
            $display(" a = %0d (0x%0h)", a, a);
            $display(" b = %0d (0x%0h)", b, b);
            $display(" Product = %0d (0x%0h)", p, p);

            if (p == Exp_vec[i])
                $display("PASS: %0d × %0d = %0d", a, b, p);
            else
                $display("FAIL: Expected %0d, got %0d", Exp_vec[i], p);
        end

        $display("\nAll testcases completed.");
        $finish;
    end
endmodule

`default_nettype wire
