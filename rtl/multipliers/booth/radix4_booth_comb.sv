module radix4_booth_comb (
    input logic [N-1:0] M,
	input logic [N-1:0] Q,
    output logic [2*N-1:0] result
);

    logic signed [2*N+1:0] accumulator, next_accumulator, shifted;
	logic [7:0]   counter;
	logic [N:0] M_bar, M_ext;
	logic [N:0] M_2, M_2_bar;

    assign M_ext = {M[N-1],M};  //extended M
	assign M_bar = ~M_ext + 1'b1;   //twos complement of M
	assign M_2  = M_ext << 1;
	assign M_2_bar = ~M_2 + 1'b1;

    


endmodule