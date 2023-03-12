module vram (
    input  logic clk,
    input  logic cpu_en,
    input  logic reset,
    input  logic cgb,

    input  logic [12:0] addr,
    output logic [7:0] rdata,
    output logic [7:0] rdata_bank0,
    output logic [7:0] rdata_bank1,
    input  logic [7:0] wdata,
    input  logic write,

    output logic [7:0] bank_rdata,
    input  logic switch_bank
);

    logic bank = 1'b0;

    logic write_prev;

    assign rdata = bank ? rdata_bank1 : rdata_bank0;
    assign bank_rdata = {7'h7f, bank};
    
    always_ff @(posedge clk) begin
        if (reset) begin
            bank <= 1'b0;
        end else if (cpu_en & switch_bank & cgb) begin
            bank <= wdata[0];
        end
    end

    always_ff @(negedge clk) begin // negedge
        write_prev <= write;
    end

    // 8000 ~ 9FFF (8KB) * 2
    // 両バンクのデータが同時に必要であるため，WRAMとは異なる方式

    vram_bram vram_bram_0(          // IP (RAM)
        .address(addr),
        .clock(~clk),
        .data(wdata),
        .wren((~write_prev) & write & (~bank)),
        .q(rdata_bank0)
    );

    vram_bram vram_bram_1(          // IP (RAM)
        .address(addr),
        .clock(~clk),
        .data(wdata),
        .wren((~write_prev) & write & bank),
        .q(rdata_bank1)
    );
    
endmodule
