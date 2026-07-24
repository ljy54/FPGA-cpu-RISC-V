/*
    译码——执行 中间控制
*/

`include "defines.v"
module id_ex (
    input clk,
    input sys_en,
    input halt, //暂停信号
    input resume, //复位信号
    input [`CPU_WIDTH-1:0] in_current_p,
    input [`OPCODE_WIDTH-1:0] in_op_code,
    input [`CPU_WIDTH-1:0] in_imm,
    input [`ALU_TYPES_WIDTH-1:0] in_alu_type,
    input [`EXTENDS_TYPES_WIDTH-1:0] in_extends_type,
    input [`DATA_CTRL_TYPES_WIDTH-1:0] in_data_ctrl_type,
    input in_reg_write_en,
    input [`RD_WIDTH-1:0] in_rd_addr,
    input [1:0] in_jal,


    output reg [`CPU_WIDTH-1:0] out_current_p,
    output reg [`OPCODE_WIDTH-1:0] out_op_code,
    output reg [`CPU_WIDTH-1:0] out_imm,
    output reg [`ALU_TYPES_WIDTH-1:0] out_alu_type,
    output reg [`EXTENDS_TYPES_WIDTH-1:0] out_extends_type,
    output reg [`DATA_CTRL_TYPES_WIDTH-1:0] out_data_ctrl_type,
    output reg out_reg_write_en,
    output reg [`RD_WIDTH-1:0] out_rd_addr,
    output reg [1:0] out_jal
);

always @(posedge clk) begin
    if (!sys_en || resume) begin
        out_current_p <= out_current_p;
        out_op_code <= `OPCODE_WIDTH'b011_0011; 
        out_imm <= `REG_ZERO;
        out_alu_type <= `ALU_TYPE_ADD;
        out_extends_type <= `EXTENDS_TYPE_NONE;
        out_data_ctrl_type <= `DATA_CTRL_TYPE_NONE;
        out_reg_write_en <= 1'b0;
        out_rd_addr <= `RD_WIDTH'b0;
        out_jal <= 2'b00;
    end else if (halt) begin
        out_current_p <= out_current_p;
        out_op_code <= out_op_code;
        out_imm <= out_imm;
        out_alu_type <= out_alu_type;
        out_extends_type <= out_extends_type;
        out_data_ctrl_type <= out_data_ctrl_type;
        out_reg_write_en <= out_reg_write_en;
        out_rd_addr <= out_rd_addr;
        out_jal <= out_jal;
    end else begin
        out_current_p <= in_current_p;
        out_op_code <= in_op_code;
        out_imm <= in_imm;
        out_alu_type <= in_alu_type;
        out_extends_type <= in_extends_type;
        out_data_ctrl_type <= in_data_ctrl_type;
        out_reg_write_en <= in_reg_write_en;
        out_rd_addr <= in_rd_addr;
        out_jal <= in_jal;
    end
end

endmodule //id_ex