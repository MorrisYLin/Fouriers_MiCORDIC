`timescale 1ns/1ps

module tb_butterfly;

    // Match DUT parameters
    localparam int FRAC_BITS  = 15;
    localparam int DATA_WIDTH = 16;

    // Twiddle is Q2.15: width = FRAC_BITS+2 = 17 bits
    localparam int TWID_WIDTH = FRAC_BITS + 2;

    // DUT signals
    logic signed [1:0][TWID_WIDTH-1:0]   twid_i;
    logic signed [1:0][DATA_WIDTH-1:0]   a_i;
    logic signed [1:0][DATA_WIDTH-1:0]   b_i;

    wire  signed [1:0][DATA_WIDTH-1:0]   a_o;
    wire  signed [1:0][DATA_WIDTH-1:0]   b_o;

    // Instantiate DUT
    butterfly #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC_BITS (FRAC_BITS)
    ) dut (
        .twid_i(twid_i),
        .a_i   (a_i),
        .b_i   (b_i),
        .a_o   (a_o),
        .b_o   (b_o)
    );

    // ------------------------------------------------------------
    // Helper: Q(FRAC_BITS) fixed-point -> real
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

    // ------------------------------------------------------------
    // Simple test sequence
    // ------------------------------------------------------------
    initial begin
        $dumpfile("tb_butterfly.vcd");
        $dumpvars(0, tb_butterfly);

        // -------------------------------
        // Test 1: twiddle = 1 + j0
        // a = 0.5 + j0, b = 0.25 + j0
        // -------------------------------
        // twid_i in Q2.15, but still scaled by 2^FRAC_BITS
        twid_i[0] = 1 << FRAC_BITS;  // Re = +1.0
        twid_i[1] = 0;               // Im = 0.0

        a_i[0] = $rtoi(0.5 * (1 << FRAC_BITS));  // 0.5
        a_i[1] = 0;                               // 0j

        b_i[0] = $rtoi(0.25 * (1 << FRAC_BITS)); // 0.25
        b_i[1] = 0;

        #1; // combinational settle

        $display("\n=== Test 1: W=1+0j, a=0.5, b=0.25 ===");
        print_complex("a_i", a_i[0], a_i[1]);
        print_complex("b_i", b_i[0], b_i[1]);
        print_complex("b_rot", dut.b_rot_re, dut.b_rot_im);
        print_complex("a_o", a_o[0], a_o[1]);
        print_complex("b_o", b_o[0], b_o[1]);

        // -------------------------------
        // Test 2: twiddle = 0.707 - j0.707 (W16^2)
        // a = 1.0 + j0, b = 0.5 + j0
        // -------------------------------
        twid_i[0] = $rtoi( 0.70710678 * (1 << FRAC_BITS));  // Re ~ 0.7071
        twid_i[1] = $rtoi(-0.70710678 * (1 << FRAC_BITS));  // Im ~ -0.7071

        a_i[0] = 1 << FRAC_BITS;                            // 1.0
        a_i[1] = 0;

        b_i[0] = $rtoi(0.5 * (1 << FRAC_BITS));             // 0.5
        b_i[1] = 0;

        #1;

        $display("\n=== Test 2: W=0.707 - j0.707, a=1.0, b=0.5 ===");
        print_complex("a_i", a_i[0], a_i[1]);
        print_complex("b_i", b_i[0], b_i[1]);
        print_complex("b_rot", dut.b_rot_re, dut.b_rot_im);
        print_complex("a_o", a_o[0], a_o[1]);
        print_complex("b_o", b_o[0], b_o[1]);

        // -------------------------------
        // Test 3: purely imaginary twiddle (0 - j1)
        // a = 0.5 + j0.25, b = 0.25 - j0.25
        // -------------------------------
        twid_i[0] = 0;
        twid_i[1] = - (1 << FRAC_BITS);   // -j1.0

        a_i[0] = $rtoi(0.5  * (1 << FRAC_BITS));  // Re = 0.5
        a_i[1] = $rtoi(0.25 * (1 << FRAC_BITS));  // Im = 0.25

        b_i[0] = $rtoi(0.25 * (1 << FRAC_BITS));  // Re = 0.25
        b_i[1] = $rtoi(-0.25 * (1 << FRAC_BITS)); // Im = -0.25

        #1;

        $display("\n=== Test 3: W=0 - j1, a=0.5+j0.25, b=0.25-j0.25 ===");
        print_complex("a_i", a_i[0], a_i[1]);
        print_complex("b_i", b_i[0], b_i[1]);
        print_complex("b_rot", dut.b_rot_re, dut.b_rot_im);
        print_complex("a_o", a_o[0], a_o[1]);
        print_complex("b_o", b_o[0], b_o[1]);

        $finish;
    end

endmodule
