`timescale 1ns/1ps

module ccm_controller #(
    parameter ADDR_WIDTH = 11,   // 2048 words
    parameter DATA_WIDTH = 32
)(
    input clk,
    input rst_n,

    input bist_en,
    output bist_pass,
    output bist_fail,

    input cntlr_rd,
    input [ADDR_WIDTH-1:0] cntlr_raddr,
    output [DATA_WIDTH-1:0] cntlr_rd_data,
    output cntlr_rd_valid,

    input cntlr_wr,
    input [ADDR_WIDTH-1:0]cntlr_waddr,
    input [DATA_WIDTH-1:0]cntlr_wr_data,

    //2 port sram 
    
    output reg mem_rd,
    output reg [ADDR_WIDTH-1:0]mem_rd_addr,
    input [DATA_WIDTH-1:0]mem_rd_data,

    output reg mem_wr,
    output reg [ADDR_WIDTH-1:0]mem_wr_addr,
    output reg [DATA_WIDTH-1:0]mem_wr_data
);

    wire mux_cntlr_rd = bist_en ? bist_cntlr_rd : cntlr_rd;
    wire [ADDR_WIDTH-1:0]mux_cntlr_raddr = bist_en ? bist_cntlr_raddr : cntlr_raddr;

    wire mux_cntlr_wr = bist_en ? bist_cntlr_wr : cntlr_wr;
    wire [ADDR_WIDTH-1:0]mux_cntlr_waddr = bist_en ? bist_cntlr_waddr : cntlr_waddr;
    wire [DATA_WIDTH-1:0]mux_cntlr_wr_data = bist_en ? bist_cntlr_wr_data : cntlr_wr_data;

    reg mem_rd_valid;

     /* -----------------------------
       Write path
       ----------------------------- */
    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin
            mem_wr <= 0;
            mem_wr_addr <= 0;
            mem_wr_data <= 0;
        end
        else begin
            mem_wr <= mux_cntlr_wr;
            mem_wr_addr <= mux_cntlr_waddr;
            mem_wr_data <= mux_cntlr_wr_data;
        end 
        
    end
    /* -----------------------------
       Read Path
       - Read data from memory comes back with 1 clock delay
       ----------------------------- */
    
    /*
    assign mem_rd = cntlr_rd;
    assign mem_rd_addr = cntlr_raddr;
    assign cntlr_rd_data = mem_rd_data;
    */
    
    always @(*)begin
            mem_rd = mux_cntlr_rd;
            mem_rd_addr = mux_cntlr_raddr;
            cntlr_rd_data = bist_en ? 0 : mem_rd_data;
    end
    
    always @(posedge clk) begin
        mem_rd_valid <= mem_rd; 
    end

    assign cntlr_rd_valid = mem_rd_valid & ~bist_en;

    // iccm bist module
    
    wire   bist_cntlr_rd;
    wire  [ADDR_WIDTH-1:0]bist_cntlr_raddr;
    wire [DATA_WIDTH-1:0]bist_cntlr_rd_data;
    wire bist_cntlr_rd_valid;
    wire bist_cntlr_wr;
    wire [ADDR_WIDTH-1:0]bist_cntlr_waddr;
    wire [DATA_WIDTH-1:0]bist_cntlr_wr_data;
    
    assign bist_cntlr_rd_data = bist_en ? mem_rd_data : 0;
    assign bist_cntlr_rd_valid = mem_rd_valid & bist_en;

    ccm_bist #(
    .ADDR_WIDTH(11),
    .DATA_WIDTH(32),
    .NUM_ROWS(2048)
)   u_ccm_bist(
    .clk(clk),
    .rst_n(rst_n),
    .bist_en(bist_en),
    .bist_pass(bist_pass),
    .bist_fail(bist_fail),
    
    .cntlr_rd(bist_cntlr_rd),
    .cntlr_raddr(bist_cntlr_raddr),
    .cntlr_rd_data(bist_cntlr_rd_data),
    .cntlr_rd_valid(bist_cntlr_rd_valid),

    .cntlr_wr(bist_cntlr_wr),
    .cntlr_waddr(bist_cntlr_waddr),
    .cntlr_wr_data(bist_cntlr_wr_data)
    );

    

endmodule
