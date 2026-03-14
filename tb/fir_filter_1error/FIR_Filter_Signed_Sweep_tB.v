`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.03.2026 16:52:59
// Design Name: 
// Module Name: FIR_Filter_Signed_Sweep_tB
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


module FIR_Filter_Signed_Sweep_tB;

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

    // --- SIGNED GOLDEN MODEL ---
    // We cast x_in to a signed register so Verilog handles the math correctly
    wire signed [7:0] x_in_signed = x_in;
    reg signed [7:0] exact_x1, exact_x2, exact_x3;
    
    wire signed [15:0] y_exact;
    wire signed [15:0] y_approx_adjusted;
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
            exact_x1 <= x_in_signed;
        end
    end
    
    // Golden Math: Standard Signed Multiplication
    assign y_exact = (x_in_signed * 1) + (exact_x1 * 2) + (exact_x2 * 3) + (exact_x3 * 4);
    
    // Hardware Adjustment: Subtract the 8192 Baugh-Wooley bias and cast to signed
    assign y_approx_adjusted = $signed(y_out) - 16'd8192;
    
    // Absolute Error Calculation
    assign error_margin = (y_approx_adjusted > y_exact) ? (y_approx_adjusted - y_exact) : (y_exact - y_approx_adjusted);

    // Clock Generation
    always #5 clk = ~clk;

    // Sweep Variable
    integer i;

    initial begin
        // 1. Initialization
        clk = 0;
        rst = 1;
        x_in = 8'd0;
        
        #15 rst = 0;

        // 2. POSITIVE SWEEP: 0 to +127 (Will show mostly NO error, except near the top)
        for (i = 0; i <= 127; i = i + 4) begin
            x_in = i[7:0];
            #40; // Wait 4 clock cycles for filter to fill up
        end
        
        // 3. NEGATIVE SWEEP: +127 down to -128 (Will heavily trigger the 512 error)
        for (i = 127; i >= -128; i = i - 4) begin
            x_in = i[7:0];
            #40;
        end

        // 4. RETURN TO ZERO: -128 back to 0
        for (i = -128; i <= 0; i = i + 4) begin
            x_in = i[7:0];
            #40;
        end

        $finish;
    end

    // Monitor: We only print every 40ns (when the filter has settled on the current step)
    // To do this, we use a separate always block instead of $monitor
    always @(posedge clk) begin
        // Print right before the input changes (every 4th clock cycle)
        if (($time - 15) % 40 == 35) begin 
            $display("%0t | %4d |   %6d    |   %6d   |     %4d", 
                     $time, x_in_signed, y_approx_adjusted, y_exact, error_margin);
        end
    end

    // Header formatting
    initial begin
        $display("---------------------------------------------------------------");
        $display("Time  | x_in | Approx y_out | Exact y_out | Absolute Error");
        $display("---------------------------------------------------------------");
    end

endmodule
