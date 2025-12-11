`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/28/2025 05:14:26 PM
// Design Name: 
// Module Name: cordic_pipeline
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 8-input pipelined CORDIC, updated angle logic + table
// 
//////////////////////////////////////////////////////////////////////////////////

module cordic_pipeline(
    input  wire clk,
    input  wire rst,
    input  wire signed [15:0] x_in  [0:7],
    input  wire signed [15:0] y_in  [0:7],
    input  wire        [15:0] phi   [0:7], // twiddle factor, unsigned angle (rad/π format)
    output wire signed [15:0] x_out [0:7],
    output wire signed [15:0] y_out [0:7]
    );

    // ------------------------------------------------------------------------
    // CORDIC atan(2^-k) angle table in "rad/π" Q1.15 (same as single-unit version)
    // 0x8000 = π
    // 0x4000 = π/2 = 90°
    // 0x2000 = π/4 = 45°
    // ------------------------------------------------------------------------
    wire signed [15:0] phi_lut [0:7];

    assign phi_lut[0] = 16'sh2000; // atan(1)     ≈ 0.25π
    assign phi_lut[1] = 16'sh12E4; // atan(1/2)
    assign phi_lut[2] = 16'sh09F9; // atan(1/4)
    assign phi_lut[3] = 16'sh0511; // atan(1/8)
    assign phi_lut[4] = 16'sh028B; // atan(1/16)
    assign phi_lut[5] = 16'sh0146; // atan(1/32)
    assign phi_lut[6] = 16'sh00A3; // atan(1/64)
    assign phi_lut[7] = 16'sh0052; // atan(1/128)

    // ------------------------------------------------------------------------
    // Pipeline state
    // ------------------------------------------------------------------------
    reg  [4:0] in_x;
    reg  [3:0] count_first_out;
    reg  [2:0] out_x;

    // current_angle[k] is the accumulated angle after iteration k
    reg signed [16:0] current_angle [8:0];

    reg  [3:0]        state;        // (kept, though not used)
    reg signed [16:0] x_temp [8:0]; 
    reg signed [16:0] y_temp [8:0]; 

    // K gain compensation
    wire signed [33:0] x_34bits;
    wire signed [33:0] y_34bits;
    assign x_34bits = (x_temp[8] * 17'sh04DBA) >>> 15;
    assign y_34bits = (y_temp[8] * 17'sh04DBA) >>> 15;

    // Output registers
    reg signed [15:0] reg_x_out [0:7];
    reg signed [15:0] reg_y_out [0:7];

    assign x_out = reg_x_out;
    assign y_out = reg_y_out;

    // ------------------------------------------------------------------------
    // Main pipeline
    // ------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            // counters / indices
            in_x            <= 5'b0;
            out_x           <= 3'b0;
            count_first_out <= 4'b0;

            // initial pipeline state
            x_temp[0]       <= 17'sh0;
            y_temp[0]       <= 17'sh0;
            current_angle[0]<= 17'sh0;

            state           <= 4'b0;
        end else begin
            // ------------------------------------------------------------
            // Feed new input into stage 0
            // ------------------------------------------------------------
            if (in_x <= 7) begin
                x_temp[0]        <= x_in[in_x];
                y_temp[0]        <= y_in[in_x];
                current_angle[0] <= 17'sh0;   // fresh rotation every new input
            end

            if (in_x != 5'd15) begin
                in_x <= in_x + 1;
            end

            // ------------------------------------------------------------
            // Output index control
            // ------------------------------------------------------------
            if (count_first_out != 4'd9) begin
                count_first_out <= count_first_out + 1;
            end else if (out_x != 3'd7) begin
                out_x <= out_x + 1;
            end

            // ------------------------------------------------------------
            // ITERATION 0
            // Signed compare: if phi[...] > current_angle -> rotate "right"
            // else rotate "left".
            // rotate_right:  x' = x + y>>k, y' = y - x>>k, θ += φ_k
            // rotate_left :  x' = x - y>>k, y' = y + x>>k, θ -= φ_k
            // This matches your single cordic_iteration module logic.
            // ------------------------------------------------------------
            if ($signed(phi[in_x - 1]) > current_angle[0]) begin
                // rotate right
                x_temp[1]        <= x_temp[0] + (y_temp[0] >>> 0);
                y_temp[1]        <= y_temp[0] - (x_temp[0] >>> 0);
                current_angle[1] <= current_angle[0] + phi_lut[0];
            end else begin
                // rotate left
                x_temp[1]        <= x_temp[0] - (y_temp[0] >>> 0);
                y_temp[1]        <= y_temp[0] + (x_temp[0] >>> 0);
                current_angle[1] <= current_angle[0] - phi_lut[0];
            end

            // ------------------------------------------------------------
            // ITERATION 1
            // ------------------------------------------------------------
            if ($signed(phi[in_x - 2]) > current_angle[1]) begin
                x_temp[2]        <= x_temp[1] + (y_temp[1] >>> 1);
                y_temp[2]        <= y_temp[1] - (x_temp[1] >>> 1);
                current_angle[2] <= current_angle[1] + phi_lut[1];
            end else begin
                x_temp[2]        <= x_temp[1] - (y_temp[1] >>> 1);
                y_temp[2]        <= y_temp[1] + (x_temp[1] >>> 1);
                current_angle[2] <= current_angle[1] - phi_lut[1];
            end

            // ------------------------------------------------------------
            // ITERATION 2
            // ------------------------------------------------------------
            if ($signed(phi[in_x - 3]) > current_angle[2]) begin
                x_temp[3]        <= x_temp[2] + (y_temp[2] >>> 2);
                y_temp[3]        <= y_temp[2] - (x_temp[2] >>> 2);
                current_angle[3] <= current_angle[2] + phi_lut[2];
            end else begin
                x_temp[3]        <= x_temp[2] - (y_temp[2] >>> 2);
                y_temp[3]        <= y_temp[2] + (x_temp[2] >>> 2);
                current_angle[3] <= current_angle[2] - phi_lut[2];
            end

            // ------------------------------------------------------------
            // ITERATION 3
            // ------------------------------------------------------------
            if ($signed(phi[in_x - 4]) > current_angle[3]) begin
                x_temp[4]        <= x_temp[3] + (y_temp[3] >>> 3);
                y_temp[4]        <= y_temp[3] - (x_temp[3] >>> 3);
                current_angle[4] <= current_angle[3] + phi_lut[3];
            end else begin
                x_temp[4]        <= x_temp[3] - (y_temp[3] >>> 3);
                y_temp[4]        <= y_temp[3] + (x_temp[3] >>> 3);
                current_angle[4] <= current_angle[3] - phi_lut[3];
            end

            // ------------------------------------------------------------
            // ITERATION 4
            // (kept your original phi index pattern: in_x - 4)
            // ------------------------------------------------------------
            if ($signed(phi[in_x - 4]) > current_angle[4]) begin
                x_temp[5]        <= x_temp[4] + (y_temp[4] >>> 4);
                y_temp[5]        <= y_temp[4] - (x_temp[4] >>> 4);
                current_angle[5] <= current_angle[4] + phi_lut[4];
            end else begin
                x_temp[5]        <= x_temp[4] - (y_temp[4] >>> 4);
                y_temp[5]        <= y_temp[4] + (x_temp[4] >>> 4);
                current_angle[5] <= current_angle[4] - phi_lut[4];
            end

            // ------------------------------------------------------------
            // ITERATION 5
            // (kept your original phi index pattern: in_x - 6)
            // ------------------------------------------------------------
            if ($signed(phi[in_x - 6]) > current_angle[5]) begin
                x_temp[6]        <= x_temp[5] + (y_temp[5] >>> 5);
                y_temp[6]        <= y_temp[5] - (x_temp[5] >>> 5);
                current_angle[6] <= current_angle[5] + phi_lut[5];
            end else begin
                x_temp[6]        <= x_temp[5] - (y_temp[5] >>> 5);
                y_temp[6]        <= y_temp[5] + (x_temp[5] >>> 5);
                current_angle[6] <= current_angle[5] - phi_lut[5];
            end

            // ------------------------------------------------------------
            // ITERATION 6
            // (kept your original phi index pattern: in_x - 7)
            // ------------------------------------------------------------
            if ($signed(phi[in_x - 7]) > current_angle[6]) begin
                x_temp[7]        <= x_temp[6] + (y_temp[6] >>> 6);
                y_temp[7]        <= y_temp[6] - (x_temp[6] >>> 6);
                current_angle[7] <= current_angle[6] + phi_lut[6];
            end else begin
                x_temp[7]        <= x_temp[6] - (y_temp[6] >>> 6);
                y_temp[7]        <= y_temp[6] + (x_temp[6] >>> 6);
                current_angle[7] <= current_angle[6] - phi_lut[6];
            end

            // ------------------------------------------------------------
            // ITERATION 7 → FINAL INTO index 8
            // (kept your original phi index pattern: in_x - 8)
            // ------------------------------------------------------------
            if ($signed(phi[in_x - 8]) > current_angle[7]) begin
                x_temp[8]        <= x_temp[7] + (y_temp[7] >>> 7);
                y_temp[8]        <= y_temp[7] - (x_temp[7] >>> 7);
                current_angle[8] <= current_angle[7] + phi_lut[7];
            end else begin
                x_temp[8]        <= x_temp[7] - (y_temp[7] >>> 7);
                y_temp[8]        <= y_temp[7] + (x_temp[7] >>> 7);
                current_angle[8] <= current_angle[7] - phi_lut[7];
            end

            // ------------------------------------------------------------
            // Commit outputs (after K-scaling)
            // ------------------------------------------------------------
            reg_x_out[out_x] <= x_34bits[15:0];
            reg_y_out[out_x] <= y_34bits[15:0];
        end
    end

endmodule
