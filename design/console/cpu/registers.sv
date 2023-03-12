module registers (
    input  logic clk,
    input  logic cpu_en,
    input  logic reset,

    input  logic [3:0] reg_src,
    input  logic [3:0] reg_dst,
    input  logic [7:0] reg_wdata,
    input  logic [2:0] reg16_src,
    input  logic [2:0] reg16_dst,
    input  logic [15:0] reg16_wdata,
    input  logic reg_write,
    input  logic reg16_write,
    input  logic [3:0] next_f,
    input  logic [3:0] f_write,
    input  logic sp_inc,
    input  logic sp_dec,

    output logic [7:0] reg_rdata,
    output logic [15:0] reg16_rdata,

    output logic [7:0] a,
    output logic [3:0] f,
    output logic [15:0] sp,
    output logic [15:0] hl,
    output logic [7:0] data1
);

    logic [7:0] reg_a = 8'h0;
    logic [7:0] reg_b = 8'h0;
    logic [7:0] reg_c = 8'h0;
    logic [7:0] reg_d = 8'h0;
    logic [7:0] reg_e = 8'h0;
    logic [7:0] reg_h = 8'h0;
    logic [7:0] reg_l = 8'h0;
    logic [7:0] reg_data1 = 8'h0;
    logic [7:0] reg_data2 = 8'h0;
    logic [3:0] reg_f = 4'h0;
    logic [15:0] reg_sp = 16'h0;

    assign a = reg_a;
    assign f = reg_f;
    assign sp = reg_sp;
    assign hl = {reg_h, reg_l};
    assign data1 = reg_data1;

    always_comb begin
        case (reg_src)
            4'b0000: reg_rdata = reg_b; 
            4'b0001: reg_rdata = reg_c; 
            4'b0010: reg_rdata = reg_d; 
            4'b0011: reg_rdata = reg_e; 
            4'b0100: reg_rdata = reg_h; 
            4'b0101: reg_rdata = reg_l; 
            4'b0111: reg_rdata = reg_a; 
            4'b1000: reg_rdata = reg_sp[15:8]; 
            4'b1001: reg_rdata = reg_sp[7:0]; 
            4'b1100: reg_rdata = reg_data1; 
            4'b1101: reg_rdata = reg_data2; 
            4'b1111: reg_rdata = {reg_f, 4'h0}; 
            default: reg_rdata = 8'hx;
        endcase
    end

    always_comb begin
        case (reg16_src)
            3'b000: reg16_rdata = {reg_b, reg_c};
            3'b001: reg16_rdata = {reg_d, reg_e};
            3'b010: reg16_rdata = {reg_h, reg_l};
            3'b011: reg16_rdata = {reg_a, reg_f, 4'h0};
            3'b100: reg16_rdata = {reg_data1, reg_data2};
            3'b101: reg16_rdata = {8'hff, reg_c};
            3'b110: reg16_rdata = {8'hff, reg_data1};
            3'b111: reg16_rdata = reg_sp;
            default: reg16_rdata = 16'hx;
        endcase
    end


    // reg_f, reg_sp以外
    always_ff @(posedge clk) begin

        if (reset) begin
            
            reg_a <= 8'h0;
            reg_b <= 8'h0;
            reg_c <= 8'h0;
            reg_d <= 8'h0;
            reg_e <= 8'h0;
            reg_h <= 8'h0;
            reg_l <= 8'h0;
            reg_data1 <= 8'h0;
            reg_data2 <= 8'h0;

        end else if (cpu_en & reg_write) begin
            
            case (reg_dst)
                4'b0000: reg_b <= reg_wdata;
                4'b0001: reg_c <= reg_wdata;
                4'b0010: reg_d <= reg_wdata;
                4'b0011: reg_e <= reg_wdata;
                4'b0100: reg_h <= reg_wdata;
                4'b0101: reg_l <= reg_wdata;
                4'b0111: reg_a <= reg_wdata;
                // 4'b1000: reg_sp[15:8] <= reg_wdata;
                // 4'b1001: reg_sp[7:0] <= reg_wdata;
                4'b1100: {reg_data1, reg_data2} <= {reg_wdata, reg_data1};
                4'b1101: reg_data2 <= reg_wdata;
                // 4'b1111: reg_f <= reg_wdata[7:4];
                default: ;
            endcase

        end else if (cpu_en & reg16_write) begin
            
            case (reg16_dst)
                3'b000: {reg_b, reg_c} <= reg16_wdata;
                3'b001: {reg_d, reg_e} <= reg16_wdata;
                3'b010: {reg_h, reg_l} <= reg16_wdata;
                3'b011: reg_a <= reg16_wdata[15:8];
                // 3'b011: {reg_a, reg_f} <= reg16_wdata[15:4];
                3'b100: {reg_data1, reg_data2} <= reg16_wdata;
                // 3'b111: reg_sp <= reg16_wdata;
                default: ;
            endcase

        end
    end

    // reg_f
    always_ff @(posedge clk) begin
        
        if (reset) begin
            
            reg_f <= 4'h0;

        end else if (cpu_en) begin

            if (f_write != 4'h0) begin
                for (int i = 0; i < 4; i++) begin
                    if (f_write[i]) begin
                        reg_f[i] <= next_f[i];
                    end
                end
            end else if (reg_write & (reg_dst == 4'b1111)) begin
                reg_f <= reg_wdata[7:4];
            end else if (reg16_write & (reg16_dst == 3'b011)) begin
                reg_f <= reg16_wdata[7:4];
            end

        end
    end

    // reg_sp
    always_ff @(posedge clk) begin
        
        if (reset) begin
            
            reg_sp <= 16'h0;

        end else if (cpu_en) begin

            if (sp_inc) begin 
                reg_sp <= reg_sp + 16'h2;
            end else if (sp_dec) begin
                reg_sp <= reg_sp - 16'h2;
            end else if (reg_write & (reg_dst == 4'b1000)) begin
                reg_sp[15:8] <= reg_wdata;
            end else if (reg_write & (reg_dst == 4'b1001)) begin
                reg_sp[7:0] <= reg_wdata;
            end else if (reg16_write & (reg16_dst == 3'b111)) begin
                reg_sp <= reg16_wdata;
            end

        end
    end
    
endmodule
