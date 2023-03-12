module daa_calc (
    input  logic [7:0] a,
    input  logic [3:0] fin,
    output logic [7:0] daa,
    output logic [3:0] fout
);

    localparam Z = 3, N = 2, H = 1, C = 0;

    logic [7:0] correction;
    logic [7:0] minus_correction;

    assign correction[3:0] =
        (fin[H] | ((~fin[N]) & (a[3:0] > 4'h9))) ? 4'h6 : 4'h0;
    
    assign correction[7:4] =
        // (fin[C] | ((~fin[N]) & (a > 8'h99))) ? 4'd6 : 4'd0;
        (fin[C] | ((~fin[N]) & (a[7:4] > 4'h9))) ? 4'h6 : 4'h0;

    assign minus_correction = (~correction) + 8'h1;

    assign daa = a + (fin[N] ? minus_correction : correction);

    assign fout[Z] = (daa == 8'd0);
    assign fout[N] = fin[N];
    assign fout[H] = 1'b0;
    assign fout[C] = fin[C] | ((~fin[N]) & (a > 8'h99));

endmodule
