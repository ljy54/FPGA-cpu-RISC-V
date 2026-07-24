/*
    执行——存储器访问 中间控制
*/

`include "defines.v"

module ex_mem (
    input clk,
    input sys_en,
    input halt, //暂停信号
    input resume, //复位信号
    input [`OPCODE_WIDTH-1:0] in_op_code,
    input [`DATA_CTRL_TYPES_WIDTH-1:0] in_data_ctrl_type,
    input [`EXTENDS_TYPES_WIDTH-1:0] in_extends_type,
    input [`CPU_WIDTH-1:0] in_ram_addr, // alu_result
    input in_reg_write_en,
    input [`RD_WIDTH-1:0] in_rd_addr,
    input [`CPU_WIDTH-1:0] in_perip_wdata_reg,
    input [3:0] in_perip_mask_reg,
    input in_perip_wen_reg,
    input [`CPU_WIDTH-1:0] in_perip_addr_reg,

    output reg [`OPCODE_WIDTH-1:0] out_op_code,
    output reg [`DATA_CTRL_TYPES_WIDTH-1:0] out_data_ctrl_type,
    output reg [`EXTENDS_TYPES_WIDTH-1:0] out_extends_type,
    output reg [`CPU_WIDTH-1:0] out_ram_addr, // alu_result
    output reg out_reg_write_en,
    output reg [`RD_WIDTH-1:0] out_rd_addr,
    output reg [`CPU_WIDTH-1:0] out_perip_wdata_reg,
    output reg [3:0] out_perip_mask_reg,
    output reg out_perip_wen_reg,
    (*MAX_FANOUT=50*) output reg [`CPU_WIDTH-1:0] out_perip_addr_reg_rep0,
    (*MAX_FANOUT=50*) output reg [`CPU_WIDTH-1:0] out_perip_addr_reg_rep1,
    (*MAX_FANOUT=50*) output reg [`CPU_WIDTH-1:0] out_perip_addr_reg_rep2,
    (*MAX_FANOUT=50*) output reg [`CPU_WIDTH-1:0] out_perip_addr_reg_rep3,
    (*MAX_FANOUT=50*) output reg [`CPU_WIDTH-1:0] out_perip_addr_reg_rep4

);

always @(posedge clk) begin
    if (!sys_en || resume) begin
        out_op_code          <= `OPCODE_WIDTH'b0;
        out_data_ctrl_type   <= `DATA_CTRL_TYPE_NONE;
        out_extends_type     <= `EXTENDS_TYPE_NONE;
        out_ram_addr         <= `REG_ZERO;
        out_reg_write_en     <= 1'b0;
        out_rd_addr         <= `RD_WIDTH'b0;

        out_perip_wdata_reg <= `REG_ZERO;
        out_perip_mask_reg <= 4'b0000;
        out_perip_wen_reg <= 1'b0;
        out_perip_addr_reg_rep0 <= `REG_ZERO;
        out_perip_addr_reg_rep1 <= `REG_ZERO;
        out_perip_addr_reg_rep2 <= `REG_ZERO;
        out_perip_addr_reg_rep3 <= `REG_ZERO;
        out_perip_addr_reg_rep4 <= `REG_ZERO;
    end else if (halt) begin
        out_op_code          <= out_op_code;
        out_data_ctrl_type   <= out_data_ctrl_type;
        out_extends_type     <= out_extends_type;
        out_ram_addr         <= out_ram_addr;
        out_reg_write_en     <= out_reg_write_en;
        out_rd_addr          <= out_rd_addr;
        out_perip_wdata_reg <= out_perip_wdata_reg;
        out_perip_mask_reg <= out_perip_mask_reg;
        out_perip_wen_reg <= out_perip_wen_reg;
        out_perip_addr_reg_rep0 <= out_perip_addr_reg_rep0;
        out_perip_addr_reg_rep1 <= out_perip_addr_reg_rep1;
        out_perip_addr_reg_rep2 <= out_perip_addr_reg_rep2;
        out_perip_addr_reg_rep3 <= out_perip_addr_reg_rep3;
        out_perip_addr_reg_rep4 <= out_perip_addr_reg_rep4;
    end else begin
        out_op_code          <= in_op_code;
        out_data_ctrl_type   <= in_data_ctrl_type;
        out_extends_type     <= in_extends_type;
        out_ram_addr         <= in_ram_addr;
        out_reg_write_en     <= in_reg_write_en;
        out_rd_addr          <= in_rd_addr;
        out_perip_wdata_reg <= in_perip_wdata_reg;
        out_perip_mask_reg <= in_perip_mask_reg;
        out_perip_wen_reg <= in_perip_wen_reg;
        out_perip_addr_reg_rep0 <= in_perip_addr_reg;
        out_perip_addr_reg_rep1 <= in_perip_addr_reg;
        out_perip_addr_reg_rep2 <= in_perip_addr_reg;
        out_perip_addr_reg_rep3 <= in_perip_addr_reg;
        out_perip_addr_reg_rep4 <= in_perip_addr_reg;
        
    end
end

endmodule