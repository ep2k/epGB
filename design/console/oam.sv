module oam (
    input  logic clk,
    input  logic cpu_en,
    input  logic reset,

    input  logic [7:0] addr,    // 0 ~ 159
    output logic [7:0] rdata,
    input  logic [7:0] wdata,
    input  logic write
);

    logic [7:0] oam_mem[159:0];

    assign rdata = oam_mem[addr];

    always_ff @(posedge clk) begin
        if (reset) begin
            for (int i = 0; i < 160; i++) begin
                oam_mem[i] <= 8'h0;
            end
        end else if (cpu_en & write) begin
            oam_mem[addr] <= wdata;
        end
    end
    
endmodule
