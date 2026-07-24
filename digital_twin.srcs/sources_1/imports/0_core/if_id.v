/*
    取值——译码 中间控制
    1. 跳转使能时，要拒绝一条新的指令，使用nop指令代替：000000000000_00000_000_00000_0010011
*/

`include "defines.v"
module if_id (
    input clk,
    input sys_en,

    input halt, //暂停信号
    input resume, //复位信号

    input  [`CPU_WIDTH-1:0] in_inst,
    input [`CPU_WIDTH-1:0] in_current_p, 

    output reg [`CPU_WIDTH-1:0] out_inst,
    output reg [`CPU_WIDTH-1:0] out_current_p //给到EX阶段

);

always @(posedge clk) begin
    if (!sys_en || resume) begin  
        out_inst <= `INST_NOP;
        out_current_p <= `REG_ZERO;
    end else if (halt) begin
        out_inst <= out_inst; //暂停时，使用nop指令代替
        out_current_p <= out_current_p; //保持当前工作地址不变
    end else begin
        out_current_p <= in_current_p;
        out_inst <= in_inst;
    end
end

endmodule //if_id