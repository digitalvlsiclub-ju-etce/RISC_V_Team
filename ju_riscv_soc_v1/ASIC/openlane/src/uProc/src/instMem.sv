`timescale 1ns/1ps
`include "rv_isa.vh"
`include "uProc.vh"

module instMem #(
    parameter ADDR_WIDTH = 11,   // 2048 words
    parameter DATA_WIDTH = 32,
    parameter PC_WIDTH = 11
)(
    input clk,
    input rst_n,
    output  mem_stall,
    

    //input from execution stage
    input                   exec_valid_in,//inputs from execution stage are valid
    input  [4:0]            exec_rd_in, 
    input  [DATA_WIDTH-1:0] exec_alu_result_in,
    input  [DATA_WIDTH-1:0] exec_store_data_in, 
    input                   exec_op_ld_in ,
    input                   exec_op_ldu_in , // unsigned load
    input  [1:0]            exec_op_ld_sz_in, // load size
    input                   exec_op_st_in ,
    input  [1:0]            exec_op_st_sz_in,

    //output to WB stage 
    output  reg                  mem_valid_out, //input from mem stage is valid
    output  reg[4:0]            mem_rd_out, 
    output  reg [DATA_WIDTH-1:0] mem_rd_data_out   
);

assign mem_stall = 1'b0 ; // to do

//MEM stage pipeline registers

always @(posedge clk) begin
  if(rst_n)begin
    mem_valid_out   <= 'b0;
    mem_rd_out      <= 'b0;
    mem_rd_data_out <= 'b0;
  end
  else if (exec_valid_in & !mem_stall) begin
    mem_valid_out   <= 1'b1;
    mem_rd_out      <= exec_rd_in;
    mem_rd_data_out <= (exec_op_ld_in || exec_op_ldu_in) ? 'd0 : exec_alu_result_in; 
 end
end

endmodule