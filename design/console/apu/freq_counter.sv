module freq_counter (
    input  logic clk,
    input  logic slow_clk_en,
    input  logic reset,

    input  logic [10:0] new_freq,
    input  logic write_freq_low,
    input  logic write_freq_high,
    output logic [10:0] freq_for_sweep,

    output logic next_step
);

    logic [10:0] freq = 11'h0;
    logic [10:0] counter = 11'h0;

    always_ff @(posedge clk) begin
        if (reset) begin
            counter <= 11'h0;
        end else if (slow_clk_en) begin
            counter <= (counter == 11'h0) ? (~freq) : (counter - 11'h1);
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            freq <= 11'h0;
        end else begin
            if (write_freq_low) begin
                freq[7:0] <= new_freq[7:0];
            end
            if (write_freq_high) begin
                freq[10:8] <= new_freq[10:8];
            end
        end
    end

    assign next_step = (counter == 11'h0);

    assign freq_for_sweep = {new_freq[10:8], freq[7:0]};

endmodule
