`ifndef M_CYCLE_PKG_SV
`define M_CYCLE_PKG_SV

package m_cycle_pkg;

    typedef enum logic [4:0] {
        M_REG_COPY, M_REG_WRITE, M_REG16_WRITE,
        M_ROM_READ, M_MEM_READ, M_MEM_WRITE,
        M_STORE_SPL, M_STORE_SPH,
        M_PUSH1, M_PUSH2, M_PUSH_PCH, M_PUSH_PCL,
        M_POP1, M_POP2,
        M_ALU_CALC, M_SHIFT,
        M_ADDER16_CALC, M_SP_INC,
        M_BITALU_CALC, M_DAA,
        M_PC_WRITE, M_RST_ADDR_COPY,
        M_NOP, M_HALT, M_STOP,
        M_IME_CHANGE
    } m_cycle_type;
    
endpackage

`endif