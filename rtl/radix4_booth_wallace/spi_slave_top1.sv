module spi_slave_top1(
    input logic SPI_SCLK,
    input logic SPI_MOSI,
    input logic SPI_CS,
    output logic [7:0] LED
);
    logic [7:0] rx_data;
    logic rx_valid;

    spi_slave s1(
        .mosi(SPI_MOSI),
        .sclk(SPI_SCLK),
        .cs(SPI_CS),
        .rx_data(rx_data),
        .rx_valid(rx_valid)
    );

    assign LED = rx_data;

endmodule