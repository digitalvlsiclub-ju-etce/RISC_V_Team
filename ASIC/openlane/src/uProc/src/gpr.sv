module gpr (
    input clk,
    input reset,

    //write port
    input write,
    input [4:0]dr,
    input [31:0]wrData,

    //rd port 1
    input [4:0]sr1,
    output [31:0]rdData1,

    //rd port 2
    input [4:0]sr2,
    output [31:0]rdData2
);
    integer k;
    reg [31:0] gprs[1:31];

    assign rdData1 = (sr1==0)? 0 : gprs[sr1];
    assign rdData2 = (sr2==0)? 0 : gprs[sr2];

    always @(posedge clk) begin
        if (reset) begin
            for ( k=1 ; k<32 ; k=k+1 ) begin
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
endmodule