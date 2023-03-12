module pad_driver (
    input  logic clk,                   // 500kHz
    input  logic reset,

    input  logic analog_mode,           // read analog stick values
    input  logic vibrate_sub,           // small motor on
    input  logic [7:0] vibrate,         // large motor speed (00-FF)

    input  logic dat,
    output logic cmd,
    output logic n_sel,
    output logic sclk,
    input  logic n_ack,

    output logic pad_connect,           // pad is connected

    output logic [15:0] pad_buttons,    // □/×/○|△|R1|L1|R2|L2/←/↓/→/↑/ST/SW→/SW←/SEL
    output logic [7:0] pad_right_hori,  // Right Stick Horizontal (Left=00 ~ Right=FF)
    output logic [7:0] pad_right_vert,  // Right Stick Vertical (Top=00 ~ Buttom=FF)
    output logic [7:0] pad_left_hori,   // Left Stick Horizontal (Left=00 ~ Right=FF)
    output logic [7:0] pad_left_vert    // Left Stick Vertical (Top=00 ~ Buttom=FF)
);

    localparam logic [12:0] CTR_MAX = 13'd7999;

    logic [12:0] ctr = 13'd0; // 0-7999, 2us*8000=16ms(62.5Hz)毎にデータ取得
    logic [7:0] dat8 = 8'h00;
    logic [7:0] cmd8;
    logic [3:0] byte_length;

    assign n_sel = (ctr[12:10] != 3'd0);

    always_ff @(posedge clk) begin
        if (reset) begin
            ctr <= 13'd0;
        end else begin
            ctr <= (ctr == CTR_MAX) ? 13'd0 : (ctr + 13'd1); 
        end
    end

    // ---------------------------------
    //      SPI
    // ---------------------------------

    logic com_time;

    assign com_time = (~n_sel) & (ctr[5:4] == 2'b10) & (ctr[9:6] < byte_length);
    assign sclk = ~(ctr[0] & com_time);

    always_ff @(posedge clk) begin
        if (reset) begin
            dat8 <= 8'h0;
            cmd <= 1'b0;
        end else if (com_time) begin
            if (ctr[0]) begin
                dat8[ctr[3:1]] <= dat;
            end else begin
                cmd <= cmd8[ctr[3:1]];
            end
        end
    end

    // ---------------------------------
    //      Protcol
    // ---------------------------------

    /*
        0. READ_DATAでIDを取得
            → IDが41or73であれば1へ(接続)，そうでなければ0へ(未接続)
        1. CONFIG_MODE_ENTER
        2. SET_MODE_AND_LOCKで外部から受け取ったデジタル/アナログを設定，モード切替禁止
        3. VIBRATION_ENABLE
        4. CONFIG_MODE_EXIT
        5. READ_DATA_AND_VIBRATE_EXでIDとボタンを取得
            → IDが41or73でないかモード変更があれば0へ，そうでなければ5へ
    */

    logic [2:0] state = 3'h0;
    logic [7:0] id = 8'h0;
    logic id_incorrect, analog_mode_now, mode_change;

    assign pad_connect = (state != 3'h0);
    assign id_incorrect = ~((id == 8'h41) | (id == 8'h73));
    assign analog_mode_now = (id == 8'h73);
    assign mode_change = analog_mode ^ analog_mode_now;

    always_ff @(posedge clk) begin
        if (reset) begin
            state <= 3'h0;
        end else if (ctr == CTR_MAX) begin
            case (state)
                3'h0: state <= id_incorrect ? 3'h0 : 3'h1;
                3'h5: state <= (id_incorrect | mode_change) ? 3'h0 : 3'h5;
                default: state <= state + 3'h1;
            endcase
        end
    end

    always_comb begin
        case (state)
            3'h0: byte_length = 4'h5;
            3'h1: byte_length = analog_mode_now ? 4'h9 : 4'h5;
            3'h2: byte_length = 4'h9;
            3'h3: byte_length = 4'h9;
            3'h4: byte_length = 4'h9;
            3'h5: byte_length = analog_mode_now ? 4'h9 : 4'h5;
            default: byte_length = 4'h0;
        endcase
    end

    always_comb begin
        casez ({state, ctr[9:6]})
            7'h?0: cmd8 = 8'h01;

            7'h01: cmd8 = 8'h42; // READ_DATA

            7'h11: cmd8 = 8'h43; // CONFIG_MODE_ENTER
            7'h13: cmd8 = 8'h01;

            7'h21: cmd8 = 8'h44; // SET_MODE_AND_LOCK
            7'h23: cmd8 = {7'h0, analog_mode};
            7'h24: cmd8 = 8'h03; // ボタンでのモード切替禁止

            7'h31: cmd8 = 8'h4d; // VIBRATION_ENABLE
            7'h34: cmd8 = 8'h01;
            7'h35: cmd8 = 8'hff;
            7'h36: cmd8 = 8'hff;
            7'h37: cmd8 = 8'hff;
            7'h38: cmd8 = 8'hff;

            7'h41: cmd8 = 8'h43; // CONFIG_MODE_EXIT

            7'h51: cmd8 = 8'h42; // READ_DATA_AND_VIBRATE_EX
            7'h53: cmd8 = {7'h0, vibrate_sub};
            7'h54: cmd8 = vibrate;

            default: cmd8 = 8'h0;
        endcase
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            id <= 8'h0;
            pad_buttons <= 16'hffff;
            pad_right_hori <= 8'h80;
            pad_right_vert <= 8'h80;
            pad_left_hori <= 8'h80;
            pad_left_vert <= 8'h80;
        end else if ((~n_sel) & (ctr[5:0] == 6'h3f)) begin
            case ({state, ctr[9:6]})
                7'h01: id <= dat8;
                7'h51: id <= dat8;
                7'h53: pad_buttons[7:0] <= dat8;
                7'h54: pad_buttons[15:8] <= dat8;
                7'h55: if (analog_mode_now) pad_right_hori <= dat8;
                7'h56: if (analog_mode_now) pad_right_vert <= dat8;
                7'h57: if (analog_mode_now) pad_left_hori <= dat8;
                7'h58: if (analog_mode_now) pad_left_vert <= dat8;
                default: ;
            endcase
        end else if (ctr == CTR_MAX) begin
            if (id_incorrect) begin
                pad_buttons <= 16'hffff;
                pad_right_hori <= 8'h80;
                pad_right_vert <= 8'h80;
                pad_left_hori <= 8'h80;
                pad_left_vert <= 8'h80;
            end else if (~analog_mode_now) begin
                pad_right_hori <= 8'h80;
                pad_right_vert <= 8'h80;
                pad_left_hori <= 8'h80;
                pad_left_vert <= 8'h80;
            end
        end
    end
    
endmodule
