`timescale 1ns/1ps

module pc #(
    parameter PC_WIDTH = 11
)(
    input wire clk,
    input wire rst_n,
    input wire pc_en,
    input wire [1:0] pc_sel,
    input wire [PC_WIDTH-1:0] imm_addr,
    input wire [PC_WIDTH-1:0] alu_addr,
    output reg [PC_WIDTH-1:0] pc
);
    wire [PC_WIDTH-1:0] pc_plus4;
    reg [PC_WIDTH-1:0] pc_next;
    wire [PC_WIDTH-1:0] hold;
    assign hold = pc;

    assign pc_plus4 = pc + 4;

    always @(*) begin
    case (pc_sel)
        2'b00: pc_next = pc_plus4;
        2'b01: pc_next = alu_addr;
        2'b10: pc_next = imm_addr;
        2'b11: pc_next = hold;
        default: pc_next = pc_plus4;
    endcase
    end
    always @(posedge clk or negedge rst_n) 
    begin
        if (!rst_n)
        pc <= 0;
        else if (pc_en)
        pc <= pc_next;
    end
endmodule