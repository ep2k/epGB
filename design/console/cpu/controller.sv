module controller (
    input  logic clk,
    input  logic cpu_en,
    input  logic reset,

    input  logic [7:0] op,
    input  logic [7:0] op_prefix,
    input  logic [3:0] f,

    input  logic [4:0] ints,
    output logic int_ack,

    output logic stop,

    output logic [3:0] reg_src,
    output logic [3:0] reg_dst,
    output logic [1:0] reg_wdata_src,
    output logic reg_write,
    output logic op_write,
    output logic [2:0] next_f_src,
    output logic [3:0] f_write,

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
    output logic [2:0] bitalu_control,

    output logic [4:0] int_reg = 5'h0,
    output logic [1:0] t = 2'b00
);

    import m_cycle_pkg::*;

    // ------- 信号 --------------------------------

    logic exe; // 命令の実行(t=0)
    logic flg, branch_time, branch;

    m_cycle_type next_m_cycle, next_m_cycle_prefix, next_m_cycle_int;
    logic [2:0] m_cycle_num, m_cycle_num_prefix;

    // ------- サイクル制御信号 ---------------------
    // t = 0のときに適用される

    logic [3:0] reg_src_cycle, reg_dst_cycle;
    logic [1:0] reg_wdata_src_cycle;
    logic reg_write_cycle;

    logic [2:0] reg16_src_cycle, reg16_dst_cycle;
    logic reg16_wdata_src_cycle;
    logic reg16_write_cycle;
    logic sp_inc_cycle, sp_dec_cycle;

    logic [1:0] pc_wdata_src_cycle;
    logic pc_write_cycle, pch_write_cycle, pcl_write_cycle;
    logic pc_inc_cycle;

    logic addr_src_cycle;
    logic [2:0] mem_wdata_src_cycle;
    logic mem_write_cycle;

    logic alu_a_src_cycle;
    logic [1:0] alu_b_src_cycle;
    logic [3:0] alu_control_cycle;
    logic [1:0] adder16_a_src_cycle;
    logic [2:0] adder16_b_src_cycle;
    logic adder16_control_cycle;
    logic [2:0] bitalu_control_cycle;

    logic [2:0] next_f_src_cycle;
    logic [3:0] f_write_cycle;

    // ------- レジスタ ----------------------------

    m_cycle_type m_cycle = M_NOP;       // 現在のMサイクル
    logic [2:0] m_left = 3'h0;          // 現在の命令の残りMサイクル数
    logic ime = 1'b0;                    // 割り込み許可
    logic [10:0] stop_counter = 11'h0;  // STOP時にカウント(オーバーフローでSTOP終了)

    logic op_fetch = 1'b1;
    logic interrupt = 1'b0;             // 割り込み処理を実行中か否か

    // ----------------------------------------------

    assign exe = (t == 2'h0);
    assign stop = (m_cycle == M_STOP);

    assign branch = (~flg) & branch_time;
    assign branch_time = (~interrupt) & (
        ((m_left == 1) & ({op[7:5], op[2:0]} == 6'b110_010)) // JP f,nn
        | ((m_left == 1) & ({op[7:5], op[2:0]} == 6'b001_000)) // JR f,PC+n
        | ((m_left == 3) & ({op[7:5], op[1:0]} == 5'b110_00)) // CAlL f,nn / RET f
    );
    
    assign int_ack = cpu_en & op_fetch & (t == 2'b01) & ime & (ints != 5'h00);

    decoder decoder(
        .op,
        .op_prefix,
        .m_cycle,
        .interrupt,

        .reg_src(reg_src_cycle),
        .reg_dst(reg_dst_cycle),
        .reg_wdata_src(reg_wdata_src_cycle),
        .reg_write(reg_write_cycle),
        .reg16_src(reg16_src_cycle),
        .reg16_dst(reg16_dst_cycle),
        .reg16_wdata_src(reg16_wdata_src_cycle),
        .reg16_write(reg16_write_cycle),
        .sp_inc(sp_inc_cycle),
        .sp_dec(sp_dec_cycle),
        .pc_wdata_src(pc_wdata_src_cycle),
        .pc_write(pc_write_cycle),
        .pch_write(pch_write_cycle),
        .pcl_write(pcl_write_cycle),
        .pc_inc(pc_inc_cycle),
        .addr_src(addr_src_cycle),
        .mem_wdata_src(mem_wdata_src_cycle),
        .mem_write(mem_write_cycle),
        .alu_a_src(alu_a_src_cycle),
        .alu_b_src(alu_b_src_cycle),
        .alu_control(alu_control_cycle),
        .adder16_a_src(adder16_a_src_cycle),
        .adder16_b_src(adder16_b_src_cycle),
        .adder16_control(adder16_control_cycle),
        .bitalu_control(bitalu_control_cycle)
    );

    m_cycle_table m_cycle_table(
        .op,
        .op_prefix,
        .m_left,
        .next_m_cycle,
        .next_m_cycle_prefix,
        .next_m_cycle_int
    );

    m_cycle_num_table m_cycle_num_table(
        .op,
        .op_prefix,
        .m_cycle_num,
        .m_cycle_num_prefix
    );

    f_table f_table(
        .op,
        .op_prefix,
        .interrupt,
        .m_left,
        .next_f_src(next_f_src_cycle),
        .f_write(f_write_cycle)
    );

    flg_check flg_check(
        .f,
        .condition(op[4:3]),
        .flg
    );


    // t
    always_ff @(posedge clk) begin
        if (reset) begin
            t <= 2'b00;
        end else if (cpu_en) begin
            t <= t + 2'b01;
        end
    end

    // ime
    always_ff @(posedge clk) begin
        if (reset) begin
            ime <= 1'b0;
        end else if (cpu_en & exe & (m_cycle == M_IME_CHANGE)) begin
            ime <= op[3] & (~interrupt);
        end
    end

    // m_left
    always_ff @(posedge clk) begin
        if (reset) begin
            m_left <= 3'h0;
        end else if (cpu_en & (t == 2'b10)) begin
            if (op_fetch & interrupt) begin
                m_left <= 3'h4;
            end else if ((m_cycle == M_STOP) | (m_cycle == M_HALT)) begin
                m_left <= 3'h0;
            end else if (op_fetch) begin
                m_left <= m_cycle_num;
            end else if ((~interrupt) & (op == 8'hCB) & (m_left == 3'h7)) begin
                m_left <= m_cycle_num_prefix;
            end else begin
                m_left <= m_left - 3'h1;
            end
        end
    end

    // stop_counter
    always_ff @(posedge clk) begin
        if (reset) begin
            stop_counter <= 11'd0;
        end else if (cpu_en & (t == 2'b00) & (m_cycle == M_STOP)) begin
            stop_counter <= stop_counter + 11'd1;
        end
    end

    // m_cycle
    always_ff @(posedge clk) begin
        if (reset) begin
            m_cycle <= M_NOP;
        end else if (cpu_en & (t == 2'b11)) begin
            if (interrupt) begin
                m_cycle <= next_m_cycle_int;
            end else if ((m_cycle == M_STOP) & (stop_counter == 11'd0)) begin
                m_cycle <= M_NOP;
            end else if ((m_cycle == M_HALT) & (~ime) & (ints != 5'b00000)) begin
                m_cycle <= M_NOP;
            end else if ((m_cycle == M_HALT) | (m_cycle == M_STOP)) begin
                ;
            end else if (op == 8'hCB & (m_left != 3'h7)) begin
                m_cycle <= next_m_cycle_prefix;
            end else begin
                m_cycle <= next_m_cycle;
            end
        end
    end

    // op_fetch
    always_ff @(posedge clk) begin
        if (reset) begin
            op_fetch <= 1'b1;
        end else if (cpu_en & (t == 2'b11)) begin
            op_fetch <= (m_left == 3'h0) | branch;
        end
    end

    // interrupt
    always_ff @(posedge clk) begin
        if (reset) begin
            interrupt <= 1'b0;
            int_reg <= 5'h00;
        end else if (cpu_en & op_fetch & (t == 2'b01)) begin
            interrupt <= ime & (ints != 5'h00);
            int_reg <= ints;
        end
    end

    always_comb begin
        
        reg_src = 4'hx;
        reg_dst = 4'hx;
        reg_wdata_src = 2'bxx;
        reg_write = 1'b0;
        op_write = 1'b0;
        next_f_src = 2'bxx;
        f_write = 4'h0;

        reg16_src = 3'hx;
        reg16_dst = 3'hx;
        reg16_wdata_src = 1'hx;
        reg16_write = 1'b0;
        sp_inc = 1'b0;
        sp_dec = 1'b0;

        pc_wdata_src = 2'hx;
        pc_write = 1'b0;
        pch_write = 1'b0;
        pcl_write = 1'b0;
        pc_inc = 1'b0;

        addr_src = 1'b0;
        mem_wdata_src = 3'hx;
        mem_write = 1'b0;

        alu_a_src = 1'bx;
        alu_b_src = 2'hx;
        alu_control = 4'hx;
        adder16_a_src = 2'hx;
        adder16_b_src = 3'hx;
        adder16_control = 1'bx;
        bitalu_control = 3'hx;

        if (t == 2'b00) begin
            
            reg_src = reg_src_cycle;
            reg_dst = reg_dst_cycle;
            reg_wdata_src = reg_wdata_src_cycle;
            reg_write = reg_write_cycle;
            next_f_src = next_f_src_cycle;
            f_write = f_write_cycle;

            reg16_src = reg16_src_cycle;
            reg16_dst = reg16_dst_cycle;
            reg16_wdata_src = reg16_wdata_src_cycle;
            reg16_write = reg16_write_cycle;
            sp_inc = sp_inc_cycle;
            sp_dec = sp_dec_cycle;

            pc_wdata_src = pc_wdata_src_cycle;
            pc_write = pc_write_cycle;
            pch_write = pch_write_cycle;
            pcl_write = pcl_write_cycle;
            pc_inc = pc_inc_cycle;

            addr_src = addr_src_cycle;
            mem_wdata_src = mem_wdata_src_cycle;
            mem_write = mem_write_cycle;

            alu_a_src = alu_a_src_cycle;
            alu_b_src = alu_b_src_cycle;
            alu_control = alu_control_cycle;
            adder16_a_src = adder16_a_src_cycle;
            adder16_b_src = adder16_b_src_cycle;
            adder16_control = adder16_control_cycle;
            bitalu_control = bitalu_control_cycle;

        end else if (t == 2'b01) begin
            
            if (op_fetch & (~(ime & (ints != 5'h00))) & (~((m_cycle == M_STOP) | (m_cycle == M_HALT)))) begin
                addr_src = 1'b0;
                op_write = 1'b1;
                pc_inc = 1'b1;
            end

        end else begin
            
            reg_src = 4'b1100; // DATA

        end

    end
    
endmodule
