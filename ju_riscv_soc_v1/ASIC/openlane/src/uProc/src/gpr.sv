`timescale 1ns/1ps

module gpr #(
   
    parameter DATA_WIDTH = 32
    
)(
    input clk,
    input reset,

    //write port
    input write,
    input [4:0]dr,
    input [DATA_WIDTH-1:0]wrData,

    //rd port 1
    input [4:0]sr1,
    output [DATA_WIDTH-1:0]rdData1,

    //rd port 2
    input [4:0]sr2,
    output [DATA_WIDTH-1:0]rdData2
);
    integer k;
    reg [DATA_WIDTH-1:0] gprs[1:31];

    assign rdData1 = (sr1==0)? 0 : gprs[sr1];
    assign rdData2 = (sr2==0)? 0 : gprs[sr2];

    always @(posedge clk) begin
        if (reset) begin
            for ( k=1 ; k < 32 ; k=k+1 ) begin
                gprs[k]<=0;
            end
        end
        else begin
            if (write) begin
                if(dr!= 0)
                    gprs[dr]<= wrData;
            end
        end
    end

    wire [31:0] X0  = 32'b0;
    wire [31:0] X1  = gprs[1];
    wire [31:0] X2  = gprs[2];
    wire [31:0] X3  = gprs[3];
    wire [31:0] X4  = gprs[4];
    wire [31:0] X5  = gprs[5];
    wire [31:0] X6  = gprs[6];
    wire [31:0] X7  = gprs[7];
    wire [31:0] X8  = gprs[8];
    wire [31:0] X9  = gprs[9];
    wire [31:0] X10 = gprs[10];
    wire [31:0] X11 = gprs[11];
    wire [31:0] X12 = gprs[12];
    wire [31:0] X13 = gprs[13];
    wire [31:0] X14 = gprs[14];
    wire [31:0] X15 = gprs[15];
    wire [31:0] X16 = gprs[16];
    wire [31:0] X17 = gprs[17];
    wire [31:0] X18 = gprs[18];
    wire [31:0] X19 = gprs[19];
    wire [31:0] X20 = gprs[20];
    wire [31:0] X21 = gprs[21];
    wire [31:0] X22 = gprs[22];
    wire [31:0] X23 = gprs[23];
    wire [31:0] X24 = gprs[24];
    wire [31:0] X25 = gprs[25];
    wire [31:0] X26 = gprs[26];
    wire [31:0] X27 = gprs[27];
    wire [31:0] X28 = gprs[28];
    wire [31:0] X29 = gprs[29];
    wire [31:0] X30 = gprs[30];
    wire [31:0] X31 = gprs[31];




endmodule