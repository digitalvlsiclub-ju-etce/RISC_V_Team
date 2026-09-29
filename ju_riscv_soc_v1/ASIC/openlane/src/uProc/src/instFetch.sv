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
    output [ADDR_WIDTH-1:0] pc, // pc output
    output                  imem_rd,
    output [ADDR_WIDTH-1:0] imem_rd_addr // pc output
);

wire [ADDR_WIDTH-1:0] pc_int;
reg [ADDR_WIDTH-1:0] prev_pc;

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
        .pc(pc_int) //internal
    );

//delayed version of PC
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        prev_pc <= 'd0;
    end
    else begin
        prev_pc <= pc;
    end
end

assign pc = id_stall ? prev_pc : pc_int; //rollback PC to previous value @stall

assign imem_rd_addr = {2'b00,pc[ADDR_WIDTH-1:2]};

assign imem_rd = pc_en;
 
endmodule