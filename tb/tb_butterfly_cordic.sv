`timescale 1ns/1ps

module tb_butterfly_cordic;

    // Parameters
    parameter DATA_WIDTH = 16;
    parameter FRAC_BITS  = 15;

    // Clk / Reset
    reg clk_i;
    reg rst;

    // Inputs
    reg signed [FRAC_BITS:0] twid_i;
    reg signed [1:0][DATA_WIDTH-1:0] a_i;
    reg signed [1:0][DATA_WIDTH-1:0] b_i;

    // Outputs
    wire signed [1:0][DATA_WIDTH-1:0] a_o;
    wire signed [1:0][DATA_WIDTH-1:0] b_o;

    // DUT
    butterfly_cordic #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC_BITS(FRAC_BITS)
    ) dut (
        .clk_i(clk_i),
        .twid_i(twid_i),
        .a_i(a_i),
        .b_i(b_i),
        .rst(rst),
        .a_o(a_o),
        .b_o(b_o)
    );

    // Clock: 100MHz
    always #5 clk_i = ~clk_i;

    task run_test(
        input signed [15:0] ar,
        input signed [15:0] ai,
        input signed [15:0] br,
        input signed [15:0] bi,
        input signed [15:0] tw
    );
    begin
        @(negedge clk_i);
        a_i[0] = ar;
        a_i[1] = ai;
        b_i[0] = br;
        b_i[1] = bi;
        twid_i = tw;
        @(posedge clk_i);
        #1;

        $display("IN: A=(%0d,%0d) B=(%0d,%0d) tw=%0d  | OUT: A=(%0d,%0d) B=(%0d,%0d)",
            ar, ai, br, bi, tw,
            a_o[0], a_o[1], b_o[0], b_o[1]
        );
    end
    endtask

    integer i;

    initial begin
        // Init
        clk_i = 0;
        rst   = 1;
        a_i   = 0;
        b_i   = 0;
        twid_i = 0;

        // Reset pulse
        #20;
        rst = 0;

        // 16 Testcases
        run_test(16'sh4000, 0,         16'sh2000, 0,         16'sh0000); // A=(0.5,0)  B=(0.25,0)  θ=0°
        // run_test(16'sh4000, 0,         16'sh2000, 0,         16'sh4000); // θ≈45°
        // run_test(16'sh4000, 16'sh4000, 16'sh2000, 16'sh2000, 16'sh0000); // (0.5,0.5)
        // run_test(16'sh6000, 16'sh2000, 16'sh1000, 16'sh3000, 16'sh2000);

        // run_test(16'sh2000, -16'sh2000, 16'sh3000, -16'sh1000, 16'sh4000);
        // run_test(-16'sh4000, 16'sh2000, -16'sh1000, 16'sh3000, 16'sh1000);
        // run_test(-16'sh4000, -16'sh4000, -16'sh2000, -16'sh2000, 16'sh0000);
        // run_test(16'sh1000, 16'sh3000, 16'sh3000, 16'sh1000, 16'sh6000);

        // run_test(16'sh7000, 16'sh0000, 16'sh1000, 16'sh2000, 16'sh8000);
        // run_test(16'sh1000, 16'sh1000, 16'sh2000, 16'sh2000, 16'sh4000);
        // run_test(16'sh3000, 16'sh5000, 16'sh1000, 16'sh1000, 16'sh2000);
        // run_test(16'sh6000, -16'sh1000, 16'sh2000, -16'sh2000, 16'sh3000);

        // run_test(-16'sh2000, 16'sh6000, 16'sh1000, -16'sh4000, 16'sh2000);
        // run_test(16'sh5000, -16'sh3000, 16'sh3000, 16'sh1000, 16'sh1000);
        // run_test(16'sh1000, -16'sh7000, 16'sh7000, 16'sh1000, 16'sh4000);
        // run_test(-16'sh6000, -16'sh2000, -16'sh1000, -16'sh3000, 16'sh2000);

        #50;
        $finish;
    end

endmodule
