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
    input [DATA_WIDTH-1:0]   id_store_data_in,
    input [DATA_WIDTH-1:0]   id_immediate_in,
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
    input                    opcode_op_jalr_in, 
    input                    opcode_op_jal_in,
    input                    opcode_op_auipc_in,
    input                    opcode_op_lui_in,

    output     [PC_WIDTH-1:0]   exec_target_addr_out,    // unregistered 
    output                      exec_load_target_addr_out, // unregistered 
    output reg [4:0]            exec_rd_out, 
    output reg [DATA_WIDTH-1:0] exec_alu_result_out,
    output reg [DATA_WIDTH-1:0] exec_store_data_out, 
    output reg                  exec_op_ld_out ,
    output reg                  exec_op_ldu_out , // unsigned load
    output reg [1:0]            exec_op_ld_sz_out, // load size
    output reg                  exec_op_st_out ,
    output reg [1:0]            exec_op_st_sz_out   
);
//ALU:addition and substraction (using a full adder)
//when full adder is used for subtraction, carry_out  = ~borrow_out (c_out=1 means A>B, c_out=0 means A<B)

/*
Processing for SLTU:
====================
Both A and B are treated as unsigned number (all 32 bits are for numbers, no sign bit)
This makes any sign extended negative number appear as as a huge positive number

1. Compute A-B = A + ~B + 1
2. If c_out=0, underflow occured => A<B. If c_out=1, No underflow => Not(A<B)
*/

/*
Processing for SLT:
  Op1        Op2      Op1[31]    Op2[31]   Adder_A    Adder B
===============================================================
  +ve        +ve        0          0         Op1        -Op2    => Same as SLTU result
  +ve        -ve        0          1                            => Op1 > Op2 => Rd=0
  -ve        +ve        1          0                            => Op1 < Op2 => Rd=1
  -ve        -ve        1          1         -Op2       -Op1    => Do SLTU with swapped -Op1 and -Op2. Result same as SLTU

Example:  
  a==b : SLT(-5,-5) = 0 => sub_using_full_add(5,5). no underflow => cout=1 (means borrow=0) => Save 0 to Rd
  a>b  : SLT(-4,-5) = 0 => sub_using_full_add(5,4). no underflow => cout=1 (means borrow=0) => Save 0 to Rd
  a<b  : SLT(-5,-4) = 1 => sub_using_full_add(4,5). underflow    => cout=0 (means borrow=1) => Save 1 to rd
  
*/

//preparing adder inputs as per conditions mentioned above
wire [DATA_WIDTH-1:0] adder_out_c;
wire  adder_carry_out_c;

