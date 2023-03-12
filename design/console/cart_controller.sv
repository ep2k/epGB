module cart_controller (
    input  logic clk,
    input  logic reset,
    input  logic cpu_en,

    input  logic [1:0] t,

    input  logic cart_target,
    input  logic cart_write_raw,
    input  logic [15:0] cart_addr_raw,
    input  logic [7:0] cart_wdata_raw,
    
    output logic n_cart_clk,
    output logic cart_write,
    output logic cart_read,
    output logic cart_cs,
    output logic [15:0] cart_addr,
    output logic [7:0] cart_wdata,
    output logic cart_wdata_send
);

    logic write_reg = 1'b0;
    logic [15:0] addr_reg = 16'h0;
    logic [7:0] wdata_reg = 8'h0;

    assign n_cart_clk = t[1];
    assign cart_write = (t == 2'd2) & write_reg;
    assign cart_read = 1'b1; // [TODO] 要修正?
    assign cart_cs = ((t != 2'd0) & write_reg)
                ? addr_reg[15] : (cart_addr_raw[15] & cart_target);
    assign cart_addr = ((t != 2'd0) & write_reg) ? addr_reg : cart_addr_raw;
    assign cart_wdata = wdata_reg;
    assign cart_wdata_send = (t != 2'd0) & write_reg;

    always_ff @(posedge clk) begin
        if (reset) begin
            write_reg <= 1'b0;
            addr_reg <= 16'h0;
            wdata_reg <= 8'h0;
        end else if (cpu_en & (t == 2'd0)) begin
            write_reg <= cart_write_raw;
            addr_reg <= cart_addr_raw;
            wdata_reg <= cart_wdata_raw;
        end
    end
    
endmodule
