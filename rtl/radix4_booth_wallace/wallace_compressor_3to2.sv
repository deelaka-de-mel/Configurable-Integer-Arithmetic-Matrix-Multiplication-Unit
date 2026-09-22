module wallace_compressor_3to2 #(
    parameter int W = 8   // width of each row
)(
    input  logic [W-1:0] row_a,
    input  logic [W-1:0] row_b,
    input  logic [W-1:0] row_c,
    output logic [W-1:0] sum_row,
    output logic [W-1:0] carry_row
);
    assign carry_row[0] = '0;

    genvar b;
    generate
        for (b = 0; b < W-1; b++) begin : COLUMNS
            FullAdder fa(
                .x(row_a[b]),
                .y(row_b[b]),
                .ci(row_c[b]),
                .sum(sum_row[b]),
                .co(carry_row[b+1])
            );
        end
    endgenerate

    FullAdder fa_top(
                .x(row_a[W-1]),
                .y(row_b[W-1]),
                .ci(row_c[W-1]),
                .sum(sum_row[W-1]),
                .co()
            );

endmodule