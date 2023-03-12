module clock_generator (
    input  logic base_clk,              // 50MHz

    output logic clk,                   // 8.4MHz
    output logic slow_clk_en,           // 2clkに1回イネーブル (4.2MHz)
    output logic vga_clk,               // 25MHz
    output logic pad_clk                // 500kHz
);
    
    logic [5:0] pad_counter = 6'b0; // 0 ~ 49

    logic pllout_0, pllout_1, pll_locked;

    pll pll(                    // IP (PLL: 50MHz -> 8.388608MHz, 25.175MHz)
        .refclk(base_clk),
        .rst(1'b0),
        .outclk_0(pllout_0),
        .outclk_1(pllout_1),
        .locked(pll_locked)
    );

    assign clk = pll_locked & pllout_0;
    assign vga_clk = pll_locked & pllout_1;

    always_ff @(posedge clk) begin
        slow_clk_en <= ~slow_clk_en;
    end

    always_ff @(posedge base_clk) begin
        pad_counter <= (pad_counter == 6'd49) ? 6'd0 : (pad_counter + 6'd1);
        if (pad_counter == 6'd49) begin
            pad_clk <= ~pad_clk;
        end
    end

endmodule
