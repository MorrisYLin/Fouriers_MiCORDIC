module top_fft (
    input clk_i,
    input valid_i,
    input  [15:0] x_re_i [0:7],   // Time-domain, 8 real samples (Q1.15)
    output [20:0] y_re_o [0:7],   // Freq-domain, real
    output [20:0] y_im_o [0:7]    // Freq-domain, imag
);
    // ----------------------------------------------------------------
    // Parameters (match butterfly)
    // ----------------------------------------------------------------
    localparam DATA_WIDTH = 21;   // 16-bit input + 5 guard bits
    localparam FRAC_BITS  = 15;   // Q1.15 fixed point

    // ------------------------------
    // 21-bit signed Q5.15 Twiddles
    // ------------------------------
    localparam signed [20:0] TW_RE_0 = 21'h07FFF;  // +1.0000
    localparam signed [20:0] TW_RE_1 = 21'h05A82;  // +0.7071
    localparam signed [20:0] TW_RE_2 = 21'h00000;  //  0.0000
    localparam signed [20:0] TW_RE_3 = 21'h1A57E;  // -0.7071

    localparam signed [20:0] TW_IM_0 = 21'h00000;  //  0.0000
    localparam signed [20:0] TW_IM_1 = 21'h1A57E;  // -0.7071
    localparam signed [20:0] TW_IM_2 = 21'h18000;  // -1.0000
    localparam signed [20:0] TW_IM_3 = 21'h1A57E;  // -0.7071

    // Inputs extended to 21 bits
    reg [20:0] x_re_signed [0:7];

    always @(*) begin
        for (int i = 0; i < 8; i = i + 1) begin
            x_re_signed[i] = {{5{x_re_i[i][15]}}, x_re_i[i]};
        end
    end



endmodule
