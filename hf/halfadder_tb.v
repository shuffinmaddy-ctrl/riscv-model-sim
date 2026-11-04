' timescale 1ns/1ps
module halfadd_tb;
reg A;
reg B;
wire sum;
wire carry;

halfadder uut(
.A(A),
.B(B),
.sum(sum),
.carry(carry),
.zero(zero)
);

    initial begin
        $monitor("Time = %0dt | A = %b, B = %b | Sum = %b, Carry = %b", $time, a, b, sum, carry);
        
        a = 0; b = 0; #10; // Case 1
        a = 0; b = 1; #10; // Case 2
        a = 1; b = 0; #10; // Case 3
        a = 1; b = 1; #10; // Case 4
        
        $finish; 
    end

endmodule

