`timescale 1ns/1ps

module uProc_tb #(
    parameter ADDR_WIDTH = 11,   // 2048 words
    parameter DATA_WIDTH = 32,
    parameter PC_WIDTH = 11
);
    reg clk;
    reg rst_n;

    reg bist_en;
    wire bist_pass;
    wire bist_fail;

    // memory management unit ki ?
    // how does instruction cache work ?
    // we are working on the user unpriviledged mode, going to use fpga native mult/div
    // going to use  gpio , uart, timer, bus matrix(WishBone not written yet) 

/*
First test of the pupeline.

In uProc sv

* Generate clock and rst_n (same as fetch TB) and connect to uProc
* Tie off BIST pins to zero
* Write a program with couple of instuctions. Load number 2 to RS1,  and one ADDI instruction for adding RS1 + 3
* Load this program in the instruction memory using memread()
* Assert rst_n for 10 clocks. Then deassert
* Keep clock running for 50 cycles, then end simulation
* Load signals in GTKWave and inspect stage by stage if these 2 back to back instructions are reaching exec stage.

You will find that when ADDI reaches exec stage, RS1 was not still loaded with 2. This is classic hazard.

Can you get the simulation at this stage in next 2 days and upload to GitHub? I will figure out what to do for this hazard.
*/



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
        $dumpfile("compile/waveforms.vcd"); 
        $dumpvars (0,uProc_tb);

        // Initialize signals
        clk = 0;
        rst_n = 0;
        bist_en = 0;
        

        // Release reset
        #100;
        rst_n = 1;
        
        #500;
    
        $finish;
    end



endmodule