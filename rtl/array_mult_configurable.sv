module array_mult_configurable#(
	parameter int N=16
	)(
		input logic [N-1:0] a,
		input logic [N-1:0] b,
		output logic [2*N-1:0] result);
		
		logic pp [N-1:0][N-1:0];
		logic row_sum  [N-1:0][N-1:0];	// stores the sums of the full adders, also feeds the next row of full adders their inputs
      logic row_cout [N-1:0][N-1:0];	// stores the carry outs of the full adders, also feeds the i=N-1 adder its input.

		genvar i, j;
		
		generate
		
		for (j=0 ; j<N ; j++) begin : row_loop
			for (i=0 ; i<N ; i++) begin : column_loop
			
				assign pp[j][i] = a[i] & b[j]; 
				
			end
		end
		
		endgenerate
		
		//initializing row_sum with the and of first bit of b and all bits of a
		generate 
		
			for (i =0 ;i<N;i++) begin : init_sum
				assign row_sum[0][i] = b[0] & a[i];
			end	
			
		endgenerate
		
		assign row_cout[0][N-1] = 1'b0;
		// generating the adders, j= row, i= column, refer book diagram of 4 bit multiplier
		generate
			 for (j = 1; j < N; j++) begin : ROW
				  for (i = 0; i < N; i++) begin : COL
				  
					logic x_in, y_in, c_in;
					
					assign x_in = pp[j][i];
					
					assign y_in = (i==N-1)?  row_cout[j-1][i] : row_sum[j-1][i+1];
					
					assign c_in = (i==0)? 1'b0 : row_cout[j][i-1];
					
						FullAdder fa (
						.x(x_in),
						.y(y_in),
						.ci(c_in),
						.sum(row_sum[j][i]),
						.co(row_cout[j][i])
						);

				  end
			 end
		endgenerate
			
	assign result[2*N-1] = row_cout[N-1][N-1];  
	
	generate 
	
	for (i=0;i<N;i++) begin : sum1
		assign result[i] = row_sum[i][0];
		
	end
	endgenerate
	
	generate 
	
	for (i=N;i<2*N-1;i++) begin : sum2
		assign result[i] = row_sum[N-1][i-N+1];
		
	end
	endgenerate
	
	
	
	
endmodule
		