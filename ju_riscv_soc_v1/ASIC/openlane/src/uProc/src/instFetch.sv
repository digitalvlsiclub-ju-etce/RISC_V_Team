`timescale 1ns/1ps

module instFetch #(
    parameter ADDR_WIDTH = 11,   // 2048 words
    parameter DATA_WIDTH = 32
)(
    input clk,
    input rst_n,

    input id_stall,// from ID stage
    
    input bist_en,
    output bist_pass,
    output bist_fail,
    
    input [1:0] pc_sel,
    input [ADDR_WIDTH-1:0] alu_addr,
    input [ADDR_WIDTH-1:0] imm_addr,

    input                   pc_en,
    output                  imem_rd,
    output [ADDR_WIDTH-1:0] imem_rd_addr // pc output
);

    //instantiate pc_module

    pc #(
        .PC_WIDTH(ADDR_WIDTH)
    )u_pc(
        .clk(clk), 
        .rst_n(rst_n),
        .pc_en(pc_en),
        .pc_sel(pc_sel),
        .imm_addr(imm_addr),
        .alu_addr(alu_addr),
        .pc(imem_rd_addr)
    );

assign imem_rd = pc_en;
 
endmodule