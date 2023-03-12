module wram (
    input  logic clk,
    input  logic cpu_en,
    input  logic reset,
    input  logic cgb,

    input  logic [12:0] addr,
    output logic [7:0] rdata,
    input  logic [7:0] wdata,
    input  logic write,

    output logic [7:0] bank_rdata,
    input  logic switch_bank
);

    logic [2:0] bank = 3'h1; // 1~7 (0書き込み時, ~cgb時は1に)
    logic [14:0] addr_eff;
    logic write_prev;

    assign bank_rdata = {5'b00000, bank};

    assign addr_eff = {(addr[12] ? bank : 3'h0), addr[11:0]};

    always_ff @(posedge clk) begin
        if (reset) begin
            bank <= 3'h1;
        end else if (cpu_en & switch_bank & cgb) begin
            bank <= (wdata[2:0] == 3'h0) ? 3'h1 : wdata[2:0];
        end
    end

    always_ff @(negedge clk) begin // negedge
        write_prev <= write;
    end

    // C000 ~ CFFF (4KB) + D000 ~ DFFF (4KB * 7)
    wram_bram wram_bram(
        .address(addr_eff),
        .clock(~clk),
        .data(wdata),
        .wren((~write_prev) & write),
        .q(rdata)
    );
    
endmodule
