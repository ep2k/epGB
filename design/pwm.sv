module pwm #(parameter int WIDTH = 4) (
    input  logic clk,
    input  logic [WIDTH-1:0] din,
    output logic dout
);

    logic [WIDTH-1:0] ctr = 0;

    assign dout = (din > ctr);

    always_ff @(posedge clk) begin
        ctr <= ctr + 1;
    end
    
endmodule
