module top_fft (
    input clk_i,
    input valid_i,
    input  signed [15:0] x_re_i [0:7],   // Time-domain, 8 real samples (Q1.15)
    output signed [20:0] y_re_o [0:7],   // Freq-domain, real
    output signed [20:0] y_im_o [0:7]    // Freq-domain, imag
);
    // ----------------------------------------------------------------
    // Parameters (match butterfly)
    // ----------------------------------------------------------------
    localparam DATA_WIDTH = 21;   // 16-bit input + 5 guard bits
    localparam FRAC_BITS  = 15;   // Q1.15 fixed point

    // ------------------------------
    // 21-bit signed Q5.15 Twiddles
    // ------------------------------
    localparam signed [DATA_WIDTH-1:0] TW_RE_0 = 21'h07FFF;  // +1.0000
    localparam signed [DATA_WIDTH-1:0] TW_RE_1 = 21'h05A82;  // +0.7071
    localparam signed [DATA_WIDTH-1:0] TW_RE_2 = 21'h00000;  //  0.0000
    localparam signed [DATA_WIDTH-1:0] TW_RE_3 = 21'h1A57E;  // -0.7071

    localparam signed [DATA_WIDTH-1:0] TW_IM_0 = 21'h00000;  //  0.0000
    localparam signed [DATA_WIDTH-1:0] TW_IM_1 = 21'h1A57E;  // -0.7071
    localparam signed [DATA_WIDTH-1:0] TW_IM_2 = 21'h18000;  // -1.0000
    localparam signed [DATA_WIDTH-1:0] TW_IM_3 = 21'h1A57E;  // -0.7071

    // Inputs extended to 21 bits (Q5.15)
    reg  signed [DATA_WIDTH-1:0] x_re_s [0:7];
    reg  signed [DATA_WIDTH-1:0] x_im_s [0:7];

    always @(*) begin
        for (int i = 0; i < 8; i = i + 1) begin
            x_re_s[i] = {{5{x_re_i[i][15]}}, x_re_i[i]}; // sign-extend Q1.15 -> Q5.15
            x_im_s[i] = '0;                              // real input only
        end
    end

    // ------------------------------------------------------------
    // Bit-reversal stage (N = 8, indices: 0,4,2,6,1,5,3,7)
    // ------------------------------------------------------------
    wire signed [DATA_WIDTH-1:0] br_re [0:7];
    wire signed [DATA_WIDTH-1:0] br_im [0:7];

    assign br_re[0] = x_re_s[0];  // 000 -> 000
    assign br_re[1] = x_re_s[4];  // 001 -> 100
    assign br_re[2] = x_re_s[2];  // 010 -> 010
    assign br_re[3] = x_re_s[6];  // 011 -> 110
    assign br_re[4] = x_re_s[1];  // 100 -> 001
    assign br_re[5] = x_re_s[5];  // 101 -> 101
    assign br_re[6] = x_re_s[3];  // 110 -> 011
    assign br_re[7] = x_re_s[7];  // 111 -> 111

    assign br_im[0] = x_im_s[0];
    assign br_im[1] = x_im_s[4];
    assign br_im[2] = x_im_s[2];
    assign br_im[3] = x_im_s[6];
    assign br_im[4] = x_im_s[1];
    assign br_im[5] = x_im_s[5];
    assign br_im[6] = x_im_s[3];
    assign br_im[7] = x_im_s[7];

    // Stage 0 outputs
    wire signed [DATA_WIDTH-1:0] s0_re [0:7];
    wire signed [DATA_WIDTH-1:0] s0_im [0:7];

    // Stage 0 butterflies (use bit-reversed inputs br_re/br_im)
    butterfly #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC_BITS(FRAC_BITS)
    ) butter0_0 (
        .twid_re_i(TW_RE_0),
        .twid_im_i(TW_IM_0),
        .a_re_i(br_re[0]),
        .a_im_i(br_im[0]),
        .b_re_i(br_re[1]),
        .b_im_i(br_im[1]),
        .a_re_o(s0_re[0]),
        .a_im_o(s0_im[0]),
        .b_re_o(s0_re[1]),
        .b_im_o(s0_im[1])
    );

    butterfly #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC_BITS(FRAC_BITS)
    ) butter0_1 (
        .twid_re_i(TW_RE_0),
        .twid_im_i(TW_IM_0),
        .a_re_i(br_re[2]),
        .a_im_i(br_im[2]),
        .b_re_i(br_re[3]),
        .b_im_i(br_im[3]),
        .a_re_o(s0_re[2]),
        .a_im_o(s0_im[2]),
        .b_re_o(s0_re[3]),
        .b_im_o(s0_im[3])
    );

    butterfly #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC_BITS(FRAC_BITS)
    ) butter0_2 (
        .twid_re_i(TW_RE_0),
        .twid_im_i(TW_IM_0),
        .a_re_i(br_re[4]),
        .a_im_i(br_im[4]),
        .b_re_i(br_re[5]),
        .b_im_i(br_im[5]),
        .a_re_o(s0_re[4]),
        .a_im_o(s0_im[4]),
        .b_re_o(s0_re[5]),
        .b_im_o(s0_im[5])
    );

    butterfly #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC_BITS(FRAC_BITS)
    ) butter0_3 (
        .twid_re_i(TW_RE_0),
        .twid_im_i(TW_IM_0),
        .a_re_i(br_re[6]),
        .a_im_i(br_im[6]),
        .b_re_i(br_re[7]),
        .b_im_i(br_im[7]),
        .a_re_o(s0_re[6]),
        .a_im_o(s0_im[6]),
        .b_re_o(s0_re[7]),
        .b_im_o(s0_im[7])
    );

    // Stage 1 outputs
    wire signed [DATA_WIDTH-1:0] s1_re [0:7];
    wire signed [DATA_WIDTH-1:0] s1_im [0:7];

    // Stage 1 butterflies
    butterfly #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC_BITS(FRAC_BITS)
    ) butter1_0 (
        .twid_re_i(TW_RE_0),
        .twid_im_i(TW_IM_0),
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
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC_BITS(FRAC_BITS)
    ) butter1_1 (
        .twid_re_i(TW_RE_2),
        .twid_im_i(TW_IM_2),
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
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC_BITS(FRAC_BITS)
    ) butter1_2 (
        .twid_re_i(TW_RE_0),
        .twid_im_i(TW_IM_0),
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
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC_BITS(FRAC_BITS)
    ) butter1_3 (
        .twid_re_i(TW_RE_2),
        .twid_im_i(TW_IM_2),
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
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC_BITS(FRAC_BITS)
    ) butter2_0 (
        .twid_re_i(TW_RE_0),
        .twid_im_i(TW_IM_0),
        .a_re_i(s1_re[0]),
        .a_im_i(s1_im[0]),
        .b_re_i(s1_re[4]),
        .b_im_i(s1_im[4]),
        .a_re_o(y_re_o[0]),
        .a_im_o(y_im_o[0]),
        .b_re_o(y_re_o[4]),
        .b_im_o(y_im_o[4])
    );

    butterfly #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC_BITS(FRAC_BITS)
    ) butter2_1 (
        .twid_re_i(TW_RE_1),
        .twid_im_i(TW_IM_1),
        .a_re_i(s1_re[1]),
        .a_im_i(s1_im[1]),
        .b_re_i(s1_re[5]),
        .b_im_i(s1_im[5]),
        .a_re_o(y_re_o[1]),
        .a_im_o(y_im_o[1]),
        .b_re_o(y_re_o[5]),
        .b_im_o(y_im_o[5])
    );

    butterfly #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC_BITS(FRAC_BITS)
    ) butter2_2 (
        .twid_re_i(TW_RE_2),
        .twid_im_i(TW_IM_2),
        .a_re_i(s1_re[2]),
        .a_im_i(s1_im[2]),
        .b_re_i(s1_re[6]),
        .b_im_i(s1_im[6]),
        .a_re_o(y_re_o[2]),
        .a_im_o(y_im_o[2]),
        .b_re_o(y_re_o[6]),
        .b_im_o(y_im_o[6])
    );

    butterfly #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC_BITS(FRAC_BITS)
    ) butter2_3 (
        .twid_re_i(TW_RE_3),
        .twid_im_i(TW_IM_3),
        .a_re_i(s1_re[3]),
        .a_im_i(s1_im[3]),
        .b_re_i(s1_re[7]),
        .b_im_i(s1_im[7]),
        .a_re_o(y_re_o[3]),
        .a_im_o(y_im_o[3]),
        .b_re_o(y_re_o[7]),
        .b_im_o(y_im_o[7])
    );

endmodule
