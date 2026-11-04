

`timescale 1ns/1ps

// 1-bit Half Adder
module half_adder (
    input A, B,
    output SUM, CARRY
);

assign SUM = A ^ B;
assign CARRY = A & B;

endmodule


// 4-bit Half Adder
module half_adder_4bit (
    input [3:0] A, B,
    output [3:0] SUM, CARRY
);

half_adder HA0 (
    .A(A[0]), .B(B[0]),
    .SUM(SUM[0]), .CARRY(CARRY[0])
);

half_adder HA1 (
    .A(A[1]), .B(B[1]),
    .SUM(SUM[1]), .CARRY(CARRY[1])
);

half_adder HA2 (
    .A(A[2]), .B(B[2]),
    .SUM(SUM[2]), .CARRY(CARRY[2])
);

half_adder HA3 (
    .A(A[3]), .B(B[3]),
    .SUM(SUM[3]), .CARRY(CARRY[3])
);

endmodule


// 8-bit D Flip-Flop Register
module dff_8bit (
    input [7:0] D,
    input clk, rst,
    output reg [7:0] Q
);

always @(posedge clk or posedge rst)
begin
    if (rst)
        Q <= 8'b00000000;
    else
        Q <= D;
end

endmodule


// Top Module
module ha_dff (
    input [3:0] A, B,
    input clk, rst,
    output [7:0] result
);

wire [3:0] sum;
wire [3:0] carry;

wire [7:0] ha_output;

// Half Adder
half_adder_4bit HA (
    .A(A),
    .B(B),
    .SUM(sum),
    .CARRY(carry)
);

// Combine SUM and CARRY
assign ha_output = {carry, sum};

// Store output using D Flip-Flops
dff_8bit REG (
    .D(ha_output),
    .clk(clk),
    .rst(rst),
    .Q(result)
);

endmodule
