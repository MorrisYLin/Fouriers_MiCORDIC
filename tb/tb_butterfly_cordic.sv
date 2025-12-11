`timescale 1ns/1ps

module tb_butterfly_cordic;

    // Match DUT parameters
    localparam int FRAC_BITS  = 15;
    localparam int DATA_WIDTH = 16;

    // Angle encoding: 0..(2^ANGLE_BITS-1) → 0..2π
    localparam int ANGLE_BITS = FRAC_BITS + 1;         // 16 bits here
    localparam int FULL_TURN  = 1 << ANGLE_BITS;       // 65536

    // Simple "enough" latency for CORDIC to settle
    localparam int PIPE_LAT   = 8;

    // Clock / reset
    logic clk_i;
    logic rst;

    initial clk_i = 0;
    always #5 clk_i = ~clk_i;   // 100 MHz

    // DUT ports
    logic [FRAC_BITS:0]                twid_i;   // unsigned angle
    logic signed [1:0][DATA_WIDTH-1:0] a_i;
    logic signed [1:0][DATA_WIDTH-1:0] b_i;

    wire  signed [1:0][DATA_WIDTH-1:0] a_o;
    wire  signed [1:0][DATA_WIDTH-1:0] b_o;

    // Instantiate DUT
    butterfly_cordic #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC_BITS (FRAC_BITS)
    ) dut (
        .clk_i (clk_i),
        .rst   (rst),
        .twid_i(twid_i),
        .a_i   (a_i),
        .b_i   (b_i),
        .a_o   (a_o),
        .b_o   (b_o)
    );

    // ------------------------------------------------------------
    // Fixed-point helper: Q(FRAC_BITS) → real
    // ------------------------------------------------------------
    function real fxp_to_real;
        input signed [DATA_WIDTH-1:0] val;
        begin
            fxp_to_real = $itor(val) / (1.0 * (1 << FRAC_BITS));
        end
    endfunction

    // Print a complex value (Re, Im)
    task print_complex(input string label,
                       input signed [DATA_WIDTH-1:0] re,
                       input signed [DATA_WIDTH-1:0] im);
        real re_r, im_r;
        begin
            re_r = fxp_to_real(re);
            im_r = fxp_to_real(im);
            $display("%s : Re = %0f  Im = %0f  (raw: 0x%0h, 0x%0h)",
                     label, re_r, im_r, re, im);
        end
    endtask

    // Convenience: set inputs, wait for pipeline to settle, then print
    task run_test(input string name,
                  input [FRAC_BITS:0] angle,
                  input real a_re, input real a_im,
                  input real b_re, input real b_im);
        int n;
        begin
            $display("\n=== %s ===", name);

            // Apply inputs on a clock edge
            // @(posedge clk_i);
            twid_i    <= angle;
            a_i[0]    <= $rtoi(a_re * (1 << FRAC_BITS));
            a_i[1]    <= $rtoi(a_im * (1 << FRAC_BITS));
            b_i[0]    <= $rtoi(b_re * (1 << FRAC_BITS));
            b_i[1]    <= $rtoi(b_im * (1 << FRAC_BITS));

            // Wait for CORDIC / butterfly pipeline
            for (n = 0; n < PIPE_LAT; n++) begin
                @(posedge clk_i);

                if (n == 2) begin
                    rst = 1'b0;
                end
            end

            // Print I/O at this time
            print_complex("a_i", a_i[0], a_i[1]);
            print_complex("b_i", b_i[0], b_i[1]);
            print_complex("b_rot", dut.b_rot_re[0], dut.b_rot_re[1]);
            print_complex("a_o", a_o[0], a_o[1]);
            print_complex("b_o", b_o[0], b_o[1]);
        end
    endtask

    // ------------------------------------------------------------
    // Main stimulus
    // ------------------------------------------------------------
    initial begin
        // VCD dump
        $dumpfile("tb_butterfly_cordic.vcd");
        $dumpvars(0, tb_butterfly_cordic);

        // Reset
        rst   = 1'b1;
        twid_i = '0;
        a_i    = '0;
        b_i    = '0;

        repeat (3) @(posedge clk_i);
        //rst = 1'b0;

        // --------------------------------------------------------
        // Test 2: W ≈ 0.707 - j0.707 (W16^2: angle = 2π*2/16 = π/4)
        // angle code = FULL_TURN * (2/16) = FULL_TURN / 8
        // a = 1.0 + j0, b = 0.5 + j0
        // --------------------------------------------------------
        run_test("Custom test",
                 /*angle*/  FULL_TURN * 3 / 8,   // π/4
                 /*a_re*/   1.0,
                 /*a_im*/   0.0,
                 /*b_re*/   0.5,
                 /*b_im*/   0.0);


        repeat (3) @(posedge clk_i);
        rst = 1'b0;

        // --------------------------------------------------------
        // Test 1: W = 1 + j0  (angle = 0)
        // a = 0.5 + j0, b = 0.25 + j0
        // // --------------------------------------------------------
        // run_test("Test 1: W=1+0j, a=0.5, b=0.25",
        //          /*angle*/  { (FRAC_BITS+1){1'b0} },   // 0
        //          /*a_re*/   0.5,
        //          /*a_im*/   0.0,
        //          /*b_re*/   0.25,
        //          /*b_im*/   0.0);

        // // --------------------------------------------------------
        // // Test 2: W ≈ 0.707 - j0.707 (W16^2: angle = 2π*2/16 = π/4)
        // // angle code = FULL_TURN * (2/16) = FULL_TURN / 8
        // // a = 1.0 + j0, b = 0.5 + j0
        // // --------------------------------------------------------
        // run_test("Test 2: W=W16^2 (~0.707 - j0.707), a=1.0, b=0.5",
        //          /*angle*/  FULL_TURN / 8,   // π/4
        //          /*a_re*/   1.0,
        //          /*a_im*/   0.0,
        //          /*b_re*/   0.5,
        //          /*b_im*/   0.0);

        // // --------------------------------------------------------
        // // Test 3: W ≈ 0 - j1 (W16^4: angle = 2π*4/16 = π/2)
        // // angle code = FULL_TURN * (4/16) = FULL_TURN / 4
        // // a = 0.5 + j0.25, b = 0.25 - j0.25
        // // --------------------------------------------------------
        // run_test("Test 3: W=W16^4 (~0 - j1), a=0.5+j0.25, b=0.25-j0.25",
        //          /*angle*/  FULL_TURN / 4,   // π/2
        //          /*a_re*/   0.5,
        //          /*a_im*/   0.25,
        //          /*b_re*/   0.25,
        //          /*b_im*/  -0.25);

        $finish;
    end

endmodule
