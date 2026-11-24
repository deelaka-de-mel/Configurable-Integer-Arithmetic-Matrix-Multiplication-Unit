module shift_and_add_multiplier_seq #(
    parameter int N = 4
)(
    input  logic             clk, rst, start,
    input  logic [N-1:0]     A, B,
    output logic [2*N-1:0]   result,
    output logic             done      // TODO: consider adding this - useful for a testbench/top level to know when to sample result
);

    typedef enum logic [1:0] {IDLE, LOAD, CALCULATE, DONE} state_t;
    state_t state, next_state;   // TODO: think about whether you need both, or just `state`

    logic [2*N:0] accumulator;
    logic [2*N:0] next_accumulator;   // purely combinational, no persistent "temp" reg
    logic [7:0]   counter;

    // ---- Combinational: compute next_accumulator from current accumulator ----
    // TODO: write this as a single assign/always_comb, reusing the exact same
    // shift-and-conditional-add expression from your combinational module,
    // just applied to `accumulator` instead of `stage[i]`.
    // assign next_accumulator = accumulator[0] ? ... : ...;

    // ---- Sequential: state register + accumulator/counter updates ----
    always_ff @(posedge clk) begin
        if (rst) begin
            // TODO: reset state, accumulator, counter, result/done to sane values
        end else begin
            case (state)
                IDLE: begin
                    if (start) state <= LOAD;
                end
                LOAD: begin
                    accumulator <= {{(N+1){1'b0}}, B};
                    counter     <= 0;
                    state       <= CALCULATE;
                end
                CALCULATE: begin
                    if (counter < N) begin
                        accumulator <= next_accumulator;  // just register the combinational result
                        counter     <= counter + 1;
                    end else begin
                        state <= DONE;
                    end
                end
                DONE: begin
                    result <= accumulator[2*N-1:0];
                    // TODO: done <= 1'b1; then transition back to IDLE — on which cycle?
                    state  <= IDLE;
                end
            endcase
        end
    end

endmodule