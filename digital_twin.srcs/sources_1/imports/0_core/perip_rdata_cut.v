`include "defines.v"

module perip_rdata_cut (
    input [`OPCODE_WIDTH-1:0] op_code,

    input [`DATA_CTRL_TYPES_WIDTH-1:0] data_ctrl_type,
    input [`EXTENDS_TYPES_WIDTH-1:0] extends_type,
    input [`CPU_WIDTH-1:0] data_addr,
    input [`CPU_WIDTH-1:0] rdata_i,

    output reg [`CPU_WIDTH-1:0] rdata_o 
);
always @(*) begin
    if (op_code == `INST_TYPE_I_L) begin
        case (data_ctrl_type)
            `DATA_CTRL_TYPE_BYTE: // lb/lbu
                case (data_addr[1:0])
                    2'b00:  rdata_o = extends_type[0] ? {{24{rdata_i[7]}}, rdata_i[7:0]} : {24'b0, rdata_i[7:0]};
                    2'b01:  rdata_o = extends_type[0] ? {{24{rdata_i[15]}}, rdata_i[15:8]} : {24'b0, rdata_i[15:8]};
                    2'b10:  rdata_o = extends_type[0] ? {{24{rdata_i[23]}}, rdata_i[23:16]} : {24'b0, rdata_i[23:16]};
                    2'b11:  rdata_o = extends_type[0] ? {{24{rdata_i[31]}}, rdata_i[31:24]} : {24'b0, rdata_i[31:24]};
                endcase
            `DATA_CTRL_TYPE_HALF: // lh/lhu
                case (data_addr[1])
                    1'b0:  rdata_o = extends_type[0] ? {{16{rdata_i[15]}}, rdata_i[15:0]} : {16'b0, rdata_i[15:0]};
                    1'b1:  rdata_o = extends_type[0] ? {{16{rdata_i[31]}}, rdata_i[31:16]} : {16'b0, rdata_i[31:16]};
                endcase
            `DATA_CTRL_TYPE_WORD: rdata_o = rdata_i;
            default: rdata_o = 0;
        endcase
    end else begin
        rdata_o = data_addr; // 如果不是加载指令，则返回地址
    end
end
endmodule //perip_rdata_cut