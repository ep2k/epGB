module decoder
    import m_cycle_pkg::*;
(
    input  logic [7:0] op,
    input  logic [7:0] op_prefix,
    input  m_cycle_type m_cycle,
    input  logic interrupt,

    output logic [3:0] reg_src,
    output logic [3:0] reg_dst,
    output logic [1:0] reg_wdata_src,
    output logic reg_write,
    output logic [2:0] reg16_src,
    output logic [2:0] reg16_dst,
    output logic reg16_wdata_src,
    output logic reg16_write,
    output logic sp_inc,
    output logic sp_dec,
    output logic [1:0] pc_wdata_src,
    output logic pc_write,
    output logic pch_write,
    output logic pcl_write,
    output logic pc_inc,
    output logic addr_src,
    output logic [2:0] mem_wdata_src,
    output logic mem_write,
    output logic alu_a_src,
    output logic [1:0] alu_b_src,
    output logic [3:0] alu_control,
    output logic [1:0] adder16_a_src,
    output logic [2:0] adder16_b_src,
    output logic adder16_control,
    output logic [2:0] bitalu_control
);

    

    always_comb begin

        // 初期値
        reg_src = 4'h0;
        reg_dst = 4'h0;
        reg_wdata_src = 2'h0;
        reg_write = 1'b0;
        reg16_src = 3'h0;
        reg16_dst = 3'h0;
        reg16_wdata_src = 1'b0;
        reg16_write = 1'b0;
        sp_inc = 1'b0;
        sp_dec = 1'b0;
        pc_wdata_src = 2'h0;
        pc_write = 1'b0;
        pch_write = 1'b0;
        pcl_write = 1'b0;
        pc_inc = 1'b0;
        addr_src = 1'b0;
        mem_wdata_src = 3'h0;
        mem_write = 1'b0;
        alu_a_src = 1'b0;
        alu_b_src = 2'h0;
        alu_control = 4'h0;
        adder16_a_src = 2'h0;
        adder16_b_src = 3'h0;
        adder16_control = 1'b0;
        bitalu_control = 3'h0;
        
        if (m_cycle == M_REG_COPY) begin
            
            reg_dst = {1'b0, op[5:3]};
            reg_src = {1'b0, op[2:0]};
            reg_write = 1'b1;

        end else if (m_cycle == M_REG_WRITE) begin
            
            alu_a_src = 1'b0; // reg_rdata
            reg_wdata_src = 2'b00; // alu_y
            reg_write = 1'b1;

            priority casez (op)
                8'b00???110: {reg_dst, reg_src, alu_b_src, alu_control} = {1'b0, op[5:3], 4'b1100, 2'b00, 4'b0000};
                8'b01???110: {reg_dst, reg_src, alu_b_src, alu_control} = {1'b0, op[5:3], 4'b1100, 2'b00, 4'b0000};
                8'b00001010: {reg_dst, reg_src, alu_b_src, alu_control} = {4'b0111, 4'b1100, 2'b00, 4'b0000};
                8'b00011010: {reg_dst, reg_src, alu_b_src, alu_control} = {4'b0111, 4'b1100, 2'b00, 4'b0000};
                8'b111100?0: {reg_dst, reg_src, alu_b_src, alu_control} = {4'b0111, 4'b1100, 2'b00, 4'b0000};
                8'b00???100: {reg_dst, reg_src, alu_b_src, alu_control} = {1'b0, op[5:3], 1'b0, op[5:3], 2'b01, 4'b0000};
                8'b00???101: {reg_dst, reg_src, alu_b_src, alu_control} = {1'b0, op[5:3], 1'b0, op[5:3], 2'b01, 4'b0010};
                8'b00101111: {reg_dst, reg_src, alu_b_src, alu_control} = {4'b0111, 4'b0111, 2'b11, 4'b0101};
                default: {reg_dst, reg_src, alu_b_src, alu_control} = 14'hx;
            endcase

        end else if (m_cycle == M_REG16_WRITE) begin

            reg16_dst = op[7]
                ? (op[3] ? 3'b111 : {1'b0, op[5:4]}) // SP/rr
                : {op[5:4] == 2'b11, op[5:4]}; // SP/rr
            reg16_src = op[3] ? 3'b010 : 3'b100; // HL / {DATA1, DATA2}
            reg16_write = 1'b1;
            sp_inc = ({op[7], op[3]} == 3'b10); // POP

        end else if (m_cycle == M_ROM_READ) begin
            
            reg_dst = 4'b1100; // DATA
            reg_wdata_src = 2'b11; // mem_rdata
            reg_write = 1'b1;
            addr_src = 1'b0; // PC
            pc_inc = 1'b1;

        end else if (m_cycle == M_MEM_READ) begin
            
            reg_wdata_src = 2'b11; // mem_rdata
            addr_src = 1'b1; // adder16_y
            reg_write = 1'b1;

            priority casez (op)
                8'b11111010: {reg_dst, reg16_src} = {4'b0111, 3'b100};
                8'b00101010: {reg_dst, reg16_src} = {4'b0111, 3'b010};
                8'b00111010: {reg_dst, reg16_src} = {4'b0111, 3'b010};
                8'b01???110: {reg_dst, reg16_src} = {4'b1100, 3'b010};
                8'b00001010: {reg_dst, reg16_src} = {4'b1100, 3'b000};
                8'b00011010: {reg_dst, reg16_src} = {4'b1100, 3'b001};
                8'b11110000: {reg_dst, reg16_src} = {4'b1100, 3'b110};
                8'b11110010: {reg_dst, reg16_src} = {4'b1100, 3'b101};
                8'b10???110: {reg_dst, reg16_src} = {4'b1100, 3'b010};
                8'b00110100: {reg_dst, reg16_src} = {4'b1100, 3'b010};
                8'b00110101: {reg_dst, reg16_src} = {4'b1100, 3'b010};
                8'b11001011: {reg_dst, reg16_src} = {4'b1101, 3'b010};
                default: {reg_dst, reg16_src} = 7'hx;
            endcase

        end else if (m_cycle == M_MEM_WRITE) begin
            
            alu_a_src = 1'b0; // reg_rdata
            alu_b_src = 2'b01; // 1
            alu_control = {2'b00, op[0], 1'b0}; // SUB/ADD
            addr_src = 1'b1; // adder16_y
            adder16_a_src = 2'b00; // reg16_rdata
            mem_write = 1'b1;

            priority casez (op)
                8'b01110???: {reg_src, mem_wdata_src, reg16_src} = {1'b0, op[2:0], 3'b000, 3'b010};
                8'b00110110: {reg_src, mem_wdata_src, reg16_src} = {4'b1100, 3'b000, 3'b010};
                8'b00000010: {reg_src, mem_wdata_src, reg16_src} = {4'b0111, 3'b000, 3'b000};
                8'b00010010: {reg_src, mem_wdata_src, reg16_src} = {4'b0111, 3'b000, 3'b001};
                8'b11101010: {reg_src, mem_wdata_src, reg16_src} = {4'b0111, 3'b000, 3'b100};
                8'b11100000: {reg_src, mem_wdata_src, reg16_src} = {4'b0111, 3'b000, 3'b110};
                8'b11100010: {reg_src, mem_wdata_src, reg16_src} = {4'b0111, 3'b000, 3'b101};
                8'b001?0010: {reg_src, mem_wdata_src, reg16_src} = {4'b0111, 3'b000, 3'b010};
                8'b00110100: {reg_src, mem_wdata_src, reg16_src} = {4'b1100, 3'b001, 3'b010};
                8'b00110101: {reg_src, mem_wdata_src, reg16_src} = {4'b1100, 3'b001, 3'b010};
                default: {reg_src, mem_wdata_src, reg16_src} = 10'hx;
            endcase

        end else if ((m_cycle == M_STORE_SPL) | (m_cycle == M_STORE_SPH)) begin
            
            reg_src = (m_cycle == M_STORE_SPL) ? 4'b1001 : 4'b1000; // SPL/SPH
            reg16_src = 3'b100; // {DATA1, DATA2}
            adder16_a_src = 2'b00; // reg16_rdata
            adder16_b_src = (m_cycle == M_STORE_SPL) ? 3'b000 : 3'b100; // 0/1
            addr_src = 1'b1; // adder16_y
            mem_write = 1'b1;

        end else if ((m_cycle == M_PUSH1) | (m_cycle == M_PUSH2)) begin
            
            reg16_src = {1'b0, op[5:4]}; // rr
            addr_src = 1'b1; // adder16_y
            adder16_a_src = 2'b01;
            adder16_b_src = (m_cycle == M_PUSH1) ? 3'b100 : 3'b000; // 1/0
            mem_wdata_src = (m_cycle == M_PUSH1) ? 3'b100 : 3'b101; // reg16_rdataH/L
            mem_write = 1'b1;

        end else if ((m_cycle == M_PUSH_PCH) | (m_cycle == M_PUSH_PCL)) begin
            
            adder16_a_src = 2'b01; // SP
            adder16_b_src = (m_cycle == M_PUSH_PCH) ? 3'b110 : 3'b111; // -1/-2
            addr_src = 1'b1; // adder16_y
            mem_wdata_src = (m_cycle == M_PUSH_PCH) ? 3'b110 : 3'b111; // PCH/PCL
            mem_write = 1'b1;

        end else if ((m_cycle == M_POP1) | (m_cycle == M_POP2)) begin
            
            addr_src = 1'b1; // adder16_y
            adder16_a_src = 2'b01;
            adder16_b_src = (m_cycle == M_POP1) ? 3'b000 : 3'b100; // 0/1
			reg_wdata_src = 2'b11; // mem_rdata
            reg_dst = 4'b1100; // DATA
            reg_write = ({op[7:6], op[3:0]} == 6'b11_0001); // POPのとき
            pcl_write = (m_cycle == M_POP1) & (~reg_write);
            pch_write = (m_cycle == M_POP2) & (~reg_write);

        end else if (m_cycle == M_ALU_CALC) begin
            
            reg_src = (op[2:0] == 3'b110) ? 4'b1100 : {1'b0, op[2:0]}; // DATA/r
            alu_a_src = 1'b1; // A
            alu_b_src = 2'b10; // reg_rdata
            alu_control = {1'b0, op[5:3]};
            reg_dst = 4'b0111; // A
            reg_wdata_src = 2'b00; // alu_y
            reg_write = 1'b1;

        end else if (m_cycle == M_SHIFT) begin
            
            alu_a_src = 1'b0; // reg_rdata
            alu_control = (op == 8'hCB) ? {1'b1, op_prefix[5:3]} : {1'b1, op[5:3]};
            reg_wdata_src = 2'b00; // alu_y
            reg16_src = 3'b010; // HL
            adder16_a_src = 2'b00; // reg16_rdata
            adder16_b_src = 3'b000; // 0
            addr_src = 1'b1; // adder16_y
            mem_wdata_src = 3'b001; // alu_y
            mem_write = ((op == 8'hCB) & (op_prefix[2:0] == 3'b110));
            reg_write = ~mem_write;
            
            reg_src = (op != 8'hCB) ? 4'b0111 // A
                : (
                    (op_prefix[2:0] == 3'b110) ? 4'b1101 : {1'b0, op_prefix[2:0]} // DATA2/r
                );

            reg_dst = reg_src;
        
        end else if (m_cycle == M_ADDER16_CALC) begin
            
            adder16_a_src = 2'b00; // reg16_rdata
            reg_src = 4'b1100; // DATA
            reg16_write = 1'b1;
            adder16_control = op[0]; // Flag mode

            priority casez (op)
                8'b0010?010: {reg16_src, reg16_dst, adder16_b_src} = {3'b010, 3'b010, 3'b100};
                8'b0011?010: {reg16_src, reg16_dst, adder16_b_src} = {3'b010, 3'b010, 3'b110};
                8'b00111001: {reg16_src, reg16_dst, adder16_b_src} = {3'b111, 3'b010, 3'b010};
                8'b00??1001: {reg16_src, reg16_dst, adder16_b_src} = {1'b0, op[5:4], 3'b010, 3'b010};
                8'b00110011: {reg16_src, reg16_dst, adder16_b_src} = {3'b111, 3'b111, 3'b100};
                8'b00??0011: {reg16_src, reg16_dst, adder16_b_src} = {1'b0, op[5:4], 1'b0, op[5:4], 3'b100};
                8'b00111011: {reg16_src, reg16_dst, adder16_b_src} = {3'b111, 3'b111, 3'b110};
                8'b00??1011: {reg16_src, reg16_dst, adder16_b_src} = {1'b0, op[5:4], 1'b0, op[5:4], 3'b110};
                8'b11101000: {reg16_src, reg16_dst, adder16_b_src} = {3'b111, 3'b111, 3'b001};
                8'b11111000: {reg16_src, reg16_dst, adder16_b_src} = {3'b111, 3'b010, 3'b001};
                default: {reg16_src, reg16_dst, adder16_b_src} = 9'hx; 
            endcase

        end else if (m_cycle == M_BITALU_CALC) begin
            
            addr_src = 1'b1; // adder16_y
            reg16_src = 3'b010; // HL
            reg_wdata_src = 2'b01; // bitalu_y
            mem_wdata_src = 3'b010; // bitalu_y
            reg_dst = {1'b0, op_prefix[2:0]}; // r

            if (op == 8'hCB) begin

                mem_write = ({op_prefix[7], op_prefix[2:0]} == 4'b1_110);
                reg_write = op_prefix[7] & (~mem_write);
                
                priority casez (op_prefix)
                    8'b01???110: {bitalu_control, reg_src} = {3'b111, 4'b1101};
                    8'b01??????: {bitalu_control, reg_src} = {3'b111, 1'b0, op_prefix[2:0]};
                    8'b11???110: {bitalu_control, reg_src} = {3'b001, 4'b1101};
                    8'b11??????: {bitalu_control, reg_src} = {3'b001, 1'b0, op_prefix[2:0]};
                    8'b10???110: {bitalu_control, reg_src} = {3'b000, 4'b1101};
                    8'b10??????: {bitalu_control, reg_src} = {3'b000, 1'b0, op_prefix[2:0]};
                    default: {bitalu_control, reg_src} = 7'hx;
                endcase

            end else begin
                
                priority casez (op)
                    8'b00111111: {bitalu_control, reg_src} = {3'b101, 4'b1111};
                    8'b00110111: {bitalu_control, reg_src} = {3'b100, 4'b1111};
                    default: {bitalu_control, reg_src} = 7'hx;
                endcase

            end

        end else if (m_cycle == M_PC_WRITE) begin

            reg16_dst = 3'b111; // SP
            reg_src = 4'b1100; // DATA
            pc_write = 1'b1;

            if (interrupt) begin
                {pc_wdata_src, reg16_src, adder16_a_src, adder16_b_src, reg16_write} = {2'b11, 3'bxxx, 2'b01, 3'b111, 1'b1};
            end else begin
                priority casez (op)
                    8'b11000011: {pc_wdata_src, reg16_src, adder16_a_src, adder16_b_src, reg16_write} = {2'b00, 3'b100, 2'bxx, 3'bxxx, 1'b0};
                    8'b11101001: {pc_wdata_src, reg16_src, adder16_a_src, adder16_b_src, reg16_write} = {2'b00, 3'b010, 2'bxx, 3'bxxx, 1'b0};
                    8'b110??010: {pc_wdata_src, reg16_src, adder16_a_src, adder16_b_src, reg16_write} = {2'b00, 3'b100, 2'bxx, 3'bxxx, 1'b0};
                    8'b00011000: {pc_wdata_src, reg16_src, adder16_a_src, adder16_b_src, reg16_write} = {2'b01, 3'bxxx, 2'b10, 3'b001, 1'b0};
                    8'b001??000: {pc_wdata_src, reg16_src, adder16_a_src, adder16_b_src, reg16_write} = {2'b01, 3'bxxx, 2'b10, 3'b001, 1'b0};
                    8'b11001101: {pc_wdata_src, reg16_src, adder16_a_src, adder16_b_src, reg16_write} = {2'b00, 3'b100, 2'b01, 3'b111, 1'b1};
                    8'b110??100: {pc_wdata_src, reg16_src, adder16_a_src, adder16_b_src, reg16_write} = {2'b00, 3'b100, 2'b01, 3'b111, 1'b1};
                    8'b11???111: {pc_wdata_src, reg16_src, adder16_a_src, adder16_b_src, reg16_write} = {2'b00, 3'b100, 2'b01, 3'b111, 1'b1};
                    default: {pc_wdata_src, reg16_src, adder16_a_src, adder16_b_src, reg16_write} = {10'hx, 1'b0};
                endcase
            end
            
        end else if (m_cycle == M_RST_ADDR_COPY) begin

            reg16_dst = 3'b100; // {DATA1, DATA2}
            reg16_wdata_src = 1'b1; // rst_addr
            reg16_write = 1'b1;
            
        end else if (m_cycle == M_SP_INC) begin

            adder16_a_src = 2'b01; // SP
            adder16_b_src = op[2] ? 3'b111 : 3'b101; // -2/2
            reg16_dst = 3'b111; // SP
            reg16_write = 1'b1;
            
        end else if (m_cycle == M_DAA) begin
            
            reg_dst = 4'b0111; // A
            reg_wdata_src = 2'b10; // daa
            reg_write = 1'b1;

        end else begin
            ;
        end

    end
    
endmodule
