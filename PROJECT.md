# 数字孪生 RISC-V 处理器项目

## 项目概述

本项目是一个基于 **Vivado FPGA** 开发的 **RISC-V RV32I 五级流水线处理器**，应用于 "集英杯"（JYD2025）FPGA 设计竞赛。项目的核心创新在于将 **数字孪生（Digital Twin）** 理念引入嵌入式处理器设计——通过 UART 串口将 FPGA 硬件的运行状态（LED、开关、数码管、计数器）实时镜像到上位机，实现硬件运行的可视化监控与交互。

**目标平台：** Xilinx 7 系列 FPGA  
**开发工具：** Vivado  
**设计语言：** Verilog / SystemVerilog  

---

## 项目目录结构

```
digital_twin/
├── digital_twin.xpr                  # Vivado 工程文件
├── digital_twin.srcs/                # ★ 核心设计源码目录
│   ├── sources_1/
│   │   ├── imports/0_core/           # RISC-V CPU 核心模块（Verilog）
│   │   │   ├── defines.v             # 宏定义（指令集、控制信号编码）
│   │   │   ├── myCPU.v               # CPU 顶层模块（集成五级流水线）
│   │   │   ├── pc_gene.v             # PC 地址生成 + Gshare 分支预测器
│   │   │   ├── ctrl.v                # 流水线仲裁与控制（冒险检测）
│   │   │   ├── id.v                  # 译码模块
│   │   │   ├── alu.v                 # 算术逻辑单元
│   │   │   ├── imm_gen.v             # 立即数生成器
│   │   │   ├── mux_alu_1.v           # ALU 操作数选择器1
│   │   │   ├── mux_alu_2.v           # ALU 操作数选择器2
│   │   │   ├── reg_ctrl.v            # 寄存器文件控制器（含调试接口）
│   │   │   ├── data_forward.v        # 三级数据前推
│   │   │   ├── ram_ctrl.v            # 存储器写控制
│   │   │   ├── perip_rdata_cut.v     # 外设读数据裁剪（lb/lh/lw）
│   │   │   ├── wb.v                  # 写回阶段选择器
│   │   │   ├── if_id.v               # IF→ID 流水线寄存器
│   │   │   ├── id_ex.v               # ID→EX 流水线寄存器
│   │   │   ├── ex_mem.v              # EX→MEM 流水线寄存器
│   │   │   └── mem_wb.v              # MEM→WB 流水线寄存器
│   │   ├── new/                      # 项目新增模块（SystemVerilog）
│   │   │   ├── top.sv                # 芯片顶层（PLL + UART + Twin控制器 + CPU）
│   │   │   ├── student_top.sv        # 学生顶层（CPU + IROM + 外设桥接）
│   │   │   ├── twin_controller.sv    # ★ 数字孪生控制器（UART 状态镜像）
│   │   │   ├── perip_bridge.sv       # 外设桥接（地址解码 + 设备路由）
│   │   │   ├── uart.sv               # UART 收发器
│   │   │   ├── dram_driver.sv        # DRAM 读写驱动（支持 sb/sh/sw/lb/lh/lw）
│   │   │   ├── counter.sv            # 跨时钟域格雷码计数器
│   │   │   ├── display_seg.sv        # 数码管动态扫描
│   │   │   └── seg7.sv               # 七段数码管译码器
│   │   ├── ip/                       # Vivado IP 核
│   │   │   ├── IROM/                 # 指令 ROM（Block Memory）
│   │   │   ├── BRAM/                 # 块 RAM（数据存储器）
│   │   │   ├── DRAM/                 # DRAM 控制器
│   │   │   └── pll/                  # PLL 时钟管理单元
│   │   └── imports/test_src/         # 测试用 COE 文件（内存初始化）
│   ├── sim_1/                        # 仿真测试平台
│   │   ├── new/
│   │   │   ├── tb_myCPU.sv           # CPU 核心仿真（监控寄存器文件）
│   │   │   ├── tb_top.sv             # 系统级仿真（UART 通信验证）
│   │   │   └── tb_uart.sv            # UART 模块仿真
│   │   └── imports/                  # 仿真波形配置文件
│   ├── constrs_1/                    # 物理约束
│   │   └── new/digital_twin.xdc      # 引脚映射 + 时钟约束 + CDC false path
│   └── utils_1/                      # 综合后 DCP 网表
├── digital_twin.runs/                # 综合与实现运行结果
├── digital_twin.sim/                 # 仿真波形数据
├── digital_twin.gen/                 # IP 核生成文件
├── digital_twin.cache/               # Vivado 项目缓存
└── digital_twin.hw/                  # 硬件管理器数据
```

