module boot_rom (
    input  logic clk,
    input  logic cpu_en,
    input  logic reset,

    input  logic cgb_hard,

    input  logic [7:0] addr,
    output logic [7:0] rdata,

    input  logic [7:0] bootmode_wdata,
    output logic [7:0] bootmode_rdata,
    input  logic bootmode_write,

    output logic use_cart
);

    logic [7:0] boot_reg = 8'h0;

    logic [7:0] dmg_rdata, cgb_rdata;

    assign use_cart = boot_reg[0];
    assign rdata = cgb_hard ? cgb_rdata : dmg_rdata;
    assign bootmode_rdata = boot_reg;

    always_ff @(posedge clk) begin
        if (reset) begin
            boot_reg <= 8'h0;
        end else if (cpu_en & bootmode_write & (~use_cart)) begin
            boot_reg <= bootmode_wdata;
        end
    end

    // 0000 ~ 00FF (256 bytes)

    dmg_rom dmg_rom(            // IP (ROM, rom/boot_rom/dmg.mif)
        .address(addr),
        .clock(~clk),
        .q(dmg_rdata)
    );

    cgb_rom cgb_rom(            // IP (ROM, rom/boot_rom/cgb.mif)
        .address(addr),
        .clock(~clk),
        .q(cgb_rdata)
    );
    
endmodule
