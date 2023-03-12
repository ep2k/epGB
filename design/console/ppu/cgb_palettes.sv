module cgb_palettes (
    input  logic clk,
    input  logic cpu_en,
    input  logic reset,

    input  logic [2:0] palette_num,
    input  logic [1:0] color_num,
    input  logic is_sp,
    output logic [14:0] color,

    input  logic [5:0] bg_palette_addr,
    input  logic [5:0] sp_palette_addr,
    output logic [7:0] bg_palette_rdata,
    output logic [7:0] sp_palette_rdata,
    input  logic [7:0] wdata,
    input  logic [1:0] write
);

    logic [7:0] bg_palette[63:0]; // 00~3F
    logic [7:0] sp_palette[63:0]; // 00~3F
    
    assign bg_palette_rdata = bg_palette[bg_palette_addr];
    assign sp_palette_rdata = sp_palette[sp_palette_addr];

    assign color = is_sp ? 
        {
            sp_palette[{palette_num, color_num, 1'b1}][6:0],
            sp_palette[{palette_num, color_num, 1'b0}]
        } :
        {
            bg_palette[{palette_num, color_num, 1'b1}][6:0],
            bg_palette[{palette_num, color_num, 1'b0}]
        };

    always_ff @(posedge clk) begin
        if (reset) begin
            for (int i = 0; i < 64; i++) begin
                bg_palette[i] <= 8'h0;
                sp_palette[i] <= 8'h0;
            end
        end else if (cpu_en & write[0]) begin
            bg_palette[bg_palette_addr] <= wdata;
        end else if (cpu_en & write[1]) begin
            sp_palette[sp_palette_addr] <= wdata;
        end
    end

endmodule
