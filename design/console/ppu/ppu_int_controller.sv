module ppu_int_controller (
    input  logic clk,
    input  logic cpu_en,

    input  logic ppu_enable,
    input  logic [3:0] int_enable,
    input  logic ly_compare,
    input  logic [1:0] mode,

    output logic vblank_int,
    output logic ppu_int
);

    logic vblank_prev;
    logic [3:0] intline, intline_prev;


    assign vblank_int = (~vblank_prev) & (mode == 2'd1);
    assign ppu_int = ((intline & (~intline_prev)) != 4'h0);

    assign intline = int_enable & {
        ly_compare,
        mode == 2'd2,
        mode == 2'd1,
        mode == 2'd0
    };

    always_ff @(posedge clk) begin
        if (cpu_en) begin
            vblank_prev <= (mode == 2'd1);
        end
    end

    always_ff @(posedge clk) begin
        if (cpu_en) begin
            intline_prev <= intline;
        end
    end

endmodule
