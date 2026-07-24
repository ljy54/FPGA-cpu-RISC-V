/*
    * 流水线仲裁与控制模块
    * 负责控制流水线各阶段的操作
*/
`include "defines.v"
module ctrl (
    input clk, // 时钟信号
    input rst, // 复位信号

    // 流水线各阶段信号
    input branch_en, // 分支跳转使能
    input jal_en, // 译码阶段跳转指令类型
    // input [1:0] ex_jal, // 执行阶段跳转指令类型
    
    input [`RS1_WIDTH-1:0] rs1_addr, // 译码阶段rs1地址
    input [`RS1_WIDTH-1:0] rs2_addr, // 译码阶段rs2地址
    input [`OPCODE_WIDTH-1:0] ex_out_op_code, // 执行阶段opcode
    input [`CPU_WIDTH-1:0] ex_out_current_p, // 执行阶段当前工作地址
    input [`CPU_WIDTH-1:0] ex_out_imm, // 执行阶段立即数
    input [`RD_WIDTH-1:0] ex_out_rd_addr, // 执行阶段rd地址
    input [`CPU_WIDTH-1:0] rs1_value, // 寄存器1的值
    input [`CPU_WIDTH-1:0] current_p, // 当前工作地址

    // 数据传输信号
    input irom_valid, // 指令ROM有效信号
    input perip_valid, // 外设数据有效信号
    input perip_ren,

    // 调试信号
    input debug_halt, // 调试暂停信号
    input debug_resume, // 调试复位信号

    // 输出信号
    output reg if_halt, // IF阶段暂停
    output reg id_halt, // ID阶段暂停
    output reg ex_halt, // EX阶段暂停
    output reg mem_halt, // MEM阶段暂停
    output reg wb_halt, // WB阶段暂停

    output reg if_resume, // IF阶段复位
    output reg id_resume, // ID阶段复位
    output reg ex_resume, // EX阶段复位
    output reg mem_resume, // MEM阶段复位
    output reg wb_resume // WB阶段复位

    // output reg [`CPU_WIDTH-1:0] next_p // PC地址输出

);
wire load_use_hazard; // 加载使用冒险
assign load_use_hazard = (ex_out_op_code == `INST_TYPE_I_L) && ((rs1_addr!=`REG_ZERO && ex_out_rd_addr == rs1_addr) || (rs2_addr!=`REG_ZERO && ex_out_rd_addr == rs2_addr));

    always @(*) begin
        if (debug_resume) begin
            if_resume = 1'b1;
        end else begin
            if_resume = 1'b0;
        end

        if (debug_halt) begin
            if_halt = 1'b1;
        end else if (!irom_valid || (perip_ren && !perip_valid)) begin
            if_halt = 1'b1;
        end else if (load_use_hazard) begin
            if_halt = 1'b1;
        end else begin
            if_halt = 1'b0;
        end
    end

    always @(*) begin
        if (debug_resume) begin
            id_resume = 1'b1;
        end if (jal_en || branch_en) begin
            id_resume = 1'b1; // 跳转指令需要复位ID阶段
        end else 
            id_resume = 1'b0;

        if (debug_halt) begin
            id_halt = 1'b1;
        end else if (!irom_valid || (perip_ren && !perip_valid)) begin
            id_halt = 1'b1;
        end else if (load_use_hazard) begin
            id_halt = 1'b1;
        end else
            id_halt = 1'b0;
    end

    always @(*) begin
        if (debug_resume) begin
            ex_resume = 1'b1;
        end else if (branch_en || (!(perip_ren && !perip_valid) && load_use_hazard) || jal_en) begin
            ex_resume = 1'b1;
        end else begin
            ex_resume = 1'b0;
        end

        if (debug_halt) begin
            ex_halt = 1'b1;
        end else if (!irom_valid || (perip_ren && !perip_valid)) begin
            ex_halt = 1'b1;
        end else begin
            ex_halt = 1'b0;
        end
    end

    always @(*) begin
        if (debug_resume) begin
            mem_resume = 1'b1;
        end else if (branch_en || jal_en) begin
            mem_resume = 1'b1;
        end else begin
            mem_resume = 1'b0;
        end

        if (debug_halt) begin
            mem_halt = 1'b1;
        end else if (!irom_valid || (perip_ren && !perip_valid)) begin
            mem_halt = 1'b1;
        end else begin
            mem_halt = 1'b0;
        end
    end

    always @(*) begin
        if (debug_resume) begin
            wb_resume = 1'b1;
        end else begin
            wb_resume = 1'b0;
        end

        if (debug_halt) begin
            wb_halt = 1'b1;
        end else if (!irom_valid || (perip_ren && !perip_valid)) begin
            wb_halt = 1'b1;
        end else begin
            wb_halt = 1'b0;
        end
    end
endmodule
