/*
 寄存器控制器
 读写操作
 */

`include "defines.v"

module reg_ctrl (
        input clk,
        input sys_en,

        input debug_reg_wen,
        input [`RD_WIDTH-1:0] debug_reg_addr,
        input [`CPU_WIDTH-1:0] debug_reg_wdata,
        output reg [`CPU_WIDTH-1:0] debug_reg_rdata,

        input write_en,
        input [`RD_WIDTH-1:0] rd_addr,
        input [`CPU_WIDTH-1:0] rd_value,
        input [`RS1_WIDTH-1:0] rs1_addr,
        input [`RS2_WIDTH-1:0] rs2_addr,
        output reg [`CPU_WIDTH-1:0] rs1_value,
        output reg [`CPU_WIDTH-1:0] rs2_value
    );

    reg [`CPU_WIDTH-1:0] reg_value_list [0:2*`CPU_WIDTH-1];

    initial begin
        reg_value_list[0] = `CPU_WIDTH'b0;
    end

    always @(posedge clk) begin
        if (debug_reg_wen) begin
            reg_value_list[debug_reg_addr] <= debug_reg_wdata;
        end 
        if (sys_en) begin
            if ((write_en) && (rd_addr != `RD_WIDTH'b0)) begin
                reg_value_list[rd_addr] <= rd_value;
            end
        end
    end

    always @(*) begin
        debug_reg_rdata = reg_value_list[debug_reg_addr];
    end

    always @(*) begin
        if (rs1_addr == rd_addr)
            rs1_value = rd_value;
        else 
            rs1_value = reg_value_list[rs1_addr];
    end

    always @(*) begin
        if (rs2_addr == rd_addr)
            rs2_value = rd_value;
        else 
            rs2_value = reg_value_list[rs2_addr];
    end

endmodule //reg_ctrl
