module pixel_mixer (
    input  logic [5:0] bg_pixel,
    input  logic [5:0] sp_pixel,

    input  logic sp_master_priority,

    output logic [5:0] mix_pixel
);

    logic sp_priority;

    assign sp_priority = 
        (sp_pixel[1:0] != 2'b00)
            & ((bg_pixel[1:0] == 2'b00) | sp_master_priority | (~(bg_pixel[5] | sp_pixel[5])));

    assign mix_pixel =
            sp_priority ? {1'b1, sp_pixel[4:0]} : {1'b0, bg_pixel[4:0]};

endmodule
