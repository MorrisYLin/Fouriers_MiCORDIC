`timescale 1ns/1ps

module tb_top_fft;

    // Match DUT parameters
    localparam int POINT_FFT_POW2 = 4;
    localparam int POINT_FFT      = 1 << POINT_FFT_POW2;   // 16
    localparam int FRAC_BITS      = 15;
    localparam int DATA_W         = FRAC_BITS + 1;         // [FRAC_BITS:0]

    // ============================================================
    // 1) Unpacked "nice" view for the testbench
    //    tb_in[n][0] = Re{x[n]}, tb_in[n][1] = Im{x[n]}
    //    tb_out[k][0] = Re{X[k]}, tb_out[k][1] = Im{X[k]}
    // ============================================================

    logic signed [FRAC_BITS:0]      tb_in  [0:POINT_FFT-1][0:1];
    wire  signed [FRAC_BITS:0]      tb_out [0:POINT_FFT-1][0:1];

    // ============================================================
    // 2) Packed view to match DUT ports
    //    data_i[n][0/1][bits], data_o[n][0/1][bits]
    // ============================================================

    wire signed [POINT_FFT-1:0][1:0][FRAC_BITS:0] data_i;
    wire signed [POINT_FFT-1:0][1:0][FRAC_BITS:0] data_o;

    genvar gi, gc;
    generate
        // Drive packed input from unpacked tb_in
        for (gi = 0; gi < POINT_FFT; gi++) begin : G_IN
            for (gc = 0; gc < 2; gc++) begin : G_IN_C
                assign data_i[gi][gc] = tb_in[gi][gc];
            end
        end

        // Unpack DUT outputs into tb_out
        for (gi = 0; gi < POINT_FFT; gi++) begin : G_OUT
            for (gc = 0; gc < 2; gc++) begin : G_OUT_C
                assign tb_out[gi][gc] = data_o[gi][gc];
            end
        end
    endgenerate

    // ============================================================
    // 3) DUT instantiation
    // ============================================================

    top_fft #(
        .POINT_FFT_POW2(POINT_FFT_POW2),
        .FRAC_BITS     (FRAC_BITS)
    ) dut (
        .data_i(data_i),
        .data_o(data_o)
    );

    // ============================================================
    // 4) Fixed-point helpers (same scale for in/out)
    // ============================================================

    function real fxp_to_real;
        input signed [FRAC_BITS:0] val;
        begin
            fxp_to_real = $itor(val) / (1.0 * (1 << FRAC_BITS));
        end
    endfunction

    // ============================================================
    // 5) Printing helpers
    // ============================================================

    task print_time_domain(input string label);
        int n;
        real re_v, im_v;
        begin
            $display("\n==== Time-domain input: %s ====", label);
            for (n = 0; n < POINT_FFT; n++) begin
                re_v = fxp_to_real(tb_in[n][0]);
                im_v = fxp_to_real(tb_in[n][1]);
                $display("n %2d : Re = %f  Im = %f", n, re_v, im_v);
            end
        end
    endtask

    task print_freq_domain(input string label);
        int k;
        real re_v, im_v;
        begin
            $display("\n==== Frequency-domain output: %s ====", label);
            for (k = 0; k < POINT_FFT; k++) begin
                re_v = fxp_to_real(tb_out[k][0]);
                im_v = fxp_to_real(tb_out[k][1]);
                $display("k %2d : Re = %f  Im = %f", k, re_v, im_v);
            end
        end
    endtask

    // ============================================================
    // 6) Stimulus: DC offset
    // ============================================================

    task apply_dc(input real dc);
        int n;
        int signed sample_fx;
        begin
            sample_fx = $rtoi(dc * (1 << FRAC_BITS));
            for (n = 0; n < POINT_FFT; n++) begin
                tb_in[n][0] = sample_fx; // real
                tb_in[n][1] = '0;        // imag
            end
        end
    endtask

    // ============================================================
    // 7) Stimulus: real cosine tone at bin k0
    // ============================================================

    task apply_tone(input int k0, input real amp);
        int  n;
        real angle, x;
        int  signed sample_fx;
        begin
            for (n = 0; n < POINT_FFT; n++) begin
                angle = 2.0 * 3.14159265358979323846 * k0 * n / POINT_FFT;
                x     = amp * $cos(angle);
                sample_fx = $rtoi(x * (1 << FRAC_BITS));
                tb_in[n][0] = sample_fx; // real
                tb_in[n][1] = '0;        // imag
            end
        end
    endtask

    // ============================================================
    // 8) Test sequence + VCD dump
    // ============================================================

    initial begin
        // VCD dump
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_top_fft);

        // ---- Test 1: DC offset ----
        apply_dc(0.5);          // x[n] = 0.5
        #1;                     // allow combinational FFT to settle
        print_time_domain("DC offset (0.5)");
        print_freq_domain("DC offset (0.5)");

        // ---- Test 2: single-tone cosine ----
        apply_tone(3, 0.5);     // bin 3, amplitude 0.5
        #1;
        print_time_domain("Cosine tone, bin 3, amp 0.5");
        print_freq_domain("Cosine tone, bin 3, amp 0.5");

        $finish;
    end

endmodule
