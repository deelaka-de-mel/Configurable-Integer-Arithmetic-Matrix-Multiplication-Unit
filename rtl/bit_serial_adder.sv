
module bit_serial_adder#(
	parameter int N=4
	)( input logic [N-1:0] A,
		input logic [N-1:0] B,
		input logic clk,
		input logic rst,
		output logic done,
		output logic [N:0] result);
		
		
		parameter LOAD  = 2'b00;
		parameter ADD = 2'b01;
		parameter SHIFT  = 2'b10;
		parameter DONE  = 2'b11;
		
		logic [1:0]  state = LOAD;
		logic A_in, B_in;
		logic [N-1:0] A_reg;
		logic [N-1:0] B_reg;
		logic [$clog2(N)-1:0] count;
		logic carry;
		
		always @(*) begin
			A_in = A_reg[0];
			B_in = B_reg[0];
		end
		
		
		always @(posedge clk) begin
			if (rst) begin
				state <= LOAD;
				done <= 0;
			end
			
			else begin
				case(state)
				
					
					LOAD: begin
						A_reg <= A;
						B_reg <= B;
						count<=0;
						carry <=0;
						done<=1'b0;
						state<=ADD;
						
					end
					
					ADD: begin
						result[count] <= carry ^ (A_in ^ B_in);
						carry <= (A_in & B_in) | (A_in & carry) | (B_in & carry);
						
						if (count==N-1) state <= DONE;
						else state <= SHIFT;
						
					end
						
					SHIFT : begin
						A_reg <= A_reg>>1;
						B_reg <= B_reg>>1;
						count<= count+1;
						state<= ADD;
					end
					
					DONE : begin
					result[N] <= carry;
					done<= 1'b1;
					end
					
				endcase
				
			end
		
		end
		
		
				
endmodule
		
		
		
		
