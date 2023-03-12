module addr_decoder (
    input  logic [15:0] addr,
    input  logic [12:0] ppu_vram_addr,
    input  logic [7:0] ppu_oam_addr,
    input  logic [15:0] oamdma_src_addr,
    input  logic [15:0] hdma_src_addr,
    input  logic [12:0] hdma_vram_addr,

    input  logic oam_block,
    input  logic vram_block,
    input  logic oamdma,
    input  logic hdma,

    output logic [15:0] cart_addr,
    output logic [7:0] boot_addr,
    output logic [12:0] vram_addr,
    output logic [12:0] wram_addr,
    output logic [7:0] oam_addr,
    output logic [6:0] hram_addr,
    output logic [6:0] io_addr,
    output logic int_reg_select,

    output logic cart_target,
    output logic boot_target,
    output logic vram_target,
    output logic wram_target,
    output logic oam_target,
    output logic hram_target,
    output logic io_target,
    output logic int_target
);

    logic [15:0] addr_eff;

    always_comb begin
        if (oamdma) begin
            addr_eff = oamdma_src_addr;
        end else if (hdma) begin
            addr_eff = hdma_src_addr;
        end else begin
            addr_eff = addr;
        end
    end

    always_comb begin
        if (hdma) begin
            vram_addr = hdma_vram_addr;
        end else if (vram_block) begin
            vram_addr = ppu_vram_addr;
        end else begin
            vram_addr = addr_eff[12:0];
        end
    end

    assign cart_addr = addr_eff;
    assign boot_addr = addr_eff[7:0];
    assign wram_addr = addr_eff[12:0];
    assign oam_addr = (oamdma | oam_block) ? ppu_oam_addr : addr_eff[7:0];
    assign hram_addr = hdma ? addr_eff[6:0] : addr[6:0];
    assign io_addr = addr_eff[6:0];
    assign int_reg_select = ~addr_eff[4]; // 0: IE, 1: IF

    assign cart_target = (~addr_eff[15]) | (addr_eff[15:13] == 3'b101);
    assign boot_target = (addr_eff[15:8] == 8'h00);
    assign vram_target = (addr_eff[15:13] == 3'b100);
    assign wram_target = (addr_eff[15:8] >= 8'hc0) & (addr_eff[15:8] < 8'hfe);
    assign oam_target = (addr_eff[15:8] == 8'hfe) & (addr_eff[7:0] < 8'ha0);
    assign hram_target = hdma
        ? ((addr_eff[15:7] == 9'b1111_1111_1) & (addr_eff != 16'hffff))
        : ((addr[15:7] == 9'b1111_1111_1) & (addr != 16'hffff));
    assign io_target = (addr_eff[15:7] == 9'b1111_1111_0) & (~int_target);
    assign int_target = (addr_eff == 16'hffff) | (addr_eff == 16'hff0f); // IE, IF
    
endmodule
