`timescale 1ns / 1ps

module FIR_Filter_tb;

    // Inputs to DUT (Design Under Test)
    reg clk;
    reg rst;
    reg [7:0] x_in;

    // Output from DUT
    wire [15:0] y_out;

    // Instantiate the FIR Filter
    FIR_Filter_4Tap uut (
        .clk(clk),
        .rst(rst),
        .x_in(x_in),
        .y_out(y_out)
    );

    // Clock Generation (10ns period -> 100MHz)
    always #5 clk = ~clk;

    initial begin
        // 1. Initialize Inputs & Apply Reset
        clk = 0;
        rst = 1;
        x_in = 8'd0;
        
        // Hold reset for 15ns to ensure it catches a clock edge
        #15;
        rst = 0;

        // --------------------------------------------------------
        // TEST 1: The Impulse Response
        // --------------------------------------------------------
        // We feed a single value (10) for one clock cycle, then return to 0.
        // Expected y_out sequence: 10, 20, 30, 40, 0
        // (Because it gets multiplied by h0=1, h1=2, h2=3, h3=4 as it shifts)
        #5 x_in = 8'd10; 
        #10 x_in = 8'd0; 
        
        // Wait for the impulse to flush completely through the 4-tap delay line
        #40; 

        // --------------------------------------------------------
        // TEST 2: The Step Response
        // --------------------------------------------------------
        // We feed a constant value (5) continuously.
        // Expected y_out sequence: 
        // Cycle 1: 5 * 1 = 5
        // Cycle 2: (5*1) + (5*2) = 15
        // Cycle 3: (5*1) + (5*2) + (5*3) = 30
        // Cycle 4: (5*1) + (5*2) + (5*3) + (5*4) = 50
        // Cycle 5+: 50 (Holds steady at 50)
        x_in = 8'd5;
        
        // Let the step response settle
        #60;

        // End Simulation
        $finish;
    end

    // Optional: Monitor changes in the console
    initial begin
        $monitor("Time=%0t | rst=%b | x_in=%3d | y_out=%3d", $time, rst, x_in, y_out);
    end

endmodule
