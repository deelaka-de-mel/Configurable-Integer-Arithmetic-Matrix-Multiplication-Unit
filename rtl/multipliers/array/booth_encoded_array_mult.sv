module booth_encoded_array_mult#(
	parameter int N=4
	)(
		input logic [N-1:0] a,
		input logic [N-1:0] b,
		output logic [2*N-1:0] result);
		
		logic [2*N+1:0] accumulator;
		
		
endmodule