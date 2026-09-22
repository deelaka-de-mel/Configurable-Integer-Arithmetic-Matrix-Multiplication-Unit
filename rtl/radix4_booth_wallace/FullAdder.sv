module FullAdder(
	input logic x,y,ci,
	output logic sum,co);
	
	always_comb begin
	sum = ci^(x^y);
	co = (x&y) | (x&ci) | (y&ci);

	end
	
endmodule