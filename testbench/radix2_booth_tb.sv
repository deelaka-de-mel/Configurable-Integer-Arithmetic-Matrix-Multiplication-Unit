`timescale 1ns/1ps
module radix2_booth_tb;

    parameter N = 4;

    logic signed [N-1:0] M, Q;
    logic start, reset, clk, done;
    logic signed [2*N-1:0] result;

    int pass_count = 0;
    int fail_count = 0;

    radix2_booth #(.N(N)) dut_booth (
        .M(M), .Q(Q), .start(start),
        .clk(clk), .done(done), .reset(reset),
        .result(result)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // Reference model: Radix-2 Booth is inherently a SIGNED (two's complement)
    // algorithm, so M and Q must be interpreted as signed N-bit values here.
    // $signed() forces the multiply to be done as signed arithmetic rather
    // than SystemVerilog's default unsigned interpretation of packed logic.
    function automatic signed [2*N-1:0] expected_product(input signed [N-1:0] m_in, input signed [N-1:0] q_in);
        expected_product = $signed(m_in) * $signed(q_in);
    endfunction

    task automatic run_test(input signed [N-1:0] m_in, input signed [N-1:0] q_in);
        logic signed [2*N-1:0] exp;
        exp = expected_product(m_in, q_in);

        M = m_in;
        Q = q_in;
        start = 1;
        @(posedge clk);
        start = 0;

        wait (done == 1);
        #1; // let result settle after the clock edge before sampling

        if (result !== exp) begin
            $error("FAIL: M=%0d Q=%0d expected=%0d got=%0d", m_in, q_in, exp, result);
            fail_count++;
        end else begin
            $display("PASS: M=%0d Q=%0d result=%0d", m_in, q_in, result);
            pass_count++;
        end

        @(posedge clk); // let done drop back to 0 before the next test is issued
    endtask

    initial begin
        // ---- Reset sequence ----
        reset = 1;
        start = 0;
        M = 0;
        Q = 0;
        @(posedge clk);
        @(posedge clk);
        reset = 0;
        @(posedge clk);

        // ---- Directed corner cases (signed N=4 range: -8 to +7) ----
        run_test(4'sd0,  4'sd0);           // zero operand
        run_test(4'sd1,  4'sd1);           // trivial positive
        run_test(4'sd3,  4'sd5);           // basic positive case
        run_test(-4'sd1, 4'sd1);           // negative x positive
        run_test(4'sd1,  -4'sd1);          // positive x negative
        run_test(-4'sd1, -4'sd1);          // negative x negative
        run_test(-4'sd8, 4'sd1);           // most negative value (M MSB set, -8)
        run_test(-4'sd8, -4'sd8);          // most negative x most negative (64, needs full 2N bits)
        run_test(4'sd7,  4'sd7);           // max positive x max positive (49)
        run_test(4'sb0111, 4'sd3);         // Q has a run of 1s -> exercises Booth add/subtract pair
        run_test(-4'sd8, -4'sd1);          // -8 x -1 = 8, tests negation of most-negative correctly
        run_test(4'sd5,  -4'sd6);          // mixed sign, no long runs

        // ---- Randomized sweep for broader coverage ----
        for (int i = 0; i < 50; i++) begin
            run_test($urandom_range(-(1<<(N-1)), (1<<(N-1))-1),
                      $urandom_range(-(1<<(N-1)), (1<<(N-1))-1));
        end

        $display("---------------------------------------");
        $display("TESTS COMPLETE: %0d passed, %0d failed", pass_count, fail_count);
        $display("---------------------------------------");

        $finish;
    end

endmodule