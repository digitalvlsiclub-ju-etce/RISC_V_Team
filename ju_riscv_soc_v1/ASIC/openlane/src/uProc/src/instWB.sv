`timescale 1ns/1ps
`include "rv_isa.vh"
`include "uProc.vh"

module instWB #(
    parameter ADDR_WIDTH = 11,   // 2048 words
    parameter DATA_WIDTH = 32,
    parameter PC_WIDTH = 11
)(
    input clk,
    input rst_n,

    //input from mem stage
    input                   mem_valid_in, //input from mem stage is valid
    input  [4:0]            mem_rd_in, 
    input  [DATA_WIDTH-1:0] mem_rd_data_in,  

    //gpr write port
    output [4:0]gpr_rd_waddr,//unregistered
    output [DATA_WIDTH-1:0] gpr_rd_wdata,//unregistered
    output  gpr_rd_we//unregistered
    
);

assign gpr_rd_we = mem_valid_in & ( mem_rd_in != 5'b0);
assign gpr_rd_waddr = mem_rd_in;
assign gpr_rd_wdata = mem_rd_data_in;

endmodule