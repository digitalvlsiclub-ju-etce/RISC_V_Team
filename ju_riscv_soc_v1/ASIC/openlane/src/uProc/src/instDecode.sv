`timescale 1ns/1ps
`include "rv_isa.vh"
`include "uProc.vh"

module instDecode #(
    parameter ADDR_WIDTH = 11,   // 2048 words
    parameter DATA_WIDTH = 32,
    parameter PC_WIDTH = 11
)(
    input clk,
    input rst_n,
    output id_stall,// to Fetch stage

    input exec_stall,//from EXEC stage

    
    input [DATA_WIDTH-1:0] inst_in,
    input inst_valid,
    input [PC_WIDTH-1:0] pc_in,


    //gpr read port
    output [4:0]gpr_rs1_raddr,//unregistered
    output [4:0]gpr_rs2_raddr,//unregistered
    input [DATA_WIDTH-1:0] gpr_rs1_rdata,
    input [DATA_WIDTH-1:0] gpr_rs2_rdata,

    //gpr write port
   // input gpr_we,
    //input [4:0]gpr_waddr,
    //input [31:0] gpr_wdata,

    //decoder output stage 
    output                       id_valid_out,//
    output reg[PC_WIDTH-1:0]     pc_out,
    output reg[DATA_WIDTH-1:0]   id_alu_operand_1_out,
    output reg[DATA_WIDTH-1:0]   id_alu_operand_2_out,
    output reg[DATA_WIDTH-1:0]   id_store_data_out,
    output reg[DATA_WIDTH-1:0]   id_immediate_out,
    output reg[4:0]              inst_rd_out,
    output reg[3:0]              id_alu_funct_out,
    output reg[2:0]              id_branch_type_out ,
    output reg                   op_ld_out ,
    output reg                   op_ldu_out , // unsigned load
    output reg[1:0]              op_ld_sz_out, // load size
    output reg                   op_st_out ,
    output reg[1:0]              op_st_sz_out, // store size
    output reg                   op_br_out ,
    output reg                   op_reg_out ,
    output reg                   op_imm_out ,
    output reg                   opcode_op_jalr_out,
    output reg                   opcode_op_jal_out,
    output reg                   opcode_op_auipc_out,
    output reg                   opcode_op_lui_out

);

wire [6:0] inst_opcode_c = inst_in[6:0];
//rd is not used in case of branch and store instructions
wire [4:0] inst_rd_c     = inst_in [11:7] & {5{~(op_br_c | op_st_c)}};
wire [2:0] inst_func3_c  = inst_in[14:12];
assign gpr_rs1_raddr     = inst_in [19:15];
assign gpr_rs2_raddr     = inst_in[24:20];
wire [6:0] inst_func7_c  = inst_in [31:25];

// func7 decoding
wire func7_base_1 = (inst_func7_c == 7'b0000000);
wire func7_base_2 = (inst_func7_c == 7'b0100000);
wire func7_mul    = (inst_func7_c == 7'b0000001);


wire  opcode_op_imm_c   = inst_valid & (inst_opcode_c == `OPC_OP_IMM);
wire  opcode_op_reg_c   = inst_valid & (inst_opcode_c == `OPC_OP_REG);
wire  opcode_op_ld_c    = inst_valid & (inst_opcode_c == `OPC_OP_LOAD);
wire  opcode_op_st_c    = inst_valid & (inst_opcode_c == `OPC_OP_STORE);
wire  opcode_op_br_c    = inst_valid & (inst_opcode_c == `OPC_OP_BRANCH);
wire  opcode_op_auipc_c = inst_valid & (inst_opcode_c == `OPC_OP_AUIPC);
wire  opcode_op_lui_c   = inst_valid & (inst_opcode_c == `OPC_OP_LUI);
wire  opcode_op_jal_c   = inst_valid & (inst_opcode_c == `OPC_OP_JAL);
wire  opcode_op_jalr_c  = inst_valid & (inst_opcode_c == `OPC_OP_JALR);

wire  op_jump_c = opcode_op_jal_c || opcode_op_jalr_c ;

wire [2:0] op_funct3_c = inst_in[14:12];

