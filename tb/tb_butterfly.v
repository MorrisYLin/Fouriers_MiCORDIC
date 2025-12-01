`timescale 1ns/1ps

module tb_butterfly;

    localparam DATA_WIDTH = 21;
    localparam FRAC_BITS  = 15;

    // Q15 twiddle for W16^1 = cos(2π/16) - j sin(2π/16)
    localparam signed [15:0] TW_RE_Q15 =  16'sd30274;   // ≈ 0.9239
    localparam signed [15:0] TW_IM_Q15 = -16'sd12540;   // ≈ -0.3827

    // DUT ports
    reg  signed [DATA_WIDTH-1:0] twid_re_i;
    reg  signed [DATA_WIDTH-1:0] twid_im_i;
    reg  signed [DATA_WIDTH-1:0] a_re_i;
    reg  signed [DATA_WIDTH-1:0] a_im_i;
    reg  signed [DATA_WIDTH-1:0] b_re_i;
    reg  signed [DATA_WIDTH-1:0] b_im_i;

    wire signed [DATA_WIDTH-1:0] a_re_o;
    wire signed [DATA_WIDTH-1:0] a_im_o;
    wire signed [DATA_WIDTH-1:0] b_re_o;
    wire signed [DATA_WIDTH-1:0] b_im_o;

    // Instantiate DUT
    butterfly #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC_BITS (FRAC_BITS)
    ) dut (
        .twid_re_i(twid_re_i),
        .twid_im_i(twid_im_i),
        .a_re_i   (a_re_i),
        .a_im_i   (a_im_i),
        .b_re_i   (b_re_i),
        .b_im_i   (b_im_i),
        .a_re_o   (a_re_o),
        .a_im_o   (a_im_o),
        .b_re_o   (b_re_o),
        .b_im_o   (b_im_o)
    );

    // Fixed-point → decimal helper
    function real fxp_to_dec;
        input signed [DATA_WIDTH-1:0] val;
        begin
            fxp_to_dec = $itor(val) / (1.0 * (1 << FRAC_BITS));
        end
    endfunction

    // Q-format constants (Q(FRAC_BITS))
    localparam signed [DATA_WIDTH-1:0] Q_ONE         = 21'sd1 <<< FRAC_BITS;         // 1.0
    localparam signed [DATA_WIDTH-1:0] Q_ONE_HALF    = 21'sd1 <<< (FRAC_BITS-1);     // 0.5
    localparam signed [DATA_WIDTH-1:0] Q_ONE_QUARTER = 21'sd1 <<< (FRAC_BITS-2);     // 0.25

    initial begin
        // VCD dump
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_butterfly);

        $display("=== Butterfly testbench start ===");

        // Sign-extend Q15 twiddle to 21-bit Q5.15
        twid_re_i = {{(DATA_WIDTH-16){TW_RE_Q15[15]}}, TW_RE_Q15};
        twid_im_i = {{(DATA_WIDTH-16){TW_IM_Q15[15]}}, TW_IM_Q15};

        // -------------------------------
        // Test vector 1
        // A = 0.5 + j0
        // B = 0.25 + j0.25
        // -------------------------------
        a_re_i = Q_ONE_HALF;
        a_im_i = 21'sd0;
        b_re_i = Q_ONE_QUARTER;
        b_im_i = Q_ONE_QUARTER;

        #1; // allow combinational logic to settle

        $display("\n--- Test 1 ---");
        $display("Twiddle W16^1 (decimal): re=%.6f, im=%.6f",
                 fxp_to_dec({{(DATA_WIDTH-16){TW_RE_Q15[15]}}, TW_RE_Q15}),
                 fxp_to_dec({{(DATA_WIDTH-16){TW_IM_Q15[15]}}, TW_IM_Q15}));

        $display("Inputs:");
        $display("  A = (%.6f, %.6f)", fxp_to_dec(a_re_i), fxp_to_dec(a_im_i));
        $display("  B = (%.6f, %.6f)", fxp_to_dec(b_re_i), fxp_to_dec(b_im_i));

        $display("Rotation:");
        $display("  B_rot = (%.6f, %.6f)", fxp_to_dec(dut.b_rot_re), fxp_to_dec(dut.b_rot_im));

        $display("Outputs:");
        $display("  A' = (%.6f, %.6f)", fxp_to_dec(a_re_o), fxp_to_dec(a_im_o));
        $display("  B' = (%.6f, %.6f)", fxp_to_dec(b_re_o), fxp_to_dec(b_im_o));

        // -------------------------------
        // Test vector 2
        // A = 1.0 + j0
        // B = 0.0 + j0.5
        // -------------------------------
        a_re_i = Q_ONE;
        a_im_i = 21'sd0;
        b_re_i = 21'sd0;
        b_im_i = Q_ONE_HALF;

        #1;

        $display("\n--- Test 2 ---");
        $display("Inputs:");
        $display("  A = (%.6f, %.6f)", fxp_to_dec(a_re_i), fxp_to_dec(a_im_i));
        $display("  B = (%.6f, %.6f)", fxp_to_dec(b_re_i), fxp_to_dec(b_im_i));

        $display("Rotation:");
        $display("  B_rot = (%.6f, %.6f)", fxp_to_dec(dut.b_rot_re), fxp_to_dec(dut.b_rot_im));

        $display("Outputs:");
        $display("  A' = (%.6f, %.6f)", fxp_to_dec(a_re_o), fxp_to_dec(a_im_o));
        $display("  B' = (%.6f, %.6f)", fxp_to_dec(b_re_o), fxp_to_dec(b_im_o));

        $display("\n=== Butterfly testbench end ===");
        $finish;
    end

endmodule
