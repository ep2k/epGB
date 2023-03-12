module bitalu (
    input  logic [7:0] a,
    input  logic [2:0] b,
    output logic [7:0] y,
    input  logic [2:0] control
);

    localparam C = 4;

    always_comb begin

        y = a;

        casez (control)
            3'b00?: y[b] = control[0]; // RESET/SET
            3'b100: y[6:4] = 3'b001; // scf
            3'b101: y[6:4] = {2'b00, ~a[C]}; // ccf
            3'b111: y = {~a[b], 7'b010_0000};
            default: ;
        endcase
    end
    
endmodule
