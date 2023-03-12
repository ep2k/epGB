module freq_sweep (
    input  logic clk,
    input  logic slow_clk_en,
    input  logic cpu_en,
    input  logic clk256_en,
    input  logic reset,

    input  logic [6:0] new_control,
    input  logic control_write,
    output logic [6:0] control = 7'h0,

    input  logic init,
    input  logic [10:0] freq,
    output logic [10:0] sweep_new_freq,
    output logic do_freq_sweep
    // output logic mute = 1'b0 // [TODO] 必要?
);

    logic [3:0] counter = 4'h0;
    logic [10:0] int_freq = 11'h0;

    logic [10:0] freq_shift;
    logic freq_overflow;

    always_ff @(posedge clk) begin
        if (reset) begin
            control <= 7'h0;
        end else if (cpu_en & control_write) begin
            control <= new_control;
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            counter <= 4'h0;
        end else if (cpu_en & control_write & (new_control[6:4] != 3'h0)) begin
            counter <= {new_control[6:4] - 3'h1, 1'b1};
        end else if (slow_clk_en & clk256_en & (control[6:4] != 3'h0)) begin
            counter <= (counter == 4'h0) ?
                    {control[6:4] - 3'h1, 1'b1} : (counter - 4'h1);
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            int_freq <= 11'h0;
        end else if (init) begin
            int_freq <= freq;
        end else if (do_freq_sweep) begin
            int_freq <= sweep_new_freq;
        end
    end

    always_comb begin
        unique case (control[2:0])
            3'h0: freq_shift = int_freq;
            3'h1: freq_shift = {1'b0, int_freq[10:1]};
            3'h2: freq_shift = {2'b00, int_freq[10:2]};
            3'h3: freq_shift = {3'b000, int_freq[10:3]};
            3'h4: freq_shift = {4'b0000, int_freq[10:4]};
            3'h5: freq_shift = {5'b00000, int_freq[10:5]};
            3'h6: freq_shift = {6'b000000, int_freq[10:6]};
            3'h7: freq_shift = {7'b0000000, int_freq[10:7]};
        endcase
    end

    assign {freq_overflow, sweep_new_freq} = control[3] ?
            (int_freq - freq_shift) : (int_freq + freq_shift);

    assign do_freq_sweep =
        slow_clk_en & clk256_en & (counter == 4'h0) & (control[6:4] != 3'h0)
            & (~(freq_overflow & (~control[3])));

endmodule
