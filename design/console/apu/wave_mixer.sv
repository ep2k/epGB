module wave_mixer (
    input  logic clk,
    input  logic cpu_en,
    input  logic reset,

    input  logic [2:0] target,
    output logic [7:0] rdata,
    input  logic [7:0] wdata,
    input  logic write,

    input  logic [3:0] pulse1_wave,
    input  logic [3:0] pulse2_wave,
    input  logic [3:0] pattern_wave,
    input  logic [3:0] noise_wave,

    input  logic [3:0] length_plays,

    input  logic [3:0] ch_off,

    output logic [8:0] sound_r,
    output logic [8:0] sound_l,

    input  logic [15:0] volumes_raw,
    output logic [15:0] volumes
);

    logic [7:0] ch_volume = 8'h0;
    logic [7:0] ch_dst = 8'h0;
    logic apu_on = 1'b0;

    logic [5:0] wave_r, wave_l;

    logic [7:0] ch_on;

    always_comb begin
        priority casez (target)
            3'b001: rdata = ch_volume;
            3'b01?: rdata = ch_dst;
            3'b1??: rdata = {apu_on, 3'b111, length_plays};
            default: rdata = 8'h0;
        endcase
    end

    assign ch_on = ch_dst & {2{~ch_off}};

    assign wave_r =
        (ch_on[0] ? pulse1_wave : 4'h0)
        + (ch_on[1] ? pulse2_wave : 4'h0)
        + (ch_on[2] ? pattern_wave : 4'h0)
        + (ch_on[3] ? noise_wave : 4'h0);

    assign wave_l =
        (ch_on[4] ? pulse1_wave : 4'h0)
        + (ch_on[5] ? pulse2_wave : 4'h0)
        + (ch_on[6] ? pattern_wave : 4'h0)
        + (ch_on[7] ? noise_wave : 4'h0);
    
    assign sound_r = wave_r * ({1'b0, ch_volume[2:0]} + 4'h1);
    assign sound_l = wave_l * ({1'b0, ch_volume[6:4]} + 4'h1);

    always_ff @(posedge clk) begin
        if (reset) begin
            ch_volume <= 8'h0;
            ch_dst <= 8'h0;
            apu_on <= 1'b0;
        end else if (cpu_en & target[0] & write) begin
            ch_volume <= wdata;
        end else if (cpu_en & target[1] & write) begin
            ch_dst <= wdata;
        end else if (cpu_en & target[2] & write) begin
            apu_on <= wdata[7];
        end
    end

    volumes_calc volumes_calc(
        .volumes_raw,
        .ch_volume,
        .ch_dst,
        .volumes
    );
    
endmodule
