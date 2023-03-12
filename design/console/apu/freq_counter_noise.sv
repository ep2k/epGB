module freq_counter_noise (
    input  logic clk,
    input  logic slow_clk_en,
    input  logic cpu_en,
    input  logic reset,

    input  logic [6:0] new_control,
    input  logic control_write,
    output logic [6:0] control = 7'h0,

    output logic next_step
);

    logic [5:0] counter = 6'h0;
    logic [15:0] counter16 = 16'h0;
    logic counter_bit_prev = 1'b0;

    logic [3:0] div_ratio;

    assign next_step = counter16[control[6:3]] & (~counter_bit_prev);

    always_ff @(posedge clk) begin
        if (reset) begin
            control <= 7'h0;
        end else if (cpu_en & control_write) begin
            control <= new_control;
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            counter <= 6'h0;
        end else if (slow_clk_en) begin
            counter <= (counter == 6'h0) ? {div_ratio, 2'b11} : (counter - 6'h1);
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            counter16 <= 16'h0;
        end else if (slow_clk_en & (counter == 6'h0)) begin
            counter16 <= counter16 + 16'h1;
        end
    end

    always_ff @(posedge clk) begin
        if (slow_clk_en) begin
            counter_bit_prev <= counter16[control[6:3]];
        end
    end

    // Pan Docsとgbsound.txtの記述が合わなかった
    // Pan Docsの情報を採用
    always_comb begin
        unique case (control[2:0])
            3'b000: div_ratio = 4'b0000;
            3'b001: div_ratio = 4'b0001;
            3'b010: div_ratio = 4'b0011;
            3'b011: div_ratio = 4'b0101;
            3'b100: div_ratio = 4'b0111;
            3'b101: div_ratio = 4'b1001;
            3'b110: div_ratio = 4'b1011;
            3'b111: div_ratio = 4'b1101; 
        endcase
    end
    
endmodule
