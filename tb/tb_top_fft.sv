`timescale 1ns/1ps

module tb_top_fft;

    // Match DUT defaults
    localparam int POINT_FFT_POW2 = 4;
    localparam int POINT_FFT      = 1 << POINT_FFT_POW2;   // 16
    localparam int FRAC_BITS      = 15;

    localparam int DATA_IN_W  = FRAC_BITS + 1;
    localparam int DATA_OUT_W = FRAC_BITS + POINT_FFT_POW2 + 1;

    // ----------------------------------------------------------------
    // 1) Unpacked TB view (nice to index with n)
    //    tb_data_i[n][0] = Re, tb_data_i[n][1] = Im
    // ----------------------------------------------------------------
    logic signed [FRAC_BITS:0]     tb_data_i [0:POINT_FFT-1][0:1];
    wire  signed [DATA_OUT_W-1:0]  tb_data_o [0:POINT_FFT-1][0:1];

    // ----------------------------------------------------------------
    // 2) Packed view to match DUT ports
    //    data_i_packed[n][0/1][bits]
    // ----------------------------------------------------------------
    wire signed [POINT_FFT-1:0][1:0][FRAC_BITS:0]     data_i_packed;
    wire signed [POINT_FFT-1:0][1:0][DATA_OUT_W-1:0]  data_o_packed;

    genvar gi, gc;
    generate
        // Drive packed input from unpacked tb_data_i
        for (gi = 0; gi < POINT_FFT; gi++) begin : G_IN
            for (gc = 0; gc < 2; gc++) begin : G_IN_C
                assign data_i_packed[gi][gc] = tb_data_i[gi][gc];
            end
        end

        // Unpack DUT outputs into tb_data_o for easy indexing
        for (gi = 0; gi < POINT_FFT; gi++) begin : G_OUT
            for (gc = 0; gc < 2; gc++) begin : G_OUT_C
                assign tb_data_o[gi][gc] = data_o_packed[gi][gc];
            end
        end
    endgenerate

    // ----------------------------------------------------------------
    // 3) DUT instantiation
    // ----------------------------------------------------------------
    top_fft #(
        .POINT_FFT_POW2(POINT_FFT_POW2),
        .FRAC_BITS     (FRAC_BITS)
    ) dut (
        .data_i(data_i_packed),
        .data_o(data_o_packed)
    );

    // ----------------------------------------------------------------
    // 4) Helper: fixed-point -> real
    // ----------------------------------------------------------------
    function real fxp_to_real;
        input signed [DATA_OUT_W-1:0] val;
        begin
            fxp_to_real = $itor(val) / (1.0 * (1 << FRAC_BITS));
        end
    endfunction

    // Print current spectrum
    task print_spectrum(input string label);
        int k;
        real re_v, im_v;
        begin
            $display("\n==== %s ====", label);
            for (k = 0; k < POINT_FFT; k++) begin
                re_v = fxp_to_real(tb_data_o[k][0]); // real
                im_v = fxp_to_real(tb_data_o[k][1]); // imag
                $display("bin %2d : Re = %f  Im = %f", k, re_v, im_v);
            end
        end
    endtask

    // Apply DC offset: x[n] = dc
    task apply_dc(input real dc);
        int n;
        int signed sample_fx;
        begin
            sample_fx = $rtoi(dc * (1 << FRAC_BITS));
            for (n = 0; n < POINT_FFT; n++) begin
                tb_data_i[n][0] = sample_fx; // real
                tb_data_i[n][1] = '0;        // imag
            end
        end
    endtask

    // Apply real cosine at bin k0, amplitude amp
    task apply_tone(input int k0, input real amp);
        int  n;
        real angle, x;
        int  signed sample_fx;
        begin
            for (n = 0; n < POINT_FFT; n++) begin
                angle = 2.0 * 3.14159265358979323846 * k0 * n / POINT_FFT;
                x     = amp * $cos(angle);
                sample_fx = $rtoi(x * (1 << FRAC_BITS));
                tb_data_i[n][0] = sample_fx; // real
                tb_data_i[n][1] = '0;        // imag
            end
        end
    endtask

    initial begin
        $dumpfile("tb_top_fft.vcd");
        $dumpvars(0, tb_top_fft);

        // Test 1: DC offset
        apply_dc(0.5);
        #1;
        print_spectrum("DC offset (0.5)");

        // Test 2: single-tone at bin 3
        apply_tone(3, 0.5);
        #1;
        print_spectrum("Single tone, bin 3, amp 0.5");

        $finish;
    end

endmodule
