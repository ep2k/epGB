module timing_controller (
    input  logic clk,
    input  logic slow_clk_en,
    input  logic reset,

    input  logic ppu_enable,
    input  logic fetch_finish,

    output logic [8:0] hori_counter,
    output logic [7:0] ly,
    output logic [1:0] mode,
    output logic hblank_start
);

    localparam LY_MAX = 153;

    logic [8:0] hori_counter_reg = 9'd0; // 0 ~ 455
    logic [7:0] ly_reg = 8'd0; // 0 ~ 153
    logic hblank_prev;

    assign hori_counter = hori_counter_reg;
    assign ly = ((ly_reg == LY_MAX) & (hori_counter_reg >= 9'd8)) ? 8'd0 : ly_reg;
    assign hblank_start = (~hblank_prev) & (mode == 2'd0);

    always_comb begin
        if (~ppu_enable) begin
            mode = 2'd0;
        end else if (ly_reg > 8'd143) begin
            mode = 2'd1; // vblank
        end else if (hori_counter < 9'd80) begin
            mode = 2'd2; // oam scan
        end else if (fetch_finish) begin
            mode = 2'd0; // hblank
        end else begin
            mode = 2'd3; // drawing
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            hori_counter_reg <= 9'd0;
        end else if (~ppu_enable) begin
            hori_counter_reg <= 9'd0;
        end else if (slow_clk_en) begin
            hori_counter_reg <= (hori_counter_reg == 9'd455)
                            ? 9'd0 : (hori_counter_reg + 9'd1);
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            ly_reg <= 8'd0;
        end else if (~ppu_enable) begin
            ly_reg <= 8'd0;
        end else if (slow_clk_en & (hori_counter_reg == 9'd455)) begin
            ly_reg <= (ly_reg == 8'd153) ? 8'd0 : (ly_reg + 8'd1);
        end
    end

    always_ff @(posedge clk) begin
        if (slow_clk_en) begin
            hblank_prev <= (mode == 2'd0);
        end
    end
    
endmodule
