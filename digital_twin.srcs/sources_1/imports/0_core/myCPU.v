`timescale 1ns / 1ps
`include "defines.v"
module myCPU (
    // 系统信号
    input cpu_clk,
	input cpu_rst,

	// 指令存储器
	input [`CPU_WIDTH-1:0] irom_data, // 指令存储器数据
    output [`CPU_WIDTH-1:0] irom_addr, // 指令存储器地址

	// 外设通信
    input [`CPU_WIDTH-1:0] perip_rdata,
	input perip_valid, // 外设数据有效信号
	output perip_ren,
	output perip_wen,  
	output [1:0] perip_mask,
	output [`CPU_WIDTH-1:0] perip_wdata,
	output [`CPU_WIDTH-1:0] perip_addr
);

wire in_halt = 1'b0; // 调试暂停信号
wire in_resume = 1'b0; // 调试复位信号

wire pc_wen = 1'b0; // PC写使能
wire [`CPU_WIDTH-1:0] pc_wdata = 0; // 当前工作
wire [`CPU_WIDTH-1:0] pc_rdata; // PC读取数据

wire [`CPU_WIDTH-1:0] reg_addr = 32'd1; // 读取寄存器地址
wire [`CPU_WIDTH-1:0] reg_wdata = 0; // 写入
wire reg_wen = 0; // 寄存器写使能
wire [`CPU_WIDTH-1:0] reg_rdata; // 寄存器读取

wire [`CPU_WIDTH-1:0] csr_addr = 0; // 读取csr地址	
wire [`CPU_WIDTH-1:0] csr_wdata = 0; // 写入csr数据
wire csr_wen = 0; // csr写使能
wire [`CPU_WIDTH-1:0] csr_rdata; // csr读取数据

wire sys_en;

wire if_halt;
wire id_halt;
wire ex_halt;
wire mem_halt;
wire wb_halt;
wire if_resume;
wire id_resume;
wire ex_resume;
wire mem_resume;
wire wb_resume;

// reg perip_valid = 1'b1;
wire [`CPU_WIDTH-1:0] 	            result;
wire [1:0]                    	        jal;
wire                     	        reg_write_en;
wire [`ALU_TYPES_WIDTH-1:0] 	    alu_type;
wire [`EXTENDS_TYPES_WIDTH-1:0] 	extends_type;
wire [`DATA_CTRL_TYPES_WIDTH-1:0] 	data_ctrl_type;
wire [`OPCODE_WIDTH-1:0] 	        op_code;
wire [`RS1_WIDTH-1:0] 	            rs1_addr;
wire [`RS2_WIDTH-1:0] 	            rs2_addr;
wire [`RD_WIDTH-1:0] 	            rd_addr;
wire [`CPU_WIDTH-1:0] 	            imm;
wire [`CPU_WIDTH-1:0] 	            inst;
wire [`CPU_WIDTH-1:0] 	            value_1;
wire [`CPU_WIDTH-1:0] 	            value_2;
wire [`CPU_WIDTH-1:0] 	            next_p;
wire [`CPU_WIDTH-1:0] 	            current_p;
wire [`CPU_WIDTH-1:0] 	            rs1_value;
wire [`CPU_WIDTH-1:0] 	            rs2_value;
wire [`CPU_WIDTH-1:0] 				out_value;

// ID 译码阶段
wire [`CPU_WIDTH-1:0] 	id_out_inst;
wire [`CPU_WIDTH-1:0] 	id_out_current_p;


// EX 执行阶段
wire [`CPU_WIDTH-1:0] 	ex_out_current_p;
wire [`OPCODE_WIDTH-1:0] 	ex_out_op_code;
wire [`CPU_WIDTH-1:0] 	ex_out_imm;
wire [`ALU_TYPES_WIDTH-1:0] 	ex_out_alu_type;
wire [`EXTENDS_TYPES_WIDTH-1:0] 	ex_out_extends_type;
wire [`DATA_CTRL_TYPES_WIDTH-1:0] 	ex_out_data_ctrl_type;
wire [`RD_WIDTH-1:0] 	ex_out_rd_addr;
wire ex_out_reg_write_en;
wire [1:0] ex_out_jal;

// MEM 存储器访问阶段
wire [`OPCODE_WIDTH-1:0] 	mem_out_op_code;
wire [`DATA_CTRL_TYPES_WIDTH-1:0] 	mem_out_data_ctrl_type;
wire [`EXTENDS_TYPES_WIDTH-1:0] 	mem_out_extends_type;
wire [`CPU_WIDTH-1:0] 	mem_out_ram_addr;
wire [`RD_WIDTH-1:0] 	mem_out_rd_addr;
wire mem_out_reg_write_en;
wire [`CPU_WIDTH-1:0] perip_wdata_o;
wire [`CPU_WIDTH-1:0] perip_rdata_o;


// WB 写回阶段
wire [`OPCODE_WIDTH-1:0] 	wb_out_op_code;
wire [`CPU_WIDTH-1:0] 	wb_out_alu_result;
wire [`CPU_WIDTH-1:0] 	wb_out_ram_data;
wire [`RD_WIDTH-1:0] 	wb_out_rd_addr;
wire wb_out_reg_write_en;

wire [`CPU_WIDTH-1:0] forward_rs1_value;
wire [`CPU_WIDTH-1:0] forward_rs2_value;

wire [1:0] perip_mask_reg;
wire perip_wen_reg;
wire [`CPU_WIDTH-1:0] perip_addr_reg;

wire fix_branch_en;
wire fix_jal_en;

assign sys_en = cpu_rst;

assign irom_addr = current_p;
assign perip_ren = (mem_out_op_code == `INST_TYPE_I_L);

// always @(posedge cpu_clk) begin
// 	if (ex_out_op_code == `INST_TYPE_I_L)
// 		perip_valid <=1'b0;
// 	if (!perip_valid)
// 		perip_valid <= 1'b1;
// end

// IF 取指阶段

ctrl ctrl (
    .clk              ( cpu_clk              ), // 时钟信号
    .rst              ( sys_en              ), // 复位信号

    .branch_en        ( fix_branch_en            ), // 分支跳转使能
    .jal_en           ( fix_jal_en               ), // 译码阶段跳转指令类型
    
	.rs1_addr        ( rs1_addr            ), // 译码阶段rs1地址
	.rs2_addr        ( rs2_addr            ), // 译码阶段rs2地址
    .ex_out_op_code   ( ex_out_op_code       ), // 执行阶段opcode
	.ex_out_current_p    ( ex_out_current_p        ), // 执行阶段当前工作地址
    .ex_out_imm           ( ex_out_imm               ), // 执行阶段立即数
    .ex_out_rd_addr   ( ex_out_rd_addr       ), // 执行阶段rd地址
	.rs1_value        ( forward_rs1_value            ), // 寄存器1的值
    .current_p       ( current_p           ), // 当前工作地址

	.irom_valid(1), // 指令ROM有效信号
    .perip_valid(perip_valid), // 外设数据有效信号
	.perip_ren(perip_ren),

    .debug_halt       ( in_halt           ), // 调试暂停信号
    .debug_resume     ( in_resume         ), // 调试复位信号

    .if_halt          ( if_halt              ), // IF阶段暂停
    .id_halt          ( id_halt              ), // ID阶段暂停
    .ex_halt          ( ex_halt              ), // EX阶段暂停
    .mem_halt         ( mem_halt             ), // MEM阶段暂停
    .wb_halt          ( wb_halt              ), // WB阶段暂停

    .if_resume        ( if_resume            ), // IF阶段复位
    .id_resume        ( id_resume            ), // ID阶段复位
    .ex_resume        ( ex_resume            ), // EX阶段复位
    .mem_resume       ( mem_resume           ), // MEM阶段复位
    .wb_resume        ( wb_resume            ) // WB阶段复位

    // .next_p          ( next_p              ) // PC地址输出
);

pc_gene u_pc_gene(
    .clk(cpu_clk),
    .sys_en(sys_en),

    .halt(if_halt), //Load-Use冒险
    .resume(if_resume), //复位信号

    .pc_wen(pc_wen), //PC写使能
    .pc_wdata(pc_wdata), //当前工作地址

	.ra_x1(reg_rdata), // ra寄存器值，暂时未使用
    .ex_out_op_code(ex_out_op_code), //操作码
    .ex_out_result(result[0]), //执行结果
    .ex_out_current_p(ex_out_current_p), //执行工作地址
    .id_out_current_p(id_out_current_p), //译码工作地址
    .ex_out_jal(ex_out_jal),		 //执行阶段的跳转类型
    .ex_out_imm(ex_out_imm),
    .rs1_value(forward_rs1_value),
    .inst(irom_data), //当前指令

    .fix_branch_en(fix_branch_en), //分支跳转使能
    .fix_jal_en(fix_jal_en), //jal跳转使能
    
    .current_p(current_p) //目前工作地址
);





//ID 译码阶段
if_id u_if_id(
	.clk           	( cpu_clk            ),
	.sys_en        	( sys_en         ),

	.halt          	( id_halt           ), //暂停信号
	.resume        	( id_resume         ), //复位信号

	.in_inst       	( irom_data        ),
	.in_current_p  	( current_p   ),

	.out_inst      	( id_out_inst       ),
	.out_current_p 	( id_out_current_p  )
);


id u_id(
	.inst           	( id_out_inst            ),//
	.jal            	( jal             ),//
	.reg_write_en   	( reg_write_en    ),//
	.alu_type       	( alu_type        ),//
	.extends_type   	( extends_type    ),//
	.data_ctrl_type 	( data_ctrl_type  ),//
	.op_code        	( op_code         ),//
	.rs1_addr       	( rs1_addr        ),//
	.rs2_addr       	( rs2_addr        ),//
	.rd_addr        	( rd_addr         )//
);

reg_ctrl u_reg_ctrl(
	.clk       	( cpu_clk        ),
	.sys_en    	( sys_en     ),

	.debug_reg_wen(reg_wen),
    .debug_reg_addr(reg_addr),
    .debug_reg_wdata(reg_wdata),
    .debug_reg_rdata(reg_rdata),

	.write_en  	( wb_out_reg_write_en   ),
	.rd_addr   	( wb_out_rd_addr    ),
	.rd_value  	( out_value   ),
	.rs1_addr  	( rs1_addr   ),
	.rs2_addr  	( rs2_addr   ),

	.rs1_value 	( rs1_value  ),
	.rs2_value 	( rs2_value  )
);

data_forward u_data_forward(
	.clk( cpu_clk ),
	.sys_en( sys_en ),

	.halt(ex_halt),
	.resume(ex_resume),

	.rs1_addr         	(rs1_addr          ),
	.rs2_addr         	(rs2_addr          ),

	.id_rs1_value 		(rs1_value  ),
	.id_rs2_value 		(rs2_value  ),
	
	.ex_out_rd_addr      	(ex_out_rd_addr       ),
	.mem_out_rd_addr       	(mem_out_rd_addr        ),
	.wb_out_rd_addr       	(wb_out_rd_addr        ),

	.ex_out_rd_value     	(result      ), 
	.mem_out_rd_value      	(perip_rdata_o       ),
	.wb_out_rd_value      	(out_value       ),

	.rs1_value        	(forward_rs1_value         ),
	.rs2_value        	(forward_rs2_value         )
);

imm_gen u_imm_gen(
	.inst   	( id_out_inst    ),//
	.opcode 	( op_code  ),//
	.imm    	( imm     )//
);


//EX 执行阶段
id_ex u_id_ex(
	.clk                	( cpu_clk                 ),
	.sys_en             	( sys_en              ),
	.halt				( ex_halt				), //暂停信号
	.resume		( ex_resume		), //复位信号

	.in_current_p       	( id_out_current_p        ),
	.in_op_code         	( op_code          ),
	.in_imm             	( imm              ),
	.in_alu_type        	( alu_type         ),
	.in_extends_type    	( extends_type     ),
	.in_data_ctrl_type  	( data_ctrl_type   ),
    .in_reg_write_en	    ( reg_write_en	 ),
	.in_rd_addr				( rd_addr		   ),
	.in_jal					( jal),


	.out_current_p      	( ex_out_current_p       ),
	.out_op_code        	( ex_out_op_code         ),
	.out_imm            	( ex_out_imm             ),
	.out_alu_type       	( ex_out_alu_type        ),
	.out_extends_type   	( ex_out_extends_type    ),
	.out_data_ctrl_type 	( ex_out_data_ctrl_type  ),
    .out_reg_write_en	    ( ex_out_reg_write_en	 ),
	.out_rd_addr			( ex_out_rd_addr		 ),
	.out_jal				( ex_out_jal				)


);

mux_alu_1 u_mux_alu_1(
	.current_pc 	( ex_out_current_p  ),//
	.op_code    	( ex_out_op_code     ),//
	.imm        	( ex_out_imm         ),//
	.rs1_value  	( forward_rs1_value   ),//
	.value_1    	( value_1     )//
);

mux_alu_2 u_mux_alu_2(
	.op_code   	( ex_out_op_code    ),//
	.imm       	( ex_out_imm        ),//
	.rs2_value 	( forward_rs2_value  ),//
	.value_2   	( value_2    )//
);
alu u_alu(
	.sys_en       	( sys_en        ),
	.alu_type     	( ex_out_alu_type      ),
	.extends_type 	( ex_out_extends_type  ),
	.value_1      	( value_1       ),
	.value_2      	( value_2       ),

	.result       	( result        )
);

ram_ctrl u_ram_ctrl(
    .op_code(ex_out_op_code),

    .data_ctrl_type(ex_out_data_ctrl_type),
    .data_addr(result),
	.wdata_i(forward_rs2_value),

	.wdata_o(perip_wdata_o),
	.mask(perip_mask_reg),
    .w_en(perip_wen_reg),
	.perip_addr(perip_addr_reg)
); 

//访存
ex_mem u_ex_mem(
	.clk                	( cpu_clk                 ),
	.sys_en             	( sys_en              ),
	.halt				( mem_halt				), //暂停信号
	.resume		( mem_resume		), //复位信号
	.in_op_code         	( ex_out_op_code          ),
	.in_data_ctrl_type  	( ex_out_data_ctrl_type   ),
	.in_extends_type    	( ex_out_extends_type     ),
	.in_ram_addr        	( result         ),
	.in_reg_write_en		( ex_out_reg_write_en	  ),
	.in_rd_addr				(ex_out_rd_addr			),
	.in_perip_wdata_reg		(perip_wdata_o		),
	.in_perip_mask_reg		(perip_mask_reg		),
	.in_perip_wen_reg		(perip_wen_reg		),
	.in_perip_addr_reg		(perip_addr_reg		),

	.out_op_code        	( mem_out_op_code         ),
	.out_data_ctrl_type 	( mem_out_data_ctrl_type  ),
	.out_extends_type   	( mem_out_extends_type    ),
	.out_ram_addr       	( mem_out_ram_addr        ), //写入和读取的地址
	.out_reg_write_en 		( mem_out_reg_write_en	  ),
	.out_rd_addr			( mem_out_rd_addr		 ),
	.out_perip_wdata_reg	(perip_wdata		),
	.out_perip_mask_reg		(perip_mask		),
	.out_perip_wen_reg		(perip_wen		),
	.out_perip_addr_reg_rep0	(perip_addr	),
	.out_perip_addr_reg_rep1	(perip_addr_rep1	),
	.out_perip_addr_reg_rep2	(perip_addr_rep2	),
	.out_perip_addr_reg_rep3	(perip_addr_rep3	),
	.out_perip_addr_reg_rep4	(perip_addr_rep4	)

);
// wire [`CPU_WIDTH-1:0] mem_out_value = (mem_out_op_code == `INST_TYPE_I_L) ?  
perip_rdata_cut u_perip_rdata_cut (
    .op_code(mem_out_op_code),
    .data_ctrl_type(mem_out_data_ctrl_type),
    .extends_type(mem_out_extends_type),
    .data_addr(mem_out_ram_addr),
    .rdata_i(perip_rdata),
    .rdata_o(perip_rdata_o)
);

// WB 写回阶段


mem_wb u_mem_wb(
	.clk            	( cpu_clk             ),
	.sys_en         	( sys_en          ),
	.halt           	( wb_halt            ), //暂停信号
	.resume         	( wb_resume          ), //复位信号
	.in_op_code     	( mem_out_op_code      ),
	.in_alu_result  	( mem_out_ram_addr   ),
	.in_ram_data    	( perip_rdata_o     ),
	.in_reg_write_en	( mem_out_reg_write_en ),
	.in_rd_addr			( mem_out_rd_addr	),

	.out_op_code    	( wb_out_op_code     ),
	.out_alu_result 	( wb_out_alu_result  ),
	.out_ram_data   	( wb_out_ram_data    ),
	.out_reg_write_en 	( wb_out_reg_write_en),
	.out_rd_addr		( wb_out_rd_addr		)

);


wb u_wb(
	.op_code    	( wb_out_op_code     ),
	.alu_result 	( wb_out_alu_result  ),
	.ram_value  	( wb_out_ram_data   ),
	.out_value  	( out_value   )
);

endmodule //top_rescv