---

## CPU 设计详解

### 1. 整体架构

CPU 采用 **经典五级流水线** 架构，支持 RISC-V **RV32I** 指令集（基础整数指令集，含 M 标准扩展的乘除法指令）。

```
  +-------+     +-------+     +-------+     +-------+     +-------+
  |  IF   | --> |  ID   | --> |  EX   | --> |  MEM  | --> |  WB   |
  | 取指  |     | 译码  |     | 执行  |     | 访存  |     | 写回  |
  +-------+     +-------+     +-------+     +-------+     +-------+
       |             |             |             |             |
  +--------+    +--------+    +--------+    +--------+    +--------+
  | if_id  |    | id_ex  |    | ex_mem |    | mem_wb |    | regfile|
  | 寄存器 |    | 寄存器 |    | 寄存器 |    | 寄存器 |    | 寄存器 |
  +--------+    +--------+    +--------+    +--------+    +--------+
```

**流水线级间寄存器**（if_id / id_ex / ex_mem / mem_wb）在时钟上升沿锁存数据，支持 `halt`（暂停）和 `resume`（冲刷/复位）控制信号，用于流水线冒险的处理。

### 2. 各阶段功能

| 阶段 | 模块 | 功能 |
|------|------|------|
| **IF** | `pc_gene` | 程序计数器生成、Gshare 分支预测、BTB/BHT 管理 |
| **ID** | `id` + `reg_ctrl` + `imm_gen` | 指令译码、寄存器读取、立即数生成 |
| **EX** | `alu` + `mux_alu_1/2` + `ram_ctrl` | ALU 运算、操作数选择、存储器写请求生成 |
| **MEM** | `perip_rdata_cut` | 外设数据读取与对齐裁剪 |
| **WB** | `wb` | 写回数据选择（ALU 结果 / 内存读取） |

### 3. 指令集支持

完全支持 **RV32I 基础整数指令集**（38条指令），并扩展了 **M 扩展乘除法**：

| 类型 | 指令 | 说明 |
|------|------|------|
| R-type | ADD, SUB, XOR, OR, AND, SLL, SRL, SRA, SLT, SLTU | 寄存器-寄存器运算 |
| R-type (M) | MUL, MULH, MULHSU, MULHU, DIV, DIVU, REM, REMU | 乘除法扩展 |
| I-type | ADDI, XORI, ORI, ANDI, SLLI, SRLI, SRAI, SLTI, SLTIU | 立即数运算 |
| Load | LW, LH, LHU, LB, LBU | 存储器加载 |
| Store | SW, SH, SB | 存储器存储 |
| Branch | BEQ, BNE, BLT, BGE, BLTU, BGEU | 条件分支 |
| Jump | JAL, JALR | 无条件跳转 |
| Upper | LUI, AUIPC | 立即数高位操作 |

### 4. 存储器映射

```
0x8000_0000 - 0x8000_FFFF    指令 ROM (IROM)
0x8010_0000 - 0x8013_FFFF    数据 RAM (DRAM, 256KB)
0x8020_0000 - 0x8020_0003    开关输入 SW[31:0]（只读）
0x8020_0004 - 0x8020_0007    开关输入 SW[63:32]（只读）
0x8020_0010 - 0x8020_0013    按键输入 KEY[7:0]（只读）
0x8020_0020 - 0x8020_0023    数码管输出 SEG[31:0]（读写）
0x8020_0040 - 0x8020_0043    LED 输出 LED[31:0]（读写）
0x8020_0050 - 0x8020_0053    计数器（读写，写 0x80000000 启动 / 0xFFFFFFFF 停止）
```

---

## 设计创新点

### 创新1：Gshare 分支预测器（BTB + GBHT + BHT 三级预测）

