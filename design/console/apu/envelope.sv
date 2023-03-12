module envelope (
    input  logic clk,
    input  logic slow_clk_en,
    input  logic cpu_en,
    input  logic clk256_en,
    input  logic reset,

    input  logic init,

    input  logic [7:0] new_control,
    input  logic control_write,
    output logic [7:0] control = 8'h0,

    output logic [3:0] amp
);

    logic [3:0] amp_reg = 4'h0;
    logic [4:0] counter = 5'd0;
    logic overflow;

    always_ff @(posedge clk) begin
        if (reset) begin
            control <= 8'h0;
        end else if (cpu_en & control_write) begin
            control <= new_control;
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            counter <= 5'd0;
        end else if (init) begin
            counter <= {control[2:0] - 3'd1, 2'b11};
        end else if (slow_clk_en & clk256_en & (control[2:0] != 3'd0)) begin
            counter <= (counter == 5'd0) ? {control[2:0] - 3'd1, 2'b11} : (counter - 5'd1);
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            amp_reg <= 4'h0;
        end else if (init) begin
            amp_reg <= control[7:4];
        end else if (slow_clk_en & clk256_en & (counter == 5'd0) & (control[2:0] != 3'd0) & (~overflow)) begin
            amp_reg <= amp_reg + (control[3] ? 4'h1 : 4'hf);
        end
    end

    assign overflow = (amp_reg == {4{control[3]}});

    assign amp = (control[7:4] == 4'h0) ? 4'h0 : amp_reg;
    
endmodule
