`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/23/2025 03:50:55 PM
// Design Name: 
// Module Name: tb_myCPU
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`define SIM_PERIOD 20
`define CPU_WIDTH 32
module tb_myCPU;
    reg clk;

    top uut (
        .i_sys_clk_p(clk),
        .i_sys_clk_n(~clk),
        .i_uart_rx(1'b1),
        .o_uart_tx(),
        .virtual_led(),  
        .virtual_seg()
    );

    wire [`CPU_WIDTH-1:0] zero_x0  = uut.student_top_inst.Core_cpu.u_reg_ctrl.reg_value_list[0];
wire [`CPU_WIDTH-1:0] ra_x1    = uut.student_top_inst.Core_cpu.u_reg_ctrl.reg_value_list[1];
wire [`CPU_WIDTH-1:0] sp_x2    = uut.student_top_inst.Core_cpu.u_reg_ctrl.reg_value_list[2];
wire [`CPU_WIDTH-1:0] gp_x3    = uut.student_top_inst.Core_cpu.u_reg_ctrl.reg_value_list[3];
wire [`CPU_WIDTH-1:0] tp_x4    = uut.student_top_inst.Core_cpu.u_reg_ctrl.reg_value_list[4];
wire [`CPU_WIDTH-1:0] t0_x5    = uut.student_top_inst.Core_cpu.u_reg_ctrl.reg_value_list[5];
wire [`CPU_WIDTH-1:0] t1_x6    = uut.student_top_inst.Core_cpu.u_reg_ctrl.reg_value_list[6];
wire [`CPU_WIDTH-1:0] t2_x7    = uut.student_top_inst.Core_cpu.u_reg_ctrl.reg_value_list[7];
wire [`CPU_WIDTH-1:0] s0_fp_x8 = uut.student_top_inst.Core_cpu.u_reg_ctrl.reg_value_list[8];
wire [`CPU_WIDTH-1:0] s1_x9    = uut.student_top_inst.Core_cpu.u_reg_ctrl.reg_value_list[9];
wire [`CPU_WIDTH-1:0] a0_x10   = uut.student_top_inst.Core_cpu.u_reg_ctrl.reg_value_list[10];
wire [`CPU_WIDTH-1:0] a1_x11   = uut.student_top_inst.Core_cpu.u_reg_ctrl.reg_value_list[11];
wire [`CPU_WIDTH-1:0] a2_x12   = uut.student_top_inst.Core_cpu.u_reg_ctrl.reg_value_list[12];
wire [`CPU_WIDTH-1:0] a3_x13   = uut.student_top_inst.Core_cpu.u_reg_ctrl.reg_value_list[13];
wire [`CPU_WIDTH-1:0] a4_x14   = uut.student_top_inst.Core_cpu.u_reg_ctrl.reg_value_list[14];
wire [`CPU_WIDTH-1:0] a5_x15   = uut.student_top_inst.Core_cpu.u_reg_ctrl.reg_value_list[15];
wire [`CPU_WIDTH-1:0] a6_x16   = uut.student_top_inst.Core_cpu.u_reg_ctrl.reg_value_list[16];
wire [`CPU_WIDTH-1:0] a7_x17   = uut.student_top_inst.Core_cpu.u_reg_ctrl.reg_value_list[17];
wire [`CPU_WIDTH-1:0] s2_x18   = uut.student_top_inst.Core_cpu.u_reg_ctrl.reg_value_list[18];
wire [`CPU_WIDTH-1:0] s3_x19   = uut.student_top_inst.Core_cpu.u_reg_ctrl.reg_value_list[19];
wire [`CPU_WIDTH-1:0] s4_x20   = uut.student_top_inst.Core_cpu.u_reg_ctrl.reg_value_list[20];
wire [`CPU_WIDTH-1:0] s5_x21   = uut.student_top_inst.Core_cpu.u_reg_ctrl.reg_value_list[21];
wire [`CPU_WIDTH-1:0] s6_x22   = uut.student_top_inst.Core_cpu.u_reg_ctrl.reg_value_list[22];
wire [`CPU_WIDTH-1:0] s7_x23   = uut.student_top_inst.Core_cpu.u_reg_ctrl.reg_value_list[23];
wire [`CPU_WIDTH-1:0] s8_x24   = uut.student_top_inst.Core_cpu.u_reg_ctrl.reg_value_list[24];
wire [`CPU_WIDTH-1:0] s9_x25   = uut.student_top_inst.Core_cpu.u_reg_ctrl.reg_value_list[25];
wire [`CPU_WIDTH-1:0] s10_x26  = uut.student_top_inst.Core_cpu.u_reg_ctrl.reg_value_list[26];
wire [`CPU_WIDTH-1:0] s11_x27  = uut.student_top_inst.Core_cpu.u_reg_ctrl.reg_value_list[27];
wire [`CPU_WIDTH-1:0] t3_x28   = uut.student_top_inst.Core_cpu.u_reg_ctrl.reg_value_list[28];
wire [`CPU_WIDTH-1:0] t4_x29   = uut.student_top_inst.Core_cpu.u_reg_ctrl.reg_value_list[29];
wire [`CPU_WIDTH-1:0] t5_x30   = uut.student_top_inst.Core_cpu.u_reg_ctrl.reg_value_list[30];
wire [`CPU_WIDTH-1:0] t6_x31   = uut.student_top_inst.Core_cpu.u_reg_ctrl.reg_value_list[31];

    initial begin
    wait(uut.student_top_inst.bridge_inst.seg_driver.s != 32'd0)   // wait sim end, when x26 == 1
        #(`SIM_PERIOD * 10 + 1)
        $display("Simulation finished successfully!");
        $finish;
    end
    

    initial begin
        #(`SIM_PERIOD/2);
        clk       = 1'b0;
        #(`SIM_PERIOD * 1);
    end

    initial begin
        $dumpfile("waveform.vcd"); // 指定波形文件名
        $dumpvars(0, tb_myCPU);
        #(`SIM_PERIOD * 50000);
        $display("Time Out");
        $finish;
    end

    always #2.5 clk = ~clk;
endmodule