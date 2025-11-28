`timescale 1ns / 1ps

module top(
    input [15:0] theta,
    input trigMode, //0 -> cos(theta)  1-> sin(theta)
    input initialize,
    input calculate,
    input clk,
    output [15:0] result
    );
    
    reg [15:0] phi [0:7]; //increment angle values
    reg [15:0] k; // end scaling factor (prod(cos(arctan(1/2^i))) for 0<=i<=7
    reg [15:0] x; // point coordinates
    reg [15:0] y; //
    reg [15:0] z; // residual angle between current guess and goal theta
    
    reg [2:0] i; //iteration tracker
    
    reg mode;
    
    reg go;
    
    initial begin
    phi[0] = 16'b0011001001000011;
    phi[1] = 16'b0001110110101100;
    phi[2] = 16'b0000111110101101;
    phi[3] = 16'b0000011111110101;
    phi[4] = 16'b0000001111111110; //radians are v small and Fs appear as phi -> zero, should we use degrees for greater accuracy?
    phi[5] = 16'b0000000111111111;
    phi[6] = 16'b0000000011111111;
    phi[7] = 16'b0000000001111111;
    
    k = 16'b0010011011011101; // scaling still requires two multiplications at the end, any possible optimizations?
    
    x = 16'b0000000000000001;
    y = 16'b0000000000000000;
    
    z = theta;
    
    mode = trigMode;
    
    i = 3'b000;
    
    go <= 1'b0;
    end
    
    
    always @(posedge clk) begin 
    if (!go) begin // todo: standardize input to quadrant 1
        if (initialize) begin
            z <= theta;
            x <= 16'b0000000000000001;
            y <= 16'b0000000000000000;
            i <= 3'b000;
            mode <= trigMode;
        end
        if (calculate) begin
            go <= 1'b1;
        end
    end else begin
        // if (!((theta - z)>> 15)) // z is less than theta, positive case
    end
    
    end
endmodule
