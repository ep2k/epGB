module ppu (
    input  logic clk,
    input  logic slow_clk_en,
    input  logic cpu_en,
    input  logic reset,
    input  logic cgb,

    input  logic [4:0] reg_select,
    output logic [7:0] rdata,
    input  logic [7:0] wdata,
    input  logic write,

    output logic oam_block,
    output logic vram_block,

    output logic [7:0] oam_addr,
    input  logic [7:0] oam_rdata,
    output logic [12:0] vram_addr,
    input  logic [7:0] vram_rdata_bank0,
    input  logic [7:0] vram_rdata_bank1,

    output logic vblank_int,
    output logic ppu_int,

    output logic oamdma,
    output logic [15:0] oamdma_src_addr,
    output logic oamdma_write,

    output logic hblank_start,

    output logic ppu_enable,
    output logic [15:0] pixel_num,
    output logic [14:0] pixel_color,
    output logic pixel_write
);

    logic [7:0] control;
    logic [3:0] int_enable;
    logic [15:0] scroll, win_position;
    logic [23:0] dmg_palettes;
    logic [5:0] bg_palette_addr, sp_palette_addr;

    logic [7:0] oamdma_start_addr;
    logic oamdma_start;

    logic [7:0] bg_palette_rdata, sp_palette_rdata;
    logic [1:0] palette_write;
    logic palette_block;

    logic [8:0] hori_counter;
    logic [7:0] ly, pixel_x;
    logic [1:0] mode;
    logic ly_compare, sp_priority;
    logic sp_fetch, fetch_finish, rendering;

    logic bg_enable, win_enable, sp_enable;

    logic [7:0] oam_scan_addr, oamdma_oam_addr, oam_fetch_addr;
    logic [12:0] bg_fetch_addr, sp_fetch_addr;

    logic [5:0] oam_scan_sp_num;
    logic [3:0] oam_scan_fine_y;
    logic line_sp_list_write;

    logic [5:0] bg_pixel, sp_pixel, mix_pixel;

    logic draw_frame = 1'b0;


    assign ppu_enable = control[7];
    assign pixel_num = {ly, pixel_x};
    assign pixel_write = rendering & draw_frame;

    assign bg_enable = control[0] | cgb;
    assign win_enable = control[5];
    assign sp_enable = control[1] & (~oamdma);

    assign vram_block = ppu_enable & (bg_enable | sp_enable) & (mode == 2'd3);
    assign oam_block = ppu_enable & sp_enable & mode[1];
    assign palette_block = vram_block;

    always_comb begin
        if (oamdma) begin
            oam_addr = oamdma_oam_addr;
        end else if (mode == 2'd2) begin
            oam_addr = oam_scan_addr;
        end else begin
            oam_addr = oam_fetch_addr;
        end
    end

    assign vram_addr = sp_fetch ? sp_fetch_addr : bg_fetch_addr;
    

    always_ff @(posedge clk) begin
        if (reset) begin
            draw_frame <= 1'b0;
        end else if (slow_clk_en) begin
            if (~ppu_enable) begin
                draw_frame <= 1'b0;
            end else if (mode == 2'd1) begin
                draw_frame <= 1'b1; // PPUオン直後の1フレームは描画しない
            end
        end
    end

    ppu_registers ppu_registers(
        .clk,
        .slow_clk_en,
        .cpu_en,
        .reset,
        .cgb,

        .reg_select,
        .rdata,
        .wdata,
        .write,

        .ppu_enable,
        .mode,
        .ly,
        .bg_palette_rdata,
        .sp_palette_rdata,
        .palette_block,

        .control,
        .int_enable,
        .scroll,
        .win_position,
        .ly_compare,
        .dmg_palettes,
        .bg_palette_addr,
        .sp_palette_addr,
        .sp_priority,

        .oamdma_start_addr,
        .oamdma_start,

        .palette_write
    );

    timing_controller timing_controller(
        .clk,
        .slow_clk_en,
        .reset,

        .ppu_enable,
        .fetch_finish,
        
        .hori_counter,
        .ly,
        .mode,
        .hblank_start
    );

    ppu_int_controller ppu_int_controller(
        .clk,
        .cpu_en,

        .ppu_enable,
        .int_enable,
        .ly_compare,
        .mode,

        .vblank_int,
        .ppu_int
    );

    oam_scan_controller oam_scan_controller(
        .sp_enable,
        .mode,
        .sp_8x16(control[2]),
        .hori_counter,
        .ly,

        .oam_rdata,

        .oam_scan_addr,
        .sp_num(oam_scan_sp_num),
        .fine_y(oam_scan_fine_y),
        .line_sp_list_write
    );

    oamdma_controller oamdma_controller(
        .clk,
        .cpu_en,
        .reset,

        .oamdma_start_addr,
        .oamdma_start,

        .oamdma,
        .oamdma_src_addr,
        .oamdma_oam_addr,
        .oamdma_write
    );

    bg_renderer bg_renderer(
        .clk,
        .slow_clk_en,
        .cgb,

        .mode,
        .bg_enable,
        .win_enable,
        .sp_fetch,

        .ly,
        .scroll,
        .win_position,
        .bg_tile_map_area(control[3]),
        .win_tile_map_area(control[6]),
        .tile_data_area(control[4]),

        .bg_fetch_addr,
        .vram_rdata_bank0,
        .vram_rdata_bank1,

        .pixel_x,

        .bg_pixel,
        .fetch_finish,
        .rendering
    );

    sp_renderer sp_renderer(
        .clk,
        .slow_clk_en,
        .reset,
        .cgb,

        .sp_enable,
        .mode,
        .sp_8x16(control[2]),
        .sp_priority(sp_priority | (~cgb)), // 1で座標優先
        
        .oam_scan_sp_num,
        .oam_scan_fine_y,
        .line_sp_list_write,

        .oam_fetch_addr,
        .sp_fetch_addr,
        .sp_fetch,

        .oam_rdata,
        .vram_rdata_bank0,
        .vram_rdata_bank1,

        .pixel_x,
        .sp_pixel
    );

    pixel_mixer pixel_mixer(
        .bg_pixel,
        .sp_pixel,

        .sp_master_priority(cgb & (~control[0])),

        .mix_pixel
    );

    pixel_coloring pixel_coloring(
        .clk,
        .cpu_en,
        .reset,
        .ppu_enable,

        .mix_pixel,
        .pixel_color,

        .cgb,
        .dmg_palettes,

        .bg_palette_addr,
        .sp_palette_addr,
        .bg_palette_rdata,
        .sp_palette_rdata,
        .palette_wdata(wdata),
        .palette_write
    );
    
endmodule
