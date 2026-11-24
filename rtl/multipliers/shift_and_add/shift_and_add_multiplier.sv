module shift_and_add_multiplier #(
	parameter int N=16
	)(
		input logic [N-1:0] A,
		input logic [N-1:0] B,
		output logic [2*N-1:0] result);
		
		genvar i;
		
		logic [2*N:0] stage [N:0];
		assign stage[0] = {{(N+1){1'b0}},{B}};
		
		generate 
		
			for (i=0 ; i<N ; i++) begin : stages
			
				logic [2*N:0] added;
				
				assign added = stage[i][0] ? stage[i]+({{(N+1){1'b0}},A}<<N) : stage[i];
				
				assign stage[i+1] = added>>1;
				
			end
				
		endgenerate
		
		assign result = stage[N][2*N-1:0];
		

endmodule
				
					
				
				
		
		
		