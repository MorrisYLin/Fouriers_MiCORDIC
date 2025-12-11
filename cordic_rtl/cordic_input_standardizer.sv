// cordic_input_standardizer_fixed.v
// theta_in is unsigned 16-bit in [0 .. 32767] representing [0 .. 2*pi)
// x_in, y_in are signed Q1.15 (16-bit)

module cordic_input_standardizer #(
    parameter FRAC_BITS = 15
    ) (
    input  signed [FRAC_BITS:0] x_in,       // Q1.15 signed
    input  signed [FRAC_BITS:0] y_in,       // Q1.15 signed
    input         [FRAC_BITS:0] theta_in,    // unsigned: 0 .. 32767 -> 0 .. 2*pi (FULL_TURN)
    output signed [FRAC_BITS:0] x_out,      // Q1.15 signed
    output signed [FRAC_BITS:0] y_out,      // Q1.15 signed
    output        [FRAC_BITS:0] theta_out   // unsigned in [0 .. PI/2) (0 .. 8191)
    // output reg    [1:0]  quadrant     // 0..3
);

    // full-turn constant and quadrant thresholds
    localparam integer FULL_TURN = 16'd32768; // maps to 2*pi
    localparam integer PI_HALF   = FULL_TURN/4; // 8192 -> pi/2
    localparam integer PI        = FULL_TURN/2; // 16384 -> pi
    localparam integer THREE_PI_HALF = 3*FULL_TURN/4; // 24576 -> 3pi/2


    localparam [15:0] ANG90  = 16'h4000;
    localparam [15:0] ANG180 = 16'h8000;
    localparam [15:0] ANG270 = 16'hC000;

    // angle is already unsigned in [0..FULL_TURN-1], but guard against FULL_TURN input
    // Treat theta_in == FULL_TURN as 0 (wrap).
    wire [FRAC_BITS:0] angle_norm = (theta_in == FULL_TURN) ? 16'd0 : theta_in;

    // quadrant detection
    reg [1:0] q;
    reg [1:0] a_q;
    reg [FRAC_BITS:0] rem_angle;
    reg signed [FRAC_BITS:0] x_pr, y_pr;

    wire [1:0] vquad = { (y_in < 0), (x_in < 0) };  // vector quadrant 0-3
    wire [1:0] aquad = theta_in[15:14];              // top 2 bits define angle quadrant

/*
    always @(*) begin
        // quadrant detection
        if (angle_norm > 16'hc000) begin
            q = 2'd3;
            rem_angle = angle_norm - 16'hc000; // 0 .. PI_HALF-1
        end else if (angle_norm < PI) begin
            q = 2'd1;
            rem_angle = angle_norm - PI_HALF;
        end else if (angle_norm < THREE_PI_HALF) begin
            q = 2'd2;
            rem_angle = angle_norm - PI;
        end else begin
            q = 2'd3;
            rem_angle = angle_norm - THREE_PI_HALF;
        end

        // pre-rotation : apply q * 90° clockwise
        // clockwise +90° mapping: (x,y) -> (y, -x)
        case (q)
            2'd0: begin x_pr = x_in;    y_pr = y_in;   end
            2'd1: begin x_pr = y_in;    y_pr = -x_in;  end
            2'd2: begin x_pr = -x_in;   y_pr = -y_in;  end
            2'd3: begin x_pr = -y_in;   y_pr = x_in;   end
            default: begin x_pr = x_in; y_pr = y_in;   end
        endcase
    end
*/
always @(*) begin
    case (aquad)

    // =============================================================
    // ANGLE QUADRANT 0: 0° to 90°
    // NO SHIFT NECESSARY
    // =============================================================
    2'd0: begin
        x_pr      = x_in;
        y_pr      = y_in;
        rem_angle = (theta_in);
    end

    // =============================================================
    // ANGLE QUADRANT 1: 90° to 180°
    // SUBTRACT 90° → rotate vector right 90°: (x,y) → (y, -x)
    // =============================================================
    2'd1: begin
        x_pr      =  y_in;
        y_pr      = -x_in;
        rem_angle = (theta_in) - ANG90;
    end

    // =============================================================
    // ANGLE QUADRANT 2: 180° to 270°
    // SUBTRACT 180° → rotate vector right 180°: (x,y) → (-x, -y)
    // =============================================================
    2'd2: begin
        x_pr      = -x_in;
        y_pr      = -y_in;
        rem_angle = (theta_in) - ANG180;
    end

    // =============================================================
    // ANGLE QUADRANT 3: 270° to 360°
    // SUBTRACT 270° → rotate vector right 270°: (x,y) → (-y, x)
    // =============================================================
    2'd3: begin
        x_pr      = -y_in;
        y_pr      =  x_in;
        rem_angle = (theta_in) - ANG270;
    end

    endcase
end


    assign x_out = x_pr;
    assign y_out = y_pr;
    assign theta_out = rem_angle;

endmodule
