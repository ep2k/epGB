module clock_controller (
    input  logic clk,
    input  logic reset,

    input  logic slow_clk_en,
    input  logic cgb,
    input  logic stop,

    output logic [7:0] rdata,
    input  logic [7:0] wdata,
    input  logic write,

    output logic cpu_en,            // 1のときclkでCPUなどを駆動
    output logic fast_mode = 1'b0
);
    
    logic prepare_switch = 1'b0;

    logic stop_prev, stop_rise;


    assign rdata = {fast_mode, 6'b111111, prepare_switch};
    assign cpu_en = fast_mode | slow_clk_en;

    assign stop_rise = (~stop_prev) & stop;

    always_ff @(posedge clk) begin
        stop_prev <= stop;
    end

    // prepare_switch
    always_ff @(posedge clk) begin
        if (reset) begin
            prepare_switch <= 1'b0;
        end else if (stop_rise) begin
            prepare_switch <= 1'b0;
        end else if (cpu_en & write) begin
            prepare_switch <= wdata[0];
        end
    end

    // fast_mode
    always_ff @(posedge clk) begin
        if (reset) begin
            fast_mode <= 1'b0;
        end else if (prepare_switch & stop_rise & cgb) begin
            fast_mode <= ~fast_mode;
        end
    end

endmodule
