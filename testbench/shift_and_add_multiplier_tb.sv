module shift_and_add_multiplier_tb;
	parameter N = 4;

    // 1. Declare testbench signals
    logic clk;
    logic reset;
    logic [N-1:0] input1;
    logic [N-1:0] input2;
    logic [2*N-1:0] result;


    // 2. Instantiate the DUT
    shift_and_add_multiplier #(.N(N)) dut (
        .A(input1),
        .B(input2),
        .result(result)
    );


    // 3. Generate stimulus
    initial begin

        // Initialize inputs
        input1 = 0;
        input2 = 0;

        // Apply test cases
        #10;
        input1 = 5;
        input2 = 3;

        #10;
        input1 = 10;
        input2 = 7;

        #10;
        $finish;

    end


    // 4. Monitor outputs
    initial begin
        $monitor("time=%0t input1=%d input2=%d result=%d",
                  $time, input1, input2, result);
    end

endmodule