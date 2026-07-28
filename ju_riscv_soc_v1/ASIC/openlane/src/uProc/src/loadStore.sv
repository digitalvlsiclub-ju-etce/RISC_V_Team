`timescale 1ns/1ps
`include "rv_isa.vh"
`include "uProc.vh"

module loadStore #(
    parameter ADDR_WIDTH = 11,   // 2048 words
    parameter DATA_WIDTH = 32,
    parameter PC_WIDTH = 11
)(
    input clk,
    input rst_n,
    input mem_stall,
    

    //input from execution stage


    input  [PC_WIDTH-1:0]   exec_target_addr_in,    // unregistered 
    input                   exec_load_target_addr_in, // unregistered 
    input  [4:0]            exec_rd_in, 
    input  [DATA_WIDTH-1:0] exec_alu_result_in,
    input  [DATA_WIDTH-1:0] exec_store_data_in, 
    input                   exec_op_ld_in ,
    input                   exec_op_ldu_in , // unsigned load
    input  [1:0]            exec_op_ld_sz_in, // load size
    input                   exec_op_st_in ,
    input  [1:0]            exec_op_st_sz_in   
);



endmodule