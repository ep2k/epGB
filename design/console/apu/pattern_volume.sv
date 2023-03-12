module pattern_volume (
    input  logic clk,
    input  logic cpu_en,
    input  logic reset,

    input  logic [1:0] new_volume,
    input  logic write,
    output logic [1:0] volume = 2'b00,

    input  logic [3:0] wave_raw,
    output logic [3:0] wave_volume
);

    always_comb begin
        unique case (volume)
            2'b00: wave_volume = 4'h0;
            2'b01: wave_volume = wave_raw;
            2'b10: wave_volume = {1'b0, wave_raw[3:1]};
            2'b11: wave_volume = {2'b00, wave_raw[3:2]};
        endcase
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            volume <= 2'b00;
        end else if (cpu_en & write) begin
            volume <= new_volume;
        end
    end
    
endmodule
