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
    input  wire clk,
    input wire rst,
    input wire signed [15:0] x_in,
    input wire signed [15:0] y_in,
    input wire [15:0] phi, //twiddle factor
    output wire signed [15:0] x_out,
    output wire signed [15:0] y_out
    );

    //wire signed [15:0] shifted_phi = $signed({1'b0, phi[15:1]});
    //wire signed [15:0] signed_phi  = -shifted_phi;
    wire signed [15:0] signed_phi = -$signed(phi);
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
    
    reg signed [16:0] current_angle;
    reg [2:0] n;
    reg [1:0] state;
    reg signed [16:0] x_temp; 
    reg signed [16:0] y_temp; 
    
    wire signed [15:0] angle_check;
    assign angle_check = phi_lut[n];
    
    reg signed [16:0] x_old;
    reg signed [16:0] y_old;

    wire signed [33:0] x_34bits;
    wire signed [33:0] y_34bits;
    assign x_34bits = (x_temp * 17'sh04DBA) >>> 15;
    assign y_34bits = (y_temp * 17'sh04DBA) >>> 15;
    
    assign x_out = x_34bits[15:0];
    assign y_out = y_34bits[15:0];
    
    
    assign rotate_left = ( (signed_phi - current_angle) >= 0) ? 1'b1 : 1'b0;
    
    always @(posedge clk) begin
        if (rst) begin
            n <= 3'b0;
            current_angle <= 17'sh0;
            state <= 2'b1;
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
                    
                    
                    if (n == 0) begin
                    
                        if (rotate_left) begin
                            x_temp <= x_in - (y_in >>> n);
                            y_temp <= y_in + (x_in >>> n);
                            current_angle <= current_angle + phi_lut[n];
                        end else begin
                            x_temp <= x_in + (y_in >>> n);
                            y_temp <= y_in - (x_in >>> n);
                            current_angle <= current_angle - phi_lut[n];
                        end
                    end else begin
                    
                        if (rotate_left) begin
                            x_temp <= x_old - (y_old >>> n);
                            y_temp <= y_old + (x_old >>> n);
                            current_angle <= current_angle + phi_lut[n];
                        end else begin
                            x_temp <= x_old + (y_old >>> n);
                            y_temp <= y_old - (x_old >>> n);
                            current_angle <= current_angle - phi_lut[n];
                        end
                    end
                
                    // Advance iteration
                    if (n == 7) begin
                        state <= 1'b0;
                        current_angle <= 17'sh0;
                        n <= 0;
                    end else begin
                        n <= n + 1;
                    end
                end
                                
                2'd2: begin 
                    // k = 0.607252935
                    // 16'sh4DC0 - k value for in 1 bit sign, 15 bit frac
                    // 17'sh04DBA - k value for 1 bit sign, 1 bit int, 15 bit frac
                    //x_out <= x_34bits[15:0];
                    //y_out <= y_34bits[15:0];
                    n <= 0;               
                    state <= 1'b0;
                    current_angle <= 17'sh0;
                end

            endcase    
        end
    end
    
endmodule
