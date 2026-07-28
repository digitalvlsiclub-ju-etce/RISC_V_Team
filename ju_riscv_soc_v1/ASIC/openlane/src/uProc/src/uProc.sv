`timescale 1ns/1ps

module uProc#(
    parameter ADDR_WIDTH = 11,   // 2048 words
    parameter DATA_WIDTH = 32,
    parameter PC_WIDTH = 11
)(
    input clk,
    input rst_n,

    input bist_en,
    output bist_pass,
    output bist_fail

    // input wire pc_en
);

wire [1:0]          pc_sel = load_target_addr_out ? 2'b01 : 2'b00 ;
wire [PC_WIDTH-1:0] imm_addr;
wire [PC_WIDTH-1:0] alu_addr = target_addr_out ;
wire                pc_en = 1'b1;

// instantiate instFetch
    
instFetch #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) u_instFetch (
    .clk(clk),
    .rst_n(rst_n),
    
    .bist_en(bist_en),
    .bist_pass(bist_pass),
    .bist_fail(bist_fail),
    
    .pc_sel(pc_sel),
    .alu_addr(alu_addr),
    .imm_addr(imm_addr),

    .pc_en(pc_en),
    .imem_rd(imem_rd),
    .imem_rd_addr(pc)
);

wire                imem_rd;
wire [PC_WIDTH-1:0] pc;

// instantiate ccm_controller as u_iccm_cntlr


ccm_controller #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
)
u_iccm_cntlr(
    .clk(clk),
    .rst_n(rst_n),
    
    .bist_en(bist_en),
    .bist_pass(bist_pass),
    .bist_fail(bist_fail),

// connect instFetch output (from pc) to ccm_controller read port
    .cntlr_rd(imem_rd),
    .cntlr_raddr({2'b00,pc[ADDR_WIDTH-1:2]}),
    .cntlr_rd_data(imem_rd_data),
    .cntlr_rd_valid(imem_rd_data_valid),

    .cntlr_wr(1'b0), //ccm wr port tied to zero for now
    .cntlr_waddr({ADDR_WIDTH{1'b0}}),
    .cntlr_wr_data({DATA_WIDTH{1'b0}}),

    //2 port sram 
    
    .mem_rd(mem_rd),
    .mem_rd_addr(mem_rd_addr),
    .mem_rd_data(mem_rd_data),

    .mem_wr(mem_wr),
    .mem_wr_addr(mem_wr_addr),
    .mem_wr_data(mem_wr_data)
);

wire                  mem_rd;
wire [ADDR_WIDTH-1:0] mem_rd_addr;
wire [DATA_WIDTH-1:0] mem_rd_data;

wire                  mem_wr;
wire [ADDR_WIDTH-1:0] mem_wr_addr;
wire [DATA_WIDTH-1:0] mem_wr_data;

// instantiate dpram as u_iccm

dpram_2048x32 u_iccm(

        //write port
        .clka(clk),
        .ena(mem_wr),
        .wea(mem_wr),
        .addra(mem_wr_addr),
        .dia(mem_wr_data),

        //read port
        .clkb(clk),
        .enb(mem_rd),
        .addrb(mem_rd_addr),
        .dob(mem_rd_data)
);

reg [PC_WIDTH-1 : 0] pc_d1;
wire [PC_WIDTH-1 : 0] pc_to_id;

always @(posedge clk) begin
    if(imem_rd)begin
        pc_d1 <= pc;
    end
end
assign pc_to_id = pc_d1;

wire [DATA_WIDTH-1:0] imem_rd_data; //current insruction
wire                  imem_rd_data_valid;

// instantiate instDecode

instDecode #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) u_instDecode (
    .clk(clk),
    .rst_n(rst_n),
    .id_stall(1'b0),
    
    .inst_in(imem_rd_data),
    .inst_valid(imem_rd_data_valid),
    .pc_in(pc_to_id),

    .gpr_we(1'b0),
    .gpr_waddr(5'h00),
    .gpr_wdata(32'h00000000),

    .pc_out(pc_id_to_ex),
    .id_alu_operand_1_out(alu_operand_1),
    .id_alu_operand_2_out(alu_operand_2),
    .id_store_data_out(store_data),
    .id_immediate_out(immediate),
    .inst_rd_out(inst_rd),
    .id_alu_funct_out(alu_funct),
    .id_branch_type_out(branch_type) ,
    .op_ld_out(op_ld) ,
    .op_ldu_out(op_ldu) , // unsigned load
    .op_ld_sz_out(op_ld_sz), // load size
    .op_st_out(op_st) ,
    .op_st_sz_out(op_st_sz), // store size
    .op_br_out (op_br),
    .op_reg_out (op_reg),
    .op_imm_out(op_imm) ,
    .opcode_op_jalr_out(opcode_op_jalr),
    .opcode_op_jal_out(opcode_op_jal),
    .opcode_op_auipc_out(opcode_op_auipc),
    .opcode_op_lui_out(opcode_op_lui)
);

// decode to execute stage connections
    wire [PC_WIDTH-1:0]     pc_id_to_ex;
    wire [DATA_WIDTH-1:0]   alu_operand_1;
    wire [DATA_WIDTH-1:0]   alu_operand_2;
    wire [DATA_WIDTH-1:0]   store_data;
    wire [DATA_WIDTH-1:0]   immediate;
    wire [4:0]              inst_rd;
    wire [3:0]              alu_funct;
    wire [2:0]              branch_type;
    wire                    op_ld;
    wire                    op_ldu; // unsigned load
    wire [1:0]              op_ld_sz; // load size
    wire                    op_st;
    wire [1:0]              op_st_sz; // store size
    wire                    op_br;
    wire                    op_reg;
    wire                    op_imm;
    wire                    opcode_op_jalr;
    wire                    opcode_op_jal;
    wire                    opcode_op_auipc;
    wire                    opcode_op_lui;

//instantiate instExec
instExec #(
    .ADDR_WIDTH(ADDR_WIDTH),   // 2048 words
    .DATA_WIDTH(DATA_WIDTH),
    .PC_WIDTH(PC_WIDTH)
) u_instExec (
    .clk(clk),
    .rst_n(rst_n),
    .exec_stall(1'b0),
    

    //input from decoder
    .pc_in(pc_id_to_ex),
    .id_alu_operand_1_in(alu_operand_1),
    .id_alu_operand_2_in(alu_operand_2),
    .id_store_data_in(store_data),
    .id_immediate_in(immediate),
    .inst_rd_in(inst_rd),
    .id_alu_funct_in(alu_funct),
    .id_branch_type_in(branch_type) ,
    .op_ld_in(op_ld) ,
    .op_ldu_in(op_ldu) , // unsigned load
    .op_ld_sz_in(op_ld_sz), // load size
    .op_st_in(op_sz) ,
    .op_st_sz_in(op_st_sz), // store size
    .op_br_in(op_br) ,
    .op_reg_in(op_reg) ,
    .op_imm_in(op_imm) ,
    .opcode_op_jalr_in(opcode_op_jalr), 
    .opcode_op_jal_in(opcode_op_jal),
    .opcode_op_auipc_in(opcode_op_auipc),
    .opcode_op_lui_in(opcode_op_lui),

    .exec_target_addr_out(target_addr_out),    // unregistered 
    .exec_load_target_addr_out(load_target_addr_out), // unregistered 
    .exec_rd_out(rd), 
    .exec_alu_result_out(alu_result),
    .exec_store_data_out(store_data), 
    .exec_op_ld_out(op_ld) ,
    .exec_op_ldu_out(op_ldu) , // unsigned load
    .exec_op_ld_sz_out(op_ld_sz), // load size
    .exec_op_st_out(op_st) ,
    .exec_op_st_sz_out(op_st_sz)   
);

    wire [PC_WIDTH-1:0] target_addr_out;
    wire                load_target_addr_out;

// execute to mem stage connections
    wire [4:0]            rd; 
    wire [DATA_WIDTH-1:0] alu_result;
    wire [DATA_WIDTH-1:0] store_data; 
    wire                  op_ld ;
    wire                  op_ldu ; // unsigned load
    wire  [1:0]           op_ld_sz; // load size
    wire                  op_st;
    wire  [1:0]           op_st_sz;

loadStore #(
    .ADDR_WIDTH(ADDR_WIDTH),   // 2048 words
    .DATA_WIDTH(DATA_WIDTH),
    .PC_WIDTH(PC_WIDTH)
) u_loadStore (
    .clk(clk),
    .rst_n(rst_n),
    .mem_stall(1'b0),
    
//input from execution stage

    .exec_rd_in(rd), 
    .exec_alu_result_in(alu_result),
    .exec_store_data_in(store_data), 
    .exec_op_ld_in(op_ld) ,
    .exec_op_ldu_in(op_ldu) , // unsigned load
    .exec_op_ld_sz_in(op_ld_sz), // load size
    .exec_op_st_in(op_st) ,
    .exec_op_st_sz_in(op_st_sz)   
);



endmodule