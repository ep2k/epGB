module clk256_generator (
    input  logic clk,
    input  logic slow_clk_en,
    input  logic reset,
    
    output logic clk256_en
);
    
    logic [13:0] counter = 14'h0;

    assign clk256_en = (counter == 14'h0);

    always_ff @(posedge clk) begin
        if (reset) begin
            counter <= 14'h0;
        end else if (slow_clk_en) begin
            counter <= counter + 14'h1;
        end
    end

endmodule
