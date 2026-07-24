/*
    宏定义
*/
`define SIM_PERIOD 20

`define CPU_WIDTH 32
`define INST_DEPTH 8192
`define ADDR_WIDTH 10

`define FUNCT7_WIDTH 7
`define RS2_WIDTH 6
`define RS1_WIDTH 6
`define RS3_WIDTH 6
`define RM_WIDTH  3
`define FUNCT3_WIDTH 3
`define RD_WIDTH 6
`define OPCODE_WIDTH 7
`define CSR_ADDR_WIDTH 12

`define REG_ZERO 32'b0

`define INST_ADD 32'd0
`define INST_SUB 32'd1
`define INST_XOR 32'd2
`define INST_OR 32'd3
`define INST_AND 32'd4
`define INST_SLI 32'd5
`define INST_SRL 32'd6
`define INST_SRA 32'd7
`define INST_SLT 32'd8
`define INST_SLTU 32'd9
`define INST_ADDI 32'd10
`define INST_XORI 32'd11
`define INST_ORI 32'd12
`define INST_ANDI 32'd13
`define INST_SLLI 32'd14
`define INST_SRLI 32'd15
`define INST_SRAI 32'd16
`define INST_SLTI 32'd17
`define INST_SLTIU 32'd18
`define INST_LB 32'd19
`define INST_LH 32'd20
`define INST_LW 32'd21
`define INST_LBU 32'd22
`define INST_LHU 32'd23
`define INST_SB 32'd24
`define INST_SH 32'd25
`define INST_SW 32'd26
`define INST_BEQ 32'd27
`define INST_BNE 32'd28
`define INST_BLT 32'd29
`define INST_BGE 32'd30
`define INST_BLTU 32'd31
`define INST_BGEU 32'd32
`define INST_JAL 32'd33
`define INST_JALR 32'd34
`define INST_LUI 32'd35
`define INST_AUIPC 32'd36
`define INST_ECALL 32'd37
`define INST_EBREAK 32'd38

`define INST_TYPE_R 7'b011_0011
`define INST_TYPE_I 7'b001_0011
`define INST_TYPE_I_L 7'b000_0011
`define INST_TYPE_S 7'b010_0011
`define INST_TYPE_B 7'b110_0011
`define INST_TYPE_I_E 7'b111_0011
`define INST_TYPE_I_CSR 7'b111_0011

`define INST_TYPE_R_F 7'b101_0011
`define INST_TYPE_I_F 7'b000_0111
`define INST_TYPE_S_F 7'b010_0111
`define INST_TYPE_F_MA 7'b100_0011
`define INST_TYPE_F_MS 7'b100_0111
`define INST_TYPE_F_NMA 7'b100_1111
`define INST_TYPE_F_NMS 7'b100_1011

`define RM_TYPE_RTE 3'b000  //向最近偶数舍入
`define RM_TYPE_RTZ 3'b001  //向零舍入
`define RM_TYPE_RDN 3'b010  //向下舍入
`define RM_TYPE_RUP 3'b011  //向上舍入
`define RM_TYPE_RMM 3'b100  //向最近的最大值舍入

`define INST_TYPE_J_JAL 7'b110_1111
`define INST_TYPE_I_JALR 7'b110_0111
`define INST_TYPE_U_LUI 7'b011_0111
`define INST_TYPE_U_AUIPC 7'b001_0111

`define FPU_TYPE_ADD 5'd0
`define FPU_TYPE_SUB 5'd1
`define FPU_TYPE_MUL 5'd2
`define FPU_TYPE_DIV 5'd3
`define FPU_TYPE_SQRT 5'd4
`define FPU_TYPE_FMADD  5'd5 
`define FPU_TYPE_FMSUB  5'd6 
`define FPU_TYPE_FNMSUB 5'd7
`define FPU_TYPE_FNMADD 5'd8  
`define FPU_TYPE_FEQ    5'd9  
`define FPU_TYPE_FLT    5'd10
`define FPU_TYPE_FLE    5'd11
`define FPU_TYPE_FCVT_W_S 5'd12
`define FPU_TYPE_FCVT_S_W 5'd13  
`define FPU_TYPE_FMIN    5'd14
`define FPU_TYPE_FMAX    5'd15 
`define FPU_TYPE_FSGNJ   5'd16  
`define FPU_TYPE_FSGNJN  5'd17  
`define FPU_TYPE_FSGNJX  5'd18  
`define FPU_TYPE_FCLASS  5'd19  
`define FPU_TYPE_FMV_X_W 5'd20  
`define FPU_TYPE_FMV_W_X 5'd21
`define FPU_TYPE_FCVT_WU_S 5'd22
`define FPU_TYPE_FCVT_S_WU 5'd23
`define FPU_TYPE_FLW 5'd24
`define FPU_TYPE_FSW 5'd25
`define FPU_TYPE_NONE 5'd26
`define FPU_TYPES_WIDTH 5


`define ALU_TYPE_ADD 5'd0
`define ALU_TYPE_SUB 5'd1
`define ALU_TYPE_XOR 5'd2
`define ALU_TYPE_OR 5'd3
`define ALU_TYPE_AND 5'd4
`define ALU_TYPE_SHIFT_LEFT 5'd5
`define ALU_TYPE_SHIFT_RIGHT 5'd6
`define ALU_TYPE_LESS_THAN 5'd7
`define ALU_TYPE_GREATER_EQUAL 5'd8
`define ALU_TYPE_EQUAL 5'd9
`define ALU_TYPE_NOT_EQUAL 5'd10
`define ALU_TYPE_MUL 5'd11
`define ALU_TYPE_MULH 5'd12
`define ALU_TYPE_MULHSU 5'd13
`define ALU_TYPE_MULHU 5'd14
`define ALU_TYPE_DIV 5'd15
`define ALU_TYPE_DIVU 5'd16
`define ALU_TYPE_REM 5'd17
`define ALU_TYPE_REMU 5'd18

`define ALU_TYPES_WIDTH 5

`define EXTENDS_TYPE_MSB 2'b11
`define EXTENDS_TYPE_ZERO 2'b10
`define EXTENDS_TYPE_NONE 2'b01
`define EXTENDS_TYPES_WIDTH 2

`define DATA_DEPTH 5 //我也忘了这是干啥的
`define DATA_CTRL_TYPE_BYTE 2'b00
`define DATA_CTRL_TYPE_HALF 2'b01
`define DATA_CTRL_TYPE_WORD 2'b10
`define DATA_CTRL_TYPE_NONE 2'b11
`define DATA_CTRL_TYPES_WIDTH 2

`define EFFECTIVE_SHIFT_WIDTH 5 // 32 位 CPU 的移位位数需 5 位（2^5=32）

`define INST_NOP `CPU_WIDTH'b000000000000_00000_000_00000_0010011
