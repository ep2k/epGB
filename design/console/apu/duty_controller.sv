module duty_controller (
    input  logic clk,
    input  logic slow_clk_en,
    input  logic cpu_en,
    input  logic reset,

    input  logic next_step,

    input  logic [1:0] new_duty,
    input  logic duty_write,
    output logic [1:0] duty = 2'b00,

    output logic play
);

    logic [4:0] step = 5'h0;

    always_ff @(posedge clk) begin
        if (reset) begin
            step <= 5'h0;
        end else if (slow_clk_en & next_step) begin
            step <= step + 5'h1;
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            duty <= 2'b00;
        end else if (cpu_en & duty_write) begin
            duty <= new_duty;
        end
    end

    always_comb begin
        unique case (duty)
            2'b00: play = (step[4:2] == 3'h0);      // 12.5%
            2'b01: play = (step[4:3] == 2'b00);     // 25%
            2'b10: play = ~step[4];                 // 50%
            2'b11: play = ~(step[4:3] == 2'b11);    // 75%
        endcase
    end
    
endmodule
