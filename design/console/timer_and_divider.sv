module timer_and_divider (
    input  logic clk,
    input  logic cpu_en,
    input  logic reset,
    input  logic stop,

    input  logic [1:0] reg_select,
    output logic [7:0] rdata,
    input  logic [7:0] wdata,
    input  logic write,

    output logic timer_int
);

    logic [15:0] divider_counter = 16'h0;

    logic [7:0] tima = 8'h0;    // tacで指定した周波数でカウント
    logic [7:0] tma = 8'h0;     // tima初期値
    logic [2:0] tac = 3'b000;   // timer control
    logic [2:0] overflow_counter = 3'd0;

    logic divider_out, divider_out_prev, timer_inc;

    assign timer_inc = divider_out_prev & (~divider_out);
    assign timer_int = cpu_en & (overflow_counter == 3'd4);

    always_comb begin
        unique case (reg_select)
            2'b00: rdata = divider_counter[15:8];
            2'b01: rdata = tima + {7'h0, timer_inc};
            2'b10: rdata = tma;
            2'b11: rdata = {5'h1f, tac};
        endcase
    end

    always_comb begin
        unique case (tac[1:0])
            2'b00: divider_out = tac[2] & divider_counter[9];
            2'b01: divider_out = tac[2] & divider_counter[3];
            2'b10: divider_out = tac[2] & divider_counter[5];
            2'b11: divider_out = tac[2] & divider_counter[7];
        endcase
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            divider_counter <= 16'h0;
        end else if ((cpu_en & (reg_select == 2'b00) & write) | stop) begin
            divider_counter <= 16'h1;
        end else if (cpu_en) begin
            divider_counter <= divider_counter + 16'h1;
        end
    end

    always_ff @(posedge clk) begin
        if (cpu_en) begin
            divider_out_prev <= divider_out;
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            tima <= 8'h0;
        end else if (cpu_en & (reg_select == 2'b01) & write) begin
            tima <= wdata;
        end else if (cpu_en & timer_inc) begin
            tima <= tima + 8'h1;
        end else if (cpu_en & (overflow_counter == 3'd4)) begin
            tima <= tma;
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            overflow_counter <= 3'd0;
        end else if (cpu_en & timer_inc & (tima == 8'hff)) begin
            overflow_counter <= 3'd1;
        end else if (cpu_en & (reg_select == 2'b01) & write) begin
            overflow_counter <= 3'd0;
        end else if (cpu_en & (overflow_counter != 3'd0)) begin
            overflow_counter <= (overflow_counter == 3'd4) ? 3'd0 : (overflow_counter + 3'd1);
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            tma <= 8'h0;
        end else if (cpu_en & (reg_select == 2'b10) & write) begin
            tma <= wdata;
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            tac <= 3'h0;
        end else if (cpu_en & (reg_select == 2'b11) & write) begin
            tac <= wdata[2:0];
        end
    end

endmodule
