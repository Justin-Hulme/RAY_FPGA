module control_unit #(
    parameter SCREEN_WIDTH  = 640,
    parameter SCREEN_HEIGHT = 600,
    parameter FIFO_DEPTH    = 32
)(
    input  logic        clk,

    // camera
    input  logic [15:0] x_pos,
    input  logic [15:0] y_pos,
    input  logic [15:0] angle,

    // output stream (to VGA)
    output logic        col_valid,
    output logic [9:0]  col_index,
    output logic [9:0]  col_height,
    output logic [7:0]  col_color,
    output logic        col_y_side
);

    // Column packet
    typedef struct packed {
        logic [9:0] column;
        logic [9:0] height;
        logic [7:0] color;
        logic       y_side;
    } column_t;

    // FIFO
    localparam FIFO_BITS = $clog2(FIFO_DEPTH);

    column_t fifo_mem [FIFO_DEPTH];
    logic [FIFO_BITS:0] wr_ptr, rd_ptr;

    logic fifo_full, fifo_empty;

    assign fifo_empty =
        (wr_ptr == rd_ptr);

    assign fifo_full =
        (wr_ptr[FIFO_BITS] != rd_ptr[FIFO_BITS]) &&
        (wr_ptr[FIFO_BITS-1:0] == rd_ptr[FIFO_BITS-1:0]);

    // write
    logic fifo_wr;
    column_t fifo_in;

    always_ff @(posedge clk) begin
        if (fifo_wr && !fifo_full) begin
            fifo_mem[wr_ptr[FIFO_BITS-1:0]] <= fifo_in;
            wr_ptr <= wr_ptr + 1;
        end
    end

    // read
    logic fifo_rd;
    column_t fifo_out;

    assign fifo_out = fifo_mem[rd_ptr[FIFO_BITS-1:0]];

    always_ff @(posedge clk) begin
        if (fifo_rd && !fifo_empty)
            rd_ptr <= rd_ptr + 1;
    end

    // Column scheduler (1 column per cycle)
    logic [9:0] column_counter;

    always_ff @(posedge clk) begin
        if (column_counter == SCREEN_WIDTH-1)
            column_counter <= 10'd0;
        else
            column_counter <= column_counter + 1;
    end

    // angle step = FOV / SCREEN_WIDTH
    localparam signed [15:0] ANGLE_STEP = 16'd128; // tune later

    logic signed [15:0] ray_angle;

    assign ray_angle =
        angle +
        ( $signed({1'b0,column_counter}) -
          $signed(SCREEN_WIDTH/2) ) * ANGLE_STEP;

    // process_element instance
    logic pe_done;
    logic [9:0] pe_column;
    logic [9:0] pe_height;
    logic [7:0] pe_color;
    logic       pe_y_side;

    process_element #(
        .SCREEN_HEIGHT(SCREEN_HEIGHT)
    ) pe (
        .clk        (clk),
        .start      (1'b1),             // launch every cycle
        .x_pos      (x_pos),
        .y_pos      (y_pos),
        .angle      (ray_angle),
        .column_id  (column_counter),

        .done       (pe_done),
        .out_column_id (pe_column),

        .color      (pe_color),
        .height     (pe_height),
        .y_side     (pe_y_side)
    );

    // FIFO write on ray completion
    always_comb begin
        fifo_wr = pe_done && !fifo_full;

        fifo_in.column = pe_column;
        fifo_in.height = pe_height;
        fifo_in.color  = pe_color;
        fifo_in.y_side = pe_y_side;
    end

    // Output stream (send to dual port RAM module)
    always_ff @(posedge clk) begin
        if (!fifo_empty) begin
            col_valid  <= 1'b1;
            col_index  <= fifo_out.column;
            col_height <= fifo_out.height;
            col_color  <= fifo_out.color;
            col_y_side <= fifo_out.y_side;
            fifo_rd    <= 1'b1;
        end else begin
            col_valid <= 1'b0;
            fifo_rd   <= 1'b0;
        end
    end

endmodule
