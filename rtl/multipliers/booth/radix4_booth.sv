module radix4_booth#(
	parameter int N=4
	)(
		input logic [N-1:0] M,
		input logic [N-1:0] Q,
		input logic start,clk,reset,
		output logic done,
		output logic [2*N-1:0] result);
	
	localparam int ITERATIONS = (N + 1) / 2;
		
	typedef enum logic [1:0] {IDLE, LOAD, CALCULATE, DONE} state_t;
	state_t state, next_state;
	
	logic signed [2*N+1:0] accumulator, next_accumulator, shifted;
	logic [7:0]   counter;
	logic [N:0] M_bar, M_ext;
	logic [N:0] M_2, M_2_bar;
	
	assign M_ext = {M[N-1],M};  //extended M
	assign M_bar = ~M_ext + 1'b1;   //twos complement of M
	assign M_2  = M_ext << 1;	//2*M
	assign M_2_bar = ~M_2 + 1'b1;
	
	always_ff @(posedge clk or posedge reset) begin
		
		if (reset) begin
			 state <= IDLE;
			 accumulator <= 0;
			 counter <=0;
			 result <=0;
			 done <=0;
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
			
			CALCULATE : next_state = (counter==ITERATIONS-1)? DONE: CALCULATE;
			
			DONE : next_state = IDLE;
			
		endcase
		
	end

	always_comb begin
	
		next_accumulator = accumulator;
		
		case(accumulator[2:0])
		
			3'b000,
			3'b111: ;
				  // +0

			3'b001,
		   3'b010: next_accumulator = accumulator + {M_ext,{(N+1){1'b0}}};
				  // +M

			3'b011: next_accumulator = accumulator + {M_2,{(N+1){1'b0}}};
				  // +2M

			3'b100: next_accumulator = accumulator + {M_2_bar,{(N+1){1'b0}}};
				  // -2M

			3'b101,
			3'b110: next_accumulator = accumulator + {M_bar,{(N+1){1'b0}}};
        // -M
			default : ;
			
		endcase
		
		shifted = next_accumulator >>>2;
			
	end
	
endmodule				