module length_counter #(parameter int WIDTH = 6) (
    input  logic clk,
    input  logic slow_clk_en,
    input  logic cpu_en,
    input  logic clk256_en,
    input  logic reset,

    input  logic init,

    input  logic [WIDTH-1:0] new_length,
    input  logic length_write,

    input  logic new_enable,
    input  logic enable_write,
    output logic enable = 1'b0,

    output logic play
);
    
    logic [WIDTH-1:0] counter;
    logic length_play = 1'b0;

    always_ff @(posedge clk) begin
        if (reset) begin
            counter <= 0;
            length_play <= 1'b0;
        end else if (cpu_en & length_write) begin
            counter <= (~new_length);
            length_play <= 1'b1;
        end else if (slow_clk_en & clk256_en & enable & length_play) begin
            if (counter == 0) begin
                length_play <= 1'b0;
            end else begin
                counter <= counter - 1;
            end
        end else if ((~length_play) & init) begin
            counter <= '1;
            length_play <= 1'b1;
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            enable <= 1'b0;
        end else if (cpu_en & enable_write) begin
            enable <= new_enable;
        end
    end

    assign play = length_play | (~enable);

endmodule
