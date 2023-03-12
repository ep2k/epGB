module sp_fetcher (
    input  logic clk,
    input  logic slow_clk_en,

    input  logic sp_enable,
    input  logic [1:0] mode,
    input  logic sp_8x16,

    input  logic [5:0] oam_scan_sp_num,
    input  logic [3:0] oam_scan_fine_y,
    input  logic line_sp_list_write,

    output logic [7:0] oam_fetch_addr,
    output logic [12:0] sp_fetch_addr,
    output logic sp_fetch,

    input  logic [7:0] oam_rdata,
    input  logic [7:0] vram_rdata_bank0,
    input  logic [7:0] vram_rdata_bank1,

    output logic [3:0] line_sp_num,
    input  logic [2:0] sp_info,             // V flip, H flip, Tile Bank
    output logic [7:0] sp_wdata,
    output logic [3:0] sp_write             // Tile High, Tile Low, Attrubute, X
);

    logic [5:0] line_sp_list[9:0];  // スプライト番号リスト
    logic [3:0] fine_y_list[9:0];   // fine_y(タイル内でのライン番号0~15)のリスト
    logic [3:0] line_sp_quantity;   // 走査線上のスプライト数(0~10)

    logic [3:0] line_sp_num_reg;    // 現在フェッチ中のラインスプライト番号
    logic [3:0] counter;            // 0 ~ 9

    logic [7:0] sp_tile_num;


    logic [7:0] sp_tile_num_eff;    // sp8x16,fine_y,垂直反転を考慮したタイル番号
    logic [2:0] fine_y_eff;         // sp8x16,垂直反転を考慮したfine_y

    logic [7:0] tile_data;          // バンク，水平反転を考慮したタイルデータ


    assign sp_fetch =
        sp_enable & (mode == 2'd3) & (line_sp_num_reg != line_sp_quantity);

    assign line_sp_num = line_sp_num_reg;

    always_comb begin
        case (counter)
            4'b001_1: sp_write = 4'b0001; // sp_x[i]
            4'b010_1: sp_write = 4'h0;    // sp_tile_num
            4'b011_1: sp_write = 4'b0010; // sp_attribute[i]
            4'b100_1: sp_write = 4'b0100; // sp_tile_low[i]
            4'b101_1: sp_write = 4'b1000; // sp_tile_high[i]
            default: sp_write = 4'h0;
        endcase
    end

    assign sp_wdata = (counter[3:2] == 2'b10) ? tile_data : oam_rdata;

    assign oam_fetch_addr = {line_sp_list[line_sp_num_reg], counter[2:1]};

    assign sp_fetch_addr = {1'b0, sp_tile_num_eff, fine_y_eff, counter[1]};

    // 8x16スプライトでは下タイルのときLSB=1
    assign sp_tile_num_eff = sp_8x16
                ? {sp_tile_num[7:1], fine_y_list[line_sp_num_reg][3] ^ sp_info[2]}
                : sp_tile_num;

    assign fine_y_eff = sp_info[2]
                ? (~fine_y_list[line_sp_num_reg][2:0])
                : fine_y_list[line_sp_num_reg][2:0];

    // tile_data (水平反転を考慮)
    always_comb begin
        if (sp_info[0]) begin
            tile_data = sp_info[1] ? vram_rdata_bank1
                : {
                    vram_rdata_bank1[0],
                    vram_rdata_bank1[1],
                    vram_rdata_bank1[2],
                    vram_rdata_bank1[3],
                    vram_rdata_bank1[4],
                    vram_rdata_bank1[5],
                    vram_rdata_bank1[6],
                    vram_rdata_bank1[7]
                };
        end else begin
            tile_data = sp_info[1] ? vram_rdata_bank0
                : {
                    vram_rdata_bank0[0],
                    vram_rdata_bank0[1],
                    vram_rdata_bank0[2],
                    vram_rdata_bank0[3],
                    vram_rdata_bank0[4],
                    vram_rdata_bank0[5],
                    vram_rdata_bank0[6],
                    vram_rdata_bank0[7]
                };
        end
    end


    // OAM scan

    always_ff @(posedge clk) begin
        if (slow_clk_en) begin
            if ((mode == 2'd0) | (mode == 2'd1)) begin
                line_sp_quantity <= 4'd0;
            end else if (line_sp_list_write) begin
                line_sp_quantity <= line_sp_quantity + 4'd1;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (slow_clk_en & line_sp_list_write) begin
            line_sp_list[line_sp_quantity] <= oam_scan_sp_num;
            fine_y_list[line_sp_quantity] <= oam_scan_fine_y;
        end
    end

    // Sprite fetch

    always_ff @(posedge clk) begin
        if (slow_clk_en) begin
            if ((~sp_fetch) | (~sp_enable)) begin
                counter <= 4'b001_0;
            end else begin
                counter <= (counter == 4'b101_1) ? 4'b001_0 : (counter + 4'd1);
            end
        end
    end

    always_ff @(posedge clk) begin
        if (slow_clk_en & (counter == 4'b010_1)) begin
            sp_tile_num <= oam_rdata;
        end
    end

    always_ff @(posedge clk) begin
        if (slow_clk_en & (mode != 2'd3)) begin
            line_sp_num_reg <= 4'd0;
        end else if (slow_clk_en & sp_fetch & (counter == 4'b101_1)) begin
            line_sp_num_reg <= line_sp_num_reg + 4'd1;
        end
    end

endmodule
