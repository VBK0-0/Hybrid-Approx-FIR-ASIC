`timescale 1ns / 1ps

module FIR_Filter_4Tap(
input clk,
input rst,
input [7:0] x_in,
output [15:0] y_out
);

/* delay registers */
reg [7:0] x1,x2,x3;

/* Positive Stress-Test Coefficients */
    parameter h0 = 8'd127;  // Binary: 01111111
    parameter h1 = 8'd119;  // Binary: 01110111
    parameter h2 = 8'd63;   // Binary: 00111111
    parameter h3 = 8'd85;   // Binary: 01010101

/* multiplier outputs */
wire [15:0] m0,m1,m2,m3;

/* multiplier instances */
Exact_Multiplier_8X8_bits M0(.A(x_in), .B(h0), .Z_T(m0));
Exact_Multiplier_8X8_bits M1(.A(x1), .B(h1), .Z_T(m1));
Exact_Multiplier_8X8_bits M2(.A(x2), .B(h2), .Z_T(m2));
Exact_Multiplier_8X8_bits M3(.A(x3), .B(h3), .Z_T(m3));
/* delay line */
always @(posedge clk or posedge rst)
begin
    if(rst)
    begin
        x1 <= 0;
        x2 <= 0;
        x3 <= 0;
    end
    else
    begin
        x3 <= x2;
        x2 <= x1;
        x1 <= x_in;
    end
end

/* output sum */
assign y_out = m0 + m1 + m2 + m3;

endmodule

module Exact_Multiplier_8X8_bits(
input [7:0] A,
input [7:0] B,
output [15:0] Z_T
);

assign Z_T = A * B;

endmodule

module compressor42_exact(
    input x1,x2,x3,x4,
    input cin,
    output sum,
    output carry,
    output cout
);

wire s1,c1,s2,c2;

full_adder FA1(x1,x2,x3,s1,c1);
full_adder FA2(s1,x4,cin,sum,c2);

assign carry = c1;
assign cout = c2;

endmodule

module half_adder(
    input a,
    input b,
    output sum,
    output carry
);

assign sum = a ^ b;
assign carry = a & b;

endmodule

module full_adder(
    input a,
    input b,
    input cin,
    output sum,
    output cout
);

assign sum = a ^ b ^ cin;
assign cout = (a & b) | (b & cin) | (a & cin);

endmodule


