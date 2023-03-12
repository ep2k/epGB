module pc_register (
    input  logic clk,
    input  logic cpu_en,
    input  logic reset,

    output logic [15:0] pc = 16'h0,

    input  logic [15:0] wdata,
    input  logic [7:0] wdata8,   // 上位/下位書き込み用
    input  logic write,
    input  logic write_h,        // 上位バイト書き込み
    input  logic write_l,        // 下位バイト書き込み
    input  logic pc_inc
);

    always_ff @(posedge clk) begin
        if (reset) begin
            pc <= 16'h0;
        end else if (cpu_en) begin
            if (write) begin
                pc <= wdata;
            end else if (write_h) begin
                pc[15:8] <= wdata8;
            end else if (write_l) begin
                pc[7:0] <= wdata8;
            end else if (pc_inc) begin
                pc <= pc + 16'h1;
            end 
        end
    end
    
endmodule