// op_funct3_c decoding
wire op_add_c   = (op_funct3_c == `OP_FUNCT3_ALU_ADD);
wire op_sub_c   = (op_funct3_c == `OP_FUNCT3_ALU_ADD) & func7_base_2;
wire op_sll_c   = (op_funct3_c == ``OP_FUNCT3_ALU_SLL);
wire op_slt_c   = (op_funct3_c == `OP_FUNCT3_ALU_SLT);
wire op_sltu_c  = (op_funct3_c == `OP_FUNCT3_ALU_SLTU);
wire op_xor_c   = (op_funct3_c == `OP_FUNCT3_ALU_XOR);
wire op_or_c    = (op_funct3_c == `OP_FUNCT3_ALU_OR);
wire op_srl_c   = (op_funct3_c == `OP_FUNCT3_ALU_SRL) & func7_base_1;
wire op_sra_c   = (op_funct3_c == `OP_FUNCT3_ALU_SRL) & func7_base_2;
wire op_and_c   = (op_funct3_c == `OP_FUNCT3_ALU_AND);

// immediate alu instructions
wire op_imm_addi_c  = opcode_op_imm_c & op_add_c;
wire op_imm_slli_c  = opcode_op_imm_c & op_sll_c;
wire op_imm_slti_c  = opcode_op_imm_c & op_slt_c;
wire op_imm_sltiu_c = opcode_op_imm_c & op_sltu_c;
wire op_imm_xori_c  = opcode_op_imm_c & op_xor_c;
wire op_imm_ori_c   = opcode_op_imm_c & op_or_c;
wire op_imm_srli_c  = opcode_op_imm_c & op_srl_c;
wire op_imm_srai_c  = opcode_op_imm_c & op_sra_c;
wire op_imm_andi_c  = opcode_op_imm_c & op_and_c;
wire op_imm_c       = op_imm_addi_c | op_imm_slli_c | op_imm_slti_c | op_imm_sltiu_c | op_imm_xori_c | op_imm_ori_c  | op_imm_srli_c | op_imm_srai_c | op_imm_andi_c;

// register alu instructions
wire op_reg_add_c  = opcode_op_reg_c & op_add_c;
wire op_reg_sub_c  = opcode_op_reg_c & op_sub_c;
wire op_reg_sll_c  = opcode_op_reg_c & op_sll_c;
wire op_reg_slt_c  = opcode_op_reg_c & op_slt_c;
wire op_reg_sltu_c = opcode_op_reg_c & op_sltu_c;
wire op_reg_xor_c  = opcode_op_reg_c & op_xor_c;
wire op_reg_or_c   = opcode_op_reg_c & op_or_c;
wire op_reg_srl_c  = opcode_op_reg_c & op_srl_c;
wire op_reg_sra_c  = opcode_op_reg_c & op_sra_c;
wire op_reg_and_c  = opcode_op_reg_c & op_and_c;
wire op_reg_c      = op_reg_add_c | op_reg_sub_c | op_reg_sll_c | op_reg_slt_c | op_reg_sltu_c | op_reg_xor_c | op_reg_or_c  | op_reg_srl_c | op_reg_sra_c | op_reg_and_c;


// load instructions
wire op_ld_lb_c  = opcode_op_ld_c & (op_funct3_c == `OP_FUNCT3_LB);
wire op_ld_lh_c  = opcode_op_ld_c & (op_funct3_c == `OP_FUNCT3_LH);
wire op_ld_lw_c  = opcode_op_ld_c & (op_funct3_c == `OP_FUNCT3_LW);
wire op_ld_lbu_c = opcode_op_ld_c & (op_funct3_c == `OP_FUNCT3_LBU);
wire op_ld_lhu_c = opcode_op_ld_c & (op_funct3_c == `OP_FUNCT3_LHU);
wire op_ld_c     = op_ld_lb_c | op_ld_lh_c | op_ld_lw_c | op_ld_lbu_c | op_ld_lhu_c ;


