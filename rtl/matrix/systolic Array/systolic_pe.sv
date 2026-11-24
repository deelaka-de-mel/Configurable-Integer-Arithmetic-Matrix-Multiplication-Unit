module systolic_pe #(
    parameter W = 8,
    parametr N = 3
)(
    input logic clk,
    input logic rst,
    input logic signed [W-1:0] a_in,
    input logic signed [W-1:0] b_in,
    output logic signed [W-1:0] a_out,
    output logic signed [W-1:0] b_out,
    output logic signed [2*W-1 + N: 0] c_out
);
    localparam int ACC_W = 2*W + $clog2(N);

    logic signed [ACC_W-1: 0] accumulator;

    always_ff @(posedge clk) begin
        a_out <= a_in;
        b_out <= b_in;


    end



endmodule