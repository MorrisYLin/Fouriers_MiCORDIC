`timescale 1ns / 1ps

module cordic_iteration(
    input  wire clk,
    input wire rst,
    input wire signed [15:0] x_in,
    input wire signed [15:0] y_in,
    input wire signed [15:0] phi, //twiddle factor
    output reg signed [15:0] x_out,
    output reg signed [15:0] y_out
    );


    /*
    assign phi[0] = 16'b0011001001000011;
    assign phi[1] = 16'b0001110110101100;
    assign phi[2] = 16'b0000111110101101;
    assign phi[3] = 16'b0000011111110101;
    assign phi[4] = 16'b0000001111111110;
    assign phi[5] = 16'b0000000111111111;
    assign phi[6] = 16'b0000000011111111;
    assign phi[7] = 16'b0000000001111111;


    //place holder values

    assign phi[0] = 16'b1000_0000_0000_0000; // bit 15
    assign phi[1] = 16'b0100_0000_0000_0000; // bit 14
    assign phi[2] = 16'b0010_0000_0000_0000; // bit 13
    assign phi[3] = 16'b0001_0000_0000_0000; // bit 12
    assign phi[4] = 16'b0000_1000_0000_0000; // bit 11
    assign phi[5] = 16'b0000_0100_0000_0000; // bit 10
    assign phi[6] = 16'b0000_0010_0000_0000; // bit   9
    assign phi[7] = 16'b0000_0001_0000_0000; // bit   8
    */


    // Standard CORDIC atan(2^-k) angle table in Q1.15
    wire signed [15:0] phi_lut [0:7];

    assign phi_lut[0] = 16'sh6488; // atan(1)
    assign phi_lut[1] = 16'sh3B58; // atan(1/2)
    assign phi_lut[2] = 16'sh1F5B; // atan(1/4)
    assign phi_lut[3] = 16'sh0FEB; // atan(1/8)
    assign phi_lut[4] = 16'sh07FD; // atan(1/16)
    assign phi_lut[5] = 16'sh03FD; // atan(1/32)
    assign phi_lut[6] = 16'sh01FF; // atan(1/64)
    assign phi_lut[7] = 16'sh00FF; // atan(1/128)

    reg signed [16:0] current_angle;
    reg [2:0] n;
    reg [1:0] state;
    reg signed [16:0] x_temp;
    reg signed [16:0] y_temp;

    wire signed [15:0]angle_check;
    assign angle_check = phi_lut[n];

    reg signed [16:0] x_old;
    reg signed [16:0] y_old;


    assign rotate_left = ( (phi - current_angle) >= 0) ? 1'b1 : 1'b0;

    always @(posedge clk) begin
        if (rst) begin
            n <= 3'b0;
            current_angle <= 17'sh0;
            state <= 2'b0;
            x_temp <= 17'sh0;
            y_temp <= 17'sh0;
        end
        else begin
            case (state)

                2'd0: begin
                    x_temp <= x_in;
                    y_temp <= y_in;
                    if (!rst) begin
                        state <= 2'd1;
                    end
                end

                2'd1: begin
                    // Capture old values

                    x_old = x_temp;
                    y_old = y_temp;

                    if (rotate_left) begin
                        x_temp <= x_old - (y_old >>> n);
                        y_temp <= y_old + (x_old >>> n);
                        current_angle <= current_angle + phi_lut[n];
                    end else begin
                        x_temp <= x_old + (y_old >>> n);
                        y_temp <= y_old - (x_old >>> n);
                        current_angle <= current_angle - phi_lut[n];
                    end

                    // Advance iteration
                    if (n == 7) begin
                        state <= 2;
                    end else begin
                        n <= n + 1;
                    end
                end

                2'd2: begin
                    x_out <= x_temp;
                    y_out <= y_temp;
                    n <= 0;
                    state <= 1'b0;
                    current_angle <= 17'sh0;
                end

            endcase
        end
    end

endmodule
