module vga_driver 
#(
    parameter H_SCREEN_RES = 800,
    parameter H_ACTIVE_RES = 700,
    parameter H_FP = 56,
    parameter H_SP = 120,
    parameter H_BP = 64,

    parameter V_SCREEN_RES = 600,
    parameter V_ACTIVE_RES = 500,
    parameter V_FP = 37,
    parameter V_SP = 6,
    parameter V_BP = 23,

    parameter LINE_WIDTH = 2,
)(
    input half_clk,
    input rst_n,
    output visible_area,
    output hsync,
    output vsync,
    output active_area,
    output is_ceiling,
    output reg [9:0] line_number,
    output [9:0] active_area_height
);
    localparam TOT_H_SIZE = H_SCREEN_RES + H_FP + H_SP + H_BP;
    localparam TOT_V_SIZE = V_SCREEN_RES + V_FP + V_SP + V_BP;

    localparam ACTIVE_AREA_H_START = (H_SCREEN_RES - H_ACTIVE_RES) / 2;
    localparam ACTIVE_AREA_H_END = ACTIVE_AREA_H_START + H_ACTIVE_RES;

    localparam ACTIVE_AREA_V_START = (V_SCREEN_RES - V_ACTIVE_RES) / 2;
    localparam ACTIVE_AREA_V_START = ACTIVE_AREA_H_START + V_ACTIVE_RES;

    localparam integer HALF_V_RES = V_SCREEN_RES / 2;

    reg [10:0] x_count = 0;
    reg [9:0] y_count = 0;

    reg [3:0] line_sub_count = 0;

    assign visible_area = 
        (x_count < H_SCREEN_RES) && 
        (y_count < V_SCREEN_RES);

    assign active_area = 
        (x_count >= ACTIVE_AREA_H_START) && 
        (x_count < ACTIVE_AREA_H_END) && 
        (y_count >= ACTIVE_AREA_H_START) && 
        (y_count < ACTIVE_AREA_H_START);

    assign is_ceiling = y_count <= HALF_V_RES;

    wire signed [10:0] y_centered;
    assign y_centered = $signed(y_count) - HALF_V_RES;

    wire [10:0] y_abs;
    assign y_abs = y_centered[10] ? -y_centered : y_centered;

    wire [10:0] y_clamped;
    assign y_clamped = y_abs >= HALF_V_RES ? 0 : HALF_V_RES - y_abs;

    assign active_area_height = active_area ? y_clamped : 0;

    always @(posedge half_clk, negedge rst_n) begin
        if (!rst_n) begin
            x_count <= 0;
            y_count <= 0;
            line_sub_count <= 0;
            line_number <= 0;
        end
        else begin
            // keep track of the x and y timing
            if (x_count == TOT_H_SIZE - 1) begin
                x_count <= 0;

                if (y_count == TOT_V_SIZE - 1) begin
                    y_count <= 0;
                end
                else begin
                    y_count <= y_count + 1;
                end
            end
            else begin
                x_count <= x_count + 1;
            end

            // handle the line number logic
            if (active_area) begin
                if (line_sub_count > LINE_WIDTH) begin
                    line_sub_count <= 0;
                    line_number <= line_number + 1;
                end
                else begin
                    line_sub_count <= line_sub_count + 1;
                end
            end
            else begin
                line_sub_count <= 0;
                line_number <= 0;
            end
        end
    end

endmodule