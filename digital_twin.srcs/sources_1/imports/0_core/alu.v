`include "defines.v"

module alu(
    input sys_en,
    input [`ALU_TYPES_WIDTH-1:0] alu_type,
    input [`EXTENDS_TYPES_WIDTH-1:0] extends_type,
    input [`CPU_WIDTH-1:0] value_1,
    input [`CPU_WIDTH-1:0] value_2,
    (* dont_touch = "true" *) output reg [`CPU_WIDTH-1:0] result
);

always @(*) begin
    if (!sys_en) begin
        result = 0;
    end else begin
        case (alu_type)
            `ALU_TYPE_ADD: result = value_1 + value_2;
            `ALU_TYPE_SUB: result = value_1 - value_2;
            `ALU_TYPE_XOR: result = value_1 ^ value_2;
            `ALU_TYPE_OR:  result = value_1 | value_2;
            `ALU_TYPE_AND: result = value_1 & value_2;
            `ALU_TYPE_SHIFT_LEFT: 
                result = value_1 << value_2[`EFFECTIVE_SHIFT_WIDTH-1:0];
            `ALU_TYPE_SHIFT_RIGHT: 
                case (extends_type)
                    `EXTENDS_TYPE_NONE: 
                        result = value_1 >> value_2[`EFFECTIVE_SHIFT_WIDTH-1:0];
                    `EXTENDS_TYPE_MSB:  
                        result = $signed(value_1) >>> value_2[`EFFECTIVE_SHIFT_WIDTH-1:0];
                    default: result = 0;
                endcase
            `ALU_TYPE_LESS_THAN: 
                case (extends_type)
                    `EXTENDS_TYPE_NONE: 
                        result = ($signed(value_1) < $signed(value_2)) ? 1 : 0;
                    `EXTENDS_TYPE_ZERO: 
                        result = (value_1 < value_2) ? 1 : 0;
                    default: result = 0;
                endcase
            `ALU_TYPE_GREATER_EQUAL:  
                case (extends_type)
                    `EXTENDS_TYPE_NONE: 
                        result = ($signed(value_1) >= $signed(value_2)) ? 1 : 0;
                    `EXTENDS_TYPE_ZERO: 
                        result = (value_1 >= value_2) ? 1 : 0;
                    default: result = 0;
                endcase
            `ALU_TYPE_EQUAL: 
                result = (value_1 == value_2) ? 1 : 0;
            `ALU_TYPE_NOT_EQUAL: 
                result = (value_1 != value_2) ? 1 : 0;
            default: result = 0;
        endcase
    end
end
endmodule