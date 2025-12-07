module testmodule (
    input  a_i,
    input  b_i,
    input  clk_i,
    output reg [1:0] c_o
);

    wire [2:0] test;

    assign test[0] = 0;

    reg [1:0] state;

    always @(posedge clk_i) begin
        case (state)
            0 : state <= 1;
            1 : state <= 2;
            default : state <= 3;
        endcase
    end

    always @(*) begin
        c_o = state;
    end

endmodule
