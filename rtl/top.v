module top (
    input clk_i,
    input valid_i,
    input [15:0] x_re_i [0:15],     // Time-domain, 16 samples
    output [20:0] y_re_o [0:15],    // Freq-domain, 16 freq
    output [20:0] y_im_o [0:15]     // Imag component
);
    // Twiddle factors
    // TW_RE[k] = cos(2πk/8), Q15, unsigned hex format
    localparam [15:0] TW_RE [0:3] = {
        16'h7FFF,  // k = 0  ( +1.0000 )
        16'h5A82,  // k = 1  ( +0.7071 )
        16'h0000,  // k = 2  (  0.0000 )
        16'hA57E   // k = 3  ( -0.7071 )
    };

    // TW_IM[k] = -sin(2πk/8), Q15, unsigned hex format
    localparam [15:0] TW_IM [0:3] = {
        16'h0000,  // k = 0  (  0.0000 )
        16'hA57E,  // k = 1  ( -0.7071 )
        16'h8000,  // k = 2  ( -1.0000 )
        16'hA57E   // k = 3  ( -0.7071 )
    };

    // Stage 0
    butterfly b0 (

    )

endmodule
