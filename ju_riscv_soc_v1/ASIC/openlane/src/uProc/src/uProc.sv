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

);
// execution stage to direct feedback to pc module
    wire [PC_WIDTH-1:0]   target_addr_out;
    wire                  load_target_addr_out;
//instFetch inputs
    wire [1:0]            pc_sel = load_target_addr_out ? 2'b01 : 2'b00 ;
    wire [PC_WIDTH-1:0]   imm_addr;
    wire [PC_WIDTH-1:0]   alu_addr = target_addr_out ;
    wire                  pc_en_temp =  1'b1;
    reg                   pc_en;
//instFetch outputs to ccm_controller
    wire                  imem_rd;
    wire [PC_WIDTH-1:0]   pc;
//ccm_controller and iccm interface
    wire                  mem_rd;
    wire [ADDR_WIDTH-1:0] mem_rd_addr;
    wire [DATA_WIDTH-1:0] mem_rd_data;

    wire                  mem_wr;
    wire [ADDR_WIDTH-1:0] mem_wr_addr;
    wire [DATA_WIDTH-1:0] mem_wr_data;

// InstDecode to gpr read port
 //gpr read port
    wire [4:0]            gpr_rs1_raddr;//unregistered
    wire [4:0]            gpr_rs2_raddr;//unregistered
    wire [DATA_WIDTH-1:0] gpr_rs1_rdata;
    wire [DATA_WIDTH-1:0] gpr_rs2_rdata;
//ccm_controller to instDecode
    wire [DATA_WIDTH-1:0] imem_rd_data; //current insruction
    wire                  imem_rd_data_valid;
// Fetch to Decode stage connections
    wire                  id_stall;

// decode to execute stage connections
    wire                  exec_stall;
    wire                  id_valid;      
    wire [PC_WIDTH-1:0]   id_pc;
    wire [DATA_WIDTH-1:0] id_alu_operand_1;
    wire [DATA_WIDTH-1:0] id_alu_operand_2;
    wire [DATA_WIDTH-1:0] id_store_data;
    wire [DATA_WIDTH-1:0] id_immediate;
    wire [4:0]            id_inst_rd;
    wire [3:0]            id_alu_funct;
    wire [2:0]            id_branch_type;
    wire                  id_op_ld;
    wire                  id_op_ldu; // unsigned load
    wire [1:0]            id_op_ld_sz; // load size
    wire                  id_op_st;
    wire [1:0]            id_op_st_sz; // store size
    wire                  op_br;
    wire                  op_reg;
    wire                  op_imm;
    wire                  opcode_op_jalr;
    wire                  opcode_op_jal;
    wire                  opcode_op_auipc;
    wire                  opcode_op_lui;
// execute to mem stage connections
    wire                  mem_stall;
    wire                  exec_valid;
    wire [4:0]            exec_rd; 
    wire [DATA_WIDTH-1:0] exec_alu_result;
    wire [DATA_WIDTH-1:0] exec_store_data; 
    wire                  exec_op_ld ;
    wire                  exec_op_ldu ; // unsigned load
    wire  [1:0]           exec_op_ld_sz; // load size
    wire                  exec_op_st;
    wire  [1:0]           exec_op_st_sz;
// mem to WB stage connections 
    wire                  mem_valid_out; //input from mem stage is valid
    wire [4:0]            mem_rd_out; 
    wire [DATA_WIDTH-1:0] mem_rd_data_out;
// WB to gpr write port
//gpr write port
wire [4:0]                gpr_rd_waddr;//unregistered
wire[DATA_WIDTH-1:0]      gpr_rd_wdata;//unregistered
wire                      gpr_rd_we;//unregistered

    
always @(posedge clk or negedge rst_n) begin
        if(~rst_n) pc_en <= 1'b0;
        else pc_en <= pc_en_temp;
end

// instantiate instFetch
    
instFetch #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) u_instFetch (
    .clk(clk),
    .rst_n(rst_n),

    .id_stall(id_stall),
    
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

    reg  [PC_WIDTH-1 : 0] pc_d1;
    wire [PC_WIDTH-1 : 0] pc_to_id;

always @(posedge clk) begin
    if(imem_rd)begin
        pc_d1 <= pc;
    end
end
assign pc_to_id = pc_d1;

gpr #(
    .DATA_WIDTH(DATA_WIDTH)
)u_gpr(
  .clk(clk),
  .reset(~rst_n),

  //write port
  .write(gpr_rd_we),
  .dr(gpr_rd_waddr),
  .wrData(gpr_rd_wdata),

  //rd port 1
  .sr1(gpr_rs1_raddr),
  .rdData1(gpr_rs1_rdata),

  //rd port 2
  .sr2(gpr_rs2_raddr),
  .rdData2(gpr_rs2_rdata)
);


// instantiate instDecode

