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






endmodule