module config_matrix_mult#(
	parameter int N=3,
	parameter int W=8
	)(input logic signed [W-1:0] A [0:N-1][0:N-1],
	  input logic signed [W-1:0] B [0:N-1][0:N-1],
	  input logic clk,start,reset,
	  output logic done,
	  output logic signed [2*W-1:0] result [0:N-1][0:N-1]
	  );
	  
	  typedef enum logic [2:0] {IDLE, LOAD_MULT,MULT_START, MULT_WAIT,ACCUMULATE,LOAD_C, NEXT_INDEX, DONE} state_t;
	  state_t state, next_state;

	    
	  logic signed [2*W+1:0] accumulator, mult_intermediate;
	  logic [2:0] k, row, col, next_k, next_row, next_col;
	  logic start_mult, mult_done, all_done,next_all_done;
	  logic signed [W-1:0] M,Q;
	  

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
						if (row == N-1) next_all_done = 3'd1;
						else next_row = row + 3'd1;
				  end else next_col = col + 3'd1;
			 end else next_k = k + 3'd1;
		end
	  
	  always_comb begin
			next_state = state;
		  case(state)
		  
				IDLE : if (start) next_state = LOAD_MULT;
				
				LOAD_MULT : next_state = MULT_START;
				
				MULT_START : next_state = MULT_WAIT;
				
				MULT_WAIT : next_state = (mult_done==1)? ACCUMULATE : MULT_WAIT;
				
				ACCUMULATE : begin
									if (k<N-1) next_state = NEXT_INDEX;
									if (k==N-1) next_state = LOAD_C;					
								 end

				LOAD_C : next_state = (all_done)? DONE : NEXT_INDEX;
				
				NEXT_INDEX : next_state = LOAD_MULT;
				
				DONE : next_state = IDLE;
		  
		  endcase
		  
	 end

	 always_ff @(posedge clk or posedge reset) begin
	 
		if (reset) begin
			 state <= IDLE;
			 
		end
		
		else begin
			state <= next_state;
			
			case(state) 
				
				IDLE : begin
							done<=0;
							k<=0;
							row<=0;
							col<=0;
							all_done<=0;
							accumulator <= 0;
							start_mult<=0;
						 end
				
				LOAD_MULT : begin
									M<=A[row][k];
									Q<=B[k][col];							
								end
								
				MULT_START: begin 
									start_mult <= 1;
								end
								
				MULT_WAIT : start_mult<=0;
								
				ACCUMULATE : begin
				               accumulator <= accumulator + mult_intermediate;
									k   <= next_k;
								   col <= next_col;
								   row <= next_row;
								   all_done <= next_all_done;
								end
								
				LOAD_C : begin
								result[row][col] <= accumulator;
								accumulator <= 0;
							end
							
				DONE : done<=1; 
				
			endcase
			
		end

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