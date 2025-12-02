module butterfly #(
    parameter DATA_WIDTH = 21,  // Extra 5'b to prevent overflow
    parameter FRAC_BITS  = 15   // 16'b signed input expected to 1st layer, 1'b sign
    ) (
    input clk_i,
    input signed [DATA_WIDTH - 1 : 0] twid_re_i,
    input signed [DATA_WIDTH - 1 : 0] twid_im_i,
    input signed [DATA_WIDTH - 1 : 0] a_re_i,
    input signed [DATA_WIDTH - 1 : 0] a_im_i,
    input signed [DATA_WIDTH - 1 : 0] b_re_i,
    input signed [DATA_WIDTH - 1 : 0] b_im_i,
    output signed [DATA_WIDTH - 1 : 0] a_re_o,
    output signed [DATA_WIDTH - 1 : 0] a_im_o,
    output signed [DATA_WIDTH - 1 : 0] b_re_o,
    output signed [DATA_WIDTH - 1 : 0] b_im_o
);
    // // Temporary multiply logic (replace with CORDIC rotator)
    // localparam MUL_W = 2 * DATA_WIDTH;

    // wire signed [MUL_W-1:0] rr = b_re_i * twid_re_i;
    // wire signed [MUL_W-1:0] ii = b_im_i * twid_im_i;
    // wire signed [MUL_W-1:0] ri = b_re_i * twid_im_i;
    // wire signed [MUL_W-1:0] ir = b_im_i * twid_re_i;

    // wire signed [MUL_W:0] rot_re_full = rr - ii;
    // wire signed [MUL_W:0] rot_im_full = ri + ir;

    // wire signed [DATA_WIDTH-1:0] b_rot_re = rot_re_full >>> FRAC_BITS;
    // wire signed [DATA_WIDTH-1:0] b_rot_im = rot_im_full >>> FRAC_BITS;
    // End multiply logic

    // CORDIC rotator

    wire signed [DATA_WIDTH-1:0] b_rot_re;
    wire signed [DATA_WIDTH-1:0] b_rot_im;

    cordic_iteration cord (
        .clk(clk_i),
        .rst(0),
        .x_in(b_re_i),
        .y_in(b_im_i),
        .phi(twid_im_i),
        .x_out(b_rot_re),
        .y_out(b_rot_im)
    );

    assign a_re_o = a_re_i + b_rot_re;
    assign a_im_o = a_im_i + b_rot_im;
    assign b_re_o = a_re_i - b_rot_re;
    assign b_im_o = a_im_i - b_rot_im;

endmodule
