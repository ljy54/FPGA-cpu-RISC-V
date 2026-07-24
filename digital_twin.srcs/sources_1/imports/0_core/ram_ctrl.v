`include "defines.v"

module ram_ctrl (
    input [`OPCODE_WIDTH-1:0] op_code,

    input [`DATA_CTRL_TYPES_WIDTH-1:0] data_ctrl_type,
    input [`CPU_WIDTH-1:0] data_addr,
    input [`CPU_WIDTH-1:0] wdata_i,
    
    output reg w_en,
    output reg [1:0] mask,
    output reg [`CPU_WIDTH-1:0] perip_addr,
    output reg [`CPU_WIDTH-1:0] wdata_o
);
wire [`CPU_WIDTH-1:0] precalc_addr = data_addr;
always @(*) begin
    if (op_code == `INST_TYPE_S) begin
        w_en = 1'b1;
        perip_addr = precalc_addr;
        case (data_ctrl_type)
            `DATA_CTRL_TYPE_WORD: begin
                wdata_o = wdata_i;  
                mask = 2'b10; // sw
            end
            `DATA_CTRL_TYPE_HALF: begin 
                wdata_o = {wdata_i[15:0], wdata_i[15:0]};          // sh
                mask = 2'b01;
            end
            `DATA_CTRL_TYPE_BYTE: begin
                wdata_o = {wdata_i[7:0], wdata_i[7:0], wdata_i[7:0], wdata_i[7:0]};           // sb
                mask = 2'b00;
            end
            default: wdata_o = wdata_i;
        endcase
    end else if (op_code == `INST_TYPE_I_L) begin
        w_en = 1'b0;
        perip_addr = precalc_addr;
        wdata_o = `REG_ZERO;
        mask = 2'b10;
    end else begin
        w_en = 1'b0; // 如果不是存储指令，则不写入
        perip_addr = `REG_ZERO; // 返回零
        wdata_o = `REG_ZERO; // 返回零
        mask = 2'b00; // 不使用掩码
    end
end



endmodule //ram_ctrl