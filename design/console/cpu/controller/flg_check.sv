module flg_check (
    input  logic [3:0] f,
    input  logic [1:0] condition,
    output logic flg
);

    localparam Z = 3, N = 2, H = 1, C = 0;

    always_comb begin
        unique case (condition)
            2'b00: flg = ~f[Z];
            2'b01: flg = f[Z];
            2'b10: flg = ~f[C];
            2'b11: flg = f[C]; 
        endcase
    end
    
endmodule
