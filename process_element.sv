module process_element
    #(parameter SCREEN_HEIGHT = 600)
    (input  logic        clk,
    input  logic [15:0] x_pos,
    input  logic [15:0] y_pos,
    input  logic [15:0] angle,
    output logic [7:0]  color,
    output logic [9:0]  height
);

    // map
    logic [7:0] map [0:63][0:63];

    // angle phase
    logic [7:0] phase;
    assign phase = angle[15:8];   // 0–255 → 0–360°

    logic [7:0] cos_phase;
    assign cos_phase = phase + 8'd64; // +90°

    // sin table
    logic signed [15:0] sin_rom [0:255];

    initial begin
        `include "sin_rom_256_q14.svh"
    end

    // ray direction
    logic signed [15:0] rayDirX, rayDirY;

    always_ff @(posedge clk) begin
        rayDirY <= sin_rom[phase];
        rayDirX <= sin_rom[cos_phase];
    end

    // map cell
    logic [7:0] mapX, mapY;
    assign mapX = x_pos[15:8];
    assign mapY = y_pos[15:8];

    // step direction
    logic signed [1:0] stepX, stepY;

    always_comb begin
        stepX = rayDirX[15] ? -2'sd1 : 2'sd1;
        stepY = rayDirY[15] ? -2'sd1 : 2'sd1;
    end

    // absolute function
    function automatic signed [15:0] abs16(input signed [15:0] v);
        abs16 = v[15] ? -v : v;
    endfunction

    // reciprocal lookup table
    logic signed [15:0] inv_rom [0:255];
    initial begin
        `include "inv_rom_q14.svh"
    end

    logic [7:0] rayX_idx, rayY_idx;
    assign rayX_idx = rayDirX[15:8];
    assign rayY_idx = rayDirY[15:8];

    // delta distances
    logic [15:0] deltaDistX, deltaDistY, perpWallDistance;

    always_ff @(posedge clk) begin
        if (rayDirX == 0)
            deltaDistX <= 16'hFFFF;
        else
            deltaDistX <= abs16(inv_rom[rayX_idx]);

        if (rayDirY == 0)
            deltaDistY <= 16'hFFFF;
        else
            deltaDistY <= abs16(inv_rom[rayY_idx]);
    end

    // side distances
    logic [15:0] sideDistX, sideDistY;
    logic [7:0] fracX, fracY;

    assign fracX = x_pos[7:0];
    assign fracY = y_pos[7:0];

    always_ff @(posedge clk) begin
        if (rayDirX[15])
            sideDistX <= (fracX * deltaDistX) >> 8;
        else
            sideDistX <= ((16'd256 - fracX) * deltaDistX) >> 8;

        if (rayDirY[15])
            sideDistY <= (fracY * deltaDistY) >> 8;
        else
            sideDistY <= ((16'd256 - fracY) * deltaDistY) >> 8;
    end

    // DDA State
    logic hit = 0;
    logic side;   // 0 = X wall, 1 = Y wall

    // preform DDA
   always_ff @(posedge clk) begin
		while (hit = 0) begin
			// jump to next square
			if(sideDistX < sideDistY) begin
				sideDistX <= sideDistX + deltaDistX;
				mapX <= mapX + stepX;
				side = 0;
			end
			else begin
				sideDistY <= sideDistY + deltaDistY;
				mapY <= mapY + stepY;
				side = 1;
			end
			// check for hit
			if(map[mapX][mapY] > 0) begin
				hit = 1;
			end
		end

		// correct for no fisheyeness (no motion sickness here)
		if(side = 0) begin
			perpWallDistance <= sideDistX - deltaDistX;
		end
		else begin
			perpWallDistance <= sideDistY - deltaDistY;
        end

        //output
        color <= map[mapX][mapY];
        height <= SCREEN_HEIGHT * (inv_rom(perpWallDistance));
	end


endmodule
