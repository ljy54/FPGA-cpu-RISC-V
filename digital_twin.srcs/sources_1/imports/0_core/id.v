/*
    译码模块
    将指令译码为要进行的操作
*/

`include "defines.v"

module id (
    input [`CPU_WIDTH-1:0] inst,
    
    output reg [1:0] jal, //普通跳转类型 00不跳转 01：jal 11：jalr
    output reg reg_write_en, //寄存器写入使能
    output reg [`ALU_TYPES_WIDTH-1:0] alu_type, //计算类型
    output reg [`EXTENDS_TYPES_WIDTH-1:0] extends_type, //扩展类型 msb和zero
    output reg [`DATA_CTRL_TYPES_WIDTH-1:0] data_ctrl_type, //数据控制类型
    output reg [`OPCODE_WIDTH-1:0] op_code,
    output reg [`RS1_WIDTH-1:0] rs1_addr,
    output reg [`RS2_WIDTH-1:0] rs2_addr,
    output reg [`RD_WIDTH-1:0] rd_addr
    
);
wire [`OPCODE_WIDTH-1:0] opcode = inst[`OPCODE_WIDTH-1:0];
wire [`RD_WIDTH-1:0] rd = {1'b0, inst[`RD_WIDTH+7-2:7]};
wire [`FUNCT3_WIDTH-1:0] funct3 = inst[`FUNCT3_WIDTH+12-1:12];
wire [`RS1_WIDTH-1:0] rs1 = {1'b0, inst[`RS1_WIDTH+15-2:15]};
wire [`RS2_WIDTH-1:0] rs2 = {1'b0, inst[`RS2_WIDTH+20-2:20]};
wire [`FUNCT7_WIDTH-1:0] funct7 = inst[`FUNCT7_WIDTH+25-1:25];
always @(*) begin
    op_code = opcode; 
    jal = 2'b00;
    reg_write_en = 1'b0;
    alu_type = `ALU_TYPE_ADD;
    extends_type = `EXTENDS_TYPE_NONE;
    data_ctrl_type = `DATA_CTRL_TYPE_NONE;
    rs1_addr = rs1;
    rs2_addr = rs2;
    rd_addr = rd;
    case(opcode)
        `INST_TYPE_R: begin
            case (funct3)
                3'h0: begin
                    case (funct7)
                        7'h00: begin
                            reg_write_en = 1'b1;
                            alu_type = `ALU_TYPE_ADD;
                        end
                        7'h01:begin
                            reg_write_en = 1'b1;
                            alu_type = `ALU_TYPE_MUL;
                        end
                        7'h20:  begin
                            reg_write_en = 1'b1;
                            alu_type = `ALU_TYPE_SUB;
                        end
                    endcase
                end
                3'h1: begin
                    case(funct7)
                        7'h0:begin
                            reg_write_en = 1'b1;
                            alu_type = `ALU_TYPE_SHIFT_LEFT;
                        end
                        7'h1:begin
                            reg_write_en = 1'b1;
                            alu_type = `ALU_TYPE_MULH;
                        end
                    endcase
                end
                3'h2: begin
                    case(funct7)
                        7'h0:begin
                            reg_write_en = 1'b1;
                            alu_type = `ALU_TYPE_LESS_THAN;
                        end
                        7'h1:begin
                            reg_write_en = 1'b1;
                            alu_type = `ALU_TYPE_MULHSU;
                        end
                    endcase
                end
                3'h3: begin
                    case(funct7)
                        7'h0:begin
                            reg_write_en = 1'b1;
                            alu_type = `ALU_TYPE_LESS_THAN;
                            extends_type = `EXTENDS_TYPE_ZERO;
                        end
                        7'h1:begin
                            reg_write_en = 1'b1;
                            alu_type = `ALU_TYPE_MULHU;
                        end
                    endcase
                end
                3'h4: begin
                    case(funct7)
                        7'h0:begin
                            reg_write_en = 1'b1;
                            alu_type = `ALU_TYPE_XOR;
                        end
                    endcase
                end
                3'h5: begin
                    case (funct7)
                        7'h00: begin
                            reg_write_en = 1'b1;
                            alu_type = `ALU_TYPE_SHIFT_RIGHT;
                        end
                        7'h20: begin
                            reg_write_en = 1'b1;
                            alu_type = `ALU_TYPE_SHIFT_RIGHT;
                            extends_type = `EXTENDS_TYPE_MSB;
                        end
                    endcase
                end
                3'h6: begin
                    case(funct7)
                        7'h0:begin
                            reg_write_en = 1'b1;
                            alu_type = `ALU_TYPE_OR;
                        end
                    endcase
                end
                3'h7: begin
                    case(funct7)
                        7'h0:begin
                            reg_write_en = 1'b1;
                            alu_type = `ALU_TYPE_AND;
                        end
                    endcase
                end
            endcase
        end
        `INST_TYPE_I: begin
            case (funct3)
                3'h0: begin
                    reg_write_en = 1'b1;
                    alu_type = `ALU_TYPE_ADD;
                    rs2_addr = `REG_ZERO;
                end
                3'h1: case (funct7)
                    7'h00: begin
                        reg_write_en = 1'b1;
                        alu_type = `ALU_TYPE_SHIFT_LEFT;
                        rs2_addr = `REG_ZERO;
                    end
                endcase
                3'h2: begin
                    reg_write_en = 1'b1;
                    alu_type = `ALU_TYPE_LESS_THAN;
                    rs2_addr = `REG_ZERO;
                end
                3'h3: begin
                    reg_write_en = 1'b1;
                    alu_type = `ALU_TYPE_LESS_THAN;
                    extends_type = `EXTENDS_TYPE_ZERO;
                    rs2_addr = `REG_ZERO;
                end
                3'h4: begin
                    reg_write_en = 1'b1;
                    alu_type = `ALU_TYPE_XOR;
                    rs2_addr = `REG_ZERO;
                end
                3'h5: case (funct7)
                    7'h00: begin
                        reg_write_en = 1'b1;
                        alu_type = `ALU_TYPE_SHIFT_RIGHT;
                        rs2_addr = `REG_ZERO;
                    end
                    7'h20: begin
                        reg_write_en = 1'b1;
                        alu_type = `ALU_TYPE_SHIFT_RIGHT;
                        extends_type = `EXTENDS_TYPE_MSB;
                        rs2_addr = `REG_ZERO;
                    end
                endcase
                3'h6: begin
                    reg_write_en = 1'b1;
                    alu_type = `ALU_TYPE_OR;
                    rs2_addr = `REG_ZERO;
                end
                3'h7: begin
                    reg_write_en = 1'b1;
                    alu_type = `ALU_TYPE_AND;
                    rs2_addr = `REG_ZERO;
                end
            endcase
        end
        `INST_TYPE_I_L: begin
            case (funct3)
                3'h0: begin
                    reg_write_en = 1'b1;
                    alu_type = `ALU_TYPE_ADD;
                    rs2_addr = `REG_ZERO;
                    data_ctrl_type = `DATA_CTRL_TYPE_BYTE;
                end
                3'h1: begin
                    reg_write_en = 1'b1;
                    alu_type = `ALU_TYPE_ADD;
                    data_ctrl_type = `DATA_CTRL_TYPE_HALF;
                    rs2_addr = `REG_ZERO;
                end
                3'h2: begin
                    reg_write_en = 1'b1;
                    alu_type = `ALU_TYPE_ADD;
                    data_ctrl_type = `DATA_CTRL_TYPE_WORD;
                    rs2_addr = `REG_ZERO;
                end
                3'h4: begin
                    reg_write_en = 1'b1;
                    alu_type = `ALU_TYPE_ADD;
                    extends_type = `EXTENDS_TYPE_ZERO;
                    data_ctrl_type = `DATA_CTRL_TYPE_BYTE;
                    rs2_addr = `REG_ZERO;
                end
                3'h5: begin
                    reg_write_en = 1'b1;
                    alu_type = `ALU_TYPE_ADD;
                    extends_type = `EXTENDS_TYPE_ZERO;
                    data_ctrl_type = `DATA_CTRL_TYPE_HALF;
                    rs2_addr = `REG_ZERO;
                end
            endcase
        end
        `INST_TYPE_S: begin
            case (funct3)
                3'h0: begin
                    alu_type = `ALU_TYPE_ADD;
                    data_ctrl_type = `DATA_CTRL_TYPE_BYTE;
                    rd_addr = `RD_WIDTH'b0;
                end
                3'h1: begin
                    alu_type = `ALU_TYPE_ADD;
                    data_ctrl_type = `DATA_CTRL_TYPE_HALF;
                    rd_addr = `RD_WIDTH'b0;
                end
                3'h2: begin
                    alu_type = `ALU_TYPE_ADD;
                    data_ctrl_type = `DATA_CTRL_TYPE_WORD;
                    rd_addr = `RD_WIDTH'b0;
                end
            endcase
        end
        `INST_TYPE_B: begin
            case (funct3)
                3'h0: begin
                    alu_type = `ALU_TYPE_EQUAL;
                    rd_addr = `RD_WIDTH'b0;
                end
                3'h1: begin
                    alu_type = `ALU_TYPE_NOT_EQUAL;
                    rd_addr = `RD_WIDTH'b0;
                end
                3'h4: begin
                    alu_type = `ALU_TYPE_LESS_THAN;
                    rd_addr = `RD_WIDTH'b0;
                end
                3'h5: begin
                    alu_type = `ALU_TYPE_GREATER_EQUAL;
                    rd_addr = `RD_WIDTH'b0;
                end
                3'h6: begin
                    alu_type = `ALU_TYPE_LESS_THAN;
                    extends_type = `EXTENDS_TYPE_ZERO;
                    rd_addr = `RD_WIDTH'b0;
                end
                3'h7: begin
                    alu_type = `ALU_TYPE_GREATER_EQUAL;
                    extends_type = `EXTENDS_TYPE_ZERO;
                    rd_addr = `RD_WIDTH'b0;
                end
            endcase
        end
        `INST_TYPE_J_JAL: begin
            jal = 2'b01;
            reg_write_en = 1'b1;
            alu_type = `ALU_TYPE_ADD;
            rs1_addr = `RS1_WIDTH'b0;
            rs2_addr = `REG_ZERO;
        end
        `INST_TYPE_I_JALR: begin
            jal = 2'b11;
            reg_write_en = 1'b1;
            alu_type = `ALU_TYPE_ADD;
            rs2_addr = `REG_ZERO;
        end
        `INST_TYPE_U_LUI: begin
            reg_write_en = 1'b1;
            alu_type = `ALU_TYPE_SHIFT_LEFT;
            rs1_addr = `REG_ZERO;
            rs2_addr = `REG_ZERO;
        end
        `INST_TYPE_U_AUIPC: begin
            reg_write_en = 1'b1;
            alu_type = `ALU_TYPE_ADD;
            rs1_addr = `REG_ZERO;
            rs2_addr = `REG_ZERO;
        end
    endcase
end




endmodule //ctrl