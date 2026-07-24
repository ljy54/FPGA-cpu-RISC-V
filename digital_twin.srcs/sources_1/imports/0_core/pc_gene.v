/*
    地址更新
    更新目前运行的指令地址
*/

`include "defines.v"

module pc_gene (
    input clk,
    input sys_en,

    input halt, //Load-Use冒险
    input resume, //复位信号

    input pc_wen, //PC写使能
    input [`CPU_WIDTH-1:0] pc_wdata, //当前工作地址

    input [`CPU_WIDTH-1:0] ra_x1, //ra
    input [`OPCODE_WIDTH-1:0] ex_out_op_code, //操作码
    input ex_out_result,
    input [`CPU_WIDTH-1:0] ex_out_current_p, //执行工作地址
    input [`CPU_WIDTH-1:0] id_out_current_p, //译码工作地址
    input [1:0] ex_out_jal, //执行阶段的跳转类型
    input [`CPU_WIDTH-1:0] ex_out_imm,
    input [`CPU_WIDTH-1:0] rs1_value,
    input [`CPU_WIDTH-1:0] inst, //当前指令

    output reg fix_branch_en, //分支跳转使能
    output reg fix_jal_en, //jal跳转使能
    
    output reg [`CPU_WIDTH-1:0] current_p //目前工作地址
);

    reg [1:0] GBHT = 2'b01; //全局分支历史寄存器
    reg [40:0] BTB [63:0]; // 每个条目：{1'b_valid, 8'b_tag}
    reg [1:0] BHT [63:0]; // 分支历史表，每个条目2位，表示分支的历史状态
    // reg [40:0] btb;

    reg [`CPU_WIDTH-1:0] fix_next_p = 32'd0; // 用于修正跳转地址

    reg b = 0;
    reg jal = 0;
    reg jalr = 0;
    reg exb =0;

    reg [`CPU_WIDTH-1:0] targ_p; // 跳转目标地址
    reg [`CPU_WIDTH-1:0] rs1_value_reg = 32'd0; // 用于存储rs1的值

    integer i;
    initial begin
        for (i = 0; i < 64; i = i + 1) 
            BTB[i] = 41'b0; // 初始化
    end

    always @(posedge clk or negedge sys_en) begin
        if (!sys_en || resume) begin
            fix_next_p <= `CPU_WIDTH'h8000_0000;
            fix_branch_en <= 1'b0;
            fix_jal_en <= 1'b0;
        end else if (halt) begin 
            fix_next_p <= fix_next_p;
            fix_branch_en <= fix_branch_en;
            fix_jal_en <= fix_jal_en;
        end else if (!fix_branch_en && !fix_jal_en) begin
            if (ex_out_op_code == `INST_TYPE_B) begin
                exb <= 1;
                // btb <= BTB[ex_out_current_p[7:2]];
                // if (entry_valid) begin
                if (ex_out_result == 1'b1) begin
                    // 执行阶段的跳转指令使能
                    if (BTB[ex_out_current_p[7:2]][8] && BTB[ex_out_current_p[7:2]][7:0] == ex_out_current_p[15:8] && BHT[ex_out_current_p[7:2]] < 2'b11) begin
                        BHT[ex_out_current_p[7:2]] <= BHT[ex_out_current_p[7:2]] + 2'b01; // 更新分支历史表
                    end else if (!BTB[ex_out_current_p[7:2]][8]) begin
                        BTB[ex_out_current_p[7:2]] = {ex_out_current_p + ex_out_imm, 1'b1, ex_out_current_p[15:8]}; 
                        BHT[ex_out_current_p[7:2]] = GBHT; // 初始化分支历史表
                    end
                    GBHT <= GBHT < 2'b11 ? GBHT + 2'b01 : GBHT; // 更新全局分支历史寄存器
                    if (ex_out_current_p + ex_out_imm == id_out_current_p) begin
                        // 译码阶段工作的地址正是要跳转的地址
                        fix_branch_en <= 1'b0; // 不需要修正分支跳转
                    end else begin
                        // 执行阶段的跳转指令使能，但译码阶段工作的地址不是要跳转的地址
                        fix_next_p <= ex_out_current_p + ex_out_imm; // 直接跳转到执行阶段的目标地址
                        fix_branch_en <= 1'b1; // 需要修正分支跳转
                    end
                end else begin
                    // 执行阶段的跳转指令没有使能
                    if (BTB[ex_out_current_p[7:2]][8] && BTB[ex_out_current_p[7:2]][7:0] == ex_out_current_p[15:8] && BHT[ex_out_current_p[7:2]] > 2'b00) begin
                        BHT[ex_out_current_p[7:2]] <= BHT[ex_out_current_p[7:2]] - 2'b01; // 更新分支历史表
                    end else if (!BTB[ex_out_current_p[7:2]][8]) begin
                        BTB[ex_out_current_p[7:2]] = {ex_out_current_p + ex_out_imm, 1'b1, ex_out_current_p[15:8]}; 
                        BHT[ex_out_current_p[7:2]] = GBHT; // 初始化分支历史表
                    end
                    GBHT <= GBHT > 2'b00 ? GBHT - 2'b01 : GBHT; // 更新全局分支历史寄存器
                    if (ex_out_current_p +`CPU_WIDTH'd4 == id_out_current_p) begin
                        // 译码阶段工作的地址正是要跳转的地址
                        fix_branch_en <= 1'b0; // 不需要修正分支跳转
                    end else begin
                        // 执行阶段的跳转指令使能，但译码阶段工作的地址不是要跳转的地址
                        fix_next_p <= ex_out_current_p + `CPU_WIDTH'd4; // 直接跳转到执行阶段的目标地址
                        fix_branch_en <= 1'b1; // 需要修正分支跳转
                    end
                end
                
            end else begin
                exb <= 0;
                fix_branch_en <= 1'b0;
            end

            if (ex_out_jal == 2'b11) begin
                if (rs1_value + ex_out_imm != id_out_current_p) begin
                    // 译码阶段译码出跳转指令，但是译码给出的rs1值和预测的rs1值不一致
                    // 需要纠正跳转
                    rs1_value_reg <= rs1_value; // 更新rs1的值
                    fix_next_p <= rs1_value + ex_out_imm; // jalr指令的跳转地址
                    fix_jal_en <= 1'b1; // 需要修正jalr跳转
                end else begin
                    // 译码阶段译码出跳转指令，且rs1值和预测的rs1值一致
                    fix_jal_en = 1'b0; // 不需要修正jalr跳转
                end
            end else begin
                fix_jal_en <= 1'b0; // 非jalr指令，不需要修正
            end
        end else begin
            fix_branch_en <= 1'b0; // 如果已经在修正分支跳转，则不再处理
            fix_jal_en <= 1'b0; // 如果已经在修正jalr跳转，则不再处理
            fix_next_p <= `CPU_WIDTH'h8000_0000; // 清除修正跳转地址
        end
        
    end

    always @(posedge clk or negedge sys_en) begin
        if (!sys_en || resume) begin
            current_p <= `CPU_WIDTH'h8000_0000; // 重置下一个工作地址
            b <= 0;
            jal <= 0;
            jalr <= 0;
        end else if (halt) begin
            if (pc_wen)
                current_p <= pc_wdata;
            else
                current_p <= current_p;
        end else begin
            if (!fix_branch_en && !fix_jal_en) begin
                if(inst[6:0] == `INST_TYPE_B)begin 
                    b<=1;
                    if (BTB[current_p[7:2]][8]) begin
                        if (BTB[current_p[7:2]][7:0] == current_p[15:8]) begin
                            // 该分支有效且标签匹配
                            if (BHT[current_p[7:2]][1] == 0) begin
                                // 强不跳转或弱不跳转
                                current_p <= current_p + `CPU_WIDTH'd4; // 不跳转，继续执行下一条指令
                            end else begin
                                // 强跳转或弱跳转
                                current_p <= BTB[current_p[7:2]][40:9]; // 跳转到目标地址
                            end
                        end else begin
                            // 该分支有效但标签不匹配
                            if (GBHT[1] == 0) begin
                                // 强不跳转或弱不跳转
                                current_p <= current_p + `CPU_WIDTH'd4; // 不跳转，继续执行下一条指令
                            end else begin
                                // 强跳转或弱跳转
                                current_p <= current_p + {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0}; // 跳转到目标地址
                            end
                        end
                    end else begin
                        // BTB无效
                        if (GBHT[1] == 0) begin
                            // 强不跳转或弱不跳转
                            current_p <= current_p + `CPU_WIDTH'd4; // 不跳转，继续执行下一条指令
                        end else begin
                            // 强跳转或弱跳转
                            current_p <= current_p + {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0}; // 跳转到目标地址
                        end
                    end
                end else if (inst[6:0] == `INST_TYPE_J_JAL) begin
                    jal <= 1;
                    current_p <= current_p + {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0}; //jal指令的跳转地址
                end else if (inst[6:0] == `INST_TYPE_I_JALR) begin 
                    jalr <= 1;
                    if (inst == 32'h00008067) begin
                        // ret指令
                        current_p <= ra_x1; // 返回地址
                    end else begin
                        current_p <= rs1_value_reg + {{20{inst[31]}}, inst[31:20]}; //jalr指令的跳转地址
                    end
                end else begin
                    b<= 0;
                    jalr<=0;
                    jal<=0;
                    current_p <= current_p + `CPU_WIDTH'd4; // 非跳转指令
                end
            end else begin
                b<= 0;
                jalr<=0;
                jal<=0;
                current_p <= fix_next_p; // 使用修正后的跳转地址
            end
            end
    end

endmodule //pc_gene