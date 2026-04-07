`timescale 1ns/1ps

module instFetch #(
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

    output imem_rd,
    output [ADDR_WIDTH-1:0] imem_rd_addr,
    input [DATA_WIDTH-1:0] imem_rd_data,
    input imem_rd_data_valid
);

    //instantiate pc_module

    pc u_pc #(
        .PC_WIDTH(ADDR_WIDTH)
    )(
        .clk(clk), 
        .rst_n(rst_n),
        .pc_en(1'b1),
        .pc_sel(pc_sel),
        .imm_addr(imm_addr),
        .alu_addr(alu_addr),
        .pc(imem_rd_addr)
    );

endmodule