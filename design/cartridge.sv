module cartridge (
    input  logic clk,
    input  logic reset,

    input  logic [15:0] addr,
    output logic [7:0] rdata,
    input  logic [7:0] wdata,
    input  logic write
);

    logic write_prev;
    logic [7:0] rom_rdata, ram_rdata;
    
    assign rdata = addr[15] ? ram_rdata : rom_rdata;

    always_ff @(negedge clk) begin
        write_prev <= write;
    end

    // 0000 ~ 7FFF (32KB)
    prg_rom prg_rom(            // IP (ROM, rom/prg_rom.mif)
        .address(addr[14:0]),
        .clock(~clk),
        .q(rom_rdata)
    );

    // A000 ~ BFFF (8KB)
    extram_bram extram_bram(    // IP (RAM)
        .address(addr[12:0]),
        .clock(~clk),
        .data(wdata),
        .wren((~write_prev) & write & (addr[15:13] == 3'b101)),
        .q(ram_rdata)
    );
    
endmodule
