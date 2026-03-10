`timescale 1ns / 1ps

module FIR_Filter_4Tap_1error(
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
Approximate_Multiplier_8X8_bits M0(.A(x_in), .B(h0), .Z_T(m0));
Approximate_Multiplier_8X8_bits M1(.A(x1), .B(h1), .Z_T(m1));
Approximate_Multiplier_8X8_bits M2(.A(x2), .B(h2), .Z_T(m2));
Approximate_Multiplier_8X8_bits M3(.A(x3), .B(h3), .Z_T(m3));
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
/* output sum with bias removed */
assign y_out = (m0 + m1 + m2 + m3) - 16'd8192;
endmodule


module Approximate_Multiplier_8X8_bits(A, B, Z_T);
input [7:0]A,B;
wire [14:0]Z_S;
wire [14:0]Z_C;
output reg [15:0]Z_T;
wire [11:0]S;
wire [11:0]C;
wire [11:0]X;
wire [11:0]Y;
wire [11:0]U;


half_adder HA1(A[0]&B[4], A[1]&B[3], S[0], C[0]);

Approximate_4_2_Compressor_with_1_error ACOE1(A[0]&B[5],A[1]&B[4],A[2]&B[3],A[3]&B[2],S[1],C[1]);
Approximate_4_2_Compressor_with_1_error ACOE2(A[0]&B[6],A[1]&B[5],A[2]&B[4],A[3]&B[3],S[2],C[2]);

half_adder HA2(A[4]& B[2], A[5]&B[1], S[3], C[3]);

Approximate_4_2_Compressor_with_1_error ACOE3(A[0]&B[7],A[1]&B[6],A[2]&B[5],A[3]&B[4],S[4],C[4]);
Approximate_4_2_Compressor_with_1_error ACOE4(A[4]&B[3],A[5]&B[2],A[6]&B[1],A[7]&B[0],S[5],C[5]);

//Compressor_4_2(x0,x1,x2,x3,Cin,Cout,Carry,Sum);


//Compressor_4_2 CFT1(A[1]&B[7],A[2]&B[6],A[3]&B[5],A[4]&B[4],1'b0,U[0],C[6],S[6]);
Compressor_4_2 CFT1(A[1]&B[7],A[2]&B[6],A[3]&B[5],A[4]&B[4],1'b0,C[6],U[0],S[6]);

//module Full_Adder(A,B,C_in,Sum,Carry);
Full_Adder FA1(A[5]&B[3],A[6]&B[2],A[7]&B[1],S[7],C[7]);

//Compressor_4_2 CFT2(A[2]&B[7],A[3]&B[6],A[4]&B[5],A[5]&B[4],1'b0,U[1],C[8],S[8]);
Compressor_4_2 CFT2(A[2]&B[7],A[3]&B[6],A[4]&B[5],A[5]&B[4],1'b0,C[8],U[1],S[8]);


half_adder HA3(A[6]& B[3], A[7]&B[2], S[9], C[9]);

//Compressor_4_2 CFT3(A[3]&B[7],A[4]&B[6],A[5]&B[5],A[6]&B[4],1'b0,U[2],C[10],S[10]);
Compressor_4_2 CFT3(~(A[3]&B[7]),A[4]&B[6],A[5]&B[5],A[6]&B[4],1'b0,C[10],U[2],S[10]);

half_adder HA4(~(A[4]& B[7]), A[5]&B[6], S[11], C[11]);

///////////////////////////////////////////////////////////////////////////////////////////////////
half_adder HA5(A[0]& B[2], A[1]&B[1], X[0], Y[0]);

Approximate_4_2_Compressor_with_1_error ACOE5(A[0]&B[3],A[1]&B[2],A[2]&B[1],A[3]&B[0],X[1], Y[1]);
Approximate_4_2_Compressor_with_1_error ACOE6(S[0],A[2]&B[2],A[3]&B[1],A[4]&B[0],X[2], Y[2]);
Approximate_4_2_Compressor_with_1_error ACOE7(C[0],S[1],A[4]&B[1],A[5]&B[0],X[3], Y[3]);
Approximate_4_2_Compressor_with_1_error ACOE8(C[1],S[2],S[3],A[6]&B[0],X[4], Y[4]);
Approximate_4_2_Compressor_with_1_error ACOE9(C[2],C[3],S[4],S[5],X[5], Y[5]);

//Compressor_4_2(x0,x1,x2,x3,Cin,Cout,Carry,Sum);

//Compressor_4_2 CFT4(C[4], C[5],S[6],S[7],1'b0,U[3],Y[6],X[6]);
//Compressor_4_2 CFT5(C[6], C[7],S[8],S[9],1'b0,U[4],Y[7],X[7]);
//Compressor_4_2 CFT6(C[8], C[9],S[10],A[7]&B[3],1'b0,U[5],Y[8],X[8]);
//Compressor_4_2 CFT7(C[10], S[11], A[6]&B[5],A[7]&B[4],1'b0,U[6],Y[9],X[9]);
//Compressor_4_2 CFT8(C[11], A[5]&B[7], A[6]&B[6],A[7]&B[5],1'b0,U[7],Y[10],X[10]);

Compressor_4_2 CFT4(C[4], C[5],S[6],S[7],1'b0,Y[6],U[3],X[6]);
Compressor_4_2 CFT5(C[6], C[7],S[8],S[9],1'b0,Y[7],U[4],X[7]);
Compressor_4_2 CFT6(C[8], C[9],S[10],~(A[7]&B[3]),1'b0,Y[8],U[5],X[8]);
Compressor_4_2 CFT7(C[10], S[11], A[6]&B[5],~(A[7]&B[4]),1'b0,Y[9],U[6],X[9]);
Compressor_4_2 CFT8(C[11], ~(A[5]&B[7]), A[6]&B[6],~(A[7]&B[5]),1'b0,Y[10],U[7],X[10]);

half_adder HA6(~(A[6]& B[7]), ~(A[7]&B[6]), X[11], Y[11]);
/////////////////////////////////////////////////////////////////////////////////////////////////////

assign Z_S[0] = A[0]&B[0];
assign Z_S[1] = (A[0]&B[1])^(A[1]&B[0])|(A[0]&B[1])&(A[1]&B[0]);
assign Z_S[2] = X[0]^(A[2]&B[0])|X[0]&(A[2]&B[0]);
assign Z_S[3] = Y[0]^X[1]|Y[0]&X[1];
assign Z_S[4] = Y[1]^X[2]|Y[1]&X[2];
assign Z_S[5] = Y[2]^X[3]|Y[2]&X[3];
assign Z_S[6] = Y[3]^X[4]|Y[3]&X[4];
assign Z_S[7] = Y[4]^X[5]|Y[4]&X[5];
assign Z_S[8] = Y[5]^X[6]|Y[5]&X[6];
assign Z_S[9] = Y[6]^X[7]|Y[6]&X[7];
assign Z_S[10] = Y[7]^X[8]|Y[7]&X[8];
assign Z_S[11] = Y[8]^X[9]|Y[8]&X[9];
assign Z_S[12] = Y[9]^X[10]|Y[9]&X[10];
assign Z_S[13] = Y[10]^X[11]|Y[10]&X[11];
assign Z_S[14] = A[7]&B[7]^Y[11];

//assign Z_C = (A[1]&B[0])|(A[2]&B[0])| X[1] | X[2] | X[3] | X[4] | X[5] | X[6] | X[7] | X[8] | X[9] | X[10] | X[11];

assign Z_C[0] = 1'b0;
assign Z_C[1] = (A[0]&B[1])&(A[1]&B[0]);
assign Z_C[2] = X[0]&(A[2]&B[0]);
assign Z_C[3] = Y[0]&X[1];
assign Z_C[4] = Y[1]&X[2];
assign Z_C[5] = Y[2]&X[3];
assign Z_C[6] = Y[3]&X[4];
assign Z_C[7] = Y[4]&X[5];
assign Z_C[8] = Y[5]&X[6];
assign Z_C[9] = Y[6]&X[7];
assign Z_C[10] = Y[7]&X[8];
assign Z_C[11] = Y[8]&X[9];
assign Z_C[12] = Y[9]&X[10];
assign Z_C[13] = Y[10]&X[11];
assign Z_C[14] = Y[11];

always@(Z_S, Z_C)
begin
{Z_T} = Z_S + Z_C;
end

//module mux_4X1_case ( input [14:0] a, input [14:0] b, input [14:0]c, input [14:0]d,
//                    input [1:0] sel, output reg [14:0] out);
//mux_4X1_case MFO1(Z_S, Z_C, Z_T, 15'b000000000000000,2'b10,Z_out);

endmodule

