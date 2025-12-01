module top_fft (
    input clk_i,
    input valid_i,
    input  [15:0] x_re_i [0:7],   // Time-domain, 8 real samples (Q1.15)
    output [20:0] y_re_o [0:7],   // Freq-domain, real
    output [20:0] y_im_o [0:7]    // Freq-domain, imag
);
    // ----------------------------------------------------------------
    // Parameters (match butterfly)
    // ----------------------------------------------------------------
    localparam DATA_WIDTH = 21;   // 16-bit input + 5 guard bits
    localparam FRAC_BITS  = 15;   // Q1.15 fixed point

    // ------------------------------
    // 21-bit signed Q5.15 Twiddles
    // ------------------------------
    localparam signed [20:0] TW_RE_0 = 21'h07FFF;  // +1.0000
    localparam signed [20:0] TW_RE_1 = 21'h05A82;  // +0.7071
    localparam signed [20:0] TW_RE_2 = 21'h00000;  //  0.0000
    localparam signed [20:0] TW_RE_3 = 21'h1A57E;  // -0.7071

    localparam signed [20:0] TW_IM_0 = 21'h00000;  //  0.0000
    localparam signed [20:0] TW_IM_1 = 21'h1A57E;  // -0.7071
    localparam signed [20:0] TW_IM_2 = 21'h18000;  // -1.0000
    localparam signed [20:0] TW_IM_3 = 21'h1A57E;  // -0.7071

    // Inputs extended to 21 bits
    reg [20:0] x_re_signed [0:7];
    reg [20:0] x_im_signed [0:7];

    always @(*) begin
        for (int i = 0; i < 8; i = i + 1) begin
            x_re_signed[i] = {{5{x_re_i[i][15]}}, x_re_i[i]};
            x_im_signed[i] = 21'h000000;
        end
    end

    // Stage 0 outputs
    wire [20:0] s0_re [0:7];
    wire [20:0] s0_im [0:7];

    // Stage 0 butterflies
    butterfly #(
        .DATA_WIDTH(21),
        .FRAC_BITS(15)
    ) butter0_0 (
        // input clk_i,
        .twid_re_i(TW_RE_0),
        .twid_im_i(TW_IM_0),
        .a_re_i(x_re_signed[0]),
        .a_im_i(x_im_signed[0]),
        .b_re_i(x_re_signed[1]),
        .b_im_i(x_im_signed[1]),
        .a_re_o(s0_re[0]),
        .a_im_o(s0_im[0]),
        .b_re_o(s0_re[1]),
        .b_im_o(s0_re[1])
    );

    butterfly #(
        .DATA_WIDTH(21),
        .FRAC_BITS(15)
    ) butter0_1 (
        // input clk_i,
        .twid_re_i(TW_RE_0),
        .twid_im_i(TW_IM_0),
        .a_re_i(x_re_signed[2]),
        .a_im_i(x_im_signed[2]),
        .b_re_i(x_re_signed[3]),
        .b_im_i(x_im_signed[3]),
        .a_re_o(s0_re[2]),
        .a_im_o(s0_im[2]),
        .b_re_o(s0_re[3]),
        .b_im_o(s0_re[3])
    );

    butterfly #(
        .DATA_WIDTH(21),
        .FRAC_BITS(15)
    ) butter0_2 (
        // input clk_i,
        .twid_re_i(TW_RE_0),
        .twid_im_i(TW_IM_0),
        .a_re_i(x_re_signed[4]),
        .a_im_i(x_im_signed[4]),
        .b_re_i(x_re_signed[5]),
        .b_im_i(x_im_signed[5]),
        .a_re_o(s0_re[4]),
        .a_im_o(s0_im[4]),
        .b_re_o(s0_re[5]),
        .b_im_o(s0_re[5])
    );

    butterfly #(
        .DATA_WIDTH(21),
        .FRAC_BITS(15)
    ) butter0_3 (
        // input clk_i,
        .twid_re_i(TW_RE_0),
        .twid_im_i(TW_IM_0),
        .a_re_i(x_re_signed[6]),
        .a_im_i(x_im_signed[6]),
        .b_re_i(x_re_signed[7]),
        .b_im_i(x_im_signed[7]),
        .a_re_o(s0_re[6]),
        .a_im_o(s0_im[6]),
        .b_re_o(s0_re[7]),
        .b_im_o(s0_re[7])
    );

    // Stage 1 outputs
    wire [20:0] s1_re [0:7];
    wire [20:0] s1_im [0:7];

    // Stage 1 butterflies
    butterfly #(
        .DATA_WIDTH(21),
        .FRAC_BITS(15)
    ) butter1_0 (
        // input clk_i,
        .twid_re_i(),
        .twid_im_i(),
        .a_re_i(s0_re[0]),
        .a_im_i(s0_im[0]),
        .b_re_i(s0_re[2]),
        .b_im_i(s0_im[2]),
        .a_re_o(s1_re[0]),
        .a_im_o(s1_im[0]),
        .b_re_o(s1_re[2]),
        .b_im_o(s1_im[2])
    );

    butterfly #(
        .DATA_WIDTH(21),
        .FRAC_BITS(15)
    ) butter1_1 (
        // input clk_i,
        .twid_re_i(),
        .twid_im_i(),
        .a_re_i(s0_re[1]),
        .a_im_i(s0_im[1]),
        .b_re_i(s0_re[3]),
        .b_im_i(s0_im[3]),
        .a_re_o(s1_re[1]),
        .a_im_o(s1_im[1]),
        .b_re_o(s1_re[3]),
        .b_im_o(s1_im[3])
    );

    butterfly #(
        .DATA_WIDTH(21),
        .FRAC_BITS(15)
    ) butter1_2 (
        // input clk_i,
        .twid_re_i(),
        .twid_im_i(),
        .a_re_i(s0_re[4]),
        .a_im_i(s0_im[4]),
        .b_re_i(s0_re[6]),
        .b_im_i(s0_im[6]),
        .a_re_o(s1_re[4]),
        .a_im_o(s1_im[4]),
        .b_re_o(s1_re[6]),
        .b_im_o(s1_im[6])
    );

    butterfly #(
        .DATA_WIDTH(21),
        .FRAC_BITS(15)
    ) butter1_3 (
        // input clk_i,
        .twid_re_i(),
        .twid_im_i(),
        .a_re_i(s0_re[5]),
        .a_im_i(s0_im[5]),
        .b_re_i(s0_re[7]),
        .b_im_i(s0_im[7]),
        .a_re_o(s1_re[5]),
        .a_im_o(s1_im[5]),
        .b_re_o(s1_re[7]),
        .b_im_o(s1_im[7])
    );

    // Stage 2 Butterflies
    butterfly #(
        .DATA_WIDTH(21),
        .FRAC_BITS(15)
    ) butter2_0 (
        // input clk_i,
        .twid_re_i(),
        .twid_im_i(),
        .a_re_i(s1_re[0]),
        .a_im_i(s1_im[0]),
        .b_re_i(s1_re[4]),
        .b_im_i(s1_im[4]),
        .a_re_o(y_re_o[0]),
        .a_im_o(y_im_o[0]),
        .b_re_o(y_re_o[4]),
        .b_im_o(y_re_o[4])
    );

    butterfly #(
        .DATA_WIDTH(21),
        .FRAC_BITS(15)
    ) butter2_1 (
        // input clk_i,
        .twid_re_i(),
        .twid_im_i(),
        .a_re_i(s1_re[1]),
        .a_im_i(s1_im[1]),
        .b_re_i(s1_re[5]),
        .b_im_i(s1_im[5]),
        .a_re_o(y_re_o[1]),
        .a_im_o(y_im_o[1]),
        .b_re_o(y_re_o[5]),
        .b_im_o(y_re_o[5])
    );

    butterfly #(
        .DATA_WIDTH(21),
        .FRAC_BITS(15)
    ) butter2_2 (
        // input clk_i,
        .twid_re_i(),
        .twid_im_i(),
        .a_re_i(s1_re[2]),
        .a_im_i(s1_im[2]),
        .b_re_i(s1_re[6]),
        .b_im_i(s1_im[6]),
        .a_re_o(y_re_o[2]),
        .a_im_o(y_im_o[2]),
        .b_re_o(y_re_o[6]),
        .b_im_o(y_re_o[6])
    );

    butterfly #(
        .DATA_WIDTH(21),
        .FRAC_BITS(15)
    ) butter2_3 (
        // input clk_i,
        .twid_re_i(),
        .twid_im_i(),
        .a_re_i(s1_re[3]),
        .a_im_i(s1_im[3]),
        .b_re_i(s1_re[7]),
        .b_im_i(s1_im[7]),
        .a_re_o(y_re_o[3]),
        .a_im_o(y_im_o[3]),
        .b_re_o(y_re_o[7]),
        .b_im_o(y_re_o[7])
    );

endmodule