instDecode #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .PC_WIDTH(PC_WIDTH)
) u_instDecode (
    .clk(clk),
    .rst_n(rst_n),
    .id_stall(id_stall),// to Fetch stage

    .exec_stall(exec_stall),// from EXEC stage 
    
    
    .inst_in(imem_rd_data),
    .inst_valid(imem_rd_data_valid),
    .pc_in(pc_to_id),

     //gpr read port
    .gpr_rs1_raddr(gpr_rs1_raddr),//unregistered
    .gpr_rs2_raddr(gpr_rs2_raddr),//unregistered
    .gpr_rs1_rdata(gpr_rs1_rdata),
    .gpr_rs2_rdata(gpr_rs2_rdata),


    .id_valid_out(id_valid),
    .pc_out(id_pc),
    .id_alu_operand_1_out(id_alu_operand_1),
    .id_alu_operand_2_out(id_alu_operand_2),
    .id_store_data_out(id_store_data),
    .id_immediate_out(id_immediate),
    .inst_rd_out(id_inst_rd),
    .id_alu_funct_out(id_alu_funct),
    .id_branch_type_out(id_branch_type) ,
    .op_ld_out(id_op_ld) ,
    .op_ldu_out(id_op_ldu) , // unsigned load
    .op_ld_sz_out(id_op_ld_sz), // load size
    .op_st_out(id_op_st) ,
    .op_st_sz_out(id_op_st_sz), // store size
    .op_br_out (op_br),
    .op_reg_out (op_reg),
    .op_imm_out(op_imm) ,
    .opcode_op_jalr_out(opcode_op_jalr),
    .opcode_op_jal_out(opcode_op_jal),
    .opcode_op_auipc_out(opcode_op_auipc),
    .opcode_op_lui_out(opcode_op_lui)
);

//instantiate instExec

instExec #(
    .ADDR_WIDTH(ADDR_WIDTH),   // 2048 words
    .DATA_WIDTH(DATA_WIDTH),
    .PC_WIDTH(PC_WIDTH)
) u_instExec (
    .clk(clk),
    .rst_n(rst_n),
    .mem_stall(mem_stall),//from MEM stage
    .exec_stall(exec_stall),//to ID stage
    

    //input from decoder
    .id_valid_in(id_valid),
    .pc_in(id_pc),
    .id_alu_operand_1_in(id_alu_operand_1),
    .id_alu_operand_2_in(id_alu_operand_2),
    .id_store_data_in(id_store_data),
    .id_immediate_in(id_immediate),
    .inst_rd_in(id_inst_rd),
    .id_alu_funct_in(id_alu_funct),
    .id_branch_type_in(id_branch_type) ,
    .op_ld_in(id_op_ld) ,
    .op_ldu_in(id_op_ldu) , // unsigned load
    .op_ld_sz_in(id_op_ld_sz), // load size
    .op_st_in(id_op_st) ,
    .op_st_sz_in(id_op_st_sz), // store size
    .op_br_in(op_br) ,
    .op_reg_in(op_reg) ,
    .op_imm_in(op_imm) ,
    .opcode_op_jalr_in(opcode_op_jalr), 
    .opcode_op_jal_in(opcode_op_jal),
    .opcode_op_auipc_in(opcode_op_auipc),
    .opcode_op_lui_in(opcode_op_lui),

    .exec_valid_out(exec_valid),
    .exec_target_addr_out(target_addr_out),    // unregistered 
    .exec_load_target_addr_out(load_target_addr_out), // unregistered 
    .exec_rd_out(exec_rd), 
    .exec_alu_result_out(exec_alu_result),
    .exec_store_data_out(exec_store_data), 
    .exec_op_ld_out(exec_op_ld) ,
    .exec_op_ldu_out(exec_op_ldu) , // unsigned load
    .exec_op_ld_sz_out(exec_op_ld_sz), // load size
    .exec_op_st_out(exec_op_st) ,
    .exec_op_st_sz_out(exec_op_st_sz)   
);



instMem #(
    .ADDR_WIDTH(ADDR_WIDTH),   // 2048 words
    .DATA_WIDTH(DATA_WIDTH),
    .PC_WIDTH(PC_WIDTH)
) u_instMem (
    .clk(clk),
    .rst_n(rst_n),
    .mem_stall(mem_stall),// to EXEC stage
    
//input from execution stage

    .exec_valid_in(exec_valid),
    .exec_rd_in(exec_rd), 
    .exec_alu_result_in(exec_alu_result),
    .exec_store_data_in(exec_store_data), 
    .exec_op_ld_in(exec_op_ld) ,
    .exec_op_ldu_in(exec_op_ldu) , // unsigned load
    .exec_op_ld_sz_in(exec_op_ld_sz), // load size
    .exec_op_st_in(exec_op_st) ,
    .exec_op_st_sz_in(exec_op_st_sz),

//output to WB stage 
    .mem_valid_out(mem_valid_out), //input from mem stage is valid
    .mem_rd_out(mem_rd_out), 
    .mem_rd_data_out(mem_rd_data_out)   
  
);

instWB #(
    .ADDR_WIDTH(ADDR_WIDTH),   // 2048 words
    .DATA_WIDTH(DATA_WIDTH),
    .PC_WIDTH(PC_WIDTH)
) u_instWB(
    .clk(clk),
    .rst_n(rst_n),

    //input from mem stage
    .mem_valid_in(mem_valid_out), //input from mem stage is valid
    .mem_rd_in(mem_rd_out), 
    .mem_rd_data_in(mem_rd_data_out), 

    //gpr write port
    .gpr_rd_waddr(gpr_rd_waddr),//unregistered
    .gpr_rd_wdata(gpr_rd_wdata),//unregistered
    .gpr_rd_we(gpr_rd_we)//unregistered
    
);



endmodule