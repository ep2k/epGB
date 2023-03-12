module bg_renderer (
    input  logic clk,
    input  logic slow_clk_en,
    input  logic cgb,

    input  logic [1:0] mode,
    input  logic bg_enable,
    input  logic win_enable,
    input  logic sp_fetch,

    input  logic [7:0] ly,
    input  logic [15:0] scroll,
    input  logic [15:0] win_position,
    input  logic bg_tile_map_area,
    input  logic win_tile_map_area,
    input  logic tile_data_area,

    output logic [12:0] bg_fetch_addr,
    input  logic [7:0] vram_rdata_bank0,
    input  logic [7:0] vram_rdata_bank1,

    output logic [7:0] pixel_x,             // -23 ~ 159

    output logic [5:0] bg_pixel,
    output logic fetch_finish,
    output logic rendering
);

    logic [7:0] counter;        // bg_tile_x(5bit), step0~7(3bit)
    logic [7:0] win_ly;         // increment if (wx, wy) is in display
    logic in_win_y;             // be triggerd if LY == WY

    logic [15:0] tile_low_fifo, tile_high_fifo;
    logic [3:0] attribute_top, attribute_bottom;

    logic [7:0] next_tile_num, next_attribute, next_tile_low; //next_tile_high;

    logic in_win = 1'b0;

    logic [4:0] world_tile_x;
    logic [7:0] world_y;

    logic win_start;

    logic [2:0] fine_y;

    logic [12:0] tile_num_addr, tile_data_addr;
    logic [7:0] fetch_tile_data, fetch_tile_data_eff; // effは水平反転を考慮

    logic fetch_finish_time;


    assign bg_pixel = bg_enable ? {
                        cgb ? attribute_top : 4'h0,
                        tile_high_fifo[15],
                        tile_low_fifo[15]
                    } : 6'h0;
    
    assign bg_fetch_addr = (counter[2:1] == 2'b01) ? tile_num_addr : tile_data_addr;

    assign world_tile_x = scroll[7:3] + counter[7:3];
    assign world_y = scroll[15:8] + ly;

    assign win_start =
            (mode == 2'd3) & win_enable & in_win_y
                & (win_position[7:0] < 8'd167)
                & ((pixel_x + 8'd14) == win_position[7:0]);

    assign tile_num_addr = in_win
            ? {2'b11, win_tile_map_area, win_ly[7:3], counter[7:3]}
            : {2'b11, bg_tile_map_area, world_y[7:3], world_tile_x};

    assign fine_y = in_win ? win_ly[2:0] : world_y[2:0];

    assign tile_data_addr = {
            (~tile_data_area) & (~next_tile_num[7]),
            next_tile_num,
            (cgb & next_attribute[6]) ? ~fine_y : fine_y, // 垂直反転
            counter[1] // high_fetch
        };
    
    assign fetch_tile_data = (cgb & next_attribute[3])
                    ? vram_rdata_bank1 : vram_rdata_bank0;
    assign fetch_tile_data_eff = (cgb & next_attribute[5]) ? {
                    fetch_tile_data[0],
                    fetch_tile_data[1],
                    fetch_tile_data[2],
                    fetch_tile_data[3],
                    fetch_tile_data[4],
                    fetch_tile_data[5],
                    fetch_tile_data[6],
                    fetch_tile_data[7]
            } : fetch_tile_data;

    always_ff @(posedge clk) begin
        if (slow_clk_en) begin
            if ((mode == 2'd2) | sp_fetch) begin
                counter <= 8'b0;
            end else if (win_start) begin
                counter <= 8'd2;
            end else begin
                counter <= counter + 8'd1;
            end 
        end
    end

    always_ff @(posedge clk) begin
        if (slow_clk_en) begin
            case (counter[2:0])
                3'b011: begin
                        next_tile_num <= vram_rdata_bank0;
                        next_attribute <= vram_rdata_bank1;
                    end
                3'b101: next_tile_low <= fetch_tile_data_eff;
                // 3'b111: next_tile_high <= fetch_tile_data_eff;
                default: ;
            endcase
        end
    end

    always_ff @(posedge clk) begin
        if (slow_clk_en) begin
            if (counter[2:0] == 3'd7) begin
                if (in_win) begin
                    tile_low_fifo[15:8] <= next_tile_low;
                    tile_high_fifo[15:8] <= fetch_tile_data_eff;
                    attribute_top <= {next_attribute[7], next_attribute[2:0]};
                end else begin
                    tile_low_fifo <= {tile_low_fifo[14:7], next_tile_low};
                    tile_high_fifo <= {tile_high_fifo[14:7], fetch_tile_data_eff};
                    attribute_top <= attribute_bottom;
                    attribute_bottom <= {next_attribute[7], next_attribute[2:0]};
                end
            end else begin
                tile_low_fifo <= {tile_low_fifo[14:0], 1'b0};
                tile_high_fifo <= {tile_high_fifo[14:0], 1'b0};
            end
        end
    end

    always_ff @(posedge clk) begin
        if (slow_clk_en) begin
            if ((mode == 2'd2) | sp_fetch) begin
                pixel_x <= -16 - scroll[2:0];
            end else begin
                pixel_x <= pixel_x + 8'd1;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (slow_clk_en) begin
            if (mode == 2'd2) begin
                in_win <= 1'b0;
            end else if (win_start) begin
                in_win <= 1'b1;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (slow_clk_en) begin
            if (mode == 2'd1) begin
                in_win_y <= 1'b0;
            end else if ((mode == 2'd2) & (ly == win_position[15:8])) begin
                in_win_y <= 1'b1;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (slow_clk_en) begin
            if (mode == 2'd1) begin
                win_ly <= 8'hff;
            end else if (win_start) begin
                win_ly <= win_ly + 8'h1;
            end
        end
    end

    assign fetch_finish_time =
            (mode == 2'd3) & ((in_win & (pixel_x >= 8'd150) & (pixel_x < 8'd192) & (counter[2:0] == 3'd7))
                | (
                    ((~win_enable) | (~in_win_y) | (win_position[7:0] > 8'd166))
                        & (counter == 8'b10100_111)
                ));

    always_ff @(posedge clk) begin
        if (slow_clk_en) begin
            if (mode == 2'd2) begin
                fetch_finish <= 1'b0;
            end else if (fetch_finish_time) begin
                fetch_finish <= 1'b1;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (slow_clk_en) begin
            if (mode[1] ^ mode[0]) begin // モード1, 2
                rendering <= 1'b0;
            end else if ((mode == 2'd3) & (pixel_x == 8'hff)) begin
                rendering <= 1'b1;
            end else if (pixel_x == 8'd159) begin
                rendering <= 1'b0;
            end
        end
    end
    
endmodule
