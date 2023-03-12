module alu (
    input  logic [7:0] a,
    input  logic [7:0] b,
    input  logic [3:0] fin,
    output logic [7:0] y,
    output logic [3:0] fout,
    input  logic [3:0] control
);

    localparam Z = 3, N = 2, H = 1, C = 0;

    logic [8:0] y_add, y_adc, y_sub, y_sbc;
    logic [4:0] h_add, h_adc, h_sub, h_sbc;

    assign y_add = a + b;
    assign y_adc = a + b + {7'b0, fin[C]};
    assign y_sub = a + {1'b0, ~b} + 8'h1;
    assign y_sbc = a + {1'b0, ~b} + ~{7'b0, fin[C]} + 8'h2;

    // fout[H]算出用
    assign h_add = a[3:0] + b[3:0];
    assign h_adc = a[3:0] + b[3:0] + {3'b0, fin[C]};
    assign h_sub = a[3:0] + {1'b0, ~b[3:0]} + 4'h1;
    assign h_sbc = a[3:0] + {1'b0, ~b[3:0]} + ~{3'b0, fin[C]} + 4'h2;

    always_comb begin
        unique case (control)
            4'b0_000 : y = y_add[7:0];         // ADD 
            4'b0_001 : y = y_adc[7:0];         // ADC
            4'b0_010 : y = y_sub[7:0];         // SUB
            4'b0_011 : y = y_sbc[7:0];         // SBC
            4'b0_100 : y = a & b;              // AND
            4'b0_101 : y = a ^ b;              // XOR
            4'b0_110 : y = a | b;              // OR
            4'b0_111 : y = a;                  // CP
            4'b1_000 : y = {a[6:0], a[7]};     // RLC
            4'b1_001 : y = {a[0], a[7:1]};     // RRC
            4'b1_010 : y = {a[6:0], fin[C]};   // RL
            4'b1_011 : y = {fin[C], a[7:1]};   // RR
            4'b1_100 : y = {a[6:0], 1'b0};     // SLA
            4'b1_101 : y = {a[7], a[7:1]};     // SRA
            4'b1_110 : y = {a[3:0], a[7:4]};   // SWAP
            4'b1_111 : y = {1'b0, a[7:1]};     // SRL
        endcase
    end

    // CPのみy=aであるためy_subを利用
    assign fout[Z] = (control == 4'b0_111)
                ? (y_sub[7:0] == 8'h0) : (y == 8'h0);

    // SUB/SBC/CPでfout[N]=1
    assign fout[N] =
                (control == 4'b0_010)
                    | (control == 4'b0_011)
                    | (control == 4'b0_111);

    always_comb begin
        case (control)
            4'b0_000 : fout[H] = h_add[4];      // ADD
            4'b0_001 : fout[H] = h_adc[4];      // ADC
            4'b0_010 : fout[H] = ~h_sub[4];     // SUB
            4'b0_011 : fout[H] = ~h_sbc[4];     // SBC
            4'b0_111 : fout[H] = ~h_sub[4];     // CP
            4'b0_100 : fout[H] = 1'b1;          // AND
            default: fout[H] = 1'b0;
        endcase
    end

    always_comb begin
        case (control)
            4'b0_000 : fout[C] = y_add[8];      // ADD
            4'b0_001 : fout[C] = y_adc[8];      // ADC 
            4'b0_010 : fout[C] = ~y_sub[8];     // SUB
            4'b0_011 : fout[C] = ~y_sbc[8];     // SBC
            4'b0_111 : fout[C] = ~y_sub[8];     // CP
            4'b1_000 : fout[C] = a[7];          // RLC
            4'b1_001 : fout[C] = a[0];          // RRC
            4'b1_010 : fout[C] = a[7];          // RL
            4'b1_011 : fout[C] = a[0];          // RR
            4'b1_100 : fout[C] = a[7];          // SLA
            4'b1_101 : fout[C] = a[0];          // SRA
            4'b1_111 : fout[C] = a[0];          // SRL
            default: fout[C] = 1'b0;
        endcase
    end

endmodule
