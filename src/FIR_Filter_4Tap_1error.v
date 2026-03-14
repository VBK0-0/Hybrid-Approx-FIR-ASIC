`timescale 1ns / 1ps

module FIR_Filter_4Tap_1error(
    input clk,
    input rst,
    input [7:0] x_in,
    output [17:0] y_out // Increased to 18-bit to prevent overflow
);
    reg [7:0] x1, x2, x3;
    // Taps
    parameter h0 = 8'd127, h1 = 8'd119, h2 = 8'd63, h3 = 8'd85;
    wire [15:0] m0, m1, m2, m3;

    // Approximate Multiplier Instances
    Approximate_Multiplier_8X8_bits M0(.A(x_in), .B(h0), .Z_T(m0));
    Approximate_Multiplier_8X8_bits M1(.A(x1),   .B(h1), .Z_T(m1));
    Approximate_Multiplier_8X8_bits M2(.A(x2),   .B(h2), .Z_T(m2));
    Approximate_Multiplier_8X8_bits M3(.A(x3),   .B(h3), .Z_T(m3));

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            x1 <= 0; x2 <= 0; x3 <= 0;
        end else begin
            x3 <= x2; x2 <= x1; x1 <= x_in;
        end
    end

    // Summation with bit-growth to 18 bits
    assign y_out = m0 + m1 + m2 + m3;
endmodule

module Approximate_Multiplier_8X8_bits(
    input [7:0] A,
    input [7:0] B,
    output [15:0] Z_T
);
    wire [7:0] pp [7:0];
    
    // 1. Generate all 64 Partial Products (The "Matrix")
    genvar i, j;
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_rows
            for (j = 0; j < 8; j = j + 1) begin : gen_cols
                assign pp[i][j] = A[j] & B[i];
            end
        end
    endgenerate

    // 2. Align them by weight (Shift them)
    wire [15:0] row [7:0];
    assign row[0] = {8'b0, pp[0]};
    assign row[1] = {7'b0, pp[1], 1'b0};
    assign row[2] = {6'b0, pp[2], 2'b0};
    assign row[3] = {5'b0, pp[3], 3'b0};
    assign row[4] = {4'b0, pp[4], 4'b0};
    assign row[5] = {3'b0, pp[5], 5'b0};
    assign row[6] = {2'b0, pp[6], 6'b0};
    assign row[7] = {1'b0, pp[7], 7'b0};

    // 3. Compress the 8 rows into 2 rows (S and C)
    wire [15:0] S1, C1, S2, C2;
    
    generate
        for (i = 0; i < 16; i = i + 1) begin : col_compression
            // Columns 0-8 use your Approximate 1-error logic
            if (i < 9) begin : approx
                Approximate_4_2_Compressor_with_1_error ACC1 (
                    row[0][i], row[1][i], row[2][i], row[3][i], S1[i], C1[i]);
                Approximate_4_2_Compressor_with_1_error ACC2 (
                    row[4][i], row[5][i], row[6][i], row[7][i], S2[i], C2[i]);
            end 
            // Columns 9-15 use Exact logic (crucial for MSB accuracy)
            else begin : exact
                Compressor_4_2 EX1 (
                    row[0][i], row[1][i], row[2][i], row[3][i], 1'b0, S1[i], C1[i], );
                Compressor_4_2 EX2 (
                    row[4][i], row[5][i], row[6][i], row[7][i], 1'b0, S2[i], C2[i], );
            end
        end
    endgenerate

    // 4. Final Addition (The "Merge")
    // This uses the FPGA's fast carry chains to finish the job correctly.
    assign Z_T = S1 + {C1[14:0], 1'b0} + S2 + {C2[14:0], 1'b0};

endmodule

module Approximate_4_2_Compressor_with_1_error(x0,x1,x2,x3,Sum,Carry);
input x0,x1,x2,x3;
output Sum,Carry;

Four_way_Sorting_Network FSN1(x0,x1,x2,x3,A,h1,h2,D);
assign Carry = h1; 
assign Sum = (A&(~h1))|h2;

endmodule

module Compressor_4_2(
    input x1,x2,x3,x4,
    input cin,
    output sum,
    output carry,
    output cout
);

wire s1,c1,s2,c2;

Full_Adder FA1(x1,x2,x3,s1,c1);
Full_Adder FA2(s1,x4,cin,sum,c2);

assign carry = c1;
assign cout = c2;

endmodule


module Four_way_Sorting_Network(In1,In2,In3,In4,Out1,Out2,Out3,Out4);
    input In1,In2,In3,In4;
    output Out1,Out2,Out3,Out4;
    wire [0:3]W;

    Two_input_binary_sorter BS1(In1,In2,W[0],W[1]);
    Two_input_binary_sorter BS2(W[0],In3,Out1,W[3]);
    Two_input_binary_sorter BS3(W[1],In4,W[2],Out4);
    Two_input_binary_sorter BS4(W[2],W[3],Out2,Out3);

endmodule

module Full_Adder(
    input a,
    input b,
    input cin,
    output sum,
    output cout
);

assign sum = a ^ b ^ cin;
assign cout = (a & b) | (b & cin) | (a & cin);

endmodule


module Two_input_binary_sorter(In1,In2,Out1,Out2);
    input In1,In2;
    output Out1,Out2;

    assign Out1 = In1|In2;
    assign Out2 = In1&In2;

endmodule


