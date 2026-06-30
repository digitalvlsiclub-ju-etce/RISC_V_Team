`timescale 1ns/1ps

module uProc#(
    parameter ADDR_WIDTH = 11,   // 2048 words
    parameter DATA_WIDTH = 32,
    parameter PC_WIDTH = 11
)(
    input clk,
    input rst_n,

    input bist_en,
    output bist_pass,
    output bist_fail

    // input wire pc_en,
    

);
    

wire imem_rd;
wire [PC_WIDTH-1:0] pc;
wire [DATA_WIDTH-1:0] imem_rd_data;
wire imem_rd_data_valid;

wire mem_rd;
wire [ADDR_WIDTH-1:0]mem_rd_addr;
wire [DATA_WIDTH-1:0]mem_rd_data;

wire mem_wr;
wire [ADDR_WIDTH-1:0]mem_wr_addr;
wire [DATA_WIDTH-1:0]mem_wr_data;

wire [1:0] pc_sel = 2'b00;
wire [PC_WIDTH-1:0] imm_addr;
wire [PC_WIDTH-1:0] alu_addr;

wire pc_en = 1'b1;



// instantiate instFetch
    
instFetch #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) u_instFetch (
    .clk(clk),
    .rst_n(rst_n),
    
    .bist_en(bist_en),
    .bist_pass(bist_pass),
    .bist_fail(bist_fail),
    
    .pc_sel(pc_sel),
    .alu_addr(alu_addr),
    .imm_addr(imm_addr),

    .pc_en(pc_en),
    .imem_rd(imem_rd),
    .imem_rd_addr(pc)
);

reg [PC_WIDTH-1 : 0] pc_d1;
wire [PC_WIDTH-1 : 0] pc_to_id;

always @(posedge clk) begin
    if(imem_rd)begin
        pc_d1 <= pc;
    end
end
assign pc_to_id = pc_d1;

instDecode #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) u_instDecode (
    .clk(clk),
    .rst_n(rst_n),
    .id_stall(1'b0),
    
    .inst_in(imem_rd_data),
    .inst_valid(imem_rd_data_valid),
    .pc_in(pc_to_id),

    .gpr_we(1'b0),
    .gpr_waddr(5'h00),
    .gpr_wdata(32'h00000000)
);

// instantiate ccm_controller as u_iccm_cntlr

ccm_controller #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
)
u_iccm_cntlr(
    .clk(clk),
    .rst_n(rst_n),
    
    .bist_en(bist_en),
    .bist_pass(bist_pass),
    .bist_fail(bist_fail),

    .cntlr_rd(imem_rd),
    .cntlr_raddr({2'b00,pc[ADDR_WIDTH-1:2]}),
    .cntlr_rd_data(imem_rd_data),
    .cntlr_rd_valid(imem_rd_data_valid),

    .cntlr_wr(1'b0), //ccm wr port tied to zero for now
    .cntlr_waddr({ADDR_WIDTH{1'b0}}),
    .cntlr_wr_data({DATA_WIDTH{1'b0}}),

    //2 port sram 
    
    .mem_rd(mem_rd),
    .mem_rd_addr(mem_rd_addr),
    .mem_rd_data(mem_rd_data),

    .mem_wr(mem_wr),
    .mem_wr_addr(mem_wr_addr),
    .mem_wr_data(mem_wr_data)
);

// instantiate dpram as u_iccm

dpram_2048x32 u_iccm(

        //write port
        .clka(clk),
        .ena(mem_wr),
        .wea(mem_wr),
        .addra(mem_wr_addr),
        .dia(mem_wr_data),

        //read port
        .clkb(clk),
        .enb(mem_rd),
        .addrb(mem_rd_addr),
        .dob(mem_rd_data)
);
// connect instFetch output (from pc) to ccm_controller read port
// -> connected in instantiation itself

endmodule