`timescale 1ns/1ps

module tb_radix4_booth;

    localparam int N = 4;
    localparam int CLK_PERIOD = 10;

    logic [N-1:0]     M, Q;
    logic             start, clk, reset;
    logic             done;
    logic [2*N-1:0]   result;

    int errors = 0;
    int tests  = 0;

    // ---------------------------------------------------------------
    // DUT
    // ---------------------------------------------------------------
    radix4_booth #(.N(N)) dut (
        .M      (M),
        .Q      (Q),
        .start  (start),
        .clk    (clk),
        .reset  (reset),
        .done   (done),
        .result (result)
    );

    // ---------------------------------------------------------------
    // Clock
    // ---------------------------------------------------------------
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // ---------------------------------------------------------------
    // Reset
    // ---------------------------------------------------------------
    task automatic do_reset();
        reset = 1;
        start = 0;
        M     = '0;
        Q     = '0;
        @(posedge clk);
        @(posedge clk);
        reset = 0;
        @(negedge clk);
    endtask

    // ---------------------------------------------------------------
    // Drive one multiplication and self-check the result
    // ---------------------------------------------------------------
    task automatic run_case(input logic signed [N-1:0] m_in,
                             input logic signed [N-1:0] q_in);
        logic signed [2*N-1:0] expected;
        int watchdog;
        begin
            expected = m_in * q_in;

            @(negedge clk);
            M     = m_in;
            Q     = q_in;
            start = 1;
            @(negedge clk);
            start = 0;

            // Wait for done, with a watchdog so a broken FSM can't hang the sim.
            watchdog = 0;
            while (!done && watchdog < 100) begin
                @(negedge clk);
                watchdog++;
            end

            tests++;

            if (watchdog >= 100) begin
                errors++;
                $display("[FAIL] M=%0d Q=%0d : TIMEOUT waiting for done", m_in, q_in);
            end
            else if ($signed(result) !== expected) begin
                errors++;
                $display("[FAIL] M=%0d Q=%0d : expected=%0d got=%0d",
                          m_in, q_in, expected, $signed(result));
            end
            else begin
                $display("[PASS] M=%0d Q=%0d : result=%0d", m_in, q_in, $signed(result));
            end

            // let done deassert before starting the next case
            @(negedge clk);
        end
    endtask

    // ---------------------------------------------------------------
    // Stimulus
    // ---------------------------------------------------------------
    initial begin
        do_reset();

        $display("---- Directed sanity checks ----");
        run_case(4'sd3,  4'sd2);    // 3 * 2   =  6
        run_case(-4'sd3, 4'sd2);    // -3 * 2  = -6
        run_case(4'sd3,  -4'sd2);   // 3 * -2  = -6
        run_case(-4'sd3, -4'sd2);   // -3 * -2 =  6
        run_case(4'sd0,  4'sd5);    // 0 * 5   =  0
        run_case(4'sd7,  4'sd7);    // max_pos * max_pos = 49

        $display("---- Min-negative-M edge case (M = -2^(N-1) = -8) ----");
        // Sweeps every Q so every Booth digit (-2M,-M,0,+M,+2M) gets exercised
        // against the minimum negative multiplicand, which is where the
        // M_2_bar (-2M) term can overflow its (N+1)-bit width.
        for (int q = -8; q <= 7; q++) begin
            run_case(-4'sd8, N'(q));
        end

        $display("---- Min-negative-Q edge case (Q = -2^(N-1) = -8) ----");
        for (int m = -8; m <= 7; m++) begin
            run_case(N'(m), -4'sd8);
        end

        $display("---- Exhaustive sweep over all M x Q combinations ----");
        for (int m = -8; m <= 7; m++) begin
            for (int q = -8; q <= 7; q++) begin
                run_case(N'(m), N'(q));
            end
        end

        $display("=============================================");
        $display("TESTS RUN : %0d", tests);
        $display("FAILURES  : %0d", errors);
        if (errors == 0)
            $display("RESULT: ALL TESTS PASSED");
        else
            $display("RESULT: %0d TEST(S) FAILED", errors);
        $display("=============================================");

        $finish;
    end

    // Safety timeout for the whole simulation
    initial begin
        #100000;
        $display("[TIMEOUT] Simulation did not finish in time");
        $finish;
    end

endmodule