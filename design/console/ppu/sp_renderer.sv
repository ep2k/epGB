module sp_renderer (
    input  logic clk,
    input  logic slow_clk_en,
    input  logic reset,
    input  logic cgb,

    input  logic sp_enable,
    input  logic [1:0] mode,
    input  logic sp_8x16,
    input  logic sp_priority,

    input  logic [5:0] oam_scan_sp_num,
    input  logic [3:0] oam_scan_fine_y,
    input  logic line_sp_list_write,

    output logic [7:0] oam_fetch_addr,
    output logic [12:0] sp_fetch_addr,
    output logic sp_fetch,

    input  logic [7:0] oam_rdata,
    input  logic [7:0] vram_rdata_bank0,
    input  logic [7:0] vram_rdata_bank1,

    input  logic [7:0] pixel_x,
    output logic [5:0] sp_pixel
);

    logic [3:0] line_sp_num;
    logic [2:0] sp_info;
    logic [7:0] sp_wdata;
    logic [3:0] sp_write;

    logic [5:0] sp_pixel_raw;

    assign sp_pixel = sp_enable ? sp_pixel_raw : 6'h0;

    sprites sprites(
        .clk,
        .slow_clk_en,
        .reset,
        .cgb,

        .sp_num(line_sp_num),
        .wdata(sp_wdata),
        .sp_write,
        .sp_info,

        .pixel_x,
        .sp_priority,
        .sp_pixel(sp_pixel_raw)
    );

    sp_fetcher sp_fetcher(
        .clk,
        .slow_clk_en,
        
        .sp_enable,
        .mode,
        .sp_8x16,

        .oam_scan_sp_num,
        .oam_scan_fine_y,
        .line_sp_list_write,

        .oam_fetch_addr,
        .sp_fetch_addr,
        .sp_fetch,

        .oam_rdata,
        .vram_rdata_bank0,
        .vram_rdata_bank1,

        .line_sp_num,
        .sp_info,
        .sp_wdata,
        .sp_write
    );
    
endmodule
