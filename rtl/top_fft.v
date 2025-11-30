module top_fft (
    input clk_i,
    input valid_i,
    input [15:0] x_re_i [0:15],     // Time-domain, 16 samples
    output [20:0] y_re_o [0:15],    // Freq-domain, 16 freq
    output [20:0] y_im_o [0:15]     // Imag component
);
    // Twiddle factors
    // TW_RE[k] = cos(2πk/8), Q15, unsigned hex format
    localparam [15:0] TW_RE [0:3] = {
        16'h7FFF,
        16'h5A82,
        16'h0000,
        16'hA57E
    };

    // TW_IM[k] = -sin(2πk/8), Q15, unsigned hex format
    localparam [15:0] TW_IM [0:3] = {
        16'h0000,
        16'hA57E,
        16'h8000,
        16'hA57E
    };

    // Stage 0
    butterfly b0 (

    );

endmodule
