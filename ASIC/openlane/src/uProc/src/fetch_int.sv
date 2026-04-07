`timescale 1ns/1ps

module fetch_int #(
    parameter ADDR_WIDTH = 11,   // 2048 words
    parameter DATA_WIDTH = 32
)(
    input clk,
    input rst_n,
    
    input bist_en,
    output bist_pass,
    output bist_fail,
    
    input [1:0] pc_sel,
    input [ADDR_WIDTH-1:0] alu_addr,
    input [ADDR_WIDTH-1:0] imm_addr,
    
    input   cntlr_rd,
    output  [DATA_WIDTH-1:0]cntlr_rd_data,
    output  cntlr_rd_valid,

    input cntlr_wr,
    input [ADDR_WIDTH-1:0]cntlr_waddr,
    input [DATA_WIDTH-1:0]cntlr_wr_data,

    output   mem_rd,
    output  [ADDR_WIDTH-1:0]mem_rd_addr,
    input   [DATA_WIDTH-1:0]mem_rd_data,

    output   mem_wr,
    output  [ADDR_WIDTH-1:0]mem_wr_addr,
    output  [DATA_WIDTH-1:0]mem_wr_data
);

    wire [ADDR_WIDTH-1:0] cntlr_raddr;
    
    // iccm bist module
    
    wire   bist_cntlr_rd;
    wire  [ADDR_WIDTH-1:0]bist_cntlr_raddr;
    wire bist_cntlr_wr;
    wire [ADDR_WIDTH-1:0]bist_cntlr_waddr;
    wire [DATA_WIDTH-1:0]bist_cntlr_wr_data;
    
    iccm_bist #(
    .ADDR_WIDTH(11),
    .DATA_WIDTH(32),
    .NUM_ROWS(2048)
)   u_iccm_bist(
    .clk(clk),
    .rst_n(rst_n),
    .bist_en(bist_en),
    .bist_pass(bist_pass),
    .bist_fail(bist_fail),
    
    .cntlr_rd(bist_cntlr_rd),
    .cntlr_raddr(bist_cntlr_raddr),
    .cntlr_rd_data(cntlr_rd_data),
    .cntlr_rd_valid(cntlr_rd_valid),

    .cntlr_wr(bist_cntlr_wr),
    .cntlr_waddr(bist_cntlr_waddr),
    .cntlr_wr_data(bist_cntlr_wr_data)
    );

    //instantiate pc_module & ccm_controller

    pc_block pc_uut (
        .clk(clk), 
        .rst_n(rst_n),
        .pc_en(1'b1),
        .pc_sel(pc_sel),
        .imm_addr(imm_addr),
        .alu_addr(alu_addr),
        .pc(cntlr_raddr)
    );
    
    wire mux_cntlr_rd = bist_en ? bist_cntlr_rd : cntlr_rd;
    wire [ADDR_WIDTH-1:0]mux_cntlr_raddr = bist_en ? bist_cntlr_raddr : cntlr_raddr;

    wire mux_cntlr_wr = bist_en ? bist_cntlr_wr : cntlr_wr;
    wire [ADDR_WIDTH-1:0]mux_cntlr_waddr = bist_en ? bist_cntlr_waddr : cntlr_waddr;
    wire [DATA_WIDTH-1:0]mux_cntlr_wr_data = bist_en ? bist_cntlr_wr_data : cntlr_wr_data;
    
    ccm_controller ccm_uut (
        .clk(clk),
        .rst_n(rst_n),

        .cntlr_rd(mux_cntlr_rd),
        .cntlr_raddr(mux_cntlr_raddr), // address coming from pc
        .cntlr_rd_data(cntlr_rd_data),
        .cntlr_rd_valid(cntlr_rd_valid),

        .cntlr_wr(mux_cntlr_wr),
        .cntlr_waddr(mux_cntlr_waddr),
        .cntlr_wr_data(mux_cntlr_wr_data),

        .mem_rd(mem_rd),
        .mem_rd_addr(mem_rd_addr),
        .mem_rd_data(mem_rd_data),

        .mem_wr(mem_wr),
        .mem_wr_addr(mem_wr_addr),
        .mem_wr_data(mem_wr_data)
    );

    
    


endmodule