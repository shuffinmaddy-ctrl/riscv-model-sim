`timescale 1ns/1ps

module ha_dff_tb;

reg [3:0] A, B;
reg clk, rst;

wire [7:0] result;

// DUT instantiation
ha_dff uut (
    .A(A),
    .B(B),
    .clk(clk),
    .rst(rst),
    .result(result)
);

// Clock generation
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

// Test stimulus
initial begin

$monitor("Time=%0t | A=%b | B=%b | SUM=%b | CARRY=%b | RESULT=%b",
             $time, A, B, result[3:0],
             result[7:4], result);

// Reset
    rst = 1;
    A = 4'b0000;
    B = 4'b0000;

#12;
    rst = 0;

// Test 1
    A = 4'b0011;
    B = 4'b0001;

    #10;

// Test 2
    A = 4'b0101;
    B = 4'b0011;

    #10;

// Test 3
    A = 4'b1111;
    B = 4'b1111;

    #10;

// Test 4
    A = 4'b1010;
    B = 4'b0101;

    #10;

// Test 5
    A = 4'b0000;
    B = 4'b0000;

    #10;

end

endmodule