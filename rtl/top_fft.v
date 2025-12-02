module top_fft #(
    parameter POINT_FFT_POW2 = 4,
    parameter FRAC_BITS = 15,
    parameter POINT_FFT = 1 << POINT_FFT_POW2
) (
    // input clk_i,
    input  signed [FRAC_BITS:0] data_i [2][POINT_FFT-1],
    output signed [FRAC_BITS+POINT_FFT_POW2:0] data_o [2][POINT_FFT-1]
);
    // Bit-reversal NOT INCLUDED


endmodule
