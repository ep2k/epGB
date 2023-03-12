module lfsr (
    input  logic clk,
    input  logic slow_clk_en,
    input  logic cpu_en,
    input  logic reset,

    input  logic new_width,
    input  logic width_write,
    output logic width = 1'b0,

    input  logic init,
    input  logic next_step,

    output logic play
);

    logic [14:0] shifter = 15'h01;
    logic feed_back;

    assign feed_back = shifter[1] ^ shifter[0];
    assign play = ~shifter[0];

    always_ff @(posedge clk) begin
        if (reset) begin
            width <= 1'b0;
        end else if (cpu_en & width_write) begin
            width <= new_width;
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            shifter <= 15'h01;
        end else if (init) begin
            shifter <= 15'h7fff;
        end else if (slow_clk_en & next_step) begin
            // shifter <= {feed_back, shifter[14:7], (width ? feed_back : shifter[6]) ,shifter[5:1]};
            shifter <= {feed_back, shifter[14:8], (width ? feed_back : shifter[7]) ,shifter[6:1]};
        end
    end
    
endmodule
