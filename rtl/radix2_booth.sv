module radix2_booth#(
	parameter int N=4
	)(
		input logic [N-1:0] M,
		input logic [N-1:0] Q,
		input logic start,clk,reset,
		output logic done,
		output logic [2*N-1:0] result);
		
	typedef enum logic [1:0] {IDLE, LOAD, CALCULATE, DONE} state_t;
	state_t state, next_state;
	
	logic signed [2*N+1:0] accumulator, next_accumulator, shifted;
	logic [7:0]   counter;
	logic [N:0] M_bar, M_ext;
	
	assign M_ext = {M[N-1],M};
	assign M_bar = ~M_ext + 1'b1;
	
	always_ff @(posedge clk or posedge reset) begin
		
		if (reset) begin
			 state <= IDLE;
			 accumulator <= 0;
			 counter <=0;
		end
		
		else begin
			state <= next_state;
			
			case(state)
			
				IDLE : done <=0;
				LOAD : begin
					accumulator <= {{(N+1){1'b0}},Q,1'b0};
					counter<=0;
					
				end
				
				CALCULATE : begin
					accumulator <= shifted;
					
					counter<=counter+1;
				end
				
				DONE : begin
					result<= accumulator[2*N:1];
					done <= 1;
				end
				
			endcase
				
		end
		 
	end
	
	always_comb begin
		next_state = state;
		
		case(state)
			
			IDLE: if (start)  next_state = LOAD;

			LOAD : next_state = CALCULATE;
			
			CALCULATE : next_state = (counter==N-1)? DONE: CALCULATE;
			
			DONE : next_state = IDLE;
			
		endcase
		
	end

	always_comb begin
	
		next_accumulator = accumulator;
		
		case(accumulator[1:0])
		
			2'b01 : next_accumulator = accumulator + {M_ext,{(N+1){1'b0}}};
			2'b10 : next_accumulator = accumulator + {M_bar,{(N+1){1'b0}}};
			default : ;
			
		endcase
		
		shifted = next_accumulator >>>1;
			
	end
	
endmodule				