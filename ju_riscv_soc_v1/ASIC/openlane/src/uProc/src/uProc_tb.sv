`timescale 1ns/1ps

module uProc_tb;

    parameter ADDR_WIDTH = 11;   // 2048 words
    parameter DATA_WIDTH = 32;
    parameter PC_WIDTH = 11;

    reg clk;
    reg rst_n;
    
    reg bist_en;
    wire bist_pass;
    wire bist_fail;

    reg[1:0] pc_sel;
    reg[PC_WIDTH-1:0] imm_addr;
    reg [PC_WIDTH-1:0] alu_addr;

    reg read;

uProc #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .PC_WIDTH(PC_WIDTH)
) u_uProc(
    .clk(clk),
    .rst_n(rst_n),

    .bist_en(bist_en),
    .bist_pass(bist_pass),
    .bist_fail(bist_fail)

);


always #5 clk = ~clk;

    initial begin
        $dumpfile("uProc_sim.vcd"); 
        $dumpvars (0,uProc_tb);

        // Initialize signals
        clk = 0;
        rst_n = 1;
        bist_en = 0;
        

        // Apply reset
        #17;
        rst_n = 0;

        // Release reset
        #17;
        rst_n = 1;
        
        #2000;
    
        $finish;
    end

    
endmodule