`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/22/2025 11:42:01 AM
// Design Name: 
// Module Name: dram_driver
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


module dram_driver(
    input  logic         clk				,

    input  logic [17:0]  perip_addr			,
    input  logic [31:0]  perip_wdata		,
	input  logic [1:0]	 perip_mask			,
    input  logic         dram_wen           ,
    output logic [31:0]  perip_rdata		
);
    logic [15:0] dram_addr;
    logic [ 1:0] offset;
    logic [31:0] dram_data, dram_rdata_raw, dout;

    reg [1:0] offset_reg;
    reg [1:0] perip_mask_reg;

    reg [3 : 0] wea;


    assign dram_addr = perip_addr[17:2];
    assign offset = perip_addr[1:0];
    assign perip_rdata = dout;

    // DRAM Mem_DRAM (
    //     .clk        (clk),
    //     .a          (dram_addr),
    //     .spo        (dram_rdata_raw),
    //     .we         (dram_wen),
    //     .d          (dram_data)
    // );

    BRAM your_instance_name (
        .clka(clk),    // input wire clka
        .wea(wea),      // input wire [3 : 0] wea
        .addra(dram_addr),  // input wire [15 : 0] addra
        .dina(dram_data),    // input wire [31 : 0] dina
        .douta(dram_rdata_raw)  // output wire [31 : 0] douta
    );

    always @(posedge clk) begin
        offset_reg <= offset;
        perip_mask_reg <= perip_mask;
    end

    // dram_rdata_raw process, lh lb
    always_comb begin
        dout = 0;
        case (perip_mask_reg)
            2'b00: // lb/lbu
                case (offset_reg)
                    2'b00:  dout = {24'b0, dram_rdata_raw[7:0]};
                    2'b01:  dout = {24'b0, dram_rdata_raw[15:8]};
                    2'b10:  dout = {24'b0, dram_rdata_raw[23:16]};
                    2'b11:  dout = {24'b0, dram_rdata_raw[31:24]};
                endcase
            2'b01: // lh/lhu
                case (offset_reg[1])
                    1'b0:  dout = {24'b0, dram_rdata_raw[15:0]};
                    1'b1:  dout = {24'b0, dram_rdata_raw[31:16]};
                endcase
            2'b10: dout = dram_rdata_raw;
            default: dout = 0;
        endcase
    end

    // dram_data_raw process, sh, sb
    always_comb begin
        if (dram_wen) begin
            case (perip_mask)
                2'b10: begin
                    wea = 4'b1111;
                    dram_data = perip_wdata;  // sw
                end
                2'b01: begin           // sh
                    dram_data = {perip_wdata[15:0], perip_wdata[15:0]};
                    if (offset[1] == 1'b1) begin
                        wea = 4'b1100;
                    end else begin
                        wea = 4'b0011;
                    end
                end
                2'b00: begin           // sb
                    dram_data = {perip_wdata[7:0], perip_wdata[7:0], perip_wdata[7:0], perip_wdata[7:0]};
                    case (offset)
                        2'b00: wea = 4'b0001;
                        2'b01: wea = 4'b0010;
                        2'b10: wea = 4'b0100;
                        2'b11: wea = 4'b1000;
                    endcase
                end
                default: dram_data = perip_wdata;
            endcase
        end else begin
            wea = 4'b0000;
        end
    end
endmodule
