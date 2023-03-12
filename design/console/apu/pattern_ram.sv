module pattern_ram (
    input  logic clk,
    input  logic slow_clk_en,
    input  logic cpu_en,
    input  logic reset,

    input  logic [3:0] addr,
    output logic [7:0] rdata,
    input  logic [7:0] wdata,
    input  logic write,

    input  logic init,
    input  logic next_step,
    
    output logic [3:0] wave
);

    logic [3:0] ram[31:0];
    logic [5:0] step = 6'h0;

    assign rdata = {ram[{addr, 1'b0}], ram[{addr, 1'b1}]};

    assign wave = ram[step[5:1]];

    always_ff @(posedge clk) begin
        if (reset) begin
            for (int i = 0; i < 32; i++) begin
                ram[i] <= 4'h0;
            end
        end else if (cpu_en & write) begin
            {ram[{addr, 1'b0}], ram[{addr, 1'b1}]} <= wdata;
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            step <= 6'h0;
        end else if (init) begin
            step <= 6'h0;
        end else if (slow_clk_en & next_step) begin
            step <= step + 6'h1;
        end
    end
    
endmodule
