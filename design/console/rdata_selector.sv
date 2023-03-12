module rdata_selector (
    input  logic [7:0] cart_rdata,
    input  logic [7:0] boot_rdata,
    input  logic [7:0] vram_rdata,
    input  logic [7:0] wram_rdata,
    input  logic [7:0] oam_rdata,
    input  logic [7:0] hram_rdata,
    input  logic [7:0] int_rdata,

    input  logic [7:0] joypad_rdata,
    input  logic [7:0] serial_rdata,
    input  logic [7:0] timer_rdata,
    input  logic [7:0] apu_rdata,
    input  logic [7:0] ppu_rdata,
    input  logic [7:0] cgb_rdata,
    input  logic [7:0] clk_rdata,
    input  logic [7:0] vram_bank_rdata,
    input  logic [7:0] bootmode_rdata,
    input  logic [7:0] hdma_rdata,
    input  logic [7:0] infrared_rdata,
    input  logic [7:0] wram_bank_rdata,
    input  logic [7:0] un_reg_rdata,

    input  logic cart_target,
    input  logic boot_target,
    input  logic vram_target,
    input  logic wram_target,
    input  logic oam_target,
    input  logic hram_target,
    input  logic int_target,

    input  logic joypad_target,
    input  logic serial_target,
    input  logic timer_target,
    input  logic apu_target,
    input  logic ppu_target,
    input  logic cgb_target,
    input  logic clk_target,
    input  logic vram_bank_target,
    input  logic bootmode_target,
    input  logic hdma_target,
    input  logic infrared_target,
    input  logic wram_bank_target,
    input  logic un_reg_target,

    input  logic use_cart,
    input  logic vram_block,
    input  logic oam_block,
    input  logic oamdma,

    output logic [7:0] cpu_rdata,
    output logic [7:0] dma_rdata
);

    logic [7:0] rdata;

    assign cpu_rdata = oamdma ? (hram_target ? hram_rdata : 8'hff) : rdata; // OAM DMA中はHRAMにのみアクセス可能
    assign dma_rdata = rdata;

    always_comb begin
        if (boot_target) begin
            rdata = use_cart ? cart_rdata : boot_rdata;
        end else if (cart_target) begin
            rdata = cart_rdata;
        end else if (vram_target) begin
            rdata = vram_block ? 8'hff : vram_rdata;
        end else if (wram_target) begin
            rdata = wram_rdata;
        end else if (oam_target) begin
            rdata = oam_block ? 8'hff : oam_rdata;
        end else if (int_target) begin
            rdata = int_rdata;
        end else if (joypad_target) begin
            rdata = joypad_rdata;
        end else if (serial_target) begin
            rdata = serial_rdata;
        end else if (timer_target) begin
            rdata = timer_rdata;
        end else if (apu_target) begin
            rdata = apu_rdata;
        end else if (ppu_target) begin
            rdata = ppu_rdata;
        end else if (cgb_target) begin
            rdata = cgb_rdata;
        end else if (clk_target) begin
            rdata = clk_rdata;
        end else if (vram_bank_target) begin
            rdata = vram_bank_rdata;
        end else if (bootmode_target) begin
            rdata = bootmode_rdata;
        end else if (hdma_target) begin
            rdata = hdma_rdata;
        end else if (infrared_target) begin
            rdata = infrared_rdata;
        end else if (wram_bank_target) begin
            rdata = wram_bank_rdata;
        end else if (un_reg_target) begin
            rdata = un_reg_rdata;
        end else if (hram_target) begin
            rdata = hram_rdata;
        end else begin
            rdata = 8'hff;
        end
    end
    
endmodule
