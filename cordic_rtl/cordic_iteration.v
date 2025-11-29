`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/28/2025 05:14:26 PM
// Design Name: 
// Module Name: cordic_interation
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module cordic_iteration(
    input  wire        clk,
    input wire rst,
    input  wire [15:0] angle,
    input wire calc,
    output  wire [15:0] x,
    output  wire [15:0] y
    );
    
    reg [15:0] approx_angle;
    reg [15:0] check_angle;
    
    wire [15:0] phi [0:7];
    /*
    assign phi[0] = 16'b0011001001000011;
    assign phi[1] = 16'b0001110110101100;
    assign phi[2] = 16'b0000111110101101;
    assign phi[3] = 16'b0000011111110101;
    assign phi[4] = 16'b0000001111111110; 
    assign phi[5] = 16'b0000000111111111;
    assign phi[6] = 16'b0000000011111111;
    assign phi[7] = 16'b0000000001111111;
    */
    
    //place holder values
    assign phi[0] = 16'b1000_0000_0000_0000; // bit 15
    assign phi[1] = 16'b0100_0000_0000_0000; // bit 14
    assign phi[2] = 16'b0010_0000_0000_0000; // bit 13
    assign phi[3] = 16'b0001_0000_0000_0000; // bit 12
    assign phi[4] = 16'b0000_1000_0000_0000; // bit 11
    assign phi[5] = 16'b0000_0100_0000_0000; // bit 10
    assign phi[6] = 16'b0000_0010_0000_0000; // bit   9
    assign phi[7] = 16'b0000_0001_0000_0000; // bit   8
    
    
    wire rotation_left;
    wire rotation_right;
    assign rotation_left = (angle > approx_angle) ? 1'b1 : 1'b0;
    assign rotation_right = (angle < approx_angle) ? 1'b1 : 1'b0;
    
    
    
    reg [2:0] n;
    reg [16:0] x_old;
    reg [16:0] y_old;

    assign x = x_old;
    assign y = y_old;
    
    wire [3:0] shift_amount;
    assign shift_amount = n + 4'b1;
    always @(posedge clk) begin
        if (rst) begin
            approx_angle <= 16'b0;
            //check_angle <= phi[0];
            n <= 3'b0;
            x_old <= 16'd1;
            y_old <= 16'b0;
            approx_angle <= 16'b0;
        end
        else begin
            if (calc) begin
                if (rotation_left || rotation_right) begin
                    x_old <= x_old - (y_old >>> shift_amount);
                    y_old <= y_old + (x_old >>> shift_amount);
                    if (rotation_left) begin
                        approx_angle <= approx_angle + phi[n];
                    end
                    else if (rotation_right) begin
                        approx_angle <= approx_angle - phi[n];
                    end
                end
                if (n == 3'b111) begin
                    approx_angle <= approx_angle;
                     x_old <= x_old;
                     y_old <= y_old;
                end else begin
                    n <= n + 3'b1;
                end
            end
        end
    end
    
endmodule