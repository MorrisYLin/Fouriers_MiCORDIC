`timescale 1ns/1ps
module cordic_input_standardizer_tb;

    reg  signed [15:0] x_in;
    reg  signed [15:0] y_in;
    reg        [15:0] theta_in; // unsigned 0..32767 mapping to 0..2*pi
    wire signed [15:0] x_out;
    wire signed [15:0] y_out;
    wire       [15:0] theta_out;
    wire [1:0] quadrant;

    // instantiate DUT
    cordic_input_standardizer dut (
        .x_in(x_in),
        .y_in(y_in),
        .theta_in(theta_in),
        .x_out(x_out),
        .y_out(y_out),
        .theta_out(theta_out),
        .quadrant(quadrant)
    );

    // constants
    localparam integer FULL_TURN = 16'd32768;
    localparam integer PI_HALF   = FULL_TURN/4; // 8192
    localparam integer PI        = FULL_TURN/2; // 16384
    localparam integer THREE_PI_HALF = 3*FULL_TURN/4; // 24576

    // helper to print angle as turns (fraction of full turn) with fixed decimal (approx)
    function [127:0] fmt_angle;
        input [15:0] a;
        real val;
        begin
            val = a / 32768.0;
            $sformat(fmt_angle, "%0.6f_turns", val);
        end
    endfunction

    // test driver
    task run_test;
        input signed [15:0] tx;
        input signed [15:0] ty;
        input      [15:0] ttheta;
        begin
            x_in = tx;
            y_in = ty;
            theta_in = ttheta;
            #1; // combinational propagation
            $display("IN  : x=%6d y=%6d theta=%6d (%s) | OUT : x=%6d y=%6d theta=%6d (%s) quadrant=%0d",
                     x_in, y_in, theta_in, fmt_angle(theta_in),
                     x_out, y_out, theta_out, fmt_angle(theta_out),
                     quadrant);
        end
    endtask

    initial begin
        $display("Starting testbench...");

        // 1: zero angle
        run_test(16'sd16384, 16'sd0, 16'd0);

        // 2: small angle near zero
        run_test(16'sd16384, 16'sd0, 16'd100);

        // 3: angle = PI/2 boundary
        run_test(16'sd10000, 16'sd5000, PI_HALF);

        // 4: angle just above PI/2
        run_test(16'sd10000, 16'sd5000, PI_HALF + 1);

        // 5: angle = PI
        run_test(16'sd12000, -16'sd12000, PI);

        // 6: angle = 3PI/2
        run_test(16'sd2000, 16'sd3000, THREE_PI_HALF);

        // 7: angle slightly below FULL_TURN (wrap region)
        run_test(-16'sd15000, 16'sd8000, 16'd32767);

        // 8: angle exactly FULL_TURN (treated as 0)
        run_test(16'sd20000, 16'sd1000, 16'd32768 % 65536); // will be 32768 but DUT maps to 0

        // 9: random vector small angle
        run_test(-16'sd8000, 16'sd4000, 16'd2000);

        //10: random vector medium angle
        run_test(16'sd25000, -16'sd12000, 16'd12000);

        //11: angle near PI+1000
        run_test(16'sd3000, 16'sd3000, PI + 1000);

        //12: angle near 5/4*pi (between PI and 3PI/2)
        run_test(-16'sd22000, -16'sd12000, PI + (PI_HALF/2));

        //13: angle near 7/4*pi
        run_test(16'sd15000, -16'sd30000, THREE_PI_HALF + 2000);

        //14: minimal vectors and angle small
        run_test(-16'sd1, -16'sd1, 16'd1);

        //15: maximal positive vector
        run_test(16'sd32767, 16'sd0, PI/8);

        //16: maximal magnitude vector negative y
        run_test(16'sd32767, -16'sd32767, 16'd25000);

        $display("Tests complete.");
        $finish;
    end

endmodule
