module radix4_booth_wallace #(
    parameter int N = 8
)(
    input  logic signed [N-1:0]   M,
    input  logic signed [N-1:0]   Q,
    output logic signed [2*N-1:0] result
);
    localparam int ITER = N/2;

    // ---------------------------------------------------------------
    // Block 1: Booth encoders - one per window
    // ---------------------------------------------------------------
    logic [ITER-1:0] neg, sel1, sel2;

    genvar gi;
    generate
        for (gi = 0; gi < ITER; gi++) begin : ENCODERS
            logic [2:0] window;

            if (gi == 0) begin
                assign window = {Q[1], Q[0], 1'b0};
            end
            else begin
                assign window = {Q[2*gi+1], Q[2*gi], Q[2*gi-1]};
            end

            booth_r4_encoder enc (
                .window (window),
                .neg    (neg[gi]),
                .sel1   (sel1[gi]),
                .sel2   (sel2[gi])
            );
        end
    endgenerate

    // ---------------------------------------------------------------
    // Block 2+3: Partial product rows - magnitude select, NOT-only
    // negation, sign-extended, shifted into position
    // ---------------------------------------------------------------
    localparam int PW = 2*N + 8;

    logic [N:0]    magnitude [ITER-1:0];
    logic [N:0]    maybe_neg [ITER-1:0];
    logic [PW-1:0] row       [ITER-1:0];

    generate
        for (gi = 0; gi < ITER; gi++) begin : ROWS
            assign magnitude[gi] = sel2[gi] ? ({M[N-1], M} << 1) :
                                    sel1[gi] ? {M[N-1], M}        :
                                               '0;

            assign maybe_neg[gi] = neg[gi] ? ~magnitude[gi] : magnitude[gi];

            assign row[gi] = ( {{(PW-(N+1)){maybe_neg[gi][N]}}, maybe_neg[gi]} ) << (2*gi);
        end
    endgenerate

    // ---------------------------------------------------------------
    // Correction row: one "+1" bit per negated row, at that row's LSB position
    // ---------------------------------------------------------------
    logic [PW-1:0] correction_row;

    always_comb begin
        correction_row = '0;
        for (int gj = 0; gj < ITER; gj++) begin
            correction_row[2*gj] = neg[gj];
        end
    end

    // ---------------------------------------------------------------
    // Block 4: Wallace tree reduction
    // ---------------------------------------------------------------
    localparam int TOTAL_ROWS = ITER + 1;

    // Scalar-returning function: computes how many rows survive after
    // `layer` reduction steps, starting from `start_count` rows.
    // NOTE: Quartus (and many synthesis tools) do not support functions
    // that return an unpacked-array type - only scalar return types are
    // portable across simulator + synthesizer. So instead of building a
    // whole ROW_COUNTS[] array in one call, this is called once per
    // layer index, recomputing from scratch each time (cheap - it's all
    // elaboration-time, not real hardware).
    function automatic int row_count_at(input int start_count, input int layer);
        int k;
        int i;
        begin
            k = start_count;
            for (i = 0; i < layer; i++) begin
                k = (k/3)*2 + (k%3);
            end
            row_count_at = k;
        end
    endfunction

    // Still scalar - this one was never the problem, kept as-is.
    function automatic int num_wallace_layers(input int num_rows);
        int k;
        int layers;
        begin
            k = num_rows;
            layers = 0;
            while (k > 2) begin
                k = (k/3)*2 + (k%3);
                layers = layers + 1;
            end
            num_wallace_layers = layers;
        end
    endfunction

    localparam int NUM_LAYERS = num_wallace_layers(TOTAL_ROWS);

    logic [PW-1:0] layer_rows [0:NUM_LAYERS][0:TOTAL_ROWS-1];

    generate
        for (gi = 0; gi < ITER; gi++) begin : LOAD_LAYER0
            assign layer_rows[0][gi] = row[gi];
        end
    endgenerate

    assign layer_rows[0][ITER] = correction_row;

    genvar layer_i, group_i, leftover_i;
    generate
        for (layer_i = 0; layer_i < NUM_LAYERS; layer_i++) begin : WALLACE_LAYERS

            // Each of these is computed fresh per layer_i via the scalar
            // function above - no array-typed localparam needed anymore.
            localparam int rows_this_layer     = row_count_at(TOTAL_ROWS, layer_i);
            localparam int groups_this_layer   = rows_this_layer / 3;
            localparam int leftover_this_layer = rows_this_layer % 3;

            for (leftover_i = 0; leftover_i < leftover_this_layer; leftover_i++) begin : LEFTOVERS
                assign layer_rows[layer_i+1][2*groups_this_layer+leftover_i] =
                       layer_rows[layer_i][3*groups_this_layer+leftover_i];
            end

            for (group_i = 0; group_i < groups_this_layer; group_i++) begin : GROUPS
                wallace_compressor_3to2 #(.W(PW)) compressor (
                    .row_a     (layer_rows[layer_i][3*group_i]),
                    .row_b     (layer_rows[layer_i][3*group_i+1]),
                    .row_c     (layer_rows[layer_i][3*group_i+2]),
                    .sum_row   (layer_rows[layer_i+1][2*group_i]),
                    .carry_row (layer_rows[layer_i+1][2*group_i+1])
                );
            end
        end
    endgenerate

    // ---------------------------------------------------------------
    // Block 5: Final adder
    // ---------------------------------------------------------------
    logic [PW-1:0] full_result;

    assign full_result = layer_rows[NUM_LAYERS][0] + layer_rows[NUM_LAYERS][1];

    assign result = full_result[2*N-1:0];

endmodule