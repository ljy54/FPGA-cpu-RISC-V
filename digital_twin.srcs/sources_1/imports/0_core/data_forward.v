/*
    数据前传
    忽视Load-Use冒险
*/

`include "defines.v"

module data_forward (
    input clk,
    input sys_en,

    input halt,
    input resume,

    // 需要比对的两个地址
    input [`RS1_WIDTH-1:0] rs1_addr,
    input [`RS2_WIDTH-1:0] rs2_addr,

    input [`CPU_WIDTH-1:0] id_rs1_value,
    input [`CPU_WIDTH-1:0] id_rs2_value,

    // 比对目标，看rs1_addr或rs2_addr是否与两者有重合，若重合说明目标地址数值被前置指令修改
    input [`RD_WIDTH-1:0] ex_out_rd_addr, 
    input [`RD_WIDTH-1:0] mem_out_rd_addr, 
    input [`RD_WIDTH-1:0] wb_out_rd_addr, 

    input [`CPU_WIDTH-1:0] ex_out_rd_value,
    input [`CPU_WIDTH-1:0] mem_out_rd_value,
    input [`CPU_WIDTH-1:0] wb_out_rd_value,

    output reg [`CPU_WIDTH-1:0] rs1_value,
    output reg [`CPU_WIDTH-1:0] rs2_value
    // output reg [`CPU_WIDTH-1:0] load_use_hazard
);

always @(posedge clk or negedge sys_en) begin
    if (!sys_en || resume) begin
        rs1_value <= `REG_ZERO;
        rs2_value <= `REG_ZERO;
    end else if (halt) begin
        rs1_value <= rs1_value;
        rs2_value <= rs2_value;
    end else begin
        
        if (rs1_addr == `RS1_WIDTH'b0)
            rs1_value <= `REG_ZERO;
        else if (rs1_addr == ex_out_rd_addr)
            rs1_value <= ex_out_rd_value;
        else if (rs1_addr == mem_out_rd_addr)
            rs1_value <= mem_out_rd_value;
        else if (rs1_addr == wb_out_rd_addr)
            rs1_value <= wb_out_rd_value;
        else
            rs1_value <= id_rs1_value;

        if (rs2_addr == `RS2_WIDTH'b0)
            rs2_value <= `REG_ZERO;
        else if (rs2_addr == ex_out_rd_addr)
            rs2_value <= ex_out_rd_value;
        else if (rs2_addr == mem_out_rd_addr)
            rs2_value <= mem_out_rd_value;
        else if (rs2_addr == wb_out_rd_addr)
            rs2_value <= wb_out_rd_value;
        else
            rs2_value <= id_rs2_value;
    end
end

endmodule //data_forward