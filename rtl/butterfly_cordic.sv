module butterfly_cordic #(
    parameter DATA_WIDTH = 16,
    parameter FRAC_BITS  = 15
) (
    input                               clk_i,
    input                                 rst,
    input         [FRAC_BITS:0]        twid_i, //twiddle input angle
    input  signed [1:0][DATA_WIDTH-1:0]   a_i, //
    input  signed [1:0][DATA_WIDTH-1:0]   b_i, //complex # used in cordic [0] = real
    output signed [1:0][DATA_WIDTH-1:0]   a_o,
    output signed [1:0][DATA_WIDTH-1:0]   b_o
);
    // Complex multiply, replace later with CORDIC
    localparam MUL_W = 2 * DATA_WIDTH;

    wire [1:0] quadrant;
    wire signed [FRAC_BITS:0] normalized_twiddle;
    wire signed [1:0][DATA_WIDTH-1:0] normalized_b_i;

    cordic_input_standardizer s1 (
        .x_in(b_i[0]),
        .y_in(b_i[1]),
        .theta_in(twid_i),
        .x_out(normalized_b_i[0]),
        .y_out(normalized_b_i[1]),
        .theta_out(normalized_twiddle),
        .quadrant(quadrant)
    );

    wire signed [DATA_WIDTH-1:0] b_rot_re;
    wire signed [DATA_WIDTH-1:0] b_rot_im;

    cordic_iteration c1 (
        .clk(clk_i),
        .rst(rst),
        .x_in(normalized_b_i[0]),
        .y_in(normalized_b_i[1]),
        .phi(normalized_twiddle),
        .x_out(b_rot_re),
        .y_out(b_rot_im)
    );

    wire signed [DATA_WIDTH-1:0] b_re_final;
    wire signed [DATA_WIDTH-1:0] b_im_final;

    wire signed [1:0][DATA_WIDTH:0] a_sum;
    wire signed [1:0][DATA_WIDTH:0] b_sum;

    cordic_post_normalizer n1 (
        .x_cordic(b_rot_re),
        .y_cordic(b_rot_im),
        .orig_angle_quadrant(quadrant),
        .phi_std(normalized_twiddle),
        .x_out(b_re_final),
        .y_out(b_im_final)
    );

    // Applying per-stage right-shift
    assign a_sum[0] = a_i[0] + b_re_final;
    assign a_sum[1] = a_i[1] + b_im_final;

    assign b_sum[0] = a_i[0] - b_re_final;
    assign b_sum[1] = a_i[1] - b_im_final;

    assign a_o[0] = a_sum[0] [DATA_WIDTH:1];
    assign a_o[1] = a_sum[1] [DATA_WIDTH:1];

    assign b_o[0] = b_sum[0] [DATA_WIDTH:1];
    assign b_o[1] = b_sum[1] [DATA_WIDTH:1];

endmodule
