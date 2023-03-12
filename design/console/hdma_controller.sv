module hdma_controller (
    input  logic clk,
    input  logic cpu_en,
    input  logic reset,
    input  logic cgb,

    input  logic [2:0] reg_select,
    output logic [7:0] rdata,
    input  logic [7:0] wdata,
    input  logic write,

    input  logic hblank_start,

    output logic hdma,
    output logic [15:0] hdma_src_addr,
    output logic [12:0] hdma_vram_addr,
    output logic hdma_write
);

    logic [11:0] src_start_addr = 12'h0;
    logic [8:0] dst_start_addr = 9'h0;
    logic [6:0] remain_block = 7'h0;
    logic [6:0] block_num = 7'h0;
    logic [4:0] counter = 5'h0;
    logic general_hdma = 1'b0;
    logic hblank_hdma = 1'b0;
    logic hblank_hdma_active = 1'b0;

    logic hdma_active;
    logic general_hdma_start, hblank_hdma_start, hblank_hdma_restart;
    logic hdma_stop;
    logic hdma_finish;

    assign hdma = general_hdma | hblank_hdma;
    assign hdma_src_addr =
            {src_start_addr + (block_num - remain_block), counter[4:1]};
    assign hdma_vram_addr =
            {dst_start_addr + (block_num - remain_block), counter[4:1]};
    assign hdma_write = cpu_en & hdma & (~counter[0]);

    assign rdata = (cgb & (reg_select == 3'h5))
                        ? {~hdma_active, remain_block} : 8'hff;

    assign hdma_active = general_hdma | hblank_hdma_active;

    // CGBモードでなければスタートしない
    assign general_hdma_start =
            cgb & (reg_select == 3'h5) & write & (~wdata[7]) & (~hdma_active);
    assign hblank_hdma_start =
            cgb & (reg_select == 3'h5) & write & wdata[7] & (~hdma_active);
    assign hblank_hdma_restart = hblank_hdma_active & hblank_start;
    assign hdma_stop =
            (reg_select == 3'h5) & write & (~wdata[7]) & (hdma_active);
    
    assign hdma_finish = ({remain_block, counter} == 12'h0);

    always_ff @(posedge clk) begin
        if (reset) begin
            general_hdma <= 1'b0;
        end else if (cpu_en & general_hdma_start) begin
            general_hdma <= 1'b1;
        end else if (cpu_en & hdma_finish) begin
            general_hdma <= 1'b0;
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            hblank_hdma_active <= 1'b0;
        end else if (cpu_en & hblank_hdma_start) begin
            hblank_hdma_active <= 1'b1;
        end else if (cpu_en & (hdma_finish | hdma_stop)) begin
            hblank_hdma_active <= 1'b0;
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            hblank_hdma <= 1'b0;
        end else if (cpu_en & hblank_hdma_restart) begin
            hblank_hdma <= 1'b1;
        end else if (cpu_en & (counter == 5'h0)) begin
            hblank_hdma <= 1'b0;
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            counter <= 5'h0;
        end else if (cpu_en & (general_hdma_start | hblank_hdma_restart)) begin
            counter <= 5'h1f;
        end else if (cpu_en & hdma) begin
            counter <= counter - 5'h1;
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            remain_block <= 7'h0;
            block_num <= 7'h0;
        end else if (cpu_en & (general_hdma_start | hblank_hdma_start)) begin
            remain_block <= wdata[6:0];
            block_num <= wdata[6:0];
        end else if (cpu_en & hdma & (counter == 5'h0)) begin
            remain_block <= remain_block - 7'h1;
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            src_start_addr <= 12'h0;
            dst_start_addr <= 9'h0;
        end else if (cpu_en & write) begin
            case (reg_select)
                3'h1: src_start_addr[11:4] <= wdata;
                3'h2: src_start_addr[3:0] <= wdata[7:4];
                3'h3: dst_start_addr[8:4] <= wdata[4:0];
                3'h4: dst_start_addr[3:0] <= wdata[7:4];
                default: ;
            endcase
        end
    end

endmodule