**文件：** [pc_gene.v](digital_twin.srcs/sources_1/imports/0_core/pc_gene.v)

传统教学 RISC-V CPU 通常采用静态预测（总是预测不跳转），本项目实现了 **Gshare 风格的动态分支预测器**：

**结构：**
- **BTB**（Branch Target Buffer）：64 条目，每条目 = {`32-bit 目标地址`, `1-bit 有效位`, `8-bit 标签`}，使用 PC[7:2] 索引
- **BHT**（Branch History Table）：64 条目 × 2-bit 饱和计数器，使用 PC[7:2] 索引
- **GBHT**（Global Branch History）：2-bit 全局历史寄存器，作为 BTB 未命中时的回退预测

**预测策略（三级决策）：**

```
IF 阶段遇到分支指令时：
  1. 查 BTB[PC[7:2]].valid && BTB.tag == PC[15:8]
     → BTB 命中：使用 BHT[PC[7:2]] 的 2-bit 计数器决定跳转/不跳转
     → 跳转目标 = BTB[PC[7:2]].target
  2. BTB 未命中
     → 使用 GBHT 全局历史决定跳转/不跳转
     → 跳转目标 = PC + 立即数（B-type 立即数解码）
```

**执行阶段修正机制：**
- 在 EX 阶段验证预测结果
- 预测错误时触发 `fix_branch_en` / `fix_jal_en` 信号
- 冲刷 ID 阶段错误指令（插入 NOP），同时更新 BTB/BHT/GBHT
- BHT 用 2-bit 饱和计数器（强不跳/弱不跳/弱跳/强跳），GBHT 类似更新

**JALR 预测支持：**
- 保存上次 `rs1_value`，用于 JALR 的静态跳转预测
- 特殊识别 `ret` 伪指令（`jalr x0, x1, 0`），使用 `ra` 寄存器值作为返回地址

```
预测正确时的流程：
IF(预测跳转) → ID(正常译码) → EX(验证✓) → 不触发冲刷，继续执行

预测错误时的流程：
IF(预测跳转) → ID(正常译码) → EX(验证✗) → 触发 mem_resume 冲刷 ID 阶段
                                          → fix_next_p 修正 PC
```

### 创新2：数字孪生实时状态镜像

**文件：** [twin_controller.sv](digital_twin.srcs/sources_1/new/twin_controller.sv)

通过 UART 串口协议实现 FPGA 硬件状态与上位机的**实时双向通信**，实现"数字孪生"：

**通信协议：**

```
上位机 → FPGA（控制指令，单字节）：
  0x00           : 读取状态请求（无效，保留）
  0x80           : 请求完整状态回传（18字节）
  0b1xxx_xxxx    : 设置 SW/KEY 位
    bit[7]  = 1  表示设置
    bit[6:0]= 1-64   → 设置 SW[bit[6:0]-1] = bit[7]
    bit[6:0]= 65-72  → 设置 KEY[bit[6:0]-65] = bit[7]

FPGA → 上位机（状态回传，18字节）：
  Byte[0:4]   : SEG 数码管 (40bit)
  Byte[5]     : KEY 按键 (8bit)
  Byte[6:13]  : SW 开关 (64bit)
  Byte[14:17] : LED 灯 (32bit)
```

**设计特点：**
- 每收到 `0x80` 命令，采样当前全部硬件状态并打包回传
- 上位机可实时注入 SW/KEY 输入，被 CPU 通过外设桥接读取
- 实现真正的"硬件影子"——上位机有完全同步的 FPGA 外设状态视图

### 创新3：跨时钟域格雷码计数器

**文件：** [counter.sv](digital_twin.srcs/sources_1/new/counter.sv)

实现了一个精密的跨时钟域（CDC）毫秒计数器，展示工程化的 CDC 设计方法：

