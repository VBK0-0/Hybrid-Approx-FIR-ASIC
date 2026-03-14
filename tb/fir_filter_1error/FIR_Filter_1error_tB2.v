`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.03.2026 16:44:36
// Design Name: 
// Module Name: FIR_Filter_1error_tB2
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


module FIR_Filter_1error_tB2;

    // Inputs
    reg clk;
    reg rst;
    reg [7:0] x_in;

    // Outputs
    wire [15:0] y_out;

    // Instantiate the Approximate FIR Filter
    FIR_Filter_4Tap_1error uut (
        .clk(clk),
        .rst(rst),
        .x_in(x_in),
        .y_out(y_out)
    );

    // --- GOLDEN MODEL FOR ERROR MEASUREMENT ---
    reg [7:0] exact_x1, exact_x2, exact_x3;
    wire [15:0] y_exact;
    wire [15:0] error_margin;
    
    // Exact delay line
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            exact_x1 <= 0;
            exact_x2 <= 0;
            exact_x3 <= 0;
        end else begin
            exact_x3 <= exact_x2;
            exact_x2 <= exact_x1;
            exact_x1 <= x_in;
        end
    end
    
    // Exact mathematical calculation
    assign y_exact = (x_in * 1) + (exact_x1 * 2) + (exact_x2 * 3) + (exact_x3 * 4);
    
    // Calculate Absolute Error (assuming you used Option A to remove the 8192 bias)
    // If you DID NOT remove the 8192 bias yet, use: assign error_margin = (y_out - 16'd8192) > y_exact ? (y_out - 16'd8192) - y_exact : y_exact - (y_out - 16'd8192);
    assign error_margin = (y_out > y_exact) ? (y_out - y_exact) : (y_exact - y_out);


    // Clock Generation
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        x_in = 8'd0;
        
        #15 rst = 0;

        // --------------------------------------------------------
        // TEST 1: Medium Values (Triggering some approximation)
        // --------------------------------------------------------
        #5  x_in = 8'd100; 
        #10 x_in = 8'd150; 
        #10 x_in = 8'd0;
        #40; 

        // --------------------------------------------------------
        // TEST 2: High Values (Maximum approximation error expected)
        // --------------------------------------------------------
        x_in = 8'd200; #10;
        x_in = 8'd255; #10; // Max 8-bit value
        x_in = 8'd250; #10;
        x_in = 8'd0;   #40;

        $finish;
    end

    // Monitor changes to compare Exact vs Approximate
    initial begin
        $display("------------------------------------------------------------------");
        $display("Time  | x_in | Approx y_out | Exact y_out | Absolute Error");
        $display("------------------------------------------------------------------");
        $monitor("%0t |  %3d |    %5d     |    %5d    |      %d", $time, x_in, y_out, y_exact, error_margin);
    end

endmodule
