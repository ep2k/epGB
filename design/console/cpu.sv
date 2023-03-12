module cpu (
    input  logic clk,
    input  logic cpu_en,
    input  logic reset,

    output logic [15:0] mem_addr,
    input  logic [7:0] mem_rdata,
    output logic [7:0] mem_wdata,
    output logic write,

    input  logic [4:0] ints, // 割り込み要求
    output logic int_ack,

    output logic [1:0] t,
    output logic stop
);

    // --- 配線 ---------------------------------

    logic [7:0] reg_wdata, reg_rdata;
    logic [15:0] reg16_wdata, reg16_rdata;
    logic [7:0] a, op, op_prefix;
    logic [3:0] f, next_f;
    logic [15:0] sp, hl, pc, pc_wdata;

    logic [7:0] alu_a, alu_b, alu_y, bitalu_y, daa;
    logic [15:0] adder16_a, adder16_b, adder16_y;
    logic [3:0] alu_f, adder16_f, daa_f;

    logic [15:0] rst_addr, int_vector;

    // --- 制御信号 ------------------------------

    // registers
    logic [3:0] reg_src, reg_dst;
    logic [1:0] reg_wdata_src;
    logic reg_write;
    logic [2:0] next_f_src;
    logic [3:0] f_write;

    logic [2:0] reg16_src, reg16_dst;
    logic reg16_wdata_src;
    logic reg16_write;
    logic sp_inc, sp_dec;

    // pc_register
    logic [1:0] pc_wdata_src;
    logic pc_write, pch_write, pcl_write;
    logic pc_inc;

    // op_register
    logic op_write;

    // memory
    logic addr_src;
    logic [2:0] mem_wdata_src;

    // alu
    logic alu_a_src;
    logic [1:0] alu_b_src;
    logic [3:0] alu_control;

    // adder16
    logic [1:0] adder16_a_src;
    logic [2:0] adder16_b_src;
    logic adder16_control;

    // bitalu
    logic [2:0] bitalu_control;


    logic [4:0] int_reg;

    // ---------------------------------------------

    controller controller(
        .clk,
        .cpu_en,
        .reset,

        .op,
        .op_prefix,
        .f,

        .ints,
        .int_ack,
        
        .stop,

        .reg_src,
        .reg_dst,
        .reg_wdata_src,
        .reg_write,
        .op_write,
        .next_f_src,
        .f_write,

        .reg16_src,
        .reg16_dst,
        .reg16_wdata_src,
        .reg16_write,
        .sp_inc,
        .sp_dec,

        .pc_wdata_src,
        .pc_write,
        .pch_write,
        .pcl_write,
        .pc_inc,

        .addr_src,
        .mem_wdata_src,
        .mem_write(write),

        .alu_a_src,
        .alu_b_src,
        .alu_control,
        .adder16_a_src,
        .adder16_b_src,
        .adder16_control,
        .bitalu_control,

        .int_reg,
        .t
    );

    registers registers(
        .clk,
        .cpu_en,
        .reset,

        .reg_src,
        .reg_dst,
        .reg_wdata,
        .reg16_src,
        .reg16_dst,
        .reg16_wdata,
        .reg_write,
        .reg16_write,
        .next_f,
        .f_write,
        .sp_inc,
        .sp_dec,

        .reg_rdata,
        .reg16_rdata,

        .a,
        .f,
        .sp,
        .hl,
        .data1(op_prefix)
    );

    pc_register pc_register(
        .clk,
        .cpu_en,
        .reset,

        .pc,

        .wdata(pc_wdata),
        .wdata8(mem_rdata),
        .write(pc_write),
        .write_h(pch_write),
        .write_l(pcl_write),
        .pc_inc
    );

    op_register op_register(
        .clk,
        .cpu_en,
        .reset,

        .op,

        .wdata(mem_rdata),
        .write(op_write)
    );

    alu alu(
        .a(alu_a),
        .b(alu_b),
        .fin(f),
        .y(alu_y),
        .fout(alu_f),
        .control(alu_control)
    );

    adder16 adder16(
        .a(adder16_a),
        .b(adder16_b),
        .y(adder16_y),
        .f(adder16_f),
        .control(adder16_control)
    );

    bitalu bitalu(
        .a(reg_rdata),
        .b(op_prefix[5:3]),
        .y(bitalu_y),
        .control(bitalu_control)
    );

    daa_calc daa_calc(
        .a,
        .fin(f),
        .daa,
        .fout(daa_f)
    );

    // --- 選択 ---------------------------

    // reg_wdata
    always_comb begin
        case (reg_wdata_src)
            2'b00: reg_wdata = alu_y;
            2'b01: reg_wdata = bitalu_y;
            2'b10: reg_wdata = daa;
            2'b11: reg_wdata = mem_rdata;
            default: reg_wdata = 8'hx;
        endcase
    end

    // next_f
    always_comb begin
        case (next_f_src)
            3'b000: next_f = alu_f;
            3'b001: next_f = {1'b0, alu_f[2:0]};
            3'b010: next_f = adder16_f;
            3'b011: next_f = bitalu_y[7:4];
            3'b100: next_f = daa_f;
            3'b101: next_f = 4'b0110;
            default: next_f = 4'hx;
        endcase
    end

    // reg16_wdata
    assign reg16_wdata = reg16_wdata_src ? rst_addr : adder16_y;

    // pc_wdata
    always_comb begin
        case (pc_wdata_src)
            2'b00: pc_wdata = reg16_rdata;
            2'b01: pc_wdata = adder16_y;
            2'b11: pc_wdata = int_vector;
            default: pc_wdata = 16'hx;
        endcase
    end

    // mem_addr
    assign mem_addr = addr_src ? adder16_y : pc;

    // mem_wdata
    always_comb begin
        case (mem_wdata_src)
            3'b000: mem_wdata = reg_rdata;
            3'b001: mem_wdata = alu_y;
            3'b010: mem_wdata = bitalu_y;
            3'b100: mem_wdata = reg16_rdata[15:8];
            3'b101: mem_wdata = reg16_rdata[7:0];
            3'b110: mem_wdata = pc[15:8];
            3'b111: mem_wdata = pc[7:0];
            default: mem_wdata = 8'hx;
        endcase
    end

    // alu_a
    assign alu_a = alu_a_src ? a : reg_rdata;

    // alu_b
    always_comb begin
        unique case (alu_b_src)
            2'b00: alu_b = 8'h0;
            2'b01: alu_b = 8'h1;
            2'b10: alu_b = reg_rdata;
            2'b11: alu_b = 8'hff; 
        endcase
    end

    // adder16_a
    always_comb begin
        case (adder16_a_src)
            2'b00: adder16_a = reg16_rdata;
            2'b01: adder16_a = sp;
            2'b10: adder16_a = pc;
            default: adder16_a = 16'hx;
        endcase
    end

    // adder16_b
    always_comb begin
        case (adder16_b_src)
            3'b000: adder16_b = 16'h0;
            3'b001: adder16_b = {{8{reg_rdata[7]}}, reg_rdata}; // 符号拡張
            3'b010: adder16_b = hl;
            3'b100: adder16_b = 16'h1;
            3'b101: adder16_b = 16'h2;
            3'b110: adder16_b = 16'hffff; // -1
            3'b111: adder16_b = 16'hfffe; // -2
            default: adder16_b = 16'hx;
        endcase
    end

    // rst_addr
    assign rst_addr = {10'h00, op[5:3], 3'b000};

    // int_vector
    always_comb begin
        priority casez(int_reg)
            5'b????1: int_vector = 16'h40;
            5'b???10: int_vector = 16'h48;
            5'b??100: int_vector = 16'h50;
            5'b?1000: int_vector = 16'h58;
            5'b10000: int_vector = 16'h60;
            default: int_vector = 16'hx;
        endcase
    end
    
endmodule
