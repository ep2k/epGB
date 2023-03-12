module op_register (
    input  logic clk,
    input  logic cpu_en,
    input  logic reset,

    output logic [7:0] op = 8'h0,

    input  logic [7:0] wdata,
    input  logic write
);

    always_ff @(posedge clk) begin
        if (reset) begin
            op <= 8'h0;
        end else if (cpu_en & write) begin
            op <= wdata;
        end
    end
    
endmodule
