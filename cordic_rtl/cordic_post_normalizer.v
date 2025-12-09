`timescale 1ns/1ps

module cordic_post_normalizer (
    input  wire signed [15:0] x_cordic,
    input  wire signed [15:0] y_cordic,
    input  wire [1:0]         orig_angle_quadrant,
    input  wire signed [15:0] phi_std,

    output reg signed [15:0]  x_out,
    output reg signed [15:0]  y_out
);

    reg signed [17:0] x_temp;
    reg signed [17:0] y_temp;

    // Saturation helper
    function signed [15:0] sat16;
        input signed [17:0] v;
        begin
            if (v > 18'sd32767)
                sat16 = 16'sd32767;
            else if (v < -18'sd32768)
                sat16 = -16'sd32768;
            else
                sat16 = v[15:0];
        end
    endfunction

    always @(*) begin
        // Default: passthrough
        x_temp = {{2{x_cordic[15]}}, x_cordic};
        y_temp = {{2{y_cordic[15]}}, y_cordic};

        // Reverse the standardizer's pre-rotation
        case (orig_angle_quadrant)

            2'b00: begin
                // Q1: no rotation applied originally → passthrough
                x_temp = {{2{x_cordic[15]}}, x_cordic};
                y_temp = {{2{y_cordic[15]}}, y_cordic};
            end

            2'b01: begin
                // Q2: original standardizer did -90 rotation
                // Undo: +90 rotation
                x_temp = -{{2{y_cordic[15]}}, y_cordic};
                y_temp =  {{2{x_cordic[15]}}, x_cordic};
            end

            2'b10: begin
                // Q3: original standardizer did 180 rotation
                // Undo: 180 rotation
                x_temp = -{{2{x_cordic[15]}}, x_cordic};
                y_temp = -{{2{y_cordic[15]}}, y_cordic};
            end

            2'b11: begin
                // Q4: original standardizer did +90 rotation
                // Undo: -90 rotation
                x_temp =  {{2{y_cordic[15]}}, y_cordic};
                y_temp = -{{2{x_cordic[15]}}, x_cordic};
            end

        endcase
    end

    always @(*) begin
        x_out = sat16(x_temp);
        y_out = sat16(y_temp);
    end

endmodule
