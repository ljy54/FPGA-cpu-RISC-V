# 数字孪生 RISC-V 五级流水线处理器

基于 Xilinx 7 系列 FPGA，使用 Verilog/SystemVerilog 从零设计并实现的 RISC-V RV32I 五级流水线处理器。创新性地将"数字孪生"理念引入嵌入式处理器设计——通过 UART 串口将 FPGA 硬件外设状态实时镜像到上位机。项目参加"集英杯"FPGA 设计竞赛。

## CPU 架构

采用经典五级流水线架构：

```
  +-------+     +-------+     +-------+     +-------+     +-------+
  |  IF   | --> |  ID   | --> |  EX   | --> |  MEM  | --> |  WB   |
  | 取指  |     | 译码  |     | 执行  |     | 访存  |     | 写回  |
  +-------+     +-------+     +-------+     +-------+     +-------+
       |             |             |             |             |
  +--------+    +--------+    +--------+    +--------+    +--------+
  | if_id  |    | id_ex  |    | ex_mem |    | mem_wb |    | regfile|
  +--------+    +--------+    +--------+    +--------+    +--------+
```

## 关键特性

- **指令集**：完整支持 RV32I（38 条）+ M 扩展乘除法（8 条），共 46 条指令
- **Gshare 分支预测器**：BTB 64 条目 + BHT 2-bit 饱和计数器 + 2-bit 全局历史寄存器，支持 JALR 返回地址预测
- **三级数据前推**：EX/MEM/WB 三级回传到 ID 阶段，配套 Load-Use 冒险检测与流水线暂停
- **精确流水线控制**：各阶段独立 halt/resume 信号，处理分支预测错误、Load-Use 冒险、外设未就绪
- **数字孪生**：UART 串口（9600 bps）实时双向镜像 FPGA 外设状态到上位机
- **跨时钟域计数器**：格雷码 CDC，CPU 时钟域 ↔ 50MHz 外设时钟域

## 技术栈

| 类别 | 技术 |
|------|------|
| 硬件描述语言 | Verilog、SystemVerilog |
| 开发工具 | Xilinx Vivado 2024.2 |
| 目标平台 | Xilinx 7 系列 FPGA |
| 通信协议 | UART（9600 bps） |
| 仿真验证 | Vivado XSim |

## 存储器映射

| 地址范围 | 外设 | 说明 |
|----------|------|------|
| `0x8000_0000` | IROM | 指令 ROM |
| `0x8010_0000` | DRAM | 数据 RAM（256KB） |
| `0x8020_0000` | SW[31:0] | 开关输入（只读） |
| `0x8020_0004` | SW[63:32] | 开关输入高位 |
| `0x8020_0010` | KEY[7:0] | 按键输入（只读） |
| `0x8020_0020` | SEG[31:0] | 数码管输出（读写） |
| `0x8020_0040` | LED[31:0] | LED 输出（读写） |
| `0x8020_0050` | Counter | 毫秒计数器（读写） |

## 项目结构

```
digital_twin.srcs/
├── sources_1/
│   ├── imports/0_core/          # RISC-V CPU 核心模块（Verilog）
│   │   ├── defines.v            # 宏定义（指令集、控制信号编码）
│   │   ├── myCPU.v              # CPU 顶层（集成五级流水线）
│   │   ├── pc_gene.v            # PC 生成 + Gshare 分支预测器
│   │   ├── ctrl.v               # 流水线仲裁与控制（冒险检测）
│   │   ├── id.v                 # 译码模块
│   │   ├── alu.v                # 算术逻辑单元
│   │   ├── data_forward.v       # 三级数据前推
│   │   ├── reg_ctrl.v           # 寄存器文件（含调试接口）
│   │   ├── if_id.v / id_ex.v    # 流水线寄存器
│   │   ├── ex_mem.v / mem_wb.v
│   │   └── ...
│   ├── new/                     # 外设与系统模块（SystemVerilog）
│   │   ├── top.sv               # 芯片顶层
│   │   ├── twin_controller.sv   # ★ 数字孪生 UART 控制器
│   │   ├── perip_bridge.sv      # 外设地址解码与路由
│   │   ├── uart.sv              # UART 收发器
│   │   ├── counter.sv           # 跨时钟域格雷码计数器
│   │   └── ...
│   └── imports/test_src/        # COE 内存初始化文件
├── sim_1/new/                   # 仿真测试平台
│   ├── tb_myCPU.sv              # CPU 核心仿真
│   ├── tb_top.sv                # 系统级 UART 通信仿真
│   └── tb_uart.sv               # UART 模块仿真
└── constrs_1/new/
    └── digital_twin.xdc         # 引脚映射 + 时钟约束 + CDC false path
```

## 设计创新点

### Gshare 分支预测器

- BTB 64 条目，使用 PC[7:2] 索引，每条目存储 32-bit 目标地址 + 有效位 + 8-bit 标签
- BHT 64 条目 × 2-bit 饱和计数器（强不跳/弱不跳/弱跳/强跳）
- EX 阶段验证失败后精确冲刷，同步更新 BTB/BHT/GBHT

### 三级数据前推与冒险处理

- EX/MEM/WB 三级结果回传，优先使用最新：EX > MEM > WB
- Load-Use 冒险：IF 暂停 + ID 暂停 + EX 插入气泡，一周期后自动恢复

### 数字孪生实时状态镜像

- UART 双向通信实现硬件"影子"——上位机完全同步 FPGA 外设状态
- FPGA → PC：18 字节状态包（SEG/KEY/SW/LED）
- PC → FPGA：单字节命令，可实时注入虚拟 SW/KEY 输入

### 跨时钟域格雷码计数器

- CPU 时钟域 ↔ 50MHz 计数器时钟域，双向 CDC
- 格雷码多比特信号 + 两级同步器（`ASYNC_REG = "TRUE"`）
- `set_false_path` 约束正确处理异步时钟

## 关键技术指标

| 指标 | 数值 |
|------|------|
| 指令集 | RV32I + M 扩展（46 条指令） |
| 流水线级数 | 5 级（IF/ID/EX/MEM/WB） |
| 寄存器文件 | 32 × 32-bit |
| 分支预测器 | Gshare（BTB 64 + BHT 2-bit + GBHT 2-bit） |
| 数据前推 | 3 级（EX/MEM/WB） |
| UART 波特率 | 9600 bps |
| 外设接口 | 64-bit SW / 8-bit KEY / 40-bit SEG / 32-bit LED |

## 环境要求

- Xilinx Vivado 2024.2
- Xilinx 7 系列 FPGA 开发板

> 注：工程文件（`.xpr`）包含本地绝对路径未纳入版本控制，请在 Vivado 中新建工程并添加 `digital_twin.srcs/` 下的源文件。

## 许可证

本项目为竞赛/课程设计项目，仅供学习参考。