wire op_slt_with_both_operands_neg_c = (id_alu_funct_in == `ALU_SLT) &&    // SLT
                                     (id_alu_operand_1_in[31] ==1'b1) && // op1 is negetive
                                     (id_alu_operand_2_in[31] ==1'b1) ;  // op2 is negetive

wire [DATA_WIDTH-1:0] adder_in_A_c = (
                                        (
                                            (id_alu_funct_in == `ALU_SUB) ||
                                            (id_alu_funct_in == `ALU_SLTU) 
                                        ) ?   id_alu_operand_1_in 
                                        :  op_slt_with_both_operands_neg_c ? ~id_alu_operand_2_in + 1'b1
                                        :  id_alu_operand_1_in
                                    );
wire [DATA_WIDTH-1:0] adder_in_B_c = (
                                        (
                                            (id_alu_funct_in == `ALU_SUB) ||
                                            (id_alu_funct_in == `ALU_SLTU) 
                                        ) ?   ~id_alu_operand_2_in + 1'b1 
                                        :  op_slt_with_both_operands_neg_c ? id_alu_operand_1_in
                                        :  id_alu_operand_2_in
                                    );

//using full adder to perform subtraction (operand2 is negetive)
assign {adder_carry_out_c, adder_out_c} = adder_in_A_c + adder_in_B_c ;
wire adder_out_zero_c = (adder_out_c == 'd0);

wire sltu_result_c = ~adder_carry_out_c ;
reg slt_result_c ;

always @(*) begin
    slt_result_c = 1'b0;
    if ((id_alu_operand_1_in[31] == 1'b0) && (id_alu_operand_2_in[31] == 1'b1)) begin //op1 :positive , op2:negetive
        slt_result_c = 1'b0; // op1 > op2
    end
    if ((id_alu_operand_1_in[31] == 1'b1) && (id_alu_operand_2_in[31] == 1'b0)) begin //op1 :negetive , op2:positive
        slt_result_c = 1'b1; // op1 < op2
    end
    if ((id_alu_operand_1_in[31] == 1'b0) && (id_alu_operand_2_in[31] == 1'b0)) begin //op1 :positive , op2:positive
        slt_result_c = sltu_result_c;
    end
    if (op_slt_with_both_operands_neg_c) begin //op1 :negetive , op2:negetive
        slt_result_c = sltu_result_c;
    end
end

//SLL : using standard barrel shifter
wire [4:0] shift_amount_c = id_alu_operand_2_in[4:0];
wire [DATA_WIDTH-1:0] left_shift_stage1_c = shift_amount_c[0] ? {id_alu_operand_1_in[30:0],1'b0} : id_alu_operand_1_in;
wire [DATA_WIDTH-1:0] left_shift_stage2_c = shift_amount_c[1] ? {left_shift_stage1_c[29:0],2'b0}  : left_shift_stage1_c ;
wire [DATA_WIDTH-1:0] left_shift_stage3_c = shift_amount_c[2] ? {left_shift_stage2_c[27:0],4'b0} : left_shift_stage2_c;
wire [DATA_WIDTH-1:0] left_shift_stage4_c = shift_amount_c[3] ? {left_shift_stage3_c[23:0],8'b0} : left_shift_stage3_c;
wire [DATA_WIDTH-1:0] left_shift_stage5_c = shift_amount_c[4] ? {left_shift_stage4_c[15:0],16'b0} : left_shift_stage4_c;

wire [DATA_WIDTH-1:0] sll_result_c = left_shift_stage5_c ;

//SRL : using standard barrel shifter
wire [DATA_WIDTH-1:0] right_shift_stage1_c = shift_amount_c[0] ? {1'b0, id_alu_operand_1_in[31:1]} : id_alu_operand_1_in;
wire [DATA_WIDTH-1:0] right_shift_stage2_c = shift_amount_c[1] ? {2'b0, right_shift_stage1_c[31:2]}  : right_shift_stage1_c ;
wire [DATA_WIDTH-1:0] right_shift_stage3_c = shift_amount_c[2] ? {4'b0, right_shift_stage2_c[31:4]} : right_shift_stage2_c;
wire [DATA_WIDTH-1:0] right_shift_stage4_c = shift_amount_c[3] ? {8'b0, right_shift_stage3_c[31:8]} : right_shift_stage3_c;
wire [DATA_WIDTH-1:0] right_shift_stage5_c = shift_amount_c[4] ? {16'b0, right_shift_stage4_c[31:16]} : right_shift_stage4_c;

wire [DATA_WIDTH-1:0] srl_result_c = right_shift_stage5_c ;

//SRA : using standard barrel shifter
wire op1_sign_bit_c = id_alu_operand_1_in[31];
wire [DATA_WIDTH-1:0] right_shift_arith_stage1_c = shift_amount_c[0] ? { {1{op1_sign_bit_c}}, id_alu_operand_1_in[31:1]} : id_alu_operand_1_in;
wire [DATA_WIDTH-1:0] right_shift_arith_stage2_c = shift_amount_c[1] ? { {2{op1_sign_bit_c}}, right_shift_arith_stage1_c[31:2]}  : right_shift_arith_stage1_c ;
wire [DATA_WIDTH-1:0] right_shift_arith_stage3_c = shift_amount_c[2] ? { {4{op1_sign_bit_c}}, right_shift_arith_stage2_c[31:4]} : right_shift_arith_stage2_c;
wire [DATA_WIDTH-1:0] right_shift_arith_stage4_c = shift_amount_c[3] ? { {8{op1_sign_bit_c}}, right_shift_arith_stage3_c[31:8]} : right_shift_arith_stage3_c;
wire [DATA_WIDTH-1:0] right_shift_arith_stage5_c = shift_amount_c[4] ? { {16{op1_sign_bit_c}}, right_shift_arith_stage4_c[31:16]} : right_shift_arith_stage4_c;

wire [DATA_WIDTH-1:0] sra_result_c = right_shift_arith_stage5_c ;

//All ALU operation results are muxed here as per the instruction
reg [DATA_WIDTH-1:0] exec_alu_result_out_c ;
always @(*) begin
    case (id_alu_funct_in)
        
        `ALU_ADD   : exec_alu_result_out_c = adder_out_c ;
        `ALU_SUB   : exec_alu_result_out_c = adder_out_c ;
        `ALU_SLL   : exec_alu_result_out_c = sll_result_c ;
        `ALU_SLT   : exec_alu_result_out_c = slt_result_c ;
        `ALU_SLTU  : exec_alu_result_out_c = sltu_result_c ;
        `ALU_XOR   : exec_alu_result_out_c = id_alu_operand_1_in ^ id_alu_operand_2_in ;
        `ALU_OR    : exec_alu_result_out_c = id_alu_operand_1_in | id_alu_operand_2_in ;
        `ALU_SRL   : exec_alu_result_out_c = srl_result_c ;
        `ALU_SRA   : exec_alu_result_out_c = sra_result_c ;
        `ALU_AND   : exec_alu_result_out_c = id_alu_operand_1_in & id_alu_operand_2_in ;
        `ALU_AUIPC : exec_alu_result_out_c = adder_out_c ; // pc + imm -> rd 
        // for jal and jalr pc+4 is saved into rd
        `ALU_JUMP  : exec_alu_result_out_c = pc_in + 'd4; 
        default    : exec_alu_result_out_c = 32'b0;
    endcase
end

wire [DATA_WIDTH-1 : 0] temp_exec_target_addr = opcode_op_jalr_in ? {adder_out_c[31:1],1'b0} 
                                             : ( pc_in + id_immediate_in );

assign  exec_target_addr_out  = temp_exec_target_addr [PC_WIDTH-1 : 0];                             

reg branch_true_c ;
always @(*) begin
    case (id_branch_type_in)
        `BR_BEQ   : branch_true_c = adder_out_zero_c ;
        `BR_BNE   : branch_true_c = ~adder_out_zero_c ; 
        `BR_BLT   : branch_true_c = slt_result_c ; 
        `BR_BGE   : branch_true_c = ~slt_result_c ; 
        `BR_BLTU  : branch_true_c = sltu_result_c ; 
        `BR_BGEU  : branch_true_c = ~sltu_result_c ; 
        `BR_JMP   : branch_true_c = 1'b1 ; 
        default   : branch_true_c = 1'b0;
    endcase
end

// pc is loaded with target address under these conditions
assign exec_load_target_addr_out = branch_true_c;

//EX stage pipeline registers

always @(posedge clk) begin
  if(rst_n)begin
    exec_rd_out         <= 'b0;
    exec_alu_result_out <= 'b0;
    exec_store_data_out <= 'b0;
    exec_op_ld_out      <= 'b0;
    exec_op_ldu_out     <= 'b0;
    exec_op_ld_sz_out   <= 'b0;
    exec_op_st_out      <= 'b0;
    exec_op_st_sz_out   <= 'b0; 
  end
  else if (!exec_stall) begin
    exec_rd_out         <= inst_rd_in;
    exec_alu_result_out <= exec_alu_result_out_c;
    exec_store_data_out <= id_store_data_in;
    exec_op_ld_out      <= op_ld_in;
    exec_op_ldu_out     <= op_ldu_in;
    exec_op_ld_sz_out   <= op_ld_sz_in;
    exec_op_st_out      <= op_st_in;
    exec_op_st_sz_out   <= op_st_sz_in; 
 end
end



endmodule