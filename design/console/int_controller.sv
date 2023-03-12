module int_controller (
    input  logic clk,
    input  logic cpu_en,
    input  logic reset,
    
    input  logic vblank_int,
    input  logic ppu_int,
    input  logic timer_int,
    input  logic serial_int,
    input  logic joypad_int,

    output logic [4:0] ints,
    input  logic int_ack,

    input  logic reg_select,    // R/Wのレジスタ選択 (0: IE, 1: IF)
    output logic [7:0] rdata,
    input  logic [7:0] wdata,   // レジスタへの書き込み値
    input  logic write
);

    logic [4:0] int_enable = 5'h0;
    logic [4:0] int_flg = 5'h0;

    logic [4:0] new_ints;

    assign ints = int_enable & int_flg;

    assign rdata = reg_select ? {3'b000, int_flg} : {3'b000, int_enable};

    assign new_ints = {joypad_int, serial_int, timer_int, ppu_int, vblank_int};

    // IE
    always_ff @(posedge clk) begin
        if (reset) begin
            int_enable <= 5'h0;
        end else if (cpu_en & (~reg_select) & write) begin
            int_enable <= wdata[4:0];
        end
    end

    // IF
    always_ff @(posedge clk) begin
        if (reset) begin
            int_flg <= 5'h0;
        end else if (cpu_en) begin
            if (reg_select & write) begin
                int_flg <= wdata[4:0];
            end else begin
                priority casez ({int_ack, ints})
                    6'b1_????1: int_flg <= {int_flg[4:1], 1'b0} | new_ints;
                    6'b1_???10: int_flg <= {int_flg[4:2], 1'b0, int_flg[0]} | new_ints;
                    6'b1_??100: int_flg <= {int_flg[4:3], 1'b0, int_flg[1:0]} | new_ints;
                    6'b1_?1000: int_flg <= {int_flg[4], 1'b0, int_flg[2:0]} | new_ints;
                    6'b1_10000: int_flg <= {1'b0, int_flg[3:0]} | new_ints;
                    default: int_flg <= int_flg | new_ints;
                endcase
            end
        end
    end
    
endmodule
