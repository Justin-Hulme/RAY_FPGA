`timescale 1ns/1ps

module tb_process_element;

    // ------------------------------------
    // Clock
    // ------------------------------------
    logic clk = 0;
    always #5 clk = ~clk;   // 100 MHz

    // ------------------------------------
    // DUT signals
    // ------------------------------------
    logic [15:0] x_pos;
    logic [15:0] y_pos;
    logic [15:0] angle;

    logic [7:0]  color;
    logic [9:0]  height;
    logic        y_side;

    // ------------------------------------
    // Instantiate DUT
    // ------------------------------------
    process_element #(.SCREEN_HEIGHT(600)) dut (
        .clk    (clk),
        .x_pos  (x_pos),
        .y_pos  (y_pos),
        .angle  (angle),
        .color  (color),
        .height (height),
        .y_side (y_side)
    );

    // ------------------------------------
    // Test map initialization
    // ------------------------------------
    integer i, j;

    initial begin
        // Clear map
        for (i = 0; i < 64; i = i + 1)
            for (j = 0; j < 64; j = j + 1)
                dut.map[i][j] = 8'd0;

        // Outer walls
        for (i = 0; i < 64; i = i + 1) begin
            dut.map[i][0]  = 8'd1;
            dut.map[i][63] = 8'd1;
            dut.map[0][i]  = 8'd1;
            dut.map[63][i] = 8'd1;
        end

        // Single vertical wall at x = 10
        for (j = 5; j < 60; j = j + 1)
            dut.map[10][j] = 8'd2;
    end

    // ------------------------------------
    // Stimulus
    // ------------------------------------
    initial begin
        // Start position (Q8.8)
        x_pos = 16'h0800;  // x = 8.0
        y_pos = 16'h0800;  // y = 8.0

        // Look east
        angle = 16'h0000;

        // Let it run
        repeat (200) @(posedge clk);

        // Look south
        angle = 16'h4000;  // ~90°
        repeat (200) @(posedge clk);

        // Look west
        angle = 16'h8000;  // ~180°
        repeat (200) @(posedge clk);

        // Look north
        angle = 16'hC000;  // ~270°
        repeat (200) @(posedge clk);

        $display("Simulation finished.");
        $stop;
    end

    // ------------------------------------
    // Monitor
    // ------------------------------------
    always_ff @(posedge clk) begin
        if (dut.state == dut.DDA_DONE) begin
            $display(
                "time=%0t angle=%0d map=(%0d,%0d) side=%0d color=%0d height=%0d",
                $time,
                angle[15:8],
                dut.mapX,
                dut.mapY,
                y_side,
                color,
                height
            );
        end
    end

endmodule
