typedef struct packed {
    logic [9:0] height;
    logic [7:0] color;
    logic       y_side;
} vram_entry_t;


module vram #(
    parameter WIDTH = 640
)(
    input  logic        clk,

    // Write port (raycaster)
    input  logic        wen,
    input  logic [9:0]  waddr,
    input  vram_entry_t wdata,

    // Read port (VGA)
    input  logic [9:0]  raddr,
    output vram_entry_t rdata
);

    vram_entry_t mem [0:WIDTH-1];

    // Write (port A)
    always_ff @(posedge clk) begin
        if (we)
            mem[waddr] <= wdata;
    end

    // Read (port B)
    always_ff @(posedge clk) begin
        rdata <= mem[raddr];
    end

endmodule
