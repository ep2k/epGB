module oamdma_controller (
    input  logic clk,
    input  logic cpu_en,
    input  logic reset,

    input  logic [7:0] oamdma_start_addr,
    input  logic oamdma_start,

    output logic oamdma,
    output logic [15:0] oamdma_src_addr,
    output logic [7:0] oamdma_oam_addr,
    output logic oamdma_write
);

    localparam COUNTER_MAX = 10'b1001_1111_11; // 9F_11, 160*4-1

    logic oamdma_reg = 1'b0;
    logic [9:0] counter = 10'h0;

    assign oamdma = oamdma_reg;
    assign oamdma_src_addr = {oamdma_start_addr, counter[9:2]};
    assign oamdma_oam_addr = counter[9:2];
    assign oamdma_write = (counter[1:0] == 2'b11);

    always_ff @(posedge clk) begin
        if (reset) begin
            oamdma_reg <= 1'b0;
        end else if (cpu_en & oamdma_start) begin
            oamdma_reg <= 1'b1;
        end else if (cpu_en & (counter == COUNTER_MAX)) begin
            oamdma_reg <= 1'b0;
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            counter <= 10'h0;
        end else if (cpu_en & (~oamdma)) begin
            counter <= 10'h0;
        end else if (cpu_en & oamdma) begin
            counter <= (counter == COUNTER_MAX) ? 10'h0 : (counter + 10'h1);
        end
    end
    
endmodule
