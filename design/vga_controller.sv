module vga_controller (
    input  logic clk,                       // 25MHz
    input  logic cgb,
    input  logic dmg_monochrome,

    output logic [15:0] draw_pixel_num,     // 0 ~ 36864
    input  logic [14:0] draw_pixel_color,

    output logic [3:0] vga_r,
    output logic [3:0] vga_g,
    output logic [3:0] vga_b,
    output logic vga_hs,
    output logic vga_vs
);

    localparam H_SYNC = 10'd96;
    localparam H_BACK = 10'd48;
    localparam H_ACTIVE = 10'd640;
    localparam H_FRONT = 10'd16;
    localparam H_MAX = H_SYNC + H_BACK + H_ACTIVE + H_FRONT - 10'd1;

    localparam V_SYNC = 10'd2;
    // localparam V_BACK = 10'd32;
    localparam V_BACK = 10'd2; // for my display
    localparam V_ACTIVE = 10'd480;
    // localparam V_FRONT = 10'd11;
    localparam V_FRONT = 10'd41; // for my display
    localparam V_MAX = V_SYNC + V_BACK + V_ACTIVE + V_FRONT - 10'd1;

    localparam H_BAR = 10'd80;
    localparam V_BAR = 10'd24;


    logic [9:0] h_count = 10'd0; // 0 ~ 799
    logic [9:0] v_count = 10'd0; // 0 ~ 524

    logic [7:0] x = 8'd0; // 0 ~ 159
    logic [7:0] y = 8'd0; // 0 ~ 143

    logic [1:0] x_inc_counter = 2'd0; // 0 ~ 2
    logic [1:0] y_inc_counter = 2'd0; // 0 ~ 2

    logic [14:0] color_reg = 15'h0;

    logic h_visible, v_visible;


    assign draw_pixel_num = {y, x};

    always_comb begin
        if (~(h_visible & v_visible)) begin
            {vga_r, vga_g, vga_b} = 12'h0;
        end else if (cgb) begin
            vga_r = color_reg[4:1];
            vga_g = color_reg[9:6];
            vga_b = color_reg[14:11];
        end else if (dmg_monochrome) begin
            if (color_reg == 15'h7fff) begin
                {vga_r, vga_g, vga_b} = 12'hfff;
            end else begin
                unique case (color_reg[1:0])
                    2'b00: {vga_r, vga_g, vga_b} = 12'hfff;
                    2'b01: {vga_r, vga_g, vga_b} = 12'hbbb;
                    2'b10: {vga_r, vga_g, vga_b} = 12'h555;
                    2'b11: {vga_r, vga_g, vga_b} = 12'h000; 
                endcase
            end
        end else begin
            if (color_reg == 15'h7fff) begin
                {vga_r, vga_g, vga_b} = 12'hac1;
            end else begin
                unique case (color_reg[1:0])
                    2'b00: {vga_r, vga_g, vga_b} = 12'hac1;
                    2'b01: {vga_r, vga_g, vga_b} = 12'h8a0;
                    2'b10: {vga_r, vga_g, vga_b} = 12'h363;
                    2'b11: {vga_r, vga_g, vga_b} = 12'h141; 
                endcase
            end
        end
    end


    always_ff @(posedge clk) begin
        color_reg <= draw_pixel_color;
    end


    // --- Horizontal ---------

    assign vga_hs = (h_count >= H_SYNC);
    assign h_visible =
            (h_count >= H_SYNC + H_BACK + H_BAR)
            & (h_count < H_SYNC + H_BACK + H_ACTIVE - H_BAR);
    
    always_ff @(posedge clk) begin
        h_count <= (h_count == H_MAX) ? 10'd0 : (h_count + 10'd1);
    end

    always_ff @(posedge clk) begin
        if (h_visible) begin
            x_inc_counter <= (x_inc_counter == 2'd2)
                                ? 2'd0 : (x_inc_counter + 2'd1);
        end else begin
            x_inc_counter <= 2'd1;
        end
    end

    always_ff @(posedge clk) begin
        if (h_visible) begin
            if (x_inc_counter == 2'd2) begin
                x <= x + 8'd1;
            end
        end else begin
            x <= 8'd0;
        end
    end

    // --- Vertical ---------
    
    assign vga_vs = (v_count >= V_SYNC);
    assign v_visible =
            (v_count >= V_SYNC + V_BACK + V_BAR)
            & (v_count < V_SYNC + V_BACK + V_ACTIVE - V_BAR);

    always_ff @(posedge clk) begin
        if (h_count == H_MAX) begin
            v_count <= (v_count == V_MAX) ? 10'd0 : (v_count + 10'd1);
        end
    end

    always_ff @(posedge clk) begin
        if (v_visible) begin
            if (h_count == H_MAX) begin
                y_inc_counter <= (y_inc_counter == 2'd2)
                                    ? 2'd0 : (y_inc_counter + 2'd1);
            end
        end else begin
            y_inc_counter <= 2'd0;
        end
    end

    always_ff @(posedge clk) begin
        if (v_visible) begin
            if ((y_inc_counter == 2'd2) & (h_count == H_MAX)) begin
                y <= y + 8'd1;
            end
        end else begin
            y <= 8'd0;
        end
    end
    
endmodule