```
  CPU 时钟域 (cpu_clk)                    计数器时钟域 (cnt_clk, 50MHz)
  ┌─────────────────┐                    ┌──────────────────────────┐
  │ cnt_enable_cpu   │─── 两级同步器 ───→│ cnt_enable_cnt_d2         │
  │ (CPU写寄存器)     │                    │ → 1ms 计数 (0~49999)      │
  │                   │                    │ → 毫秒累加 (cnt_ms_bin)    │
  │                   │                    │ → 二进制转格雷码           │
  │ cnt_gray_cpu_d2  │←── 两级同步器 ────│ cnt_ms_gray               │
  │ → 格雷码转二进制  │                    │                            │
  │ → perip_rdata     │                    └──────────────────────────┘
  └─────────────────┘
```

**特点：**
- 使用格雷码进行多比特跨时钟域传输（避免亚稳态导致的数据错误）
- 两级同步器（`ASYNC_REG = "TRUE"`）确保信号稳定采样
- 双向 CDC：CPU→计数器（启动/停止控制），计数器→CPU（毫秒值回读）
- 约束文件中声明 `set_false_path` 正确处理异步时钟

### 创新4：三级数据前推与 Load-Use 冒险处理

**文件：** [data_forward.v](digital_twin.srcs/sources_1/imports/0_core/data_forward.v) + [ctrl.v](digital_twin.srcs/sources_1/imports/0_core/ctrl.v)

**数据前推（Data Forwarding）：**
- 从 EX、MEM、WB 三个阶段回传结果到 ID 阶段
- 优先使用最新的结果：`EX > MEM > WB` 优先级
- rs1/rs2 为 x0 时直接返回 0（RISC-V 零寄存器语义）

**Load-Use 冒险检测：**

```verilog
// ctrl.v 中的负载使用冒险检测
load_use_hazard = (ex_out_op_code == INST_TYPE_I_L)  // EX阶段是LOAD指令
               && ((rs1_addr != 0 && ex_out_rd_addr == rs1_addr)  // 目标地址是下条指令的rs1
               ||  (rs2_addr != 0 && ex_out_rd_addr == rs2_addr)); // 或rs2
```

检测到 Load-Use 冒险时：
- `if_halt = 1`：IF 阶段暂停（不取新指令）
- `id_halt = 1`：ID 阶段暂停（保持当前译码）
- `ex_resume = 1`：EX 阶段插入气泡（NOP）
- 暂停一个周期后自动解除，继续正常流水

### 创新5：精确的流水线冲刷与分支处理

**文件：** [ctrl.v](digital_twin.srcs/sources_1/imports/0_core/ctrl.v)

每个流水线阶段都有独立的 `halt`（暂停）和 `resume`（冲刷）控制：

| 触发条件 | IF | ID | EX | MEM | WB |
|----------|----|----|----|----|----|
| 正常执行 | halt=0, resume=0 | halt=0, resume=0 | halt=0, resume=0 | halt=0, resume=0 | halt=0, resume=0 |
| Load-Use 冒险 | halt=1 | halt=1 | resume=1 | halt=0, resume=0 | halt=0, resume=0 |
| 分支预测错误 | halt=0 | resume=1 | resume=1 | resume=1 | halt=0, resume=0 |
| JALR 预测错误 | halt=0 | resume=1 | resume=1 | resume=1 | halt=0, resume=0 |
| 外设未就绪 | halt=1 | halt=1 | halt=1 | halt=1 | halt=1 |

**流水线冲刷机制：**
- `resume` 信号触发时，流水线寄存器的输出被清零或设为 NOP
- 各阶段的 halt 信号独立控制，实现精细粒度的流水线管理
- 支持调试暂停/恢复（`debug_halt` / `debug_resume`）

### 创新6：高扇出信号复制优化

**文件：** [ex_mem.v](digital_twin.srcs/sources_1/imports/0_core/ex_mem.v)

在 ex_mem 流水线寄存器中，`perip_addr` 被复制为 5 份独立输出（`rep0`~`rep4`），每份都添加了 `(* MAX_FANOUT = 50 *)` 综合属性：

```verilog
(* MAX_FANOUT = 50 *) output reg [31:0] out_perip_addr_reg_rep0,
(* MAX_FANOUT = 50 *) output reg [31:0] out_perip_addr_reg_rep1,
...
```

这是 **FPGA 物理级优化**：`perip_addr` 需要驱动 DRAM、LED、SEG、SW、KEY、Counter 等多个外设的地址译码逻辑，扇出很大。通过显式复制信号，让 Vivado 综合器对每份复制独立布局布线，避免单点高扇出导致的路由拥塞和时序违例。

