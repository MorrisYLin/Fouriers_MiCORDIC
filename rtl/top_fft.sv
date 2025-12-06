module top_fft #(
    parameter POINT_FFT_POW2 = 4,
    parameter FRAC_BITS = 15,
    parameter POINT_FFT = 1 << POINT_FFT_POW2
) (
    // input clk_i,
    input  signed [POINT_FFT][2][FRAC_BITS:0] data_i,
    output signed [POINT_FFT][2][FRAC_BITS:0] data_o
);
    // FFT is Radix-2, DIT
    // Means input samples in normal sample order, outputs in bit-reversed order

    // Twiddle factors
    // Twiddle factors for 16-point FFT, Q1.15, e^{-j 2πk/16}
    // TW16[k][0] = Re{W16^k}, TW16[k][1] = Im{W16^k}
    wire signed [8][2][FRAC_BITS:0] TW16;

    assign TW16[0][0] =  32767;  // W16^0  Re ≈  1.0000
    assign TW16[0][1] =      0;  //         Im ≈  0.0000

    assign TW16[1][0] =  30274;  // W16^1  Re ≈  0.9239
    assign TW16[1][1] = -12540;  //         Im ≈ -0.3827

    assign TW16[2][0] =  23170;  // W16^2  Re ≈  0.7071
    assign TW16[2][1] = -23170;  //         Im ≈ -0.7071

    assign TW16[3][0] =  12540;  // W16^3  Re ≈  0.3827
    assign TW16[3][1] = -30274;  //         Im ≈ -0.9239

    assign TW16[4][0] =      0;  // W16^4  Re ≈  0.0000
    assign TW16[4][1] = -32768;  //         Im ≈ -1.0000

    assign TW16[5][0] = -12540;  // W16^5  Re ≈ -0.3827
    assign TW16[5][1] = -30274;  //         Im ≈ -0.9239

    assign TW16[6][0] = -23170;  // W16^6  Re ≈ -0.7071
    assign TW16[6][1] = -23170;  //         Im ≈ -0.7071

    assign TW16[7][0] = -30274;  // W16^7  Re ≈ -0.9239
    assign TW16[7][1] = -12540;  //         Im ≈ -0.3827

    // Stage 0
    wire signed [POINT_FFT][2][FRAC_BITS:0] s0_out;

    generate
        for (genvar i = 0; i < 8; i = i + 1) begin
            butterfly b0 (
                .twid_i(TW16[0]),
                .a_i(data_i[2 * i + 0]),
                .b_i(data_i[2 * i + 1]),
                .a_o(s0_out[2 * i + 0]),
                .b_o(s0_out[2 * i + 1])
            );
        end
    endgenerate

    // Stage 1
    wire signed [POINT_FFT][2][FRAC_BITS:0] s1_out;

    generate
        for (genvar i = 0; i < 4; i = i + 1) begin
            for (genvar j = 0; j < 1; j = j + 1) begin
                butterfly b1 (
                    .twid_i(TW16[4 * j]),
                    .a_i(s0_out[4 * i + j]),
                    .b_i(s0_out[4 * i + j + 2]),
                    .a_o(s1_out[4 * i + j]),
                    .b_o(s1_out[4 * i + j + 2])
                );
            end
        end
    endgenerate

    // Stage 2
    wire signed [POINT_FFT][2][FRAC_BITS:0] s2_out;

    generate
        for (genvar i = 0; i < 1; i = i + 1) begin
            for (genvar j = 0; j < 4; j = j + 1) begin
                butterfly b2 (
                    .twid_i(TW16[2 * j]),
                    .a_i(s1_out[8 * i + 0 + j]),
                    .b_i(s1_out[8 * i + 4 + j]),
                    .a_o(s2_out[8 * i + 0 + j]),
                    .b_o(s2_out[8 * i + 4 + j])
                );
            end
        end
    endgenerate

    // Stage 3
    wire signed [POINT_FFT][2][FRAC_BITS:0] s3_out;

    generate
        for (genvar i = 0; i < 8; i = i + 1) begin
            butterfly b3 (
                .twid_i(TW16[i]),
                .a_i(s2_out[i]),
                .b_i(s2_out[i + 8]),
                .a_o(s3_out[i]),
                .b_o(s3_out[i + 8])
            );
        end
    endgenerate

    // Bit-reversed output

endmodule
