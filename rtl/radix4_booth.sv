module radix4_booth#(
	parameter int N=5
	)(
		input logic [N-1:0] M,
		input logic [N-1:0] Q,
		input logic start,clk,reset,
		output logic done,
		output logic [2*N-1:0] result);
		
endmodule