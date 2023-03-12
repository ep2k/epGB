module m_cycle_table
    import m_cycle_pkg::*;
(
    input  logic [7:0] op,
    input  logic [7:0] op_prefix,
    input  logic [2:0] m_left,
    output m_cycle_type next_m_cycle,
    output m_cycle_type next_m_cycle_prefix,
    output m_cycle_type next_m_cycle_int
);

    always_comb begin
        priority casez ({op, m_left})
            11'b11111010_011: next_m_cycle = M_ROM_READ;
            11'b11111010_010: next_m_cycle = M_ROM_READ;
            11'b11111010_001: next_m_cycle = M_MEM_READ;
            11'b11111010_000: next_m_cycle = M_NOP;
            11'b11111001_001: next_m_cycle = M_REG16_WRITE;
            11'b11111001_000: next_m_cycle = M_NOP;
            11'b11111000_010: next_m_cycle = M_ROM_READ;
            11'b11111000_001: next_m_cycle = M_ADDER16_CALC;
            11'b11111000_000: next_m_cycle = M_NOP;
            11'b11110010_001: next_m_cycle = M_MEM_READ;
            11'b11110010_000: next_m_cycle = M_REG_WRITE;
            11'b11110000_010: next_m_cycle = M_ROM_READ;
            11'b11110000_001: next_m_cycle = M_MEM_READ;
            11'b11110000_000: next_m_cycle = M_REG_WRITE;
            11'b1111?011_000: next_m_cycle = M_IME_CHANGE;
            11'b11101010_011: next_m_cycle = M_ROM_READ;
            11'b11101010_010: next_m_cycle = M_ROM_READ;
            11'b11101010_001: next_m_cycle = M_MEM_WRITE;
            11'b11101010_000: next_m_cycle = M_NOP;
            11'b11101001_000: next_m_cycle = M_PC_WRITE;
            11'b11101000_011: next_m_cycle = M_ROM_READ;
            11'b11101000_010: next_m_cycle = M_ADDER16_CALC;
            11'b11101000_001: next_m_cycle = M_NOP;
            11'b11101000_000: next_m_cycle = M_NOP;
            11'b11100010_001: next_m_cycle = M_MEM_WRITE;
            11'b11100010_000: next_m_cycle = M_NOP;
            11'b11100000_010: next_m_cycle = M_ROM_READ;
            11'b11100000_001: next_m_cycle = M_MEM_WRITE;
            11'b11100000_000: next_m_cycle = M_NOP;
            11'b11011001_011: next_m_cycle = M_POP1;
            11'b11011001_010: next_m_cycle = M_POP2;
            11'b11011001_001: next_m_cycle = M_SP_INC;
            11'b11011001_000: next_m_cycle = M_IME_CHANGE;
            11'b11001101_101: next_m_cycle = M_ROM_READ;
            11'b11001101_100: next_m_cycle = M_ROM_READ;
            11'b11001101_011: next_m_cycle = M_NOP;
            11'b11001101_010: next_m_cycle = M_PUSH_PCH;
            11'b11001101_001: next_m_cycle = M_PUSH_PCL;
            11'b11001101_000: next_m_cycle = M_PC_WRITE;
            11'b11001011_111: next_m_cycle = M_ROM_READ;
            11'b11001001_011: next_m_cycle = M_POP1;
            11'b11001001_010: next_m_cycle = M_POP2;
            11'b11001001_001: next_m_cycle = M_SP_INC;
            11'b11001001_000: next_m_cycle = M_NOP;
            11'b11000011_011: next_m_cycle = M_ROM_READ;
            11'b11000011_010: next_m_cycle = M_ROM_READ;
            11'b11000011_001: next_m_cycle = M_NOP;
            11'b11000011_000: next_m_cycle = M_PC_WRITE;
            11'b110??100_101: next_m_cycle = M_ROM_READ;
            11'b110??100_100: next_m_cycle = M_ROM_READ;
            11'b110??100_011: next_m_cycle = M_NOP;
            11'b110??100_010: next_m_cycle = M_PUSH_PCH;
            11'b110??100_001: next_m_cycle = M_PUSH_PCL;
            11'b110??100_000: next_m_cycle = M_PC_WRITE;
            11'b110??010_011: next_m_cycle = M_ROM_READ;
            11'b110??010_010: next_m_cycle = M_ROM_READ;
            11'b110??010_001: next_m_cycle = M_NOP;
            11'b110??010_000: next_m_cycle = M_PC_WRITE;
            11'b110??000_100: next_m_cycle = M_NOP;
            11'b110??000_011: next_m_cycle = M_NOP;
            11'b110??000_010: next_m_cycle = M_POP1;
            11'b110??000_001: next_m_cycle = M_POP2;
            11'b110??000_000: next_m_cycle = M_SP_INC;
            11'b11??0101_011: next_m_cycle = M_SP_INC;
            11'b11??0101_010: next_m_cycle = M_PUSH1;
            11'b11??0101_001: next_m_cycle = M_PUSH2;
            11'b11??0101_000: next_m_cycle = M_NOP;
            11'b11??0001_010: next_m_cycle = M_POP1;
            11'b11??0001_001: next_m_cycle = M_POP2;
            11'b11??0001_000: next_m_cycle = M_REG16_WRITE;
            11'b11???111_011: next_m_cycle = M_RST_ADDR_COPY;
            11'b11???111_010: next_m_cycle = M_PUSH_PCH;
            11'b11???111_001: next_m_cycle = M_PUSH_PCL;
            11'b11???111_000: next_m_cycle = M_PC_WRITE;
            11'b11???110_001: next_m_cycle = M_ROM_READ;
            11'b11???110_000: next_m_cycle = M_ALU_CALC;
            11'b10???110_001: next_m_cycle = M_MEM_READ;
            11'b10???110_000: next_m_cycle = M_ALU_CALC;
            11'b10??????_000: next_m_cycle = M_ALU_CALC;
            11'b01110110_000: next_m_cycle = M_HALT;
            11'b01110???_001: next_m_cycle = M_MEM_WRITE;
            11'b01110???_000: next_m_cycle = M_NOP;
            11'b01???110_001: next_m_cycle = M_MEM_READ;
            11'b01???110_000: next_m_cycle = M_REG_WRITE;
            11'b01??????_000: next_m_cycle = M_REG_COPY;
            11'b00111010_001: next_m_cycle = M_MEM_READ;
            11'b00111010_000: next_m_cycle = M_ADDER16_CALC;
            11'b00110110_010: next_m_cycle = M_ROM_READ;
            11'b00110110_001: next_m_cycle = M_MEM_WRITE;
            11'b00110110_000: next_m_cycle = M_NOP;
            11'b0011010?_010: next_m_cycle = M_MEM_READ;
            11'b0011010?_001: next_m_cycle = M_MEM_WRITE;
            11'b0011010?_000: next_m_cycle = M_NOP;
            11'b00110010_001: next_m_cycle = M_MEM_WRITE;
            11'b00110010_000: next_m_cycle = M_ADDER16_CALC;
            11'b0011?111_000: next_m_cycle = M_BITALU_CALC;
            11'b00101111_000: next_m_cycle = M_REG_WRITE;
            11'b00101010_001: next_m_cycle = M_MEM_READ;
            11'b00101010_000: next_m_cycle = M_ADDER16_CALC;
            11'b00100111_000: next_m_cycle = M_DAA;
            11'b00100010_001: next_m_cycle = M_MEM_WRITE;
            11'b00100010_000: next_m_cycle = M_ADDER16_CALC;
            11'b001??000_010: next_m_cycle = M_ROM_READ;
            11'b001??000_001: next_m_cycle = M_NOP;
            11'b001??000_000: next_m_cycle = M_PC_WRITE;
            11'b00011010_001: next_m_cycle = M_MEM_READ;
            11'b00011010_000: next_m_cycle = M_REG_WRITE;
            11'b00011000_010: next_m_cycle = M_ROM_READ;
            11'b00011000_001: next_m_cycle = M_PC_WRITE;
            11'b00011000_000: next_m_cycle = M_NOP;
            11'b00010010_001: next_m_cycle = M_MEM_WRITE;
            11'b00010010_000: next_m_cycle = M_NOP;
            11'b00010000_000: next_m_cycle = M_STOP;
            11'b00001010_001: next_m_cycle = M_MEM_READ;
            11'b00001010_000: next_m_cycle = M_REG_WRITE;
            11'b00001000_100: next_m_cycle = M_ROM_READ;
            11'b00001000_011: next_m_cycle = M_ROM_READ;
            11'b00001000_010: next_m_cycle = M_STORE_SPL;
            11'b00001000_001: next_m_cycle = M_STORE_SPH;
            11'b00001000_000: next_m_cycle = M_NOP;
            11'b00000010_001: next_m_cycle = M_MEM_WRITE;
            11'b00000010_000: next_m_cycle = M_NOP;
            11'b00000000_000: next_m_cycle = M_NOP;
            11'b000??111_000: next_m_cycle = M_SHIFT;
            11'b00??1001_001: next_m_cycle = M_ADDER16_CALC;
            11'b00??1001_000: next_m_cycle = M_NOP;
            11'b00??0001_010: next_m_cycle = M_ROM_READ;
            11'b00??0001_001: next_m_cycle = M_ROM_READ;
            11'b00??0001_000: next_m_cycle = M_REG16_WRITE;
            11'b00???110_001: next_m_cycle = M_ROM_READ;
            11'b00???110_000: next_m_cycle = M_REG_WRITE;
            11'b00???10?_000: next_m_cycle = M_REG_WRITE;
            11'b00???011_001: next_m_cycle = M_ADDER16_CALC;
            11'b00???011_000: next_m_cycle = M_NOP;
            default: next_m_cycle = M_NOP;
        endcase
    end

    always_comb begin
        priority casez ({op_prefix, m_left})
            11'b00???110_010: next_m_cycle_prefix = M_MEM_READ;
            11'b00???110_001: next_m_cycle_prefix = M_SHIFT;
            11'b00???110_000: next_m_cycle_prefix = M_NOP;
            11'b00??????_000: next_m_cycle_prefix = M_SHIFT;
            11'b01???110_001: next_m_cycle_prefix = M_MEM_READ;
            11'b01???110_000: next_m_cycle_prefix = M_BITALU_CALC;
            11'b1????110_010: next_m_cycle_prefix = M_MEM_READ;
            11'b1????110_001: next_m_cycle_prefix = M_BITALU_CALC;
            11'b1????110_000: next_m_cycle_prefix = M_NOP;
            11'b????????_000: next_m_cycle_prefix = M_BITALU_CALC;
            default: next_m_cycle_prefix = M_NOP;
        endcase
    end

    always_comb begin
        case (m_left)
            3'h4: next_m_cycle_int = M_IME_CHANGE;
            3'h3: next_m_cycle_int = M_PUSH_PCH;
            3'h2: next_m_cycle_int = M_PUSH_PCL;
            3'h1: next_m_cycle_int = M_PC_WRITE;
            3'h0: next_m_cycle_int = M_NOP;
            default: next_m_cycle_int = M_NOP;
        endcase
    end
    
endmodule
