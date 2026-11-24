module spi_slave_top3 (
    input  logic SPI_SCLK,
    input  logic SPI_MOSI,
    input  logic SPI_CS,
	 output logic SPI_MISO,
    output logic [7:0] LED
);

    logic [7:0] rx_data;
    logic       rx_valid;

    logic [7:0] M_reg;
    logic [7:0] Q_reg;
	 logic [15:0] result;

    logic       byte_count;


    // SPI receiver
    spi_slave_rx spi_receiver (
        .sclk     (SPI_SCLK),
        .mosi     (SPI_MOSI),
        .cs       (SPI_CS),
        .rx_data  (rx_data),
        .rx_valid (rx_valid)
    );


    // Store received bytes
    always_ff @(posedge SPI_SCLK) begin

        if (SPI_CS) begin
            byte_count <= 1'b0;
        end

        else if (rx_valid) begin

            if (byte_count == 1'b0) begin
                M_reg <= rx_data;
                byte_count <= 1'b1;
            end

            else begin
                Q_reg <= rx_data;
                byte_count <= 1'b0;
            end

        end
    end
	 
	radix4_booth_wallace #(.N(8)) r4bw (
		.M(M_reg),
		.Q(Q_reg),
		.result(result)
		);
		
	assign LED = result[7:0];

    logic [7:0] tx_shift_reg;

    always_ff @(negedge SPI_SCLK) begin
        if (SPI_CS) begin
            tx_shift_reg <= '0;
        end

        else begin
            tx_shift_reg <= {tx_shift_reg[6:0], 1b'0}
        end
    end

    assign SPI_MISO = tx_shift_reg[7];

endmodule