`timescale 1ns/1ps

module tb_top_fft;

    localparam int POINT_FFT_POW2 = 4;
    localparam int POINT_FFT      = 1 << POINT_FFT_POW2;   // 16
    localparam int FRAC_BITS      = 15;

    // tb_in[n][0]=Re, tb_in[n][1]=Im (Q1.FFRAC_BITS)
    logic signed [1:0][FRAC_BITS:0] tb_in  [POINT_FFT];
    wire  signed [1:0][FRAC_BITS:0] tb_out [POINT_FFT];    // alias to DUT outputs (if/when used)

    // DUT ports
    wire signed [1:0][FRAC_BITS:0] data_i [POINT_FFT];
    wire signed [1:0][FRAC_BITS:0] data_o [POINT_FFT];

    genvar gi;
    generate
        for (gi = 0; gi < POINT_FFT; gi++) begin : G_IN_OUT
            assign data_i[gi] = tb_in[gi];
            assign tb_out[gi] = data_o[gi];
        end
    endgenerate

    top_fft #(
        .POINT_FFT_POW2(POINT_FFT_POW2),
        .FRAC_BITS     (FRAC_BITS)
    ) dut (
        .data_i(data_i),
        .data_o(data_o)
    );

    // Alias final FFT stage (s3_out) for printing
    wire signed [1:0][FRAC_BITS:0] fft_final [POINT_FFT];
    genvar gj;
    generate
        for (gj = 0; gj < POINT_FFT; gj++) begin : G_ALIAS
            assign fft_final[gj] = dut.s3_out[gj];
        end
    endgenerate

    // Fixed-point to real helper (Q1.FRAC_BITS)
    function real fxp_to_real;
        input signed [FRAC_BITS:0] val;
        begin
            fxp_to_real = $itor(val) / (1.0 * (1 << FRAC_BITS));
        end
    endfunction

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
            $display("\n==== Frequency-domain output (from s3_out): %s ====", label);
            for (k = 0; k < POINT_FFT; k++) begin
                re_v = fxp_to_real(fft_final[k][0]);
                im_v = fxp_to_real(fft_final[k][1]);
                $display("k %2d : Re = %f  Im = %f", k, re_v, im_v);
            end
        end
    endtask

    // x[n] = dc (real)
    task apply_dc(input real dc);
        int n;
        int signed sample_fx;
        begin
            sample_fx = $rtoi(dc * (1 << FRAC_BITS));
            for (n = 0; n < POINT_FFT; n++) begin
                tb_in[n][0] = sample_fx;
                tb_in[n][1] = '0;
            end
        end
    endtask

    // x[n] = amp * cos(2π k0 n / N)
    task apply_tone(input int k0, input real amp);
        int  n;
        real angle, x;
        int  signed sample_fx;
        begin
            for (n = 0; n < POINT_FFT; n++) begin
                angle = 2.0 * 3.14159265358979323846 * k0 * n / POINT_FFT;
                x     = amp * $cos(angle);
                sample_fx = $rtoi(x * (1 << FRAC_BITS));
                tb_in[n][0] = sample_fx;
                tb_in[n][1] = '0;
            end
        end
    endtask

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_top_fft);

        // Test 1: DC offset
        apply_dc(0.5);
        #1;
        print_time_domain("DC offset (0.5)");
        print_freq_domain("DC offset (0.5)");

        // Test 2: single-tone cosine at bin 3
        apply_tone(3, 0.5);
        #1;
        print_time_domain("Cosine tone, bin 3, amp 0.5");
        print_freq_domain("Cosine tone, bin 3, amp 0.5");

        $finish;
    end

endmodule
