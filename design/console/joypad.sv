module joypad (
    input  logic clk,
    input  logic cpu_en,
    input  logic reset,

    input  logic [7:0] buttons, // ST/SL/B/A/↓/↑/←/→

    output logic [7:0] rdata,
    input  logic [7:0] wdata,
    input  logic write,

    output logic joypad_int
);

    logic [1:0] button_mode = 2'b00;
    logic [3:0] input_prev;

    logic [3:0] act_buttons, dir_buttons;

    assign act_buttons = button_mode[1] ? 4'hf : buttons[7:4];
    assign dir_buttons = button_mode[0] ? 4'hf : buttons[3:0];

    assign rdata = {2'b11, button_mode, act_buttons & dir_buttons};

    assign joypad_int = ((~rdata[3:0]) & input_prev) != 4'h0;

    always_ff @(posedge clk) begin
        if (reset) begin
            button_mode <= 2'b00;
        end else if (cpu_en & write) begin
            button_mode <= wdata[5:4];
        end
    end

    always_ff @(posedge clk) begin
        if (cpu_en) begin
            input_prev <= rdata[3:0]; 
        end
    end
    
endmodule
