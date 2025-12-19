module process_element
#(
    parameter SCREEN_HEIGHT = 600
)
(
    input  logic        clk,
    input  logic [15:0] x_pos,
    input  logic [15:0] y_pos,
    input  logic [15:0] angle,
    output logic [7:0]  color,
    output logic [9:0]  height,
    output logic        y_side
);

    // Map (64x64)
    logic [7:0] map [0:63][0:63];

    // Angle -> phase
    logic [7:0] phase;
    logic [7:0] cos_phase;

    assign phase     = angle[15:8];          // 0-55
    assign cos_phase = phase + 8'd64;         // +90 deg

    // Sine ROM
    logic signed [15:0] sin_rom [0:255];

    initial begin
        `include "sin_rom_256_q14.svh"
    end

    // Ray direction
    logic signed [15:0] rayDirX, rayDirY;

    always_ff @(posedge clk) begin
        rayDirY <= sin_rom[phase];
        rayDirX <= sin_rom[cos_phase];
    end

    // Reciprocal ROM
    logic signed [15:0] inv_rom [0:255];

    initial begin
        `include "inv_rom_q14.svh"
    end

    // Absolute value helper
    function automatic signed [15:0] abs16(input signed [15:0] v);
        abs16 = v[15] ? -v : v;
    endfunction

    // DDA State Machine
    typedef enum logic [1:0] {
        DDA_IDLE,
        DDA_STEP,
        DDA_CHECK,
        DDA_DONE
    } dda_state_t;

    dda_state_t state, next_state;

    always_ff @(posedge clk)
        state <= next_state;

    // combinational logic for FSM
    always_comb begin
        next_state = state;
        case (state)
            DDA_IDLE:  next_state = DDA_STEP;
            DDA_STEP:  next_state = DDA_CHECK;
            DDA_CHECK: next_state = hit ? DDA_DONE : DDA_STEP;
            DDA_DONE:  next_state = DDA_DONE;
        endcase
    end

    // Map positions
    logic [7:0] mapX, mapY;

    // Step direction
    logic signed [1:0] stepX, stepY;

    always_comb begin
        stepX = rayDirX[15] ? -2'sd1 : 2'sd1;
        stepY = rayDirY[15] ? -2'sd1 : 2'sd1;
    end

    // Delta distances
    logic [15:0] deltaDistX, deltaDistY;

    logic [7:0] rayX_idx, rayY_idx;

    assign rayX_idx = abs16(rayDirX)[15:8];
    assign rayY_idx = abs16(rayDirY)[15:8];

    // Side distances
    logic [15:0] sideDistX, sideDistY;

    // fractional parts
    logic [7:0] fracX, fracY;
    assign fracX = x_pos[7:0];
    assign fracY = y_pos[7:0];

    // Hit logic
    logic hit;
    logic side;   // 0 = X wall, 1 = Y wall


    // Perpendicular distance to prevent fisheyeness
    logic [15:0] perpWallDistance;

    // Main DDA stuff
    always_ff @(posedge clk) begin
        case (state)

            DDA_IDLE: begin
                hit <= 1'b0;
                side <= 1'b0;

                mapX <= x_pos[15:8];
                mapY <= y_pos[15:8];

                // delta distances
                deltaDistX <= (rayDirX == 0) ? 16'hFFFF
                              : abs16(inv_rom[rayX_idx]);

                deltaDistY <= (rayDirY == 0) ? 16'hFFFF
                              : abs16(inv_rom[rayY_idx]);

                // initial side distances
                sideDistX <= rayDirX[15]
                           ? (fracX * deltaDistX) >> 8
                           : ((16'd256 - fracX) * deltaDistX) >> 8;

                sideDistY <= rayDirY[15]
                           ? (fracY * deltaDistY) >> 8
                           : ((16'd256 - fracY) * deltaDistY) >> 8;
            end

            DDA_STEP: begin
                if (sideDistX < sideDistY) begin
                    sideDistX <= sideDistX + deltaDistX;
                    mapX      <= mapX + stepX;
                    side      <= 1'b0;
                end else begin
                    sideDistY <= sideDistY + deltaDistY;
                    mapY      <= mapY + stepY;
                    side      <= 1'b1;
                end
            end

            DDA_CHECK: begin
                if (map[mapX][mapY] != 0)
                    hit <= 1'b1;
            end

            DDA_DONE: begin
                if (side == 1'b0)
                    perpWallDistance <= sideDistX - deltaDistX;
                else
                    perpWallDistance <= sideDistY - deltaDistY;

                color  <= map[mapX][mapY];
                y_side <= side;

                height <= (SCREEN_HEIGHT *
                          inv_rom[perpWallDistance[15:8]]) >> 14;
            end

        endcase
    end

endmodule
