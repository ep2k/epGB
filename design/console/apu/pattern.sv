module pattern (
    input  logic clk,
    input  logic slow_clk_en,
    input  logic cpu_en,
    input  logic clk256_en,
    input  logic reset,
    
    input  logic [4:0] target,
    output logic [7:0] rdata,
    input  logic [7:0] wdata,
    input  logic write,

    input  logic [3:0] ram_addr,
    output logic [7:0] ram_rdata,
    input  logic ram_write,

    output logic [3:0] wave,
    output logic length_play,
    output logic [3:0] volume_out
);

    logic [3:0] wave_raw, wave_volume;

    logic init, next_step;
    logic length_enable;
    logic length_play_raw;

    logic play = 1'b0;

    logic [1:0] volume;

    assign init = cpu_en & write & target[4] & wdata[7];

    assign wave = (play & length_play) ? wave_volume : 4'h0;
    assign length_play = length_play_raw & play;
    assign volume_out = length_play ? {volume, 2'b00} : 4'h0;

    always_comb begin
        priority casez (target)
            5'b00001: rdata = {play, 7'h7f};
            5'b0001?: rdata = 8'hff;
            5'b001??: rdata = {1'b1, volume, 5'h1f};
            5'b01???: rdata = 8'hff;
            5'b1????: rdata = {1'b1, length_enable, 6'h3f};
            default: rdata = 8'h00;
        endcase
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            play <= 1'b0;
        end else if (cpu_en & write & target[0]) begin
            play <= wdata[7];
        end
    end

    freq_counter freq_counter(
        .clk,
        .slow_clk_en,
        .reset,

        .new_freq({wdata[2:0], wdata}),
        .write_freq_low(cpu_en & write & target[3]),
        .write_freq_high(cpu_en & write & target[4]),
        
        .next_step
    );

    pattern_ram pattern_ram(
        .clk,
        .slow_clk_en,
        .cpu_en,
        .reset,

        .addr(ram_addr),
        .rdata(ram_rdata),
        .wdata,
        .write(ram_write),

        .init,
        .next_step,

        .wave(wave_raw)
    );

    pattern_volume pattern_volume(
        .clk,
        .cpu_en,
        .reset,

        .new_volume(wdata[6:5]),
        .write(write & target[2]),
        .volume,

        .wave_raw,
        .wave_volume
    );
    
    length_counter #(.WIDTH(8)) length_counter(
        .clk,
        .slow_clk_en,
        .cpu_en,
        .clk256_en,
        .reset,

        .init,

        .new_length(wdata),
        .length_write(write & target[1]),

        .new_enable(wdata[6]),
        .enable_write(write & target[4]),
        .enable(length_enable),

        .play(length_play_raw)
    );
    
endmodule
