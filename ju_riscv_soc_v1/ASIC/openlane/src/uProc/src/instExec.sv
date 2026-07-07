`timescale 1ns/1ps
`include "rv_isa.vh"
`include "uProc.vh"

module instExec #(
    parameter ADDR_WIDTH = 11,   // 2048 words
    parameter DATA_WIDTH = 32,
    parameter PC_WIDTH = 11
)(
    input clk,
    input rst_n,
    input exec_stall,
    

    //input from decoder
    input [PC_WIDTH-1:0]     pc_in,
    input [DATA_WIDTH-1:0]   id_alu_operand_1_in,
    input [DATA_WIDTH-1:0]   id_alu_operand_2_in,
    input [4:0]              inst_rd_in,
    input [3:0]              id_alu_funct_in,
    input [2:0]              id_branch_type_in ,
    input                    op_ld_in ,
    input                    op_ldu_in , // unsigned load
    input [1:0]              op_ld_sz_in, // load size
    input                    op_st_in ,
    input [1:0]              op_st_sz_in, // store size
    input                    op_br_in ,
    input                    op_reg_in ,
    input                    op_imm_in ,
    input                    opcode_op_jalr_in 
);
/*
sltu:
 sr1 = +ve , imm = +ve => sr1 - imm = +ve means sr1 greater than imm which follows rd = 0
 sr1 = +ve , imm = -ve => sr1 - imm = +ve means sr1 greater than imm which follows rd = 0

*/
//ALU:adder
reg [DATA_WIDTH-1:0] adder_out_c ;
reg adder_carry_out_c ;
always @(*) begin
    //operand 2 is subtracted from operand 1 when op is subtract and less-than
    if ((id_alu_funct_in == `ALU_SUB) || (id_alu_funct_in == `ALU_SLT) || (id_alu_funct_in == `ALU_SLTU)) begin
        {adder_carry_out_c, adder_out_c} = id_alu_operand_1_in + ~id_alu_operand_2_in + 1'b1 ;
    end
    else begin
        {adder_carry_out_c, adder_out_c}  = id_alu_operand_1_in + id_alu_operand_2_in;
    end
end



endmodule