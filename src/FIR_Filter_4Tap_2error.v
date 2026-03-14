`timescale 1ns / 1ps

module FIR_Filter_4Tap_2error(
    input clk,
    input rst,
    input [7:0] x_in,
    output [17:0] y_out // 18-bit for full range
);
    reg [7:0] x1, x2, x3;
    parameter h0 = 8'd127, h1 = 8'd119, h2 = 8'd63, h3 = 8'd85;
    wire [15:0] m0, m1, m2, m3;

    // Multiplication
    Approximate_Multiplier_8X8_bits_2error M0(x_in, h0, m0);
    Approximate_Multiplier_8X8_bits_2error M1(x1,   h1, m1);
    Approximate_Multiplier_8X8_bits_2error M2(x2,   h2, m2);
    Approximate_Multiplier_8X8_bits_2error M3(x3,   h3, m3);

    // Delay Line
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            x1 <= 0; x2 <= 0; x3 <= 0;
        end else begin
            x1 <= x_in;
            x2 <= x1;
            x3 <= x2;
        end
    end
    
    // Accumulation
    assign y_out = m0 + m1 + m2 + m3;
endmodule

module Approximate_Multiplier_8X8_bits_2error(
    input [7:0] A,
    input [7:0] B,
    output [15:0] Z_T
);
    wire [7:0] pp [7:0];
    wire [7:0] col [15:0];
    wire [15:0] S1, C1, S2, C2;
    wire [16:0] ripple1, ripple2;

    assign ripple1[0] = 1'b0;
    assign ripple2[0] = 1'b0;

    // 1. Partial Product Generation
    genvar i, j;
    generate
        for (i = 0; i < 8; i = i + 1) begin : rows
            for (j = 0; j < 8; j = j + 1) begin : cols
                assign pp[i][j] = A[j] & B[i];
            end
        end
    endgenerate

    // 2. Column Alignment
    generate
        for (i = 0; i < 16; i = i + 1) begin : columns
            wire [7:0] temp_col;
            for (j = 0; j < 8; j = j + 1) begin : bits
                if (i >= j && (i - j) < 8)
                    assign temp_col[j] = pp[j][i-j];
                else
                    assign temp_col[j] = 1'b0;
            end
            assign col[i] = temp_col;
        end
    endgenerate

    // 3. Reduction with Correct Carry Propagation
    generate
        for (i = 0; i < 16; i = i + 1) begin : red
            if (i < 9) begin : approx_zone
                Approximate_4_2_Compressor_with_2_errors ACC1 (col[i][0], col[i][1], col[i][2], col[i][3], S1[i], C1[i]);
                Approximate_4_2_Compressor_with_2_errors ACC2 (col[i][4], col[i][5], col[i][6], col[i][7], S2[i], C2[i]);
                assign ripple1[i+1] = 1'b0;
                assign ripple2[i+1] = 1'b0;
            end else begin : exact_zone
                Compressor_4_2 EX1 (col[i][0], col[i][1], col[i][2], col[i][3], ripple1[i], ripple1[i+1], C1[i], S1[i]);
                Compressor_4_2 EX2 (col[i][4], col[i][5], col[i][6], col[i][7], ripple2[i], ripple2[i+1], C2[i], S2[i]);
            end
        end
    endgenerate

    // 4. Final Addition - Weighting C by 2^1
    assign Z_T = S1 + S2 + (C1 << 1) + (C2 << 1);

endmodule

// ----------------------------------------------------------------------------------
// SUBMODULES
// ----------------------------------------------------------------------------------

module Two_input_binary_sorter(In1,In2,Out1,Out2);
    input In1,In2;
    output Out1,Out2;

    assign Out1 = In1|In2;
    assign Out2 = In1&In2;

endmodule

// --- NEWLY ADDED 2-ERROR MODULES ---

module Approximate_4_2_Compressor_with_2_errors(x0,x1,x2,x3,Sum,Carry);
    input x0,x1,x2,x3;
    output Sum,Carry;

    wire A, h1, h2, D;

    Four_way_Sorting_Network FSN1(x0,x1,x2,x3,A,h1,h2,D);
    assign Carry = A & h1; 
    
    // --- SYNTHESIS FIREWALL ---
    // 1. Generate inverted signals explicitly
    wire not_h1 = ~h1;
    wire not_A  = ~A;

    // 2. Force Yosys to keep these intermediate AND gates 
    // This prevents the ABC engine from seeing the XOR pattern!
    (* keep = "true" *) wire and_term_1 = A & not_h1;
    (* keep = "true" *) wire and_term_2 = not_A & h1;

    // 3. Final OR gate to complete the Sum logic
    assign Sum = and_term_1 | and_term_2 | h2;

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

// ----------------------------------------------------------------------------------
// EXACT MODULES (Kept for standard routing)
// ----------------------------------------------------------------------------------

module Half_Sort(I1,I2,I3,I4,O1,O2,O3,O4);
    input I1,I2,I3,I4;
    output O1,O2,O3,O4;
    wire w[3:0];

    Two_input_binary_sorter  BS1(I1,I2,w[0],w[1]);
    Two_input_binary_sorter  BS2(I3,I4,w[2],w[3]);
    Two_input_binary_sorter  BS3(w[0],w[2],O1,O3);
    Two_input_binary_sorter  BS4(w[1],w[3],O2,O4);

endmodule

module Compressor_4_2(x0,x1,x2,x3,Cin,Cout,Carry,Sum);
    input x0,x1,x2,x3,Cin;
    output Carry,Sum,Cout;
    wire A,B,C,D,s0,h1,h2;

    Half_Sort HS1(x0,x1,x2,x3,A,B,C,D);
    assign s0 = (A&(~B))|D;
    assign Cout = B;
    assign h1 = C|Cin;
    assign h2 = C&Cin;
    assign Carry = (s0 & h1)|h2;
    assign Sum = s0?((~h1)|h2):(h1&(~h2));

endmodule
