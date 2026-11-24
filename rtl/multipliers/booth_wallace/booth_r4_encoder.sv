module booth_r4_encoder (
    input logic [2:0] window,
    output logic neg,
    output logic sel1, // magnitude M
    output logic sel2 // magnitude 2M
);
    always_comb begin
        neg = 1'b0;
        sel1 = 1'b0;
        sel2 = 1'b0;

        case(window) 
            3'b000, 3'b111 : ; // 0
            3'b001, 3'b010 : sel1 = 1'b1;   // +M
            3'b110, 3'b101 : begin sel1 = 1'b1 ; neg = 1'b1 ; end   //-M
            3'b100         : begin sel2 = 1'b1 ; neg = 1'b1 ; end   //-2M
            3'b011         : sel2 = 1'b1 ;   //+2M
            default : ;
        endcase
    end

    
endmodule