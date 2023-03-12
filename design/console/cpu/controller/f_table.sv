module f_table (
    input  logic [7:0] op,
    input  logic [7:0] op_prefix,
    input  logic interrupt,
    input  logic [2:0] m_left,
    output logic [2:0] next_f_src,
    output logic [3:0] f_write
);

    always_comb begin

        if (interrupt) begin
            
            {next_f_src, f_write} = 7'bxxx_0000;

        end else if (op == 8'hCB) begin

            priority casez ({op_prefix, m_left})
                11'b00???110_001: {next_f_src, f_write} = 7'b000_1111;
                11'b00???110_000: {next_f_src, f_write} = 7'bxxx_0000;
                11'b00??????_000: {next_f_src, f_write} = 7'b000_1111;
                11'b01??????_000: {next_f_src, f_write} = 7'b011_1110;
                default: {next_f_src, f_write} = 7'bxxx_0000;
            endcase

        end else begin

            priority casez ({op, m_left})
                11'b11111000_001: {next_f_src, f_write} = 7'b010_1111;
                11'b11101000_010: {next_f_src, f_write} = 7'b010_1111;
                11'b11???110_000: {next_f_src, f_write} = 7'b000_1111;
                11'b10???110_000: {next_f_src, f_write} = 7'b000_1111;
                11'b10??????_000: {next_f_src, f_write} = 7'b000_1111;
                11'b00111111_000: {next_f_src, f_write} = 7'b011_0111;
                11'b00110111_000: {next_f_src, f_write} = 7'b011_0111;
                11'b00110101_001: {next_f_src, f_write} = 7'b000_1110;
                11'b00110101_000: {next_f_src, f_write} = 7'bxxx_0000;
                11'b00110100_001: {next_f_src, f_write} = 7'b000_1110;
                11'b00110100_000: {next_f_src, f_write} = 7'bxxx_0000;
                11'b00101111_000: {next_f_src, f_write} = 7'b101_0110;
                11'b00100111_000: {next_f_src, f_write} = 7'b100_1011;
                11'b000??111_000: {next_f_src, f_write} = 7'b001_1111;
                11'b00??1001_001: {next_f_src, f_write} = 7'b010_0111;
                11'b00???101_000: {next_f_src, f_write} = 7'b000_1110;
                11'b00???100_000: {next_f_src, f_write} = 7'b000_1110;
                default: {next_f_src, f_write} = 7'bxxx_0000;
            endcase

        end

    end
    
endmodule
