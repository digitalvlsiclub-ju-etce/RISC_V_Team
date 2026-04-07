`timescale 1ns/1ps

module fetch #(
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
    
    input cntlr_rd,
    output [DATA_WIDTH-1:0] cntlr_rd_data,
    output  cntlr_rd_valid,

    input cntlr_wr,
    input [ADDR_WIDTH-1:0]cntlr_waddr,
    input [DATA_WIDTH-1:0]cntlr_wr_data

    /* 
    output reg mem_rd,
    output reg [ADDR_WIDTH-1:0]mem_rd_addr,
    input [DATA_WIDTH-1:0]mem_rd_data,

    output reg mem_wr,
    output reg [ADDR_WIDTH-1:0]mem_wr_addr,
    output reg [DATA_WIDTH-1:0]mem_wr_data

    */
);

    wire mem_rd;
    wire [ADDR_WIDTH-1:0]mem_rd_addr;
    wire[DATA_WIDTH-1:0]mem_rd_data;

    wire mem_wr;
    wire [ADDR_WIDTH-1:0]mem_wr_addr;
    wire [DATA_WIDTH-1:0]mem_wr_data;


    //instantiate fetch_int & block ram

    fetch_int uut_1(
        .clk(clk),
        .rst_n(rst_n),
        
        .bist_en(bist_en),
        .bist_pass(bist_pass),
        .bist_fail(bist_fail),

        .pc_sel(pc_sel),
        .imm_addr(imm_addr),
        .alu_addr(alu_addr),

        .cntlr_rd(cntlr_rd),
        .cntlr_rd_data(cntlr_rd_data),
        .cntlr_rd_valid(cntlr_rd_valid),

        .cntlr_wr(cntlr_wr),
        .cntlr_waddr(cntlr_waddr),
        .cntlr_wr_data(cntlr_wr_data),

        .mem_rd(mem_rd),
        .mem_rd_addr(mem_rd_addr),
        .mem_rd_data(mem_rd_data),

        .mem_wr(mem_wr),
        .mem_wr_addr(mem_wr_addr),
        .mem_wr_data(mem_wr_data)
    );

    
    
    dpram_2048x32 u_iccm(
        .clka(clk),
        .ena(mem_wr),
        .wea(mem_wr),
        .addra(mem_wr_addr),
        .dia(mem_wr_data),
        .clkb(clk),
        .enb(mem_rd),
        .addrb(mem_rd_addr),
        .dob(mem_rd_data)
   );


endmodule
