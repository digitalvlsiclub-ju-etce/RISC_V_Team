// rv32i opcodes

`ifndef RV32I_OPCODES_HDR__
`define RV32I_OPCODES_HDR__ 

`define RV32_OPCODE_WIDTH 7

// base32 opcodes
`define OPC_OP_IMM    7'b 00_100_11
`define OPC_OP_REG    7'b 01_100_11
`define OPC_OP_STORE  7'b 01_000_11
`define OPC_OP_LOAD   7'b 00_000_11
`define OPC_OP_BRANCH 7'b 11_000_11

`define OPC_OP_AUIPC   7'b 00_101_11
`define OPC_OP_LUI     7'b 01_101_11
`define OPC_OP_JAL     7'b 11_011_11
`define OPC_OP_JALR    7'b 11_001_11

// ALU func3 decoding
`define OP_FUNCT3_WIDTH 3
`define OP_FUNCT3_ALU_ADD   3'b000
`define OP_FUNCT3_ALU_SLL   3'b001
`define OP_FUNCT3_ALU_SLT   3'b010
`define OP_FUNCT3_ALU_SLTU  3'b011
`define OP_FUNCT3_ALU_XOR   3'b100
`define OP_FUNCT3_ALU_SRL   3'b101
`define OP_FUNCT3_ALU_OR    3'b110
`define OP_FUNCT3_ALU_AND   3'b111

// STORE func3 decoding

`define OP_FUNCT3_SB 3'b000
`define OP_FUNCT3_SH 3'b001
`define OP_FUNCT3_SW 3'b010

// LOAD func3 decoding

`define OP_FUNCT3_LB 3'b000
`define OP_FUNCT3_LH 3'b001
`define OP_FUNCT3_LW 3'b010
`define OP_FUNCT3_LBU 3'b100
`define OP_FUNCT3_LHU 3'b101

//BRANCH func3 decoding
`define OP_FUNCT3_BEQ 3'b000
`define OP_FUNCT3_BNE 3'b001
`define OP_FUNCT3_BLT   3'b100
`define OP_FUNCT3_BGE 3'b101
`define OP_FUNCT3_BLTU 3'b110
`define OP_FUNCT3_BGEU 3'b111



//register_ALU  func3 decoding
`define OP_IMM_FUNCT3_WIDTH 3
`define OP_IMM_FUNCT3_ADDI 3'b000
`define OP_IMM_FUNCT3_SLLI 3'b001
`define OP_IMM_FUNCT3_SLTI 3'b010
`define OP_IMM_FUNCT3_SLTIU 3'b011
`define OP_IMM_FUNCT3_XORI 3'b100
`define OP_IMM_FUNCT3_SRLI 3'b101
`define OP_IMM_FUNCT3_SRAI 3'b101
`define OP_IMM_FUNCT3_ORI 3'b110
`define OP_IMM_FUNCT3_ANDI 3'b111





`define OPC_NOP 32'b000000000000_00000_000_00000_00_100_11
`endif 

