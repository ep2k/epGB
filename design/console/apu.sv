module apu (
    input  logic clk,
    input  logic slow_clk_en,
    input  logic cpu_en,
    input  logic reset,

    input  logic [5:0] reg_select,
    output logic [7:0] rdata,
    input  logic [7:0] wdata,
    input  logic write,

    input  logic [3:0] ch_off,

    output logic [8:0] sound_r = 9'h0,
    output logic [8:0] sound_l = 9'h0,
    output logic [15:0] volumes = 16'h0,

    output logic [15:0] pcm_amp
);

    logic clk256_en;

    logic [7:0] pulse1_rdata, pulse2_rdata, pattern_rdata, noise_rdata;
    logic [7:0] control_rdata, pattern_ram_rdata;

    logic [4:0] pulse1_target, pulse2_target, pattern_target;
    logic [4:1] noise_target;
    logic [2:0] control_target;

    logic [3:0] pulse1_wave, pulse2_wave, pattern_wave, noise_wave;
    logic [3:0] length_plays;

    logic [8:0] sound_r_next, sound_l_next;
    logic [15:0] volumes_raw, volumes_next;


    assign rdata = (reg_select[5:4] == 2'b11)
                ? pattern_ram_rdata
                : (pulse1_rdata | pulse2_rdata | pattern_rdata
                    | noise_rdata | control_rdata);

    assign pcm_amp = {noise_wave, pattern_wave, pulse2_wave, pulse1_wave};

    always_ff @(posedge clk) begin
        sound_r <= sound_r_next;
        sound_l <= sound_l_next;
        volumes <= volumes_next;
    end

    clk256_generator clk256_generator(
        .clk,
        .slow_clk_en,
        .reset,

        .clk256_en
    );

    apu_decoder apu_decoder(
        .reg_select,

        .pulse1_target,
        .pulse2_target,
        .pattern_target,
        .noise_target,
        .control_target
    );

    pulse pulse1(
        .clk,
        .slow_clk_en,
        .cpu_en,
        .clk256_en,
        .reset,
        .ch1(1'b1),

        .target(pulse1_target),
        .rdata(pulse1_rdata),
        .wdata,
        .write,

        .wave(pulse1_wave),
        .length_play(length_plays[0]),
        .volume_out(volumes_raw[3:0])
    );

    pulse pulse2(
        .clk,
        .slow_clk_en,
        .cpu_en,
        .clk256_en,
        .reset,
        .ch1(1'b0),

        .target(pulse2_target),
        .rdata(pulse2_rdata),
        .wdata,
        .write,

        .wave(pulse2_wave),
        .length_play(length_plays[1]),
        .volume_out(volumes_raw[7:4])
    );

    pattern pattern(
        .clk,
        .slow_clk_en,
        .cpu_en,
        .clk256_en,
        .reset,

        .target(pattern_target),
        .rdata(pattern_rdata),
        .wdata,
        .write,

        .ram_addr(reg_select[3:0]),
        .ram_rdata(pattern_ram_rdata),
        .ram_write(write & (reg_select[5:4] == 2'b11)),

        .wave(pattern_wave),
        .length_play(length_plays[2]),
        .volume_out(volumes_raw[11:8])
    );

    noise noise(
        .clk,
        .slow_clk_en,
        .cpu_en,
        .clk256_en,
        .reset,

        .target(noise_target),
        .rdata(noise_rdata),
        .wdata,
        .write,

        .wave(noise_wave),
        .length_play(length_plays[3]),
        .volume_out(volumes_raw[15:12])
    );

    wave_mixer wave_mixer(
        .clk,
        .cpu_en,
        .reset,

        .target(control_target),
        .rdata(control_rdata),
        .wdata,
        .write,

        .pulse1_wave,
        .pulse2_wave,
        .pattern_wave,
        .noise_wave,

        .length_plays,
        
        .ch_off,

        .sound_r(sound_r_next),
        .sound_l(sound_l_next),

        .volumes_raw,
        .volumes(volumes_next)
    );
    
endmodule
