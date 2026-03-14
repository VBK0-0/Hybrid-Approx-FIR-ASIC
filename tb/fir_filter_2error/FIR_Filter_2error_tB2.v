`timescale 1ns / 1ps

module FIR_Filter_2error_tB2;
    // Inputs
    reg clk;
    reg rst;
    reg [7:0] x_in;

    // Outputs - Increased to 17 bits to prevent clipping
    wire [16:0] y_out;

    // Instantiate the Approximate FIR Filter
    FIR_Filter_4Tap_2error uut (
        .clk(clk),
        .rst(rst),
        .x_in(x_in),
        .y_out(y_out)
    );

    // --- GOLDEN MODEL FOR ERROR MEASUREMENT ---
    reg [7:0] exact_x1, exact_x2, exact_x3;
    wire [16:0] y_exact;
    wire [16:0] error_margin;
    
    // FIR Coefficients must match your hardware parameters!
    parameter H0 = 8'd127, H1 = 8'd119, H2 = 8'd63, H3 = 8'd85;
    
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
    
    // FIXED MATH: Must use the same coefficients as the UUT
    assign y_exact = (x_in * H0) + (exact_x1 * H1) + (exact_x2 * H2) + (exact_x3 * H3);
    
    // Calculate Absolute Error
    assign error_margin = (y_out > y_exact) ? (y_out - y_exact) : (y_exact - y_out);

    // Clock Generation
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        // Reset sequence
        rst = 1;
        x_in = 8'd0;
        #20 rst = 0;

        // TEST 1: Step through values to see the delay line fill
        #10 x_in = 8'd100; // Expected M0 result: 12,700
        #10 x_in = 8'd150; 
        #10 x_in = 8'd200;
        #10 x_in = 8'd255; // Max 8-bit value
        
        // Wait for pipeline to flush
        #10 x_in = 8'd0;
        #50;

        $display("Simulation Finished.");
        $finish;
    end

    // Monitor changes
    initial begin
        $display("------------------------------------------------------------------");
        $display("Time  | x_in | Approx y_out | Exact y_out | Absolute Error");
        $display("------------------------------------------------------------------");
        // Added formatting to make columns line up better
        $monitor("%5t | %4d | %12d | %12d | %12d", $time, x_in, y_out, y_exact, error_margin);
    end

endmodule