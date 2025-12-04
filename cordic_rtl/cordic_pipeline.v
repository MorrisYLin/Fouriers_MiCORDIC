`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/04/2025 02:10:36 AM
// Design Name: 
// Module Name: cordic_pipeline
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


module cordic_pipeline(
    input  wire clk,
    input wire rst,
    input wire signed [15:0] x_in,
    input wire signed [15:0] y_in,
    input wire signed [15:0] phi, //twiddle factor
    output wire signed [15:0] x_out,
    output wire signed [15:0] y_out
    );


    // Standard CORDIC atan(2^-k) angle table in Q1.15
    wire signed [15:0] phi_lut [0:7];
    
    assign phi_lut[0] = 16'sh6488; // atan(1) =45
    assign phi_lut[1] = 16'sh3B58; // atan(1/2) =26.5650512 
    assign phi_lut[2] = 16'sh1F5B; // atan(1/4) =14
    assign phi_lut[3] = 16'sh0FEB; // atan(1/8)
    assign phi_lut[4] = 16'sh07FD; // atan(1/16)
    assign phi_lut[5] = 16'sh03FD; // atan(1/32)
    assign phi_lut[6] = 16'sh01FF; // atan(1/64)
    assign phi_lut[7] = 16'sh00FF; // atan(1/128)
    
    reg signed [16:0] current_angle [8:0];
    reg [2:0] n;
    reg [3:0] state;
    reg signed [16:0] x_temp [8:0]; 
    reg signed [16:0] y_temp [8:0]; 
    
    wire signed [15:0] angle_check;
    assign angle_check = phi_lut[n];
    
    reg signed [16:0] x_old;
    reg signed [16:0] y_old;

    wire signed [33:0] x_34bits;
    wire signed [33:0] y_34bits;
    assign x_34bits = (x_temp[8] * 17'sh04DBA) >>> 15;
    assign y_34bits = (y_temp[8] * 17'sh04DBA) >>> 15;
    
    assign x_out = x_34bits[15:0];
    assign y_out = y_34bits[15:0];
    
    //assign rotate_left = ( (phi - current_angle) >= 0) ? 1'b1 : 1'b0;
    
    always @(posedge clk) begin
        if (rst) begin
            n <= 3'b0;
            current_angle[0] <= 17'sh0;
            state <= 2'b0;
            x_temp[0] <= 17'sh0;
            y_temp[0] <= 17'sh0;
        end
        else begin
            x_temp[0] <= x_in;
            y_temp[0] <= y_in;

            // ITERATION 0
            if ((phi - current_angle[0]) >= 0) begin
            x_temp[1] <=  x_in - (y_in >>> 0);
            y_temp[1] <= y_in + ( x_in >>> 0);
            current_angle[1] <= current_angle[0] + phi_lut[0];
            end else begin
            x_temp[1] <=  x_in + (y_in >>> 0);
            y_temp[1] <= y_in - ( x_in >>> 0);
            current_angle[1] <= current_angle[0] - phi_lut[0];
            end
            
            // ITERATION 1
            if ((phi - current_angle[1]) >= 0) begin
            x_temp[2] <= x_temp[1] - (y_temp[1] >>> 1);
            y_temp[2] <= y_temp[1] + (x_temp[1] >>> 1);
            current_angle[2] <= current_angle[1] + phi_lut[1];
            end else begin
            x_temp[2] <= x_temp[1] + (y_temp[1] >>> 1);
            y_temp[2] <= y_temp[1] - (x_temp[1] >>> 1);
            current_angle[2] <= current_angle[1] - phi_lut[1];
            end
            
            // ITERATION 2
            if ((phi - current_angle[2]) >= 0) begin
            x_temp[3] <= x_temp[2] - (y_temp[2] >>> 2);
            y_temp[3] <= y_temp[2] + (x_temp[2] >>> 2);
            current_angle[3] <= current_angle[2] + phi_lut[2];
            end else begin
            x_temp[3] <= x_temp[2] + (y_temp[2] >>> 2);
            y_temp[3] <= y_temp[2] - (x_temp[2] >>> 2);
            current_angle[3] <= current_angle[2] - phi_lut[2];
            end
            
            // ITERATION 3
            if ((phi - current_angle[3]) >= 0) begin
            x_temp[4] <= x_temp[3] - (y_temp[3] >>> 3);
            y_temp[4] <= y_temp[3] + (x_temp[3] >>> 3);
            current_angle[4] <= current_angle[3] + phi_lut[3];
            end else begin
            x_temp[4] <= x_temp[3] + (y_temp[3] >>> 3);
            y_temp[4] <= y_temp[3] - (x_temp[3] >>> 3);
            current_angle[4] <= current_angle[3] - phi_lut[3];
            end
            
            // ITERATION 4
            if ((phi - current_angle[4]) >= 0) begin
            x_temp[5] <= x_temp[4] - (y_temp[4] >>> 4);
            y_temp[5] <= y_temp[4] + (x_temp[4] >>> 4);
            current_angle[5] <= current_angle[4] + phi_lut[4];
            end else begin
            x_temp[5] <= x_temp[4] + (y_temp[4] >>> 4);
            y_temp[5] <= y_temp[4] - (x_temp[4] >>> 4);
            current_angle[5] <= current_angle[4] - phi_lut[4];
            end
            
            // ITERATION 5
            if ((phi - current_angle[5]) >= 0) begin
            x_temp[6] <= x_temp[5] - (y_temp[5] >>> 5);
            y_temp[6] <= y_temp[5] + (x_temp[5] >>> 5);
            current_angle[6] <= current_angle[5] + phi_lut[5];
            end else begin
            x_temp[6] <= x_temp[5] + (y_temp[5] >>> 5);
            y_temp[6] <= y_temp[5] - (x_temp[5] >>> 5);
            current_angle[6] <= current_angle[5] - phi_lut[5];
            end
            
            // ITERATION 6
            if ((phi - current_angle[6]) >= 0) begin
            x_temp[7] <= x_temp[6] - (y_temp[6] >>> 6);
            y_temp[7] <= y_temp[6] + (x_temp[6] >>> 6);
            current_angle[7] <= current_angle[6] + phi_lut[6];
            end else begin
            x_temp[7] <= x_temp[6] + (y_temp[6] >>> 6);
            y_temp[7] <= y_temp[6] - (x_temp[6] >>> 6);
            current_angle[7] <= current_angle[6] - phi_lut[6];
            end
            
            // ITERATION 7 → FINAL INTO index 8
            if ((phi - current_angle[7]) >= 0) begin
            x_temp[8] <= x_temp[7] - (y_temp[7] >>> 7);
            y_temp[8] <= y_temp[7] + (x_temp[7] >>> 7);
            current_angle[8] <= current_angle[7] + phi_lut[7];
            end else begin
            x_temp[8] <= x_temp[7] + (y_temp[7] >>> 7);
            y_temp[8] <= y_temp[7] - (x_temp[7] >>> 7);
            current_angle[8] <= current_angle[7] - phi_lut[7];
            end
        end
    end
    
endmodule
