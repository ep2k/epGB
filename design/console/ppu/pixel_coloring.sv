module pixel_coloring (
    input  logic clk,
    input  logic cpu_en,
    input  logic reset,
    input  logic ppu_enable,

    input  logic [5:0] mix_pixel,
    output logic [14:0] pixel_color,

    input  logic cgb,
    input  logic [23:0] dmg_palettes,

    input  logic [5:0] bg_palette_addr,
    input  logic [5:0] sp_palette_addr,
    output logic [7:0] bg_palette_rdata,
    output logic [7:0] sp_palette_rdata,
    input  logic [7:0] palette_wdata,
    input  logic [1:0] palette_write
);

    logic [14:0] cgb_pixel_color;
    logic [1:0] dmg_pixel_color;

    always_comb begin
        if (ppu_enable) begin
            pixel_color = cgb ? cgb_pixel_color : {13'h0, dmg_pixel_color};
        end else begin
            pixel_color = 15'h0;
        end
    end

    always_comb begin
        unique casez (mix_pixel)
            6'b0_???_00: dmg_pixel_color = dmg_palettes[1:0];
            6'b0_???_01: dmg_pixel_color = dmg_palettes[3:2];
            6'b0_???_10: dmg_pixel_color = dmg_palettes[5:4];
            6'b0_???_11: dmg_pixel_color = dmg_palettes[7:6];
            // 6'b1_??0_00: dmg_pixel_color = dmg_palettes[9:8];
            6'b1_??0_00: dmg_pixel_color = 2'b00;
            6'b1_??0_01: dmg_pixel_color = dmg_palettes[11:10];
            6'b1_??0_10: dmg_pixel_color = dmg_palettes[13:12];
            6'b1_??0_11: dmg_pixel_color = dmg_palettes[15:14];
            // 6'b1_??1_00: dmg_pixel_color = dmg_palettes[17:16];
            6'b1_??1_00: dmg_pixel_color = 2'b00;
            6'b1_??1_01: dmg_pixel_color = dmg_palettes[19:18];
            6'b1_??1_10: dmg_pixel_color = dmg_palettes[21:20];
            6'b1_??1_11: dmg_pixel_color = dmg_palettes[23:22];
        endcase
    end

    cgb_palettes cgb_palettes(
        .clk,
        .cpu_en,
        .reset,

        .palette_num(mix_pixel[4:2]),
        .color_num(mix_pixel[1:0]),
        .is_sp(mix_pixel[5]),
        .color(cgb_pixel_color),

        .bg_palette_addr,
        .sp_palette_addr,
        .bg_palette_rdata,
        .sp_palette_rdata,
        .wdata(palette_wdata),
        .write(palette_write)
    );
    
endmodule
