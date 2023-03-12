module serial (
    input  logic clk,
    input  logic cpu_en,
    input  logic reset,
    input  logic cgb,

    input  logic reg_select,
    output logic [7:0] rdata,
    input  logic [7:0] wdata,
    input  logic write,

    input  logic clk_in,
    output logic clk_out,
    output logic clk_dir,

    input  logic sin,
    output logic sout = 1'b0,

    output logic serial_int
);

    logic [7:0] data = 8'h0;    // FF01: SB
    logic [2:0] control = 3'h0; // FF02: SC

    logic [8:0] clk_divider = 9'h0; // マスター時にカウント(SCLK用分周器)
    logic [2:0] clk_counter = 3'h0; // 現在のビット番号(7→0で割り込み)

    logic sclk, sclk_negedge, sclk_posedge;
    logic sclk_prev = 1'b1;

    assign rdata = reg_select
        ? {control[2], 5'h1f, (~cgb) | control[1], control[0]} : data;
    assign clk_out = (control[1] & cgb) ? (~clk_divider[3]) : (~clk_divider[8]);
    assign clk_dir = control[0];
    assign serial_int = (clk_counter == 3'h7) & sclk_posedge;

    assign sclk = control[0] ? clk_out : clk_in;
    assign sclk_negedge = cpu_en & sclk_prev & (~sclk); // sclk立ち下がり
    assign sclk_posedge = cpu_en & (~sclk_prev) & sclk; // sclk立ち上がり

    always_ff @(posedge clk) begin
        if (reset) begin
            sclk_prev <= 1'b1;
        end else if (cpu_en) begin
            sclk_prev <= sclk;
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            {sout, data} <= 9'h0;
        end else if (cpu_en & (~reg_select) & write) begin
            data <= wdata;
        end else if (sclk_negedge) begin // 立ち下がりでMSB送信
            {sout, data[7:1]} <= data;
        end else if (sclk_posedge) begin // 立ち上がりで受け取り
            data[0] <= sin;
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            control <= 3'h0;
        end else if (cpu_en & reg_select & write) begin
            control <= {wdata[7], wdata[1:0]};
        end else if ((clk_counter == 3'h7) & sclk_posedge) begin // 伝送終了
            control[2] <= 1'b0;
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            clk_divider <= 9'h0;
        end else if (cpu_en) begin
            clk_divider = (control[0] & control[2]) ? (clk_divider + 9'h1) : 9'h0;
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            clk_counter <= 3'h0;
        end else if (sclk_posedge) begin
            clk_counter <= clk_counter + 3'h1;
        end else if (cpu_en & write) begin
            clk_counter <= 3'h0;
        end
    end
    
endmodule
