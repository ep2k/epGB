module pulse (
    input  logic clk,
    input  logic slow_clk_en,
    input  logic cpu_en,
    input  logic clk256_en,
    input  logic reset,
    input  logic ch1,

    input  logic [4:0] target,
    output logic [7:0] rdata,
    input  logic [7:0] wdata,
    input  logic write,

    output logic [3:0] wave,
    output logic length_play,
    output logic [3:0] volume_out
);

    logic init;

    logic play;
    logic [3:0] amp;

    logic next_step;

    logic [10:0] freq_for_sweep;
    logic [10:0] sweep_new_freq;
    logic do_freq_sweep;

    logic [6:0] freq_sweep_control;
    logic [7:0] envelope_control;
    logic [1:0] duty;
    logic length_enable;
    logic length_play_raw;

    always_comb begin
        priority casez (target)
            5'b00001: rdata = {1'b1, ch1 ? freq_sweep_control : 7'h7f};
            5'b0001?: rdata = {duty, 6'h3f};
            5'b001??: rdata = envelope_control;
            5'b01???: rdata = 8'hff;
            5'b1????: rdata = {1'b1, length_enable, 6'h3f};
            default: rdata = 8'h0;
        endcase
    end

    assign init = cpu_en & target[4] & wdata[7] & write;

    assign length_play = length_play_raw & (amp != 4'h0);
    assign wave = (play & length_play) ? amp : 4'h0;
    assign volume_out = length_play ? amp : 4'h0;

    envelope envelope(
        .clk,
        .slow_clk_en,
        .cpu_en,
        .clk256_en,
        .reset,

        .init,

        .new_control(wdata),
        .control_write(target[2] & write),
        .control(envelope_control),

        .amp
    );

    freq_counter freq_counter(
        .clk,
        .slow_clk_en,
        .reset,

        .new_freq(do_freq_sweep ? sweep_new_freq : {wdata[2:0], wdata}),
        .write_freq_low((cpu_en & target[3] & write) | do_freq_sweep),
        .write_freq_high((cpu_en & target[4] & write) | do_freq_sweep),
        .freq_for_sweep,

        .next_step
    );

    freq_sweep freq_sweep(
        .clk,
        .slow_clk_en,
        .cpu_en,
        .clk256_en,
        .reset,

        .new_control(wdata[6:0]),
        .control_write(target[0] & write & ch1),
        .control(freq_sweep_control),
        
        .init,
        .freq(freq_for_sweep),
        .sweep_new_freq,
        .do_freq_sweep
    );

    length_counter #(.WIDTH(6)) length_counter(
        .clk,
        .slow_clk_en,
        .cpu_en,
        .clk256_en,
        .reset,

        .init,

        .new_length(wdata[5:0]),
        .length_write(target[1] & write),
        
        .new_enable(wdata[6]),
        .enable_write(target[4] & write),
        .enable(length_enable),

        .play(length_play_raw)
    );

    duty_controller duty_controller(
        .clk,
        .slow_clk_en,
        .cpu_en,
        .reset,

        .next_step,

        .new_duty(wdata[7:6]),
        .duty_write(target[1] & write),
        .duty,

        .play
    );
    
endmodule
