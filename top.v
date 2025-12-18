module top(
    input clk,
    input rst,
    output [3:0] vgaRed,
    output [3:0] vgaGreen,
    output [3:0] vgaBlue,
    output Hsync,
    output Vsync
);
    // vga driver
    wire visible_area, active_area, is_ceiling;
    wire [9:0] line_number, active_area_height;

    // color decoder
    wire line_color = 0xE0; // red
    wire floor_color = 0xA8; // brown
    wire ceiling_color = 0x02; // light blue
    wire background_color = 0x49; // dark grey

    assign rst_n = !rst;

    reg half_clk = 0;
    
    always @(posedge clk) begin
        half_clk <= ~half_clk;
    end

    vga_driver #(
        .H_ACTIVE_RES(700),
        .V_ACTIVE_RES(500),
        .LINE_WIDTH(2)
    ) VGA_DRIVER (
        .half_clk(half_clk),
        .rst_n(rst_n),
        .visible_area(visible_area),
        .is_ceiling(is_ceiling),
        .hsync(Hsync),
        .vsync(Vsync),
        .active_area(active_area),
        .line_number(line_number),
        .active_area_height(active_area_height),
    );

    wire pixel = active_area_height < line_number;

    color_decoder COLOR_DECODER(
        .line_color(line_color),
        .floor_color(floor_color),
        .ceiling_color(ceiling_color),
        .background_color(background_color),
        .visible_area(visible_area),
        .active_area(active_area),
        .is_ceiling(is_ceiling),
        .pixel(pixel),
        .red(vgaRed),
        .green(vgaGreen),
        .blue(vgaBlue)
    );

endmodule