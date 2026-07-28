`timescale 1ns/1ps

    // Simple Dual-Port Block RAM with Two Clocks
    // File: simple_dual_two_clocks.v
    module dpram_2048x32 (clka,clkb,ena,enb,wea,addra,addrb,dia,dob);
        input clka,clkb,ena,enb,wea;
        input [10:0] addra,addrb;
        input [31:0] dia;
        output [31:0] dob;
        reg [31:0] ram [0:2047];
        reg [31:0] dob;

    initial begin
        $readmemh("src/program.hex", ram ,0,17);
    end
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
