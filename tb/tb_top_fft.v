`timescale 1ns/1ps

module tb_top_fft;

    localparam N = 8;
    localparam DATA_IN_W  = 16;
    localparam DATA_OUT_W = 21;
    localparam FRAC_BITS  = 15;  // Q1.15 input

    // Testbench signals
    reg clk_i;
    reg valid_i;
    reg  signed [DATA_IN_W-1:0] x_re_i [0:N-1];
    wire signed [DATA_OUT_W-1:0] y_re_o [0:N-1];
    wire signed [DATA_OUT_W-1:0] y_im_o [0:N-1];

    // Instantiate DUT
    top_fft dut (
        .clk_i(clk_i),
        .valid_i(valid_i),
        .x_re_i(x_re_i),
        .y_re_o(y_re_o),
        .y_im_o(y_im_o)
    );

    // Clock generation (100 MHz)
    initial clk_i = 0;
    always #5 clk_i = ~clk_i;

    // Fixed-point helper: convert Q(FRAC_BITS) → real
    function real fxp_to_real;
        input signed [DATA_OUT_W-1:0] val;
        begin
            fxp_to_real = $itor(val) / (1 << FRAC_BITS);
        end
    endfunction

    initial begin
        $dumpfile("fft.vcd");
        $dumpvars(0, tb_top_fft);

        $display("=== TOP FFT Testbench ===");

        // for (int i = 0; i < N; i = i + 1) begin
        //     x_re_i[i] = 16'h4000;
        // end

        x_re_i[0] = 16'h4000; //  +0.5
        x_re_i[1] = 16'h2D41; //  +0.3536
        x_re_i[2] = 16'h0000; //   0
        x_re_i[3] = 16'hD2BF; //  -0.3536
        x_re_i[4] = 16'hC000; //  -0.5
        x_re_i[5] = 16'hD2BF; //  -0.3536
        x_re_i[6] = 16'h0000; //   0
        x_re_i[7] = 16'h2D41; //  +0.3536

        $display("\nFFT Input (decimal):");
        for (int i = 0; i < N; i = i + 1) begin
            $display("  Bin %0d :  Re = %0.6f",
                     i,
                     fxp_to_real(x_re_i[i]));
        end

        valid_i = 0;
        @(posedge clk_i);
        valid_i = 1;  // pulse valid
        @(posedge clk_i);
        valid_i = 0;

        // Allow FFT to compute (depends on your pipeline depth)
        repeat (20) @(posedge clk_i);

        // -------------------------------
        // Display outputs
        // -------------------------------
        $display("\nFFT Output (decimal):");
        for (int i = 0; i < N; i = i + 1) begin
            $display("  Bin %0d :  Re = %0.6f   Im = %0.6f",
                     i,
                     fxp_to_real(y_re_o[i]),
                     fxp_to_real(y_im_o[i]));
        end

        $display("\n=== Testbench complete ===");
        $finish;
    end

endmodule
