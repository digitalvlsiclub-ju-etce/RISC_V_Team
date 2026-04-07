`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/12/2026 07:54:03 PM
// Design Name: 
// Module Name: iccm_bist
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ccm_bist #(
    parameter ADDR_WIDTH = 11,
    parameter DATA_WIDTH = 32,
    parameter NUM_ROWS = 2048
)(
    input clk,
    input rst_n,
    input bist_en,
    output bist_pass,
    output bist_fail,
    
    output cntlr_rd,
    output [ADDR_WIDTH-1:0] cntlr_raddr,
    input [DATA_WIDTH-1:0] cntlr_rd_data,
    input cntlr_rd_valid,

    output cntlr_wr,
    output [ADDR_WIDTH-1:0]cntlr_waddr,
    output [DATA_WIDTH-1:0]cntlr_wr_data
    );
    
    reg bist_en_d1;
    wire bist_start;
    reg [ADDR_WIDTH-1:0] bist_addr;
    reg bist_wr_in_progress;
    reg bist_wr_done;
    reg bist_rd_in_progress;
    reg bist_rd_done;
    wire bist_match;
    reg [ADDR_WIDTH:0] bist_match_cntr;
    
    //always @(posedge clk or negedge rst_n)begin
      //  bist_en_d1 <= bist_en;
    //end
    
    assign bist_start = bist_en & ~bist_en_d1;
    
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n) begin
            bist_addr <= 0;
            bist_wr_in_progress <= 0;
            bist_wr_done <= 0;
        end
        else if(!bist_en) begin
            bist_addr <= 0;
            bist_wr_in_progress <= 0;
            bist_wr_done <= 0;
        end
        else if(bist_start) begin
            bist_addr <= 0;
            bist_wr_in_progress <= 1;
        end
        else begin
            if(bist_addr == NUM_ROWS-1) begin
                bist_wr_done <= 1;
                bist_wr_in_progress <= 0;
            end
            else begin
                bist_addr <= bist_addr + 1;
            end
        end
    end
    
    assign cntlr_wr = bist_wr_in_progress;
    assign cntlr_waddr = bist_addr;
    assign cntlr_wr_data = cntlr_waddr;
    
    
endmodule
