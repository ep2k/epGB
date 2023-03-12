# Clock
create_clock -name clock_in_50mhz -period 20.000 [get_ports {pin_clk}]
derive_pll_clocks
derive_clock_uncertainty
create_generated_clock -name pad_clk -source [get_ports {pin_clk}] -divide_by 100 [get_nets {clock_generator|pad_clk}]

# False Path
set_clock_groups -asynchronous -group [get_clocks {clock_generator|pll|pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -group [get_clocks {pad_clk}]
set_clock_groups -asynchronous -group [get_clocks {clock_generator|pll|pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -group [get_clocks {clock_in_50mhz}]
