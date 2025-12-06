module butterfly #(
    parameter DATA_WIDTH = 16,
    parameter FRAC_BITS  = 15
) (
    // input clk_i,
    input  signed [2][FRAC_BITS:0]      twid_i,
    input  signed [2][DATA_WIDTH-1:0]   a_i,
    input  signed [2][DATA_WIDTH-1:0]   b_i,

    output signed [2][DATA_WIDTH-1:0]   a_o,
    output signed [2][DATA_WIDTH-1:0]   b_o
);
    // Expand complex num inputs and rename
    wire signed [FRAC_BITS:0] tw_re = twid_i[0];
    wire signed [FRAC_BITS:0] tw_im = twid_i[1];

    wire signed [DATA_WIDTH-1:0] a_re  = a_i[0];
    wire signed [DATA_WIDTH-1:0] a_im  = a_i[1];

    wire signed [DATA_WIDTH-1:0] b_re  = b_i[0];
    wire signed [DATA_WIDTH-1:0] b_im  = b_i[1];

    // Complex multiply, replace later with CORDIC
    localparam MUL_W = 2 * DATA_WIDTH;

    wire signed [MUL_W-1:0] rr = b_re * tw_re;
    wire signed [MUL_W-1:0] ii = b_im * tw_im;
    wire signed [MUL_W-1:0] ri = b_re * tw_im;
    wire signed [MUL_W-1:0] ir = b_im * tw_re;

    wire signed [MUL_W:0] rot_re_full = rr - ii;
    wire signed [MUL_W:0] rot_im_full = ri + ir;

    wire signed [DATA_WIDTH-1:0] b_rot_re = rot_re_full >>> FRAC_BITS;
    wire signed [DATA_WIDTH-1:0] b_rot_im = rot_im_full >>> FRAC_BITS;
    // End complex multiply

    wire signed [1:0][DATA_WIDTH:0] a_sum;
    wire signed [1:0][DATA_WIDTH:0] b_sum;

    // Applying per-stage right-shift
    assign a_sum[0] = a_re + b_rot_re;
    assign a_sum[1] = a_im + b_rot_im;

    assign b_sum[0] = b_re - b_rot_re;
    assign b_sum[1] = b_im - b_rot_im;

    assign a_o[0] = a_sum[0] [DATA_WIDTH:1];
    assign a_o[1] = a_sum[1] [DATA_WIDTH:1];

    assign b_o[0] = b_sum[0] [DATA_WIDTH:1];
    assign b_o[1] = b_sum[1] [DATA_WIDTH:1];

endmodule
