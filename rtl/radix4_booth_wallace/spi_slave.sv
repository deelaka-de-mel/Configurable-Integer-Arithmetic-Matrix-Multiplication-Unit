module spi_slave#(
    parameter int width = 8 ;
)(
    input logic sclk,
    input logic cs,
    input logic mosi,
    output logic [width-1:0] rx_data,
    output logic rx_valid // byte received confirmation
);
    logic [width-1:0] rx_shift_reg;
    logic [$clog2(width)-1:0] bit_count;

    always_ff @(posedge sclk) begin // mode 0, 
        
        if (cs) begin
            bit_count <='0;
            rx_shift_reg <='0;
            rx_valid <= 0;
        end

        else begin
            rx_shift_reg <= {rx_shift_reg[6:0], mosi};

            if (bit_count==3'd7) begin
                rx_data <= {rx_shift_reg[6:0], mosi};
                rx_valid <= 1;
                bit_count <=0
            end

            else begin
                bit_count <= bit_count + 1;
                rx_valid <='0;
            end
        end
    end

endmodule