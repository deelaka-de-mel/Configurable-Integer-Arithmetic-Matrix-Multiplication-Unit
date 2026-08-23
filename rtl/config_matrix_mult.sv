module config_matrix_mult#(
	parameter int N=3
	parameter int W=8
	)(input logic [W-1:0] A [0:N-1][0:N-1],
	  input logic [W-1:0] B [0:N-1][0:N-1],
	  input logic clk,start,reset,
	  output logic done,
	  output logic [2*W-1:0] result [0:N-1][0:N-1]
	  );
	  
	  typedef enum logic [2:0] {IDLE, LOAD_MULT, MULT_WAIT,ACCUMULATE,LOAD_C, NEXT_INDEX, DONE} state_t;
	  state_t state, next_state;

	    
	  logic signed [2*W+1:0] accumulator, mult_intermediate;
	  logic [2:0] k, row, col, next_k, next_row, next_col;
	  logic start_mult, done_mult, all_done,next_all_done;
	  logic [W-1:0] M,Q;
	  
	  always_comb begin
			next_state = state;
			
	  
		  case(state)
		  
				IDLE : if (start) next_state = LOAD_MULT;
				
				LOAD_MULT : next_state = MULT_WAIT;
				
				MULT_WAIT : next_state = (mult_done==1)? ACCUMULATE : MULT_WAIT;
				
				ACCUMULATE : 
										
				
				LOAD_C : 
				
				NEXT_INDEX :
				
				DONE : 
		  
		  endcase
		  
	 end
	  
	 
		 // Combinational: always computes "what the next index WOULD be"
	always_comb begin
		 next_k = k;
		 next_col = col;
		 next_row = row;
		 next_all_done = all_done;

		 if (k == N-1) begin
			  next_k = 0;
			  if (col == N-1) begin
					next_col = 0;
					if (row == N-1) next_all_done = 1;
					else next_row = row + 1;
			  end else next_col = col + 1;
		 end else next_k = k + 1;
	end
	
	 always_ff @(posedge clk or posedge reset) begin
	 
		if (reset) begin
			 state <= IDLE;
		end
		
		else begin
			state <= next_state;
			k <= next_k;
			
			case(state) 
				
				IDLE : done<=0;
				
				LOAD_MULT : begin
									M<=A[row][k];
									Q<=B[k][col];
									start_mult <= 1;
								end
								
				ACCUMULATE : begin
				               accumulator <= accumulator + mult_intermediate;
									k   <= next_k;
								   col <= next_col;
								   row <= next_row;
								   all_done <= next_all_done;

	 end
	 
	 
	 
	  radix2_booth #(
        .N(W)
    ) ra1 (
        .M(M),
        .Q(Q),
        .start(start_mult),
        .clk(clk),
        .reset(reset),
        .done(mult_done),
        .result(mult_intermediate)
    );
			

			
endmodule