### 创新7：调试友好的寄存器文件设计

**文件：** [reg_ctrl.v](digital_twin.srcs/sources_1/imports/0_core/reg_ctrl.v)

寄存器文件包含独立的调试端口（`debug_reg_wen/addr/wdata/rdata`），允许通过外部调试器直接读写 CPU 寄存器，不影响正常流水线运行。仿真测试平台利用此功能监控全部 32 个寄存器的值。

---

## 系统时钟架构

```
  200MHz 差分时钟
  (i_sys_clk_p/n)
        │
   ┌────▼────┐
   │   PLL   │
   │ clk_wiz │
   └─┬──┬────┘
     │  │
     │  └──→ cpu_clk (CPU 主频) ──→ myCPU / perip_bridge
     │
     └──→ w_clk_50Mhz (50MHz) ──→ UART / Counter
```

两个时钟域通过 `set_false_path` 声明为异步，Counter 模块内部使用格雷码 CDC 安全传输。

---

## 关键技术指标

| 指标 | 数值 |
|------|------|
| 指令集 | RV32I + M 扩展（38+8 条指令） |
| 流水线级数 | 5 级（IF/ID/EX/MEM/WB） |
| 寄存器文件 | 32 × 32-bit |
| 分支预测器 | Gshare（BTB 64 条目 + BHT 2-bit + GBHT 2-bit） |
| 数据前推 | 3 级（EX/MEM/WB） |
| 指令存储器 | Block RAM（IROM） |
| 数据存储器 | Block RAM（DRAM, 256KB） |
| UART 波特率 | 9600 bps |
| 外设接口 | 64-bit SW × 8-bit KEY × 40-bit SEG × 32-bit LED |
| 跨时钟域 | 格雷码 CDC（50MHz ← → CPU时钟） |

---

## 文件清单

### CPU 核心（`sources_1/imports/0_core/`）

| 文件 | 说明 |
|------|------|
| `defines.v` | 宏定义：指令编码、控制信号宽度、ALU类型 |
| `myCPU.v` | CPU 顶层：实例化五级流水线全部模块 |
| `pc_gene.v` | PC 生成 + Gshare 分支预测器（BTB/BHT/GBHT） |
| `ctrl.v` | 流水线控制：冒险检测、暂停/冲刷仲裁 |
| `id.v` | 译码模块：指令→控制信号 |
| `alu.v` | ALU：算术逻辑运算 |
| `imm_gen.v` | 立即数生成器 |
| `mux_alu_1.v` | ALU 源操作数1选择 |
| `mux_alu_2.v` | ALU 源操作数2选择 |
| `reg_ctrl.v` | 寄存器文件（含调试接口） |
| `data_forward.v` | 数据前推（三级） |
| `ram_ctrl.v` | 存储器写控制 |
| `perip_rdata_cut.v` | 读数据字节/半字裁剪 |
| `wb.v` | 写回阶段选择 |
| `if_id.v` | IF→ID 流水线寄存器 |
| `id_ex.v` | ID→EX 流水线寄存器 |
| `ex_mem.v` | EX→MEM 流水线寄存器（含扇出复制） |
| `mem_wb.v` | MEM→WB 流水线寄存器 |

### 外设与系统（`sources_1/new/`）

| 文件 | 说明 |
|------|------|
| `top.sv` | 芯片顶层 |
| `student_top.sv` | 学生设计顶层 |
| `twin_controller.sv` | 数字孪生 UART 控制器 |
| `perip_bridge.sv` | 外设地址解码与路由 |
| `uart.sv` | UART 收发器 |
| `dram_driver.sv` | DRAM 读写驱动 |
| `counter.sv` | 跨时钟域格雷码计数器 |
| `display_seg.sv` | 数码管动态扫描 |
| `seg7.sv` | 七段数码管译码 |

### 仿真（`sim_1/new/`）

| 文件 | 说明 |
|------|------|
| `tb_myCPU.sv` | CPU 核心仿真 |
| `tb_top.sv` | 系统级 UART 通信仿真 |
| `tb_uart.sv` | UART 模块仿真 |
