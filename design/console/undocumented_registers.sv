module undocumented_registers (
    input  logic clk,
    input  logic cpu_en,
    input  logic reset,
    input  logic cgb,

    input  logic [2:0] reg_select,
    output logic [7:0] rdata,
    input  logic [7:0] wdata,
    input  logic write,

    input  logic [15:0] pcm_amp
);

    logic [7:0] un_reg2 = 8'h0;
    logic [7:0] un_reg3 = 8'h0;
    logic [7:0] un_reg4 = 8'h0;
    logic [2:0] un_reg5 = 3'h0;

    always_comb begin
        case ({cgb, reg_select})
            4'b1_010: rdata = un_reg2;
            4'b1_011: rdata = un_reg3;
            4'b1_100: rdata = un_reg4;
            4'b1_101: rdata = {1'b1, un_reg5, 4'b1111};
            4'b1_110: rdata = pcm_amp[7:0];
            4'b1_111: rdata = pcm_amp[15:8];
            default: rdata = 8'hff;
        endcase
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            un_reg2 <= 8'h0;
            un_reg3 <= 8'h0;
            un_reg4 <= 8'h0;
            un_reg5 <= 3'h0;
        end else if (cpu_en & cgb & write) begin
            case (reg_select)
                3'd2: un_reg2 <= wdata;
                3'd3: un_reg3 <= wdata;
                3'd4: un_reg4 <= wdata;
                3'd5: un_reg5 <= wdata[6:4];
                default: ;
            endcase
        end
    end

endmodule
