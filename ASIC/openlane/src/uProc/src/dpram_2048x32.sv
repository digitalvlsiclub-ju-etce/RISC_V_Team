    // Simple Dual-Port Block RAM with Two Clocks
    // File: simple_dual_two_clocks.v
    module dpram_2048x32 (clka,clkb,ena,enb,wea,addra,addrb,dia,dob);
        input clka,clkb,ena,enb,wea;
        input [10:0] addra,addrb;
        input [31:0] dia;
        output [31:0] dob;
        reg [31:0] ram [2047:0];
        reg [31:0] dob;
        always @(posedge clka)begin
            if (ena)begin
                if (wea) ram[addra] <= dia;
            end
        end
        always @(posedge clkb)begin
            if (enb)begin
                dob <= ram[addrb];
            end
        end
    endmodule
