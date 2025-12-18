module tristate #(parameter BIT_WIDTH = 8)(
    input select,
    input [BIT_WIDTH - 1:0] in_1,
    input [BIT_WIDTH - 1:0] in_0,
    output [BIT_WIDTH - 1:0] out
);

    assign out = select ? in_1 : in_0;

endmodule