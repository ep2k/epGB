module apu_decoder (
    input  logic [5:0] reg_select,

    output logic [4:0] pulse1_target,
    output logic [4:0] pulse2_target,
    output logic [4:0] pattern_target,
    output logic [4:1] noise_target,
    output logic [2:0] control_target
);
    
    assign pulse1_target = {
        reg_select == 6'h14,
        reg_select == 6'h13,
        reg_select == 6'h12,
        reg_select == 6'h11,
        reg_select == 6'h10
    };

    assign pulse2_target = {
        reg_select == 6'h19,
        reg_select == 6'h18,
        reg_select == 6'h17,
        reg_select == 6'h16,
        1'b0
    };

    assign pattern_target = {
        reg_select == 6'h1e,
        reg_select == 6'h1d,
        reg_select == 6'h1c,
        reg_select == 6'h1b,
        reg_select == 6'h1a
    };

    assign noise_target = {
        reg_select == 6'h23,
        reg_select == 6'h22,
        reg_select == 6'h21,
        reg_select == 6'h20
    };

    assign control_target = {
        reg_select == 6'h26,
        reg_select == 6'h25,
        reg_select == 6'h24
    };

endmodule
