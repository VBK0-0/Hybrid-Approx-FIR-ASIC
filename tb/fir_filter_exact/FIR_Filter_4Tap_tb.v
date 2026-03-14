`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.03.2026 22:05:05
// Design Name: 
// Module Name: FIR_Filter_4Tap_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module FIR_Filter_4Tap_tb;
    reg clk;
    reg rst;
    reg [7:0] x_in;
    wire [15:0] y_out;

    // FIR Coefficients from the module
    // h0=127, h1=119, h2=63, h3=85
    
    FIR_Filter_4Tap uut (
        .clk(clk),
        .rst(rst),
        .x_in(x_in),
        .y_out(y_out)
    );

    // Clock Generation
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        // Initialize
        rst = 1;
        x_in = 0;
        #20;
        
        rst = 0;
        #10;

        // Test Case 1: Constant Input (Step Response)
        // Expected behavior: y_out should eventually equal x_in * (h0+h1+h2+h3)
        // 10 * (127 + 119 + 63 + 85) = 10 * 394 = 3940
        x_in = 8'd10;
        #100;
        $display("Step Response Input 10: y_out = %d (Expected ~3940)", y_out);

        // Test Case 2: Impulse Input
        // Expected: y_out should show coefficients h0, h1, h2, h3 scaled by x_in
        x_in = 8'd1; #10;
        x_in = 8'd0; #40;
        
        // Test Case 3: Random Values
        repeat(5) begin
            x_in = $urandom_range(0, 50);
            #10;
            $display("Input: %d, Output: %d", x_in, y_out);
        end

        #50;
        $finish;
    end

    // Monitor changes
    initial begin
        $monitor("Time=%0t | x_in=%d | y_out=%d", $time, x_in, y_out);
    end
endmodule