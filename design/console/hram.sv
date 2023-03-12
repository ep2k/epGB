module hram (
    input  logic clk,
    input  logic cpu_en,
    input  logic reset,

    input  logic [6:0] addr,
    output logic [7:0] rdata,
    input  logic [7:0] wdata,
    input  logic write
);

    logic [7:0] hram_ram[127:0]; // 80 ~ FF (FFは不使用)

    assign rdata = hram_ram[addr];

    always_ff @(posedge clk) begin
        if (reset) begin
            for (int i = 0; i < 128; i++) begin
                hram_ram[i] <= 8'h0;
            end
        end else if (cpu_en & write) begin
            hram_ram[addr] <= wdata;
        end
    end
    
endmodule
