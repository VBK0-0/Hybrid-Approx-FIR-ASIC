`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Testbench: FIR_Filter_1error_tB (Gradual Signed Sweep for Error Profiling)
//////////////////////////////////////////////////////////////////////////////////

module FIR_Filter_1error_tB;

    // Inputs to DUT
    reg clk;
    reg rst;
    reg [7:0] x_in;

    // Output from DUT
    wire [15:0] y_out;

    // Instantiate the Approximate FIR Filter
    FIR_Filter_4Tap_1error uut (
        .clk(clk),
        .rst(rst),
        .x_in(x_in),
        .y_out(y_out)
    );

    // --------------------------------------------------------
    // SIGNED GOLDEN MODEL FOR ERROR MEASUREMENT
    // --------------------------------------------------------
    // Cast x_in to signed so Verilog does the math correctly
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
    
    // Golden Math: Standard Signed Multiplication (h0=1, h1=2, h2=3, h3=4)
    assign y_exact = (x_in_signed * 1) + (exact_x1 * 2) + (exact_x2 * 3) + (exact_x3 * 4);
    
    // Hardware Adjustment: Subtract the 8192 Baugh-Wooley bias and cast to signed
    assign y_approx_adjusted = $signed(y_out) - 16'd8192;
    
    // Absolute Error Calculation
    assign error_margin = (y_approx_adjusted > y_exact) ? (y_approx_adjusted - y_exact) : (y_exact - y_approx_adjusted);

    // --------------------------------------------------------
    // CLOCK AND STIMULUS
    // --------------------------------------------------------
    // Clock Generation (10ns period -> 100MHz)
    always #5 clk = ~clk;

    integer i;

    initial begin
        // 1. Initialize Inputs & Apply Reset
        clk = 0;
        rst = 1;
        x_in = 8'd0;
        
        // Hold reset
        #15 rst = 0;

        // 2. POSITIVE SWEEP: 0 to +127
        for (i = 0; i <= 127; i = i + 4) begin
            x_in = i[7:0];
            #40; // Wait 4 clock cycles for the 4-tap filter to fill up
        end
        
        // 3. NEGATIVE SWEEP: +127 down to -128
        for (i = 127; i >= -128; i = i - 4) begin
            x_in = i[7:0];
            #40;
        end

        // 4. RETURN TO ZERO: -128 back to 0
        for (i = -128; i <= 0; i = i + 4) begin
            x_in = i[7:0];
            #40;
        end

        // Use $stop to pause simulation but keep waveform viewer open
        $stop; 
    end

    // --------------------------------------------------------
    // CONSOLE MONITORING
    // --------------------------------------------------------
    // Header formatting
    initial begin
        $display("---------------------------------------------------------------");
        $display("Time  | x_in | Approx y_out | Exact y_out | Absolute Error");
        $display("---------------------------------------------------------------");
    end

    // Print data only when the filter has settled (every 40ns)
    always @(posedge clk) begin
        // The inputs change at t=15, 55, 95... 
        // We print exactly 40ns later (t=55, 95, 135) to see the steady state
        if ($time >= 55 && ($time - 55) % 40 == 0) begin 
            $display("%0t | %4d |   %6d    |   %6d   |     %4d", 
                     $time, x_in_signed, y_approx_adjusted, y_exact, error_margin);
        end
    end

endmodule
