// Top module

module epGB (
    input  logic pin_clk,               // 50MHz
    input  logic pin_n_reset,

    output logic [3:0] vga_r,
    output logic [3:0] vga_g,
    output logic [3:0] vga_b,
    output logic vga_hs,
    output logic vga_vs,

    output logic sound_r_pdm,           // Pulse-density modulation
    output logic sound_l_pdm,


    // ---- Cartridge ----

    // 3.3V <-> 5V
    inout  logic [7:0] cart_data,
    output logic n_cart_reset,
    output logic cart_data_dir,
    output logic cart_reset_dir,

    // 3.3V -> 5V, 74HCT04(inverter)を挟むため予め反転
    output logic [15:0] n_cart_addr,
    output logic n_cart_clk,
    output logic cart_write,
    output logic cart_read,
    output logic cart_cs,

    // ---- Link ----

    output logic n_link_out,
    input  logic link_in,
    inout  logic link_clk,
    output logic link_dir,


    // ---- DUALSHOCK ----

    input  logic pad_dat,
    output logic pad_cmd,
    output logic pad_sel,
    output logic pad_sclk,
    input  logic pad_ack,


    // ---- Additional Functions ----

    input  logic use_dmg,               // 強制的にDMGモード
    input  logic dmg_monochrome,        // 0: 緑 1: 白黒 (DMGモードのみ)
    input  logic monaural,              // 0: ステレオ 1: モノラル
    input  logic use_link,              // シリアル通信アンロック
    input  logic use_cart_int,          // 内部ROM使用
    input  logic [3:0] apu_off,         // apu_off[i]=0 でサウンド i chをオフ


    // ---- LEDs ----

    output logic [9:0] led,
    output logic [6:0] hex_5,
    output logic [6:0] hex_4,
    output logic [6:0] hex_3,
    output logic [6:0] hex_2,
    output logic [6:0] hex_1,
    output logic [6:0] hex_0

);

    logic clk, slow_clk_en, vga_clk, pad_clk;

    logic cgb, fast_mode;

    logic ppu_enable;                       // LCDC[7]
    logic [15:0] write_pixel_num;           // 書き込むLCDのピクセル番号
    logic [14:0] write_pixel_color;         // LCD[write_pixel_num]に書き込む色
    logic pixel_write;                      // LCDに書き込む
    logic [15:0] draw_pixel_num;            // VGAで出力するLCDのピクセル番号
    logic [14:0] draw_pixel_color;          // LCD[draw_pixel_num]
    logic [15:0] lcd_white_counter = 16'h0; // ppuオフ時にLCDをリセットするためのカウンタ

    logic [8:0] sound_r, sound_l, sound_r_raw, sound_l_raw;
    logic [9:0] sound_sum;
    logic [15:0] sound_volumes;
    logic [3:0] sound_volumes_pwm;

    logic [15:0] cart_addr;
    logic [7:0] cart_rdata, cart_wdata, cart_rdata_int;
    logic cart_write_raw, cart_write_int, cart_cs_raw;
    logic cart_wdata_send; // カートリッジにwdataを送る
    
    logic link_out_raw, link_clk_in, link_clk_out, link_clk_out_raw;

    logic [15:0] dual_buttons, dual_buttons_reg;
    logic pad_connect;
    logic [7:0] pad_buttons; // ST/SL/B/A/↓/↑/←/→
    logic button_reset;

    logic no_push_pwm, normal_led_pwm;


    assign led[9:4] = {cgb, fast_mode, 4'h0} & {{6{normal_led_pwm}}};
    assign led[3:0] = sound_volumes_pwm;

    always_ff @(posedge clk) begin
        lcd_white_counter <= lcd_white_counter + 16'h1;
    end

    assign sound_sum = sound_r_raw + sound_l_raw;
    assign sound_r = monaural ? sound_sum[9:1] : sound_r_raw;
    assign sound_l = monaural ? sound_sum[9:1] : sound_l_raw;

    assign n_cart_addr = ~cart_addr;
    assign cart_data = cart_wdata_send ? cart_wdata : 'z;
    assign cart_write = (~use_cart_int) & cart_write_raw;
    assign cart_cs = (~use_cart_int) & cart_cs_raw;
    assign n_cart_reset = pin_n_reset;
    // assign n_cart_reset = pin_n_reset ? 1'bz : 1'b0;
    assign cart_data_dir = cart_wdata_send;
    assign cart_reset_dir = 1'b1;
    // assign cart_reset_dir = ~pin_n_reset;

    assign cart_rdata = use_cart_int ? cart_rdata_int : cart_data;

    assign n_link_out = use_link & (~link_out_raw);
    assign link_clk = link_dir ? link_clk_out : 'z;
    assign link_clk_in = link_dir | link_clk;
    assign link_clk_out = (~use_link) | link_clk_out_raw;

    always_ff @(posedge clk) begin
        dual_buttons_reg <= dual_buttons;
    end

    assign pad_buttons = {
        dual_buttons_reg[3],    // Start
        dual_buttons_reg[0],    // Select
        dual_buttons_reg[14],   // B
        dual_buttons_reg[13],   // A

        dual_buttons_reg[6],    // Down
        dual_buttons_reg[4],    // Up
        dual_buttons_reg[7],    // Left
        dual_buttons_reg[5]     // Right
    };

    // R1,L1,R2,L2同時押しでリセット
    assign button_reset = (dual_buttons_reg[11:8] == 4'h0);


    // ----  Internal ROM  --------------------------

    assign cart_write_int = use_cart_int & cart_write_raw;

    cartridge cartridge(
        .clk,
        .reset((~pin_n_reset) | button_reset),

        .addr(cart_addr),
        .rdata(cart_rdata_int),
        .wdata(cart_wdata),
        .write(cart_write_int)
    );

    // ----------------------------------------------

    clock_generator clock_generator(
        .base_clk(pin_clk),

        .clk,
        .slow_clk_en,
        .vga_clk,
        .pad_clk
    );

    console console(
        .clk,
        .slow_clk_en,
        .reset((~pin_n_reset) | button_reset),

        .ppu_enable,
        .pixel_num(write_pixel_num),
        .pixel_color(write_pixel_color),
        .pixel_write,

        .sound_r(sound_r_raw),
        .sound_l(sound_l_raw),
        .sound_volumes,
        .apu_off,

        .n_cart_clk,
        .cart_write(cart_write_raw),
        .cart_read,
        .cart_cs(cart_cs_raw),
        .cart_addr,
        .cart_wdata,
        .cart_rdata,
        .cart_wdata_send,

        .link_clk_in((~use_link) | link_clk_in),
        .link_clk_out(link_clk_out_raw),
        .link_dir,
        .link_in((~use_link) | link_in),
        .link_out(link_out_raw),

        .joypad_buttons(pad_buttons),

        .cgb_hard(~use_dmg),

        .cgb,
        .fast_mode
    );

    lcd lcd(
        .data(ppu_enable ? write_pixel_color : 15'h7fff),
        .wraddress(ppu_enable ? write_pixel_num : lcd_white_counter),
        .wrclock(clk),
        .wren((slow_clk_en & pixel_write) | (~ppu_enable)),
        .rdaddress(draw_pixel_num),
        .rdclock(vga_clk),
        .q(draw_pixel_color)
    );

    vga_controller vga_controller(
        .clk(vga_clk),
        .cgb,
        .dmg_monochrome,

        .draw_pixel_num,
        .draw_pixel_color,

        .vga_r,
        .vga_g,
        .vga_b,
        .vga_hs,
        .vga_vs
    );

    delta_sigma #(.WIDTH(9)) delta_sigma_right(
        .clk(pin_clk),
        .data_in(sound_r),
        .pulse_out(sound_r_pdm)
    );

    delta_sigma #(.WIDTH(9)) delta_sigma_left(
        .clk(pin_clk),
        .data_in(sound_l),
        .pulse_out(sound_l_pdm)
    );

    // DUALSHOCK driver
    pad_driver pad_driver(
        .clk(pad_clk),
        .reset(~pin_n_reset),

        .analog_mode(1'b0),
        .vibrate_sub(1'b0),
        .vibrate(8'h0),

        .dat(pad_dat),
        .cmd(pad_cmd),
        .n_sel(pad_sel),
        .sclk(pad_sclk),
        .n_ack(pad_ack),

        .pad_connect,

        .pad_buttons(dual_buttons)
    );

    // (サウンド各ch音量)^2をPWMで表示
    genvar gi;
    generate
        for (gi = 0; gi < 4; gi++) begin : PWMs
            logic [3:0] sound_volume;
            logic [7:0] sound_volume_square;

            assign sound_volume = sound_volumes[gi * 4 + 3 : gi * 4];
            always_comb begin
                unique case (sound_volume)
                    4'h0: sound_volume_square = 8'd0;
                    4'h1: sound_volume_square = 8'd1;
                    4'h2: sound_volume_square = 8'd4;
                    4'h3: sound_volume_square = 8'd9;
                    4'h4: sound_volume_square = 8'd16;
                    4'h5: sound_volume_square = 8'd25;
                    4'h6: sound_volume_square = 8'd36;
                    4'h7: sound_volume_square = 8'd49;
                    4'h8: sound_volume_square = 8'd64;
                    4'h9: sound_volume_square = 8'd81;
                    4'ha: sound_volume_square = 8'd100;
                    4'hb: sound_volume_square = 8'd121;
                    4'hc: sound_volume_square = 8'd144;
                    4'hd: sound_volume_square = 8'd169;
                    4'he: sound_volume_square = 8'd196;
                    4'hf: sound_volume_square = 8'd225;
                endcase
            end

            pwm #(.WIDTH(8)) pwm(
                .clk,
                .din(sound_volume_square),
                .dout(sound_volumes_pwm[gi])
            );
        end
    endgenerate

    // 非押下時の7セグLED光量生成
    pwm #(.WIDTH(8)) pwm_no_push(
        .clk,
        .din(8'hff),
        .dout(no_push_pwm)
    );

    // LED光量(低減)を生成
    pwm #(.WIDTH(2)) pwm_normal_led(
        .clk,
        .din(2'h1),
        .dout(normal_led_pwm)
    );

    // 押下情報を7セグLEDに変換
    seg7_buttons seg7_buttons(
        .buttons(pad_buttons),
        .no_push_pwm((~pad_connect) | no_push_pwm),
        .odat_l(hex_1),
        .odat_r(hex_0)
    );

    assign hex_5 = 7'h7f;
    assign hex_4 = 7'h7f;
    assign hex_3 = 7'h7f;
    assign hex_2 = 7'h7f;
    
endmodule
