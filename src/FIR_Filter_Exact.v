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
Exact_Multiplier_8X8bits M0(.A(x_in), .B(h0), .Z_T(m0));
Exact_Multiplier_8X8bits M1(.A(x1), .B(h1), .Z_T(m1));
Exact_Multiplier_8X8bits M2(.A(x2), .B(h2), .Z_T(m2));
Exact_Multiplier_8X8bits M3(.A(x3), .B(h3), .Z_T(m3));
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

module Exact_Multiplier_8X8bits(
    input [7:0] A,
    input [7:0] B,
    output [15:0] Z_T
);
    // 1. Generate all 64 Partial Products (Partial Product Matrix)
    wire [7:0] pp [7:0];
    genvar i, j;
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_row
            for (j = 0; j < 8; j = j + 1) begin : gen_col
                assign pp[i][j] = A[j] & B[i];
            end
        end
    endgenerate

    // 2. Alignment of Partial Products by Weight (Shifting)
    wire [15:0] row0 = {8'b0, pp[0]};
    wire [15:0] row1 = {7'b0, pp[1], 1'b0};
    wire [15:0] row2 = {6'b0, pp[2], 2'b0};
    wire [15:0] row3 = {5'b0, pp[3], 3'b0};
    wire [15:0] row4 = {4'b0, pp[4], 4'b0};
    wire [15:0] row5 = {3'b0, pp[5], 5'b0};
    wire [15:0] row6 = {2'b0, pp[6], 6'b0};
    wire [15:0] row7 = {1'b0, pp[7], 7'b0};

    // 3. Compression Tree Stage 1 (Compressing 8 rows to 4 rows)
    // We group rows 0-3 and rows 4-7
    wire [15:0] sum_a, carry_a, sum_b, carry_b;
    wire [15:0] cout_a, cout_b; // Inter-bit carries

    generate
        for (i = 0; i < 16; i = i + 1) begin : stage1
            // Connecting Cout of bit i to Cin of bit i+1 is critical
            wire cin_a = (i == 0) ? 1'b0 : cout_a[i-1];
            wire cin_b = (i == 0) ? 1'b0 : cout_b[i-1];
            
            Compressor_4_2 CompA (
                .x0(row0[i]), .x1(row1[i]), .x2(row2[i]), .x3(row3[i]),
                .Cin(cin_a), .Cout(cout_a[i]), .Carry(carry_a[i]), .Sum(sum_a[i])
            );
            Compressor_4_2 CompB (
                .x0(row4[i]), .x1(row5[i]), .x2(row6[i]), .x3(row7[i]),
                .Cin(cin_b), .Cout(cout_b[i]), .Carry(carry_b[i]), .Sum(sum_b[i])
            );
        end
    endgenerate

    // 4. Final Accumulation
    // Note: carries are shifted left by 1 bit by nature of the compressor
    assign Z_T = sum_a + {carry_a[14:0], 1'b0} + sum_b + {carry_b[14:0], 1'b0};

endmodule

module Compressor_4_2(x0, x1, x2, x3, Cin, Cout, Carry, Sum);
    input x0, x1, x2, x3, Cin;
    output Carry, Sum, Cout;
    wire A, B, C, D, s0, h1, h2;

    // First two stages of sorting network 
    Half_Sort HS1(x0, x1, x2, x3, A, B, C, D);

    assign s0 = (A & (~B)) | D; 
    assign Cout = B;
    
    // Summation of s0, Cin, and C using modified full adder logic 
    assign h1 = C | Cin;
    assign h2 = C & Cin;
    assign Carry = (s0 & h1) | h2;
    assign Sum = s0 ? (~h1 | h2) : (h1 & (~h2));
endmodule

module Half_Sort(I1, I2, I3, I4, O1, O2, O3, O4);
    input I1, I2, I3, I4;
    output O1, O2, O3, O4;
    wire [3:0] w;

    // Reorders data so larger inputs are "up" 
    Two_input_binary_sorter BS1(I1, I2, w[0], w[1]);
    Two_input_binary_sorter BS2(I3, I4, w[2], w[3]);
    Two_input_binary_sorter BS3(w[0], w[2], O1, O3);
    Two_input_binary_sorter BS4(w[1], w[3], O2, O4);
endmodule

module Two_input_binary_sorter(In1, In2, Out1, Out2);
    input In1, In2;
    output Out1, Out2;
    assign Out1 = In1 | In2; 
    assign Out2 = In1 & In2; 
endmodule

