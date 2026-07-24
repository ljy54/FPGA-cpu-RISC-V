`include "defines.v"

module wb (
    input [`OPCODE_WIDTH-1:0] op_code,
    input [`CPU_WIDTH-1:0] alu_result,
    input [`CPU_WIDTH-1:0] ram_value,
    output reg [`CPU_WIDTH-1:0] out_value
);
always @(*) begin
    if (op_code == `INST_TYPE_I_L)
        out_value = ram_value;
    else
        out_value = alu_result;
end
endmodule //wb