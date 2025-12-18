module color_decoder(
    input  [7:0] line_color,
    input  [7:0] floor_color,
    input  [7:0] ceiling_color,
    input  [7:0] background_color,
    input        visible_area,
    input        active_area,
    input        is_ceiling,
    input        pixel,
    output [3:0] red,
    output [3:0] green,
    output [3:0] blue
);

    // RGB332 → RGB444 expansion (bit replication)
    function automatic [11:0] rgb332_to_444(input [7:0] c);
        rgb332_to_444 = {
            c[7:5], c[7],     // red
            c[4:2], c[4],     // green
            c[1:0], c[1:0]    // blue
        };
    endfunction

    wire [11:0] line_rgb       = rgb332_to_444(line_color);
    wire [11:0] floor_rgb      = rgb332_to_444(floor_color);
    wire [11:0] ceiling_rgb    = rgb332_to_444(ceiling_color);
    wire [11:0] background_rgb = rgb332_to_444(background_color);


    wire [11:0] selected_rgb =
    !visible_area ? 12'b0 :
    !active_area  ? background_rgb :
    pixel         ? line_rgb :
    is_ceiling    ? ceiling_rgb :
                    floor_rgb;

    assign {red, green, blue} = selected_rgb;

endmodule
