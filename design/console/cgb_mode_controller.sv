module cgb_mode_controller (
    input  logic clk,
    input  logic cpu_en,
    input  logic reset,

    output logic [7:0] rdata,
    input  logic [7:0] wdata,
    input  logic write,

    output logic cgb_soft
);

    logic [7:0] cgb_reg = 8'h0; // key0 (FF4C)
    
    assign rdata = cgb_reg;
    assign cgb_soft = cgb_reg[7];

    always_ff @(posedge clk) begin
        if (reset) begin
            cgb_reg <= 8'h00;
        end else if (cpu_en & write) begin
            cgb_reg <= wdata;
        end
    end
    
endmodule
