module radix4_booth_wallace #(
    parameter int N = 8
)(
    input logic [N-1:0] M,
	input logic [N-1:0] Q,
    output logic [2*N-1:0] result
);
    localparam ITER = N/2;

    logic signed [2*N+1:0] accumulator, next_accumulator, shifted;
	logic [7:0]   counter;

    assign M_ext = {M[N-1],M};  //extended M
	assign M_bar = ~M_ext + 1'b1;   //twos complement of M
	assign M_2  = M_ext << 1;
	assign M_2_bar = ~M_2 + 1'b1;

    logic [ITER-1:0] neg, sel1, sel2;

    genvar gi;

    generate
        for (gi=0; gi<ITER ; gi++) begin : ENCODERS
            logic [2:0] window;
            if (gi==0) begin
                assign window = {Q[1], Q[0], {1'b0}};
            end

            else begin
                assign window = {Q[2*gi+1],Q[2*gi], Q[2*gi-1]}
            end

            booth_r4_encoder enc(
                .window(window),
                .neg(neg[gi]),
                .sel1(sel1[gi]),
                .sel2(sel2[gi])
            );
        end
    endgenerate

    localparam int PW = 2*N+4;

    logic [N:0] magnitude [ITER-1:0];
    logic [N:0] maybe_neg [ITER-1:0];
    logic [PW-1:0] row [ITER-1:0]; 


    generate
        for (gi=0 ; i<ITER ; i++) begin
            assign magnitude[gi] = sel2[gi] ? ({M[N-1], M}<<1) : 
                               sel1[gi] ? {M[N-1], M} :
                               '0;
        end

        assign maybe_neg[gi] = neg[gi]? ~magnitude[gi] : magnitude[gi];

        assign row[gi] = ({{(PW-(N+1)){maybe_neg[gi][N]}} , maybe_neg[gi]}) << (2*gi);

    endgenerate

    logic [PW-1:0] correction_row;

    always_comb begin
        correction_row = '0;
        for (int gi=0;gi<ITER; gi++) begin
            correction_row[2*gi] = neg[gi];     // adds 1 at the specific place where a negative addition was made, since earlier I just negated M or 2M
        end
    end

    //wallce tree implementation

    localparam int TOTAL_ROWS = ITERS +1;

    function automaitic int num_wallace_layers(input int num_rows);
        int k;
        int layers;
        begin
            k=num_rows;
            layers=0;
            while (k>2)  begin
                k = (k/3)*2 + k%3;
                layers = layers +1;
            end
            num_wallace_layers = layers;
        end
    endfunction

    localparam int NUM_LAYERS = num_wallace_layers(TOTAL_ROWS);

    typedef logic [$clog2(TOTAL_ROWS+1)-1:0] row_count_t;

    function automatic row_count_t [NUM_LAYERS:0] compute_row_counts(input int num_rows);
        row_count_t rows [0:NUM_LAYERS];
        int k;
        int i;

        k = num_rows;
        i = 0;
        rows[i] = k;

        while (k > 2) begin
            k = (k / 3) * 2 + (k % 3);
            i = i + 1;
            rows[i] = k;
        end

        compute_row_counts = rows;
    endfunction

    localparam row_count_t ROW_COUNTS [NUM_LAYERS:0] = compute_row_counts(TOTAL_ROWS);

    logic [PW-1:0] layer_rows[0:NUM_LAYERS][0:TOTAL_ROWS-1];

    generate
        for (gi = 0; gi < ITER; gi++) begin : LOAD_LAYER0
            assign layer_rows[0][gi] = row[gi];
        end
    endgenerate

    assign layer_rows[0][ITER] = correction_row;


endmodule