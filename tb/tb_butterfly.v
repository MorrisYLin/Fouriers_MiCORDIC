`timescale 1ns/1ps

module tb_butterfly;

    localparam DATA_WIDTH = 21;
    localparam FRAC_BITS  = 15;

    // Q15 twiddle for W16^1 = cos(2π/16) - j sin(2π/16)
    localparam signed [15:0] TW_RE_Q15 =  16'sd30274;   // ≈ 0.9239
    localparam signed [15:0] TW_IM_Q15 = -16'sd12540;   // ≈ -0.3827

    // DUT ports: each complex number is [0] = Re, [1] = Im
    reg  signed [DATA_WIDTH-1:0] twid_i [0:1];
    reg  signed [DATA_WIDTH-1:0] a_i    [0:1];
    reg  signed [DATA_WIDTH-1:0] b_i    [0:1];

    wire signed [DATA_WIDTH-1:0] a_o    [0:1];
    wire signed [DATA_WIDTH-1:0] b_o    [0:1];

    // Instantiate DUT
    butterfly #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC_BITS (FRAC_BITS)
    ) dut (
        .twid_i(twid_i),
        .a_i   (a_i),
        .b_i   (b_i),
        .a_o   (a_o),
        .b_o   (b_o)
    );

    // Fixed-point → decimal helper
    function real fxp_to_dec;
        input signed [DATA_WIDTH-1:0] val;
        begin
            fxp_to_dec = $itor(val) / (1.0 * (1 << FRAC_BITS));
        end
    endfunction

    // Q-format constants (Q(FRAC_BITS))
    localparam signed [DATA_WIDTH-1:0] Q_ONE         = (21'sd1 <<< FRAC_BITS);       // 1.0
    localparam signed [DATA_WIDTH-1:0] Q_ONE_HALF    = (21'sd1 <<< (FRAC_BITS-1));   // 0.5
    localparam signed [DATA_WIDTH-1:0] Q_ONE_QUARTER = (21'sd1 <<< (FRAC_BITS-2));   // 0.25

    initial begin
        // VCD dump
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_butterfly);

        $display("=== Butterfly (array I/O) testbench start ===");

        // ------------------------------------------------
        // Sign-extend Q15 twiddle to 21-bit Q5.15
        // twid_i[0] = Re{W}, twid_i[1] = Im{W}
        // ------------------------------------------------
        twid_i[0] = {{(DATA_WIDTH-16){TW_RE_Q15[15]}}, TW_RE_Q15};
        twid_i[1] = {{(DATA_WIDTH-16){TW_IM_Q15[15]}}, TW_IM_Q15};

        // =================================================
        // Test vector 1
        // A = 0.5 + j0
        // B = 0.25 + j0.25
        // =================================================
        a_i[0] = Q_ONE_HALF;      // Re(A)
        a_i[1] = 21'sd0;          // Im(A)

        b_i[0] = Q_ONE_QUARTER;   // Re(B)
        b_i[1] = Q_ONE_QUARTER;   // Im(B)

        #1; // allow combinational logic to settle

        $display("\n--- Test 1 ---");
        $display("Twiddle W16^1 (decimal): re=%.6f, im=%.6f",
                 fxp_to_dec(twid_i[0]),
                 fxp_to_dec(twid_i[1]));

        $display("Inputs:");
        $display("  A = (%.6f, %.6f)",
                 fxp_to_dec(a_i[0]), fxp_to_dec(a_i[1]));
        $display("  B = (%.6f, %.6f)",
                 fxp_to_dec(b_i[0]), fxp_to_dec(b_i[1]));

        // Access internal rotated B via hierarchical reference
        $display("Rotation (B_rot = B * W):");
        $display("  B_rot = (%.6f, %.6f)",
                 fxp_to_dec(dut.b_rot_re),
                 fxp_to_dec(dut.b_rot_im));

        $display("Outputs:");
        $display("  A' = (%.6f, %.6f)",
                 fxp_to_dec(a_o[0]), fxp_to_dec(a_o[1]));
        $display("  B' = (%.6f, %.6f)",
                 fxp_to_dec(b_o[0]), fxp_to_dec(b_o[1]));

        // =================================================
        // Test vector 2
        // A = 1.0 + j0
        // B = 0.0 - j0.5
        // =================================================
        a_i[0] = Q_ONE;           // Re(A)
        a_i[1] = 21'sd0;          // Im(A)

        b_i[0] = 21'sd0;          // Re(B)
        b_i[1] = -Q_ONE_HALF;     // Im(B)

        #1;

        $display("\n--- Test 2 ---");
        $display("Inputs:");
        $display("  A = (%.6f, %.6f)",
                 fxp_to_dec(a_i[0]), fxp_to_dec(a_i[1]));
        $display("  B = (%.6f, %.6f)",
                 fxp_to_dec(b_i[0]), fxp_to_dec(b_i[1]));

        $display("Rotation (B_rot = B * W):");
        $display("  B_rot = (%.6f, %.6f)",
                 fxp_to_dec(dut.b_rot_re),
                 fxp_to_dec(dut.b_rot_im));

        $display("Outputs:");
        $display("  A' = (%.6f, %.6f)",
                 fxp_to_dec(a_o[0]), fxp_to_dec(a_o[1]));
        $display("  B' = (%.6f, %.6f)",
                 fxp_to_dec(b_o[0]), fxp_to_dec(b_o[1]));

        $display("\n=== Butterfly (array I/O) testbench end ===");
        $finish;
    end

endmodule
