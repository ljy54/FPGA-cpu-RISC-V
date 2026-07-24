/*
    立即数生成器
*/

`include "defines.v"

module imm_gen (
    input [`CPU_WIDTH-1:0] inst,
    input [`OPCODE_WIDTH-1:0] opcode,
    output reg [`CPU_WIDTH-1:0] imm
);
always @(*) begin
    imm = `CPU_WIDTH'd0;
    case (opcode)
        `INST_TYPE_R: imm = `CPU_WIDTH'b0;
        `INST_TYPE_I:imm = {{20{inst[31]}}, inst[31:20]};
        `INST_TYPE_I_L:imm = {{20{inst[31]}}, inst[31:20]};
        `INST_TYPE_S:imm = {{20{inst[31]}}, inst[31:25], inst[11:7]};
        `INST_TYPE_B:imm = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
        `INST_TYPE_J_JAL:imm = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
        `INST_TYPE_I_JALR:imm = {{20{inst[31]}}, inst[31:20]};
        `INST_TYPE_U_LUI:imm = {inst[31:12], 12'b0};
        `INST_TYPE_U_AUIPC:imm = {inst[31:12], 12'b0};
    endcase
end
endmodule //imm_gen