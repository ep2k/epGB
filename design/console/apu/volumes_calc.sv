module volumes_calc (
    input  logic [15:0] volumes_raw,
    input  logic [7:0] ch_volume,
    input  logic [7:0] ch_dst,
    output logic [15:0] volumes
);
    
    logic [7:0] pulse1_volume, pulse2_volume, pattern_volume, noise_volume;

    assign pulse1_volume = (
            (ch_dst[0] ? ({2'b0, ch_volume[2:0]} + 5'h1) : 5'h0)
            + (ch_dst[4] ? ({2'b0, ch_volume[6:4]} + 5'h1) : 5'h0)
        ) * volumes_raw[3:0];
        
    assign pulse2_volume = (
            (ch_dst[1] ? ({2'b0, ch_volume[2:0]} + 5'h1) : 5'h0)
            + (ch_dst[5] ? ({2'b0, ch_volume[6:4]} + 5'h1) : 5'h0)
        ) * volumes_raw[7:4];

    assign pattern_volume = (
            (ch_dst[2] ? ({2'b0, ch_volume[2:0]} + 5'h1) : 5'h0)
            + (ch_dst[6] ? ({2'b0, ch_volume[6:4]} + 5'h1) : 5'h0)
        ) * volumes_raw[11:8];

    assign noise_volume = (
            (ch_dst[3] ? ({2'b0, ch_volume[2:0]} + 5'h1) : 5'h0)
            + (ch_dst[7] ? ({2'b0, ch_volume[6:4]} + 5'h1) : 5'h0)
        ) * volumes_raw[15:12];

    assign volumes = {
        noise_volume[7:4],
        pattern_volume[7:4],
        pulse2_volume[7:4],
        pulse1_volume[7:4]
    };

endmodule
