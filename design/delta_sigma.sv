module delta_sigma #(parameter int WIDTH = 9) (
    input  logic clk,
    input  logic [WIDTH-1:0] data_in,
    output logic pulse_out
);

    logic [WIDTH:0] sigma_reg = '1; // 初期値-1

    always_ff @(posedge clk) begin
        sigma_reg <= sigma_reg + {pulse_out, data_in};
    end

    assign pulse_out = ~sigma_reg[WIDTH];
    
endmodule
