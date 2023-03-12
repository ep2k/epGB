module oam_scan_controller (
    input  logic sp_enable,
    input  logic [1:0] mode,
    input  logic sp_8x16,
    input  logic [8:0] hori_counter,
    input  logic [7:0] ly,
    
    input  logic [7:0] oam_rdata,
    
    output logic [7:0] oam_scan_addr,
    output logic [5:0] sp_num,
    output logic [3:0] fine_y,
    output logic line_sp_list_write
);

    logic sp_hit;

    assign sp_num = hori_counter[6:1];

    assign oam_scan_addr = {sp_num, 2'b00};
    assign fine_y = (ly - oam_rdata + 8'd16);
    assign line_sp_list_write =
            sp_enable & (mode == 2'd2) & hori_counter[0] & sp_hit;

    // 走査線上にスプライトが含まれるとき1
    assign sp_hit = 
        (
            (oam_rdata >= (sp_8x16 ? 8'd144 : 8'd152))
                | (ly < oam_rdata - (sp_8x16 ? 8'd0 : 8'd8))
        ) & (
            ((oam_rdata[7:4] == 4'h0) & (sp_8x16 | oam_rdata[3]))
                | (ly >= oam_rdata - 8'd16)
        );
    
endmodule
