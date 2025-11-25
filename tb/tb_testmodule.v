`timescale 1ns/1ps

module tb_testmodule;

    reg clk;
    reg a;
    reg b;
    wire [1:0] c;

    // Instantiate DUT
    testmodule dut (
        .a_i(a),
        .b_i(b),
        .clk_i(clk),
        .c_o(c)
    );

    // Clock generator
    always #5 clk = ~clk;   // 100 MHz

    initial begin
        // Initialize signals
        clk = 0;
        a   = 0;
        b   = 0;

        // VCD dump
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_testmodule);

        // Run simulation for a few cycles
        #100;

        $finish;
    end

endmodule
