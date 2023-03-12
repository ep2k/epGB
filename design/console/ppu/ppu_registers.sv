module ppu_registers (
    input  logic clk,
    input  logic slow_clk_en,
    input  logic cpu_en,
    input  logic reset,
    input  logic cgb,
    
    input  logic [4:0] reg_select,
    output logic [7:0] rdata,
    input  logic [7:0] wdata,
    input  logic write,

    input  logic ppu_enable,
    input  logic [1:0] mode,
    input  logic [7:0] ly,
    input  logic [7:0] bg_palette_rdata,
    input  logic [7:0] sp_palette_rdata,
    input  logic palette_block,

    output logic [7:0] control,
    output logic [3:0] int_enable,
    output logic [15:0] scroll,
    output logic [15:0] win_position,
    output logic ly_compare = 1'b0,
    output logic [23:0] dmg_palettes,
    output logic [5:0] bg_palette_addr,
    output logic [5:0] sp_palette_addr,
    output logic sp_priority,

    output logic [7:0] oamdma_start_addr,
    output logic oamdma_start,

    output logic [1:0] palette_write
);

    logic [7:0] control_reg = 8'h0;     // LCDC
    logic [3:0] int_enable_reg = 4'h0;  // STAT[6:3]
    logic [7:0] scy = 8'h0;
    logic [7:0] scx = 8'h0;
    logic [7:0] lyc = 8'h0;
    logic [7:0] wy = 8'h0;
    logic [7:0] wx = 8'h0;
    logic [7:0] bg_palette = 8'h0;
    logic [7:0] sp_palette_0 = 8'h0;
    logic [7:0] sp_palette_1 = 8'h0;

    logic [6:0] bg_palette_index = 7'h0;
    logic [6:0] sp_palette_index = 7'h0;
    logic sp_priority_reg = 1'b0;

    logic [7:0] oamdma_start_addr_reg = 8'h0;

    assign control = control_reg;
    assign int_enable = int_enable_reg;
    assign scroll = {scy, scx};
    assign win_position = {wy, wx};
    assign dmg_palettes = {sp_palette_1, sp_palette_0, bg_palette};
    assign bg_palette_addr = bg_palette_index[5:0];
    assign sp_palette_addr = sp_palette_index[5:0];
    assign sp_priority = sp_priority_reg;
    assign oamdma_start_addr = oamdma_start_addr_reg;

    assign oamdma_start = (reg_select == 5'h6) & write & (wdata[7:5] != 3'b111);
    assign palette_write[0] = (reg_select == 5'b1_0001) & write & (~palette_block);
    assign palette_write[1] = (reg_select == 5'b1_0011) & write & (~palette_block);
    
    always_comb begin
        casez ({cgb, reg_select})
            6'b?0_0000: rdata = control_reg;
            6'b?0_0001: rdata = {1'b1, int_enable_reg, ly_compare, mode}; // STAT
            6'b?0_0010: rdata = scy;
            6'b?0_0011: rdata = scx;
            6'b?0_0100: rdata = ly;
            6'b?0_0101: rdata = lyc;
            6'b?0_0110: rdata = oamdma_start_addr_reg;
            6'b?0_0111: rdata = bg_palette;
            6'b?0_1000: rdata = sp_palette_0;
            6'b?0_1001: rdata = sp_palette_1;
            6'b?0_1010: rdata = wy;
            6'b?0_1011: rdata = wx;
            6'b11_0000: rdata = {bg_palette_index[6], 1'b1, bg_palette_index[5:0]};
            6'b11_0001: rdata = bg_palette_rdata;
            6'b11_0010: rdata = {sp_palette_index[6], 1'b1, sp_palette_index[5:0]};
            6'b11_0011: rdata = sp_palette_rdata;
            6'b11_0100: rdata = {7'b1111_111, sp_priority_reg};
            default: rdata = 8'hff;
        endcase
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            control_reg <= 8'h0;
            int_enable_reg <= 4'h0;
            {scy, scx} <= 16'h0;
            {wy, wx} <= 16'h0;
            lyc <= 8'h0;
            {sp_palette_1, sp_palette_0, bg_palette} <= 24'h0;
            {sp_palette_index, bg_palette_index} <= 14'h0;
            sp_priority_reg <= 1'b0;
            oamdma_start_addr_reg <= 8'h0;
        end else if (cpu_en & write) begin
            case (reg_select)
                5'b0_0000: control_reg <=
                    {wdata[7:6], wdata[5] & (cgb | wdata[0]), wdata[4:0]};
                5'b0_0001: int_enable_reg <= wdata[6:3];
                5'b0_0010: scy <= wdata;
                5'b0_0011: scx <= wdata;
                5'b0_0101: lyc <= wdata;
                5'b0_0110: oamdma_start_addr_reg <= wdata;
                5'b0_0111: bg_palette <= wdata;
                5'b0_1000: sp_palette_0 <= wdata;
                5'b0_1001: sp_palette_1 <= wdata;
                5'b0_1010: wy <= wdata;
                5'b0_1011: wx <= wdata;
                5'b1_0000: bg_palette_index <= {wdata[7], wdata[5:0]};
                5'b1_0001: begin
                        if (bg_palette_index[6]) begin
                            bg_palette_index[5:0] <= bg_palette_index[5:0] + 6'h1;
                        end
                    end
                5'b1_0010: sp_palette_index <= {wdata[7], wdata[5:0]};
                5'b1_0011: begin
                        if (sp_palette_index[6]) begin
                            sp_palette_index[5:0] <= sp_palette_index[5:0] + 6'h1;
                        end
                    end
                5'b1_0100: sp_priority_reg <= wdata[0];
                default: ;
            endcase
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            ly_compare <= 1'b0;
        end else if (slow_clk_en & ppu_enable) begin
            ly_compare <= (ly == lyc); // [TODO] lyc=0のときは割り込みしない?
        end
    end
    
endmodule
