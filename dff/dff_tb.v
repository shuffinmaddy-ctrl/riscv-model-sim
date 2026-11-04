`timescale 1ns/1ps
module d_flipflop_tb;

reg D;
reg clk;
reg rst;
wire Q;

// DUT instantiation
d_flipflop uut (
    .D(D),
    .clk(clk),
    .rst(rst),
    .Q(Q)
);

// Clock generation
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

// Input stimulus
initial begin
    $monitor("Time=%0t clk=%b rst=%b D=%b Q=%b",
             $time, clk, rst, D, Q);

    rst = 1;
    D = 0;
    #10;

    rst = 0;
    D = 1;
    #10;

    D = 0;
    #10;

    D = 1;
    #10;

    D = 0;
    #10;

    D = 1;
    #10;
end

endmodule
