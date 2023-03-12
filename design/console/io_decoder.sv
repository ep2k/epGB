module io_decoder (
    input  logic [6:0] addr,
    input  logic target,

    output logic serial_reg_select,
    output logic [1:0] timer_reg_select,
    output logic [5:0] apu_reg_select,
    output logic [4:0] ppu_reg_select,
    output logic [2:0] hdma_reg_select,
    output logic [2:0] un_reg_select,

    output logic joypad_target,
    output logic serial_target,
    output logic timer_target,
    output logic apu_target,
    output logic ppu_target,
    output logic cgb_target,
    output logic clk_target,
    output logic vram_bank_target,
    output logic bootmode_target,
    output logic hdma_target,
    output logic infrared_target,
    output logic wram_bank_target,
    output logic un_reg_target
);

    assign joypad_target = target & (addr == 7'h00);

    assign serial_reg_select = ~addr[0];
    assign serial_target = target & ((addr == 7'h01) | (addr == 7'h02));

    assign timer_reg_select = addr[1:0];
    assign timer_target = target & (addr[6:2] == 5'b000_01);

    assign apu_reg_select = addr[5:0];
    assign apu_target = target & (addr >= 7'h10) & (addr < 7'h40);

    assign ppu_reg_select = (addr < 7'h4c) ? {1'b0, addr[3:0]} : {2'b10, addr[2:0]};
    assign ppu_target =
            target & (((addr >= 7'h40) & (addr < 7'h4c))
                            | ((addr >= 7'h68) & (addr < 7'h6d)));
    
    assign cgb_target = target & (addr == 7'h4c);

    assign clk_target = target & (addr == 7'h4d);

    assign vram_bank_target = target & (addr == 7'h4f);

    assign bootmode_target = target & (addr == 7'h50);

    assign hdma_reg_select = addr[2:0];
    assign hdma_target = target & (addr >= 7'h51) & (addr < 7'h56);

    assign infrared_target = target & (addr == 7'h56);

    assign wram_bank_target = target & (addr == 7'h70);

    assign un_reg_select = addr[2:0];
    assign un_reg_target = target & (addr >= 7'h72) & (addr < 7'h78);

endmodule
