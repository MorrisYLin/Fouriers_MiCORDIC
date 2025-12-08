module top_fft #(
    parameter POINT_FFT_POW2 = 4,
    parameter DATA_WIDTH = 16,
    parameter FRAC_BITS = 15,
    parameter POINT_FFT = 1 << POINT_FFT_POW2
) (
    // input clk_i,
    input  signed [1:0][FRAC_BITS:0] data_i [POINT_FFT],
    output signed [1:0][FRAC_BITS:0] data_o [POINT_FFT]
);
    // FFT is Radix-2

    wire signed [1:0][FRAC_BITS+1:0] TW16 [8];
    //    k   Re{W16^k}             Im{W16^k}
    assign TW16[0][0] =  32768;  //  1.0000  →  1.0 * 2^15
    assign TW16[0][1] =      0;  //  0.0000

    assign TW16[1][0] =  30274;  //  0.9239  →  round(0.9239 * 2^15)
    assign TW16[1][1] = -12540;  // -0.3827

    assign TW16[2][0] =  23170;  //  0.7071
    assign TW16[2][1] = -23170;  // -0.7071

    assign TW16[3][0] =  12540;  //  0.3827
    assign TW16[3][1] = -30274;  // -0.9239

    assign TW16[4][0] =      0;  //  0.0000
    assign TW16[4][1] = -32768;  // -1.0000

    assign TW16[5][0] = -12540;  // -0.3827
    assign TW16[5][1] = -30274;  // -0.9239

    assign TW16[6][0] = -23170;  // -0.7071
    assign TW16[6][1] = -23170;  // -0.7071

    assign TW16[7][0] = -30274;  // -0.9239
    assign TW16[7][1] = -12540;  // -0.3827

    // Stage 0
    wire signed [2][FRAC_BITS:0] s0_out [POINT_FFT];

    generate
        for (genvar i = 0; i < 8; i = i + 1) begin
            butterfly b0 (
                .twid_i(TW16[0]),
                .a_i(data_i[2 * i]),
                .b_i(data_i[2 * i + 1]),
                .a_o(s0_out[2 * i]),
                .b_o(s0_out[2 * i + 1])
            );
        end
    endgenerate

    // Stage 1
    wire signed [2][FRAC_BITS:0] s1_out [POINT_FFT];

    generate
        for (genvar i = 0; i < 4; i = i + 1) begin
            for (genvar j = 0; j < 2; j = j + 1) begin
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
    wire signed [2][FRAC_BITS:0] s2_out [POINT_FFT];

    generate
        for (genvar i = 0; i < 2; i = i + 1) begin
            for (genvar j = 0; j < 4; j = j + 1) begin
                butterfly b2 (
                    .twid_i(TW16[2 * j]),
                    .a_i(s1_out[8 * i + j]),
                    .b_i(s1_out[8 * i + 4 + j]),
                    .a_o(s2_out[8 * i + j]),
                    .b_o(s2_out[8 * i + 4 + j])
                );
            end
        end
    endgenerate

    // Stage 3
    wire signed [2][FRAC_BITS:0] s3_out [POINT_FFT];

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
    assign data_o = s3_out;

endmodule