// store instructions
wire op_st_sb_c = opcode_op_st_c & (op_funct3_c == `OP_FUNCT3_SB);
wire op_st_sh_c = opcode_op_st_c & (op_funct3_c == `OP_FUNCT3_SH);
wire op_st_sw_c = opcode_op_st_c & (op_funct3_c == `OP_FUNCT3_SW);
wire op_st_c    = op_st_sb_c | op_st_sh_c | op_st_sw_c ; 

// branch instructions
wire op_br_beq_c  = opcode_op_br_c & (op_funct3_c == `OP_FUNCT3_BEQ);
wire op_br_bne_c  = opcode_op_br_c & (op_funct3_c == `OP_FUNCT3_BNE);
wire op_br_blt_c  = opcode_op_br_c & (op_funct3_c == `OP_FUNCT3_BLT);
wire op_br_bge_c  = opcode_op_br_c & (op_funct3_c == `OP_FUNCT3_BGE);
wire op_br_bltu_c = opcode_op_br_c & (op_funct3_c == `OP_FUNCT3_BLTU);
wire op_br_bgeu_c = opcode_op_br_c & (op_funct3_c == `OP_FUNCT3_BGEU);
wire op_br_c      = op_br_beq_c | op_br_bne_c | op_br_blt_c | op_br_bge_c | op_br_bltu_c | op_br_bgeu_c ;


// immediate formatting 
//section 2.3 of riscv unprivileged ISA version 20260120
wire[31:0] id_imm_i_type_c = { {21{inst_in[31]}},inst_in[30:20]}; 
wire[31:0] id_imm_s_type_c = { {21{inst_in[31]}},inst_in[30:25],inst_in[11:7]}; 
wire[31:0] id_imm_b_type_c = { {20{inst_in[31]}},inst_in[7],inst_in[30:25],inst_in[11:8],1'b0}; 
wire[31:0] id_imm_u_type_c = { inst_in[31:12],12'b0}; 
wire[31:0] id_imm_j_type_c = { {12{inst_in[31]}},inst_in[19:12],inst_in[20],inst_in[30:21],1'b0}; 

//selection of alu operation
reg [3:0] id_alu_funct_out_c ;
always @(*) begin
   id_alu_funct_out_c = op_add_c ;
   if (op_imm_addi_c || op_reg_add_c || opcode_op_auipc_c || opcode_op_lui_c || op_jump_c || op_br_c || op_ld_c || op_st_c) begin
     id_alu_funct_out_c = `ALU_ADD ;   
   end
   else if (op_reg_sub_c) begin
     id_alu_funct_out_c = `ALU_SUB ; 
   end
   else if (op_imm_slli_c || op_reg_sll_c) begin
    id_alu_funct_out_c = `ALU_SLL;
   end
   else if (op_imm_slti_c || op_reg_slt_c) begin
    id_alu_funct_out_c = `ALU_SLT  ; 
   end
   else if (op_imm_sltiu_c|| op_reg_sltu_c) begin
    id_alu_funct_out_c = `ALU_SLTU  ; 
   end
   else if (op_imm_xori_c|| op_reg_xor_c) begin
    id_alu_funct_out_c = `ALU_XOR  ; 
   end
   else if (op_imm_ori_c|| op_reg_or_c) begin
    id_alu_funct_out_c = `ALU_OR  ; 
   end
   else if (op_imm_srli_c|| op_reg_srl_c) begin
    id_alu_funct_out_c = `ALU_SRL  ; 
   end
   else if (op_imm_srai_c|| op_reg_sra_c) begin
    id_alu_funct_out_c = `ALU_SRA  ; 
   end
   else if (op_imm_andi_c|| op_reg_and_c) begin
    id_alu_funct_out_c = `ALU_AND  ; 
   end
   else if (opcode_op_auipc_c) begin
    id_alu_funct_out_c = `ALU_AUIPC  ; 
   end
   else if (op_jump_c) begin
    id_alu_funct_out_c = `ALU_JUMP  ; 
   end
end

//selection of branch operation
reg [2:0] id_branch_type_out_c ;
always @(*) begin
   id_branch_type_out_c = 3'b0 ;
   if (op_jump_c) begin
     id_branch_type_out_c = `BR_JMP ;   
   end
   else if (op_br_beq_c) begin
     id_branch_type_out_c = `BR_BEQ ;   
   end
    else if (op_br_bne_c) begin
     id_branch_type_out_c = `BR_BNE ;   
   end 
   else if (op_br_blt_c) begin
     id_branch_type_out_c = `BR_BLT ;   
   end 
   else if (op_br_bge_c) begin
     id_branch_type_out_c = `BR_BGE ;   
   end 
   else if (op_br_bltu_c) begin
     id_branch_type_out_c = `BR_BLTU ;   
   end
   else if (op_br_bgeu_c) begin
     id_branch_type_out_c = `BR_BGEU ;   
   end
  
end

//selection of immediates
reg [31:0] id_immediate_out_c;

always @(*) begin
   id_immediate_out_c = 32'b0;
   if (opcode_op_jalr_c || op_ld_c || op_imm_c) begin
    id_immediate_out_c = id_imm_i_type_c;
   end 
   else if (op_st_c) begin
    id_immediate_out_c = id_imm_s_type_c;;
   end
   else if (op_br_c) begin
    id_immediate_out_c = id_imm_b_type_c;;
   end
   else if (opcode_op_lui_c || opcode_op_auipc_c) begin
    id_immediate_out_c = id_imm_u_type_c;;
   end
   else if (opcode_op_jal_c) begin
    id_immediate_out_c = id_imm_j_type_c;;
   end
end



// selection of alu operand 1 :to do 

reg[31:0] id_alu_operand_1_out_c;
always @(*) begin
  id_alu_operand_1_out_c = 32'b0;
  if (op_imm_c || op_reg_c || op_br_c || op_ld_c || op_st_c || opcode_op_jalr_c ) begin
    id_alu_operand_1_out_c = gpr_rs1_rdata ;
  end
  else if (opcode_op_jal_c || opcode_op_auipc_c) begin
    id_alu_operand_1_out_c = pc_in;
  end
end

// selection of alu operand 2 :to do 

reg [31:0] id_alu_operand_2_out_c;
always @(*) begin
  id_alu_operand_2_out_c = 32'b0;
  if ( op_reg_c || op_br_c ) begin
    id_alu_operand_2_out_c = gpr_rs2_rdata ;
  end
  else if ( op_imm_c || op_ld_c || op_st_c || op_jump_c || opcode_op_lui_c || opcode_op_auipc_c) begin
    id_alu_operand_2_out_c = id_immediate_out_c ;
  end
end

//ID stage pipeline registers

always @(posedge clk) begin
  if(rst_n)begin
    pc_out               <= 'b0;
    id_alu_operand_1_out <= 'b0;
    id_alu_operand_2_out <= 'b0;
    id_store_data_out    <= 'b0;
    id_immediate_out     <= 'b0;
    inst_rd_out          <= 'b0;
    id_alu_funct_out     <= 'b0;
    id_branch_type_out   <= 'b0;
    op_ld_out            <= 'b0;
    op_ldu_out           <= 'b0; // unsigned load
    op_ld_sz_out         <= 'b0; // load size
    op_st_out            <= 'b0;
    op_st_sz_out         <= 'b0; // store size
    op_br_out            <= 'b0;
    op_reg_out           <= 'b0;
    op_imm_out           <= 'b0;
    opcode_op_jalr_out   <= 'b0;
    opcode_op_jal_out    <= 'b0;
    opcode_op_auipc_out  <= 'b0;
    opcode_op_lui_out    <= 'b0;
  end
  else if (!id_stall) begin
    pc_out               <= pc_in;
    id_alu_operand_1_out <= id_alu_operand_1_out_c;
    id_alu_operand_2_out <= id_alu_operand_2_out_c;
    id_store_data_out    <= gpr_rs2_rdata;
    id_immediate_out     <= id_immediate_out_c;
    inst_rd_out          <= inst_rd_c;
    id_alu_funct_out     <= id_alu_funct_out_c;
    id_branch_type_out   <= id_branch_type_out_c;
    op_ld_out            <= op_ld_c;
    op_ldu_out           <= op_ld_lbu_c | op_ld_lhu_c; // unsigned load
    op_ld_sz_out         <= op_ld_lb_c ? 2'd1 :(op_ld_lh_c ? 2'd2 :(op_ld_lw_c ? 2'd3 : 2'd0)); // load size
    op_st_out            <= op_st_c;
    op_st_sz_out         <= op_st_sb_c ? 2'd1 :(op_st_sh_c ? 2'd2 :(op_st_sw_c ? 2'd3 : 2'd0)); // store size
    op_br_out            <= op_br_c;
    op_reg_out           <= op_reg_c;
    op_imm_out           <= op_imm_c;
    opcode_op_jalr_out   <= opcode_op_jalr_c;
    opcode_op_jal_out    <= opcode_op_jal_c;
    opcode_op_auipc_out  <= opcode_op_auipc_c;
    opcode_op_lui_out    <= opcode_op_lui_c;
 end
end

endmodule