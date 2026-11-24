module HalfAdder(
	input logic x,y,
	output logic sum,co);
	
	always_comb begin
	sum = x^y;
	co = x & y;

	end
	
endmodule