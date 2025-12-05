module top_fft #(
    parameter POINT_FFT_POW2 = 4,
    parameter FRAC_BITS = 15,
    parameter POINT_FFT = 1 << POINT_FFT_POW2
) (
    // input clk_i,
    input  signed [FRAC_BITS:0] data_i [2][POINT_FFT],
    output signed [FRAC_BITS+POINT_FFT_POW2:0] data_o [2][POINT_FFT]
);
    // FFT is Radix-2, DIT
    // Means input samples in normal sample order, outputs in bit-reversed order

    // Stage 0
    wire signed [FRAC_BITS+1:0] s0_out [2][POINT_FFT];

    generate
        for (genvar i = 0; i < 8; i = i + 1) begin
            butterfly b0 (
                .twid_i(),
                .a_i(data_i[2 * i + 0]),
                .b_i(data_i[2 * i + 1]),
                .a_o(s0_out[2 * i + 0][16:1]),
                .b_o(s0_out[2 * i + 1][16:1])
            );
        end
    endgenerate

    // Stage 1
    wire signed [FRAC_BITS+1:0] s1_out [2][POINT_FFT];

    generate
        for (genvar i = 0; i < 4; i = i + 1) begin
            for (genvar j = 0; j < 1; j = j + 1) begin
                butterfly b1 (
                    .twid_i(),
                    .a_i(s0_out[4 * i + 0 + j]),
                    .b_i(s0_out[4 * i + 2 + j]),
                    .a_o(s1_out[4 * i + 0 + j][16:1]),
                    .b_o(s1_out[4 * i + 2 + j][16:1])
                );
            end
        end
    endgenerate

    // Stage 2
    wire signed [FRAC_BITS+1:0] s2_out [2][POINT_FFT];

    generate
        for (genvar i = 0; i < 1; i = i + 1) begin
            for (genvar j = 0; j < 4; j = j + 1) begin
                butterfly b2 (
                    .twid_i(),
                    .a_i(s1_out[8 * i + 0 + j]),
                    .b_i(s1_out[8 * i + 4 + j]),
                    .a_o(s2_out[8 * i + 0 + j][16:1]),
                    .b_o(s2_out[8 * i + 4 + j][16:1])
                );
            end
        end
    endgenerate

    // Stage 3
    wire signed [FRAC_BITS+1:0] s3_out [2][POINT_FFT];

    generate
        for (genvar i = 0; i < 8; i = i + 1) begin
            butterfly b3 (
                .twid_i(),
                .a_i(s2_out[i]),
                .b_i(s2_out[i + 8]),
                .a_o(s3_out[i][16:1]),
                .b_o(s3_out[i + 8][16:1])
            );
        end
    endgenerate

    // Bit-reversed output


endmodule
