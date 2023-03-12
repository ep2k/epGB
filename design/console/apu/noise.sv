module noise (
    input  logic clk,
    input  logic slow_clk_en,
    input  logic cpu_en,
    input  logic clk256_en,
    input  logic reset,

    input  logic [4:1] target,
    output logic [7:0] rdata,
    input  logic [7:0] wdata,
    input  logic write,

    output logic [3:0] wave,
    output logic length_play,
    output logic [3:0] volume_out
);

    logic play, init, next_step;
    logic [3:0] amp;

    logic [7:0] envelope_control;
    logic [6:0] freq_control;
    logic shifter_width;
    logic length_enable;
    logic length_play_raw;

    assign init = cpu_en & write & target[4] & wdata[7];

    assign length_play = length_play_raw & (amp != 4'h0);
    assign wave = (play & length_play) ? amp : 4'h0;
    assign volume_out = length_play ? amp : 4'h0;

    always_comb begin
        priority casez (target)
            4'b0001: rdata = 8'hf;
            4'b001?: rdata = envelope_control;
            4'b01??: rdata =
                {freq_control[6:3], shifter_width, freq_control[2:0]};
            4'b1???: rdata = {1'b1, length_enable, 6'h3f};
            default: rdata = 8'h0;
        endcase
    end

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

    freq_counter_noise freq_counter_noise(
        .clk,
        .slow_clk_en,
        .cpu_en,
        .reset,

        .new_control({wdata[7:4], wdata[2:0]}),
        .control_write(target[3] & write),
        .control(freq_control),

        .next_step
    );

    lfsr lfsr(
        .clk,
        .slow_clk_en,
        .cpu_en,
        .reset,

        .new_width(wdata[3]),
        .width_write(target[3] & write),
        .width(shifter_width),

        .init,
        .next_step,

        .play
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
    
endmodule
