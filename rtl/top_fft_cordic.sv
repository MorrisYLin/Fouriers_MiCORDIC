module top_fft_cordic #(
    parameter POINT_FFT_POW2 = 4,
    parameter DATA_WIDTH = 16,
    parameter FRAC_BITS = 15,
    parameter POINT_FFT = 1 << POINT_FFT_POW2
) (
    input clk_i,
    input start_i,
    input rst_i,
    input  signed [1:0][FRAC_BITS:0] data_i [POINT_FFT],
    output reg signed [1:0][FRAC_BITS:0] data_o [POINT_FFT]
);
    // Twiddle factor instantiation, angle
    wire signed [FRAC_BITS:0] TW16 [8];
    assign TW16[0] = 16'h0000;
    assign TW16[1] = 16'h1000;
    assign TW16[2] = 16'h2000;
    assign TW16[3] = 16'h3000;
    assign TW16[4] = 16'h4000;
    assign TW16[5] = 16'h5000;
    assign TW16[6] = 16'h6000;
    assign TW16[7] = 16'h7000;

    // Bit-reverse input data
    wire signed [1:0][FRAC_BITS:0] s0_in [POINT_FFT];

    assign s0_in[ 0] = data_i[ 0];  // 0000 -> 0000
    assign s0_in[ 1] = data_i[ 8];  // 0001 -> 1000
    assign s0_in[ 2] = data_i[ 4];  // 0010 -> 0100
    assign s0_in[ 3] = data_i[12];  // 0011 -> 1100
    assign s0_in[ 4] = data_i[ 2];  // 0100 -> 0010
    assign s0_in[ 5] = data_i[10];  // 0101 -> 1010
    assign s0_in[ 6] = data_i[ 6];  // 0110 -> 0110
    assign s0_in[ 7] = data_i[14];  // 0111 -> 1110
    assign s0_in[ 8] = data_i[ 1];  // 1000 -> 0001
    assign s0_in[ 9] = data_i[ 9];  // 1001 -> 1001
    assign s0_in[10] = data_i[ 5];  // 1010 -> 0101
    assign s0_in[11] = data_i[13];  // 1011 -> 1101
    assign s0_in[12] = data_i[ 3];  // 1100 -> 0011
    assign s0_in[13] = data_i[11];  // 1101 -> 1011
    assign s0_in[14] = data_i[ 7];  // 1110 -> 0111
    assign s0_in[15] = data_i[15];  // 1111 -> 1111

    // FSM
    reg [5:0] counter;

    always @ (posedge clk_i or posedge rst_i) begin
        if (start_i) begin
            counter <= counter + 1;
        end

        if (counter != 0) begin
            if (counter == 70) begin
                counter <= 0;
                for (int i = 0; i < 16; i = i + 1) begin
                    data_o[i] = s3_out[i];
                end
            end else
                counter <= counter + 1;
        end

        if (rst_i) begin
            counter <= 0;
        end
    end

    wire [3:0] rst_stage;
    assign rst_stage[0] = !(counter != 0);
    assign rst_stage[1] = (counter < 12 );
    assign rst_stage[2] = (counter < 24);
    assign rst_stage[3] = (counter < 36);

    // Stage 0
    wire signed [1:0][FRAC_BITS:0] s0_out [POINT_FFT];

    generate
        for (genvar i = 0; i < 8; i = i + 1) begin
            butterfly_cordic b0 (
                .clk_i(clk_i),
                .twid_i(TW16[0]),
                .rst_i(rst_stage[0]),
                .a_i(s0_in[2 * i]),
                .b_i(s0_in[2 * i + 1]),
                .a_o(s0_out[2 * i]),
                .b_o(s0_out[2 * i + 1])
            );
        end
    endgenerate

    // Stage 1
    wire signed [1:0][FRAC_BITS:0] s1_out [POINT_FFT];

    generate
        for (genvar i = 0; i < 4; i = i + 1) begin
            for (genvar j = 0; j < 2; j = j + 1) begin
                butterfly_cordic b1 (
                    .clk_i(clk_i),
                    .twid_i(TW16[4 * j]),
                    .rst_i(rst_stage[1]),
                    .a_i(s0_out[4 * i + j]),
                    .b_i(s0_out[4 * i + j + 2]),
                    .a_o(s1_out[4 * i + j]),
                    .b_o(s1_out[4 * i + j + 2])
                );
            end
        end
    endgenerate

    // Stage 2
    wire signed [1:0][FRAC_BITS:0] s2_out [POINT_FFT];

    generate
        for (genvar i = 0; i < 2; i = i + 1) begin
            for (genvar j = 0; j < 4; j = j + 1) begin
                butterfly_cordic b2 (
                    .clk_i(clk_i),
                    .twid_i(TW16[2 * j]),
                    .rst_i(rst_stage[2]),
                    .a_i(s1_out[8 * i + j]),
                    .b_i(s1_out[8 * i + 4 + j]),
                    .a_o(s2_out[8 * i + j]),
                    .b_o(s2_out[8 * i + 4 + j])
                );
            end
        end
    endgenerate

    // Stage 3
    wire signed [1:0][FRAC_BITS:0] s3_out [POINT_FFT];

    generate
        for (genvar i = 0; i < 8; i = i + 1) begin
            butterfly_cordic b3 (
                .clk_i(clk_i),
                .twid_i(TW16[i]),
                .rst_i(rst_stage[3]),
                .a_i(s2_out[i]),
                .b_i(s2_out[i + 8]),
                .a_o(s3_out[i]),
                .b_o(s3_out[i + 8])
            );
        end
    endgenerate

    // ------------------------------------------------
    // VCD-friendly aliases for stage outputs
    //   Expose s0_out..s3_out per bin as packed vectors
    //   so Surfer can see them (no unpacked arrays).
    // ------------------------------------------------
    genvar k;
    generate
        for (k = 0; k < POINT_FFT; k++) begin : G_VCD_STAGE_0
            // Stage 0
            wire signed [FRAC_BITS:0] s0_out_re = s0_out[k][0];
            wire signed [FRAC_BITS:0] s0_out_im = s0_out[k][1];
        end
    endgenerate

    generate
        for (k = 0; k < POINT_FFT; k++) begin : G_VCD_STAGE_1
            // Stage 0
            wire signed [FRAC_BITS:0] s0_out_re = s1_out[k][0];
            wire signed [FRAC_BITS:0] s0_out_im = s1_out[k][1];
        end
    endgenerate

    generate
        for (k = 0; k < POINT_FFT; k++) begin : G_VCD_STAGE_2
            // Stage 0
            wire signed [FRAC_BITS:0] s0_out_re = s2_out[k][0];
            wire signed [FRAC_BITS:0] s0_out_im = s2_out[k][1];
        end
    endgenerate

    generate
        for (k = 0; k < POINT_FFT; k++) begin : G_VCD_STAGE_3
            // Stage 0
            wire signed [FRAC_BITS:0] s0_out_re = s3_out[k][0];
            wire signed [FRAC_BITS:0] s0_out_im = s3_out[k][1];
        end
    endgenerate
endmodule
