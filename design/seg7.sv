module seg7 (
    input  logic [3:0] idat,
    output logic [6:0] odat
);

    always_comb begin
        case (idat)
            4'b0000: odat = 7'b1000000;
            4'b0001: odat = 7'b1111001;
            4'b0010: odat = 7'b0100100;
            4'b0011: odat = 7'b0110000;
            4'b0100: odat = 7'b0011001;
            4'b0101: odat = 7'b0010010;
            4'b0110: odat = 7'b0000010;
            4'b0111: odat = 7'b1011000;
            4'b1000: odat = 7'b0000000;
            4'b1001: odat = 7'b0010000;
            4'b1010: odat = 7'b0001000;
            4'b1011: odat = 7'b0000011;
            4'b1100: odat = 7'b1000110;
            4'b1101: odat = 7'b0100001;
            4'b1110: odat = 7'b0000110;
            4'b1111: odat = 7'b0001110;
            default: odat = 7'b1111111;
        endcase
    end
    
endmodule
