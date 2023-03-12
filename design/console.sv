module console (
    input  logic clk,                   // 倍速クロック(8.388608 MHz)
    input  logic slow_clk_en,           // 低速クロック(4.194304 MHz)
    input  logic reset,

    output logic ppu_enable,
    output logic [15:0] pixel_num,
    output logic [14:0] pixel_color,
    output logic pixel_write,

    output logic [8:0] sound_r,
    output logic [8:0] sound_l,
    output logic [15:0] sound_volumes,
    input  logic [3:0] apu_off,
    
    output logic n_cart_clk,
    output logic cart_write,
    output logic cart_read,
    output logic cart_cs,
    output logic [15:0] cart_addr,
    output logic [7:0] cart_wdata,
    input  logic [7:0] cart_rdata,
    output logic cart_wdata_send,

    input  logic link_clk_in,
    output logic link_clk_out,
    output logic link_dir,
    input  logic link_in,
    output logic link_out,

    input  logic [7:0] joypad_buttons,       // push=0

    input  logic cgb_hard,

    output logic cgb,
    output logic fast_mode
);

    // ------ Definition --------------

    logic cpu_en;
    logic cgb_soft;

    // CPU

    logic [15:0] cpu_addr;
    logic [7:0] cpu_rdata, cpu_wdata;
    logic cpu_write, cpu_write_eff;

    logic [1:0] t;
    logic stop;


    // Interrupt

    logic [4:0] ints;
    logic int_ack;
    logic int_reg_select;
    logic [7:0] int_rdata;
    logic int_target;


    // ROM, RAM

    logic [7:0] boot_addr;
    logic [7:0] boot_rdata;
    logic boot_target;

    logic [12:0] vram_addr, ppu_vram_addr;
    logic [7:0] vram_rdata, vram_rdata_bank0, vram_rdata_bank1;
    logic vram_target, vram_block;

    logic [12:0] wram_addr;
    logic [7:0] wram_rdata;
    logic wram_target;

    logic [7:0] oam_addr, ppu_oam_addr;
    logic [7:0] oam_rdata;
    logic oam_target, oam_block;

    logic [6:0] hram_addr;
    logic [7:0] hram_rdata;
    logic hram_target;


    // IO

    logic cart_write_raw;
    logic [15:0] cart_addr_raw;
    logic cart_target;

    logic [6:0] io_addr;
    logic io_target;


    logic [7:0] joypad_rdata;
    logic joypad_target;
    logic joypad_int;

    logic serial_reg_select;
    logic [7:0] serial_rdata;
    logic serial_target;
    logic serial_int;

    logic [1:0] timer_reg_select;
    logic [7:0] timer_rdata;
    logic timer_target;
    logic timer_int;

    logic [5:0] apu_reg_select;
    logic [7:0] apu_rdata;
    logic apu_target;
    logic [15:0] pcm_amp;

    logic [4:0] ppu_reg_select;
    logic [7:0] ppu_rdata;
    logic ppu_target;
    logic hblank_start;
    logic vblank_int, ppu_int;
    logic [15:0] oamdma_src_addr;
    logic oamdma, oamdma_write;

    logic [7:0] cgb_rdata;
    logic cgb_target;

    logic [7:0] clk_rdata;
    logic clk_target;

    logic [7:0] vram_bank_rdata;
    logic vram_bank_target;

    logic [7:0] bootmode_rdata;
    logic bootmode_target;
    logic use_cart; // 0のときBootROMを使用

    logic [2:0] hdma_reg_select;
    logic [7:0] hdma_rdata;
    logic hdma_target;
    logic [15:0] hdma_src_addr;
    logic [12:0] hdma_vram_addr;
    logic hdma, hdma_write;
    
    logic [7:0] infrared_rdata;
    logic infrared_target;
    
    logic [7:0] wram_bank_rdata;
    logic wram_bank_target;
    
    logic [2:0] un_reg_select;
    logic [7:0] un_reg_rdata;
    logic un_reg_target;
    

    logic [7:0] dma_rdata;

    // ------ Assignment --------------

    assign cgb = cgb_hard & cgb_soft;
    
    assign cpu_write_eff = cpu_write & (~oamdma) & (~hdma);
    assign cart_write_raw = cpu_write_eff & cart_target & use_cart;

    cpu cpu(
        .clk,
        .cpu_en(cpu_en & (~hdma)),      // HDMA中は動作停止
        .reset,

        .mem_addr(cpu_addr),
        .mem_rdata(cpu_rdata),
        .mem_wdata(cpu_wdata),
        .write(cpu_write),

        .ints,
        .int_ack,

        .t,
        .stop
    );

    addr_decoder addr_decoder(
        .addr(cpu_addr),
        .ppu_vram_addr,
        .ppu_oam_addr,
        .oamdma_src_addr,
        .hdma_src_addr,
        .hdma_vram_addr,

        .oam_block,
        .vram_block,
        .oamdma,
        .hdma,

        .cart_addr(cart_addr_raw),
        .boot_addr,
        .vram_addr,
        .wram_addr,
        .oam_addr,
        .hram_addr,
        .io_addr,
        .int_reg_select,

        .cart_target,
        .boot_target,
        .vram_target,
        .wram_target,
        .oam_target,
        .hram_target,
        .io_target,
        .int_target
    );

    io_decoder io_decoder(
        .addr(io_addr),
        .target(io_target),
        
        .serial_reg_select,
        .timer_reg_select,
        .apu_reg_select,
        .ppu_reg_select,
        .hdma_reg_select,
        .un_reg_select,

        .joypad_target,
        .serial_target,
        .timer_target,
        .apu_target,
        .ppu_target,
        .cgb_target,
        .clk_target,
        .vram_bank_target,
        .bootmode_target,
        .hdma_target,
        .infrared_target,
        .wram_bank_target,
        .un_reg_target
    );

    rdata_selector rdata_selector(
        .cart_rdata,
        .boot_rdata,
        .vram_rdata,
        .wram_rdata,
        .oam_rdata,
        .hram_rdata,
        .int_rdata,

        .joypad_rdata,
        .serial_rdata,
        .timer_rdata,
        .apu_rdata,
        .ppu_rdata,
        .cgb_rdata,
        .clk_rdata,
        .vram_bank_rdata,
        .bootmode_rdata,
        .hdma_rdata,
        .infrared_rdata,
        .wram_bank_rdata,
        .un_reg_rdata,
        
        .cart_target,
        .boot_target,
        .vram_target,
        .wram_target,
        .oam_target,
        .hram_target,
        .int_target,

        .joypad_target,
        .serial_target,
        .timer_target,
        .apu_target,
        .ppu_target,
        .cgb_target,
        .clk_target,
        .vram_bank_target,
        .bootmode_target,
        .hdma_target,
        .infrared_target,
        .wram_bank_target,
        .un_reg_target,

        .use_cart,
        .vram_block,
        .oam_block,
        .oamdma,

        .cpu_rdata,
        .dma_rdata
    );

    cart_controller cart_controller(
        .clk,
        .cpu_en,
        .reset,

        .t,

        .cart_target,
        .cart_write_raw,
        .cart_addr_raw,
        .cart_wdata_raw(cpu_wdata),

        .n_cart_clk,
        .cart_write,
        .cart_read,
        .cart_cs,
        .cart_addr,
        .cart_wdata,
        .cart_wdata_send
    );

    int_controller int_controller(
        .clk,
        .cpu_en,
        .reset,

        .vblank_int,
        .ppu_int,
        .timer_int,
        .serial_int,
        .joypad_int,

        .ints,
        .int_ack,

        .reg_select(int_reg_select),
        .rdata(int_rdata),
        .wdata(cpu_wdata),
        .write(int_target & cpu_write_eff)
    );


    boot_rom boot_rom(
        .clk,
        .cpu_en,
        .reset,

        .cgb_hard,

        .addr(boot_addr),
        .rdata(boot_rdata),

        .bootmode_wdata(cpu_wdata),
        .bootmode_rdata(bootmode_rdata),
        .bootmode_write(bootmode_target & cpu_write_eff),

        .use_cart
    );

    vram vram(
        .clk,
        .cpu_en,
        .reset,
        .cgb,

        .addr(vram_addr),
        .rdata(vram_rdata),
        .rdata_bank0(vram_rdata_bank0),
        .rdata_bank1(vram_rdata_bank1),
        .wdata(hdma ? dma_rdata : cpu_wdata),
        .write((vram_target & cpu_write_eff & (~vram_block)) | hdma_write),

        .bank_rdata(vram_bank_rdata),
        .switch_bank(vram_bank_target & cpu_write_eff)
    );

    wram wram(
        .clk,
        .cpu_en,
        .reset,
        .cgb,

        .addr(wram_addr),
        .rdata(wram_rdata),
        .wdata(cpu_wdata),
        .write(wram_target & cpu_write_eff),
        
        .bank_rdata(wram_bank_rdata),
        .switch_bank(wram_bank_target & cpu_write_eff)
    );

    // Object Attribute Memmory
    oam oam(
        .clk,
        .cpu_en,
        .reset,

        .addr(oam_addr),
        .rdata(oam_rdata),
        .wdata(oamdma ? dma_rdata : cpu_wdata),
        .write((oam_target & cpu_write_eff & (~oam_block)) | oamdma_write)
    );

    // High RAM (OAM DMA中でもアクセス可能なRAM)
    hram hram(
        .clk,
        .cpu_en,
        .reset,

        .addr(hram_addr),
        .rdata(hram_rdata),
        .wdata(cpu_wdata),
        .write(hram_target & cpu_write & (~hdma))
    );


    joypad joypad(
        .clk,
        .cpu_en,
        .reset,

        .buttons(joypad_buttons),

        .rdata(joypad_rdata),
        .wdata(cpu_wdata),
        .write(joypad_target & cpu_write_eff),

        .joypad_int
    );

    serial serial(
        .clk,
        .cpu_en,
        .reset,
        .cgb,

        .reg_select(serial_reg_select),
        .rdata(serial_rdata),
        .wdata(cpu_wdata),
        .write(cpu_write_eff & serial_target),

        .clk_in(link_clk_in),
        .clk_out(link_clk_out),
        .clk_dir(link_dir),

        .sin(link_in),
        .sout(link_out),
        
        .serial_int
    );

    timer_and_divider timer_and_divider(
        .clk,
        .cpu_en,
        .reset,
        .stop,

        .reg_select(timer_reg_select),
        .rdata(timer_rdata),
        .wdata(cpu_wdata),
        .write(cpu_write_eff & timer_target),
        
        .timer_int
    );

    apu apu(
        .clk,
        .slow_clk_en,
        .cpu_en,
        .reset,

        .reg_select(apu_reg_select),
        .rdata(apu_rdata),
        .wdata(cpu_wdata),
        .write(cpu_write_eff & apu_target),

        .ch_off(apu_off),

        .sound_r,
        .sound_l,
        .volumes(sound_volumes),

        .pcm_amp
    );

    ppu ppu(
        .clk,
        .slow_clk_en,
        .cpu_en,
        .reset,
        .cgb,

        .reg_select(ppu_reg_select),
        .rdata(ppu_rdata),
        .wdata(cpu_wdata),
        .write(cpu_write_eff & ppu_target),

        .oam_block,
        .vram_block,

        .oam_addr(ppu_oam_addr),
        .oam_rdata,
        .vram_addr(ppu_vram_addr),
        .vram_rdata_bank0,
        .vram_rdata_bank1,

        .vblank_int,
        .ppu_int,

        .oamdma,
        .oamdma_src_addr,
        .oamdma_write,

        .hblank_start,

        .ppu_enable,
        .pixel_num,
        .pixel_color,
        .pixel_write
    );

    cgb_mode_controller cgb_mode_controller(
        .clk,
        .cpu_en,
        .reset,

        .rdata(cgb_rdata),
        .wdata(cpu_wdata),
        .write(cgb_target & cpu_write_eff),

        .cgb_soft
    );

    clock_controller clock_controller(
        .clk,
        .reset,

        .slow_clk_en,
        .cgb,
        .stop,
        
        .rdata(clk_rdata),
        .wdata(cpu_wdata),
        .write(clk_target & cpu_write_eff),
        
        .cpu_en,
        .fast_mode
    );

    hdma_controller hdma_controller(
        .clk,
        .cpu_en,
        .reset,
        .cgb,

        .reg_select(hdma_reg_select),
        .rdata(hdma_rdata),
        .wdata(cpu_wdata),
        .write(hdma_target & cpu_write_eff),

        .hblank_start,

        .hdma,
        .hdma_src_addr,
        .hdma_vram_addr,
        .hdma_write
    );

    assign infrared_rdata = 8'b00_1111_10; // 赤外線通信は未実装

    undocumented_registers undocumented_registers(
        .clk,
        .cpu_en,
        .reset,
        .cgb,

        .reg_select(un_reg_select),
        .rdata(un_reg_rdata),
        .wdata(cpu_wdata),
        .write(un_reg_target & cpu_write_eff),

        .pcm_amp
    );
    
endmodule
