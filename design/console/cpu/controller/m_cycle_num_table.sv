module m_cycle_num_table (
    input  logic [7:0] op,
    input  logic [7:0] op_prefix,
    output logic [2:0] m_cycle_num,
    output logic [2:0] m_cycle_num_prefix
);

    always_comb begin
        priority casez (op)
            8'b11111010: m_cycle_num = 3'h3;
            8'b11111001: m_cycle_num = 3'h1;
            8'b11111000: m_cycle_num = 3'h2;
            8'b11110010: m_cycle_num = 3'h1;
            8'b11110000: m_cycle_num = 3'h2;
            8'b1111?011: m_cycle_num = 3'h0;
            8'b11101010: m_cycle_num = 3'h3;
            8'b11101001: m_cycle_num = 3'h0;
            8'b11101000: m_cycle_num = 3'h3;
            8'b11100010: m_cycle_num = 3'h1;
            8'b11100000: m_cycle_num = 3'h2;
            8'b11011001: m_cycle_num = 3'h3;
            8'b11001101: m_cycle_num = 3'h5;
            8'b11001011: m_cycle_num = 3'h7;
            8'b11001001: m_cycle_num = 3'h3;
            8'b11000011: m_cycle_num = 3'h3;
            8'b110??100: m_cycle_num = 3'h5;
            8'b110??010: m_cycle_num = 3'h3;
            8'b110??000: m_cycle_num = 3'h4;
            8'b11??0101: m_cycle_num = 3'h3;
            8'b11??0001: m_cycle_num = 3'h2;
            8'b11???111: m_cycle_num = 3'h3;
            8'b11???110: m_cycle_num = 3'h1;
            8'b10???110: m_cycle_num = 3'h1;
            8'b10??????: m_cycle_num = 3'h0;
            8'b01110110: m_cycle_num = 3'h0;
            8'b01110???: m_cycle_num = 3'h1;
            8'b01???110: m_cycle_num = 3'h1;
            8'b01??????: m_cycle_num = 3'h0;
            8'b00111010: m_cycle_num = 3'h1;
            8'b00110110: m_cycle_num = 3'h2;
            8'b0011010?: m_cycle_num = 3'h2;
            8'b00110010: m_cycle_num = 3'h1;
            8'b0011?111: m_cycle_num = 3'h0;
            8'b00101111: m_cycle_num = 3'h0;
            8'b00101010: m_cycle_num = 3'h1;
            8'b00100111: m_cycle_num = 3'h0;
            8'b00100010: m_cycle_num = 3'h1;
            8'b001??000: m_cycle_num = 3'h2;
            8'b00011010: m_cycle_num = 3'h1;
            8'b00011000: m_cycle_num = 3'h2;
            8'b00010010: m_cycle_num = 3'h1;
            8'b00010000: m_cycle_num = 3'h0;
            8'b00001010: m_cycle_num = 3'h1;
            8'b00001000: m_cycle_num = 3'h4;
            8'b00000010: m_cycle_num = 3'h1;
            8'b00000000: m_cycle_num = 3'h0;
            8'b000??111: m_cycle_num = 3'h0;
            8'b00??1001: m_cycle_num = 3'h1;
            8'b00??0001: m_cycle_num = 3'h2;
            8'b00???110: m_cycle_num = 3'h1;
            8'b00???10?: m_cycle_num = 3'h0;
            8'b00???011: m_cycle_num = 3'h1;
            default: m_cycle_num = 3'hx;
        endcase
    end

    always_comb begin
        priority casez (op_prefix)
            8'b00???110: m_cycle_num_prefix = 3'h2;
            8'b00??????: m_cycle_num_prefix = 3'h0;
            8'b1????110: m_cycle_num_prefix = 3'h2;
            8'b1???????: m_cycle_num_prefix = 3'h0;
            8'b01???110: m_cycle_num_prefix = 3'h1;
            8'b01??????: m_cycle_num_prefix = 3'h0;
            default: m_cycle_num_prefix = 3'hx;
        endcase
    end
    
endmodule
