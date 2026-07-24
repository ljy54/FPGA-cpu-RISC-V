/*
    第二个算术单元选择器
*/

`include "defines.v"

module mux_alu_2 (
    input [`OPCODE_WIDTH-1:0] op_code,
    input [`CPU_WIDTH-1:0] imm,
    input [`CPU_WIDTH-1:0] rs2_value,
    output reg [`CPU_WIDTH-1:0] value_2
);
always @(*) begin
    case(op_code)
        `INST_TYPE_R: value_2 = rs2_value;
        `INST_TYPE_I: value_2 = imm;
        `INST_TYPE_I_L: value_2 = imm;
        `INST_TYPE_S: value_2 = imm;
        `INST_TYPE_B: value_2 = rs2_value;
        `INST_TYPE_J_JAL: value_2 = `CPU_WIDTH'd4;
        `INST_TYPE_I_JALR: value_2 = `CPU_WIDTH'd4;
        `INST_TYPE_U_LUI: value_2 = `CPU_WIDTH'd12;
        `INST_TYPE_U_AUIPC: value_2 = {imm[31:12], 12'b0};
        `INST_TYPE_I_CSR: value_2 = `CPU_WIDTH'b0;
        default: value_2 = rs2_value;
    endcase
end
endmodule //mux_alu_2