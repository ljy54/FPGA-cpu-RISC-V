/*
    存储器访问-写回阶段 中间控制
*/

`include "defines.v"

module mem_wb (
    input clk,
    input sys_en,
    input halt, //暂停信号
    input resume, //复位信号
    input [`OPCODE_WIDTH-1:0] in_op_code,
    input [`CPU_WIDTH-1:0] in_alu_result,
    input [`CPU_WIDTH-1:0] in_ram_data,
    input in_reg_write_en,
    input [`RD_WIDTH-1:0] in_rd_addr,

    output reg [`OPCODE_WIDTH-1:0] out_op_code,
    output reg [`CPU_WIDTH-1:0] out_alu_result,
    output reg [`CPU_WIDTH-1:0] out_ram_data,
    output reg out_reg_write_en,
    output reg [`RD_WIDTH-1:0] out_rd_addr
);

always @(posedge clk) begin
    if (!sys_en || resume) begin
        out_op_code      <= `OPCODE_WIDTH'b0;
        out_alu_result   <= `REG_ZERO;
        out_ram_data     <= `CPU_WIDTH'b0;
        out_reg_write_en <= 1'b0;
        out_rd_addr         <= `RD_WIDTH'b0;
    end else if(halt) begin
        out_op_code      <= out_op_code;
        out_alu_result   <= out_alu_result;
        out_ram_data     <= out_ram_data;
        out_reg_write_en <= out_reg_write_en;
        out_rd_addr          <= out_rd_addr;
    end else begin
        out_op_code      <= in_op_code;
        out_alu_result   <= in_alu_result;
        out_ram_data     <= in_ram_data;
        out_reg_write_en <= in_reg_write_en;
        out_rd_addr          <= in_rd_addr;
    end
end

endmodule //mem_wb