module seg7_buttons (
    input  logic [7:0] buttons,
    input  logic no_push_pwm,
    output logic [6:0] odat_l,
    output logic [6:0] odat_r
);

    assign odat_l = {
        buttons[3] & no_push_pwm, // Down
        buttons[1] & no_push_pwm, // Left
        1'b1,
        buttons[6] & no_push_pwm, // Select
        1'b1,
        buttons[0] & no_push_pwm, // Right
        buttons[2] & no_push_pwm // Up
    };

    assign odat_r = {
        buttons[5] & no_push_pwm, // B
        1'b1,
        1'b1,
        buttons[7] & no_push_pwm, // Start
        1'b1,
        buttons[4] & no_push_pwm, // A
        1'b1
    };
    
endmodule
