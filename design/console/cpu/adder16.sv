module adder16 (
    input  logic [15:0] a,
    input  logic [15:0] b,
    output logic [15:0] y,
    output logic [3:0] f,
    input  logic control
);

    logic [16:0] c_add_16;
    logic [12:0] h_add_16;
    
    assign c_add_16 = a + b;
    assign h_add_16 = a[11:0] + b[11:0];

    logic [8:0] c_add_8;
    logic [4:0] h_add_8;

    assign c_add_8 = a[7:0] + b[7:0];
    assign h_add_8 = a[3:0] + b[3:0];

    assign y = a + b;
    assign f = control
            ? {2'b00, h_add_16[12], c_add_16[16]} // 16bit
            : {2'b00, h_add_8[4], c_add_8[8]}; // 8bit sign extension
    
endmodule
