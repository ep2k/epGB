module sprites (
    input  logic clk,
    input  logic slow_clk_en,
    input  logic reset,
    input  logic cgb,

    input  logic [3:0] sp_num,      // 0 ~ 9
    input  logic [7:0] wdata,
    input  logic [3:0] sp_write,    // Tile High, Tile Low, Attrubute, X
    output logic [2:0] sp_info,     // V flip, H flip, Tile Bank

    input  logic [7:0] pixel_x,
    input  logic sp_priority,
    output logic [5:0] sp_pixel
);
    
    logic [7:0] sp_x[9:0];
    logic [7:0] sp_attribute[9:0];
    logic [7:0] sp_tile_low[9:0];
    logic [7:0] sp_tile_high[9:0];

    logic [7:0] sp_dx[9:0];
    logic [9:0] sp_exist;
    logic [9:0] sp_transparent;
    logic [2:0] sp_palette[9:0];

    assign sp_info[2:1] = sp_attribute[sp_num][6:5];
    assign sp_info[0] = cgb ? sp_attribute[sp_num][3] : 1'b0;

    always_ff @(posedge clk) begin
        if (reset) begin
            for (int i = 0; i < 10; i++) begin
                sp_x[i] <= 8'h0;
                sp_attribute[i] <= 8'h0;
                sp_tile_low[i] <= 8'h0;
                sp_tile_high[i] <= 8'h0;
            end
        end else if (pixel_x == 8'd160) begin
            for (int i = 0; i < 10; i++) begin
                sp_x[i] <= 8'h0;
                sp_attribute[i] <= 8'h0;
                sp_tile_low[i] <= 8'h0;
                sp_tile_high[i] <= 8'h0;
            end
        end else if (slow_clk_en) begin
            case (sp_write)
                4'b0001: sp_x[sp_num] <= wdata;
                4'b0010: sp_attribute[sp_num] <= wdata;
                4'b0100: sp_tile_low[sp_num] <= wdata;
                4'b1000: sp_tile_high[sp_num] <= wdata;
                default: ;
            endcase
        end
    end

    genvar gi;
    generate
        for (gi = 0; gi < 10; gi++) begin : LineSpriteCalc
            assign sp_dx[gi] = pixel_x - sp_x[gi] + 8;
            assign sp_exist[gi] = (sp_dx[gi][7:3] == 5'h0); // 0 <= sp_dx[gi] < 8
            assign sp_transparent[gi] =
                ({sp_tile_high[gi][sp_dx[gi]], sp_tile_low[gi][sp_dx[gi]]} == 2'b00);
            assign sp_palette[gi] =
                cgb ? sp_attribute[gi][2:0] : {2'b00, sp_attribute[gi][4]};
        end
    endgenerate

    always_comb begin
        sp_pixel = 6'b0;
        if (~sp_priority) begin
            for (int i = 0; i < 10; i++) begin
                if (sp_exist[i] & (~sp_transparent[i])) begin
                    sp_pixel = {
                            sp_attribute[i][7],
                            sp_palette[i],
                            sp_tile_high[i][sp_dx[i]],
                            sp_tile_low[i][sp_dx[i]]
                        };
                    break;
                end
            end
        end else begin
           for (int dx = 0; dx < 8; dx++) begin
               for (int i = 0; i < 10; i++) begin
                   if ((sp_dx[i] == dx) & (~sp_transparent[i])) begin
                       sp_pixel = {
                            sp_attribute[i][7],
                            sp_palette[i],
                            sp_tile_high[i][sp_dx[i]],
                            sp_tile_low[i][sp_dx[i]]
                        };
                       break;
                   end
               end
           end 
        end
    end

endmodule
