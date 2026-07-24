/*
    第一个算术单元选择器
*/

`include "defines.v"

module mux_alu_1 (
    input [`CPU_WIDTH-1:0] current_pc,
    input [`OPCODE_WIDTH-1:0] op_code,
    input [`CPU_WIDTH-1:0] imm,
    input [`CPU_WIDTH-1:0] rs1_value,

    output reg [`CPU_WIDTH-1:0] value_1
);

always @(*) begin
    case(op_code)
        `INST_TYPE_J_JAL: value_1 = current_pc;
        `INST_TYPE_I_JALR: value_1 = current_pc;
        `INST_TYPE_U_LUI: value_1 = {{12{1'b0}},imm[31:12]};
        `INST_TYPE_U_AUIPC: value_1 = current_pc;
        default: value_1 = rs1_value;
    endcase
end

endmodule //mux_alu_1