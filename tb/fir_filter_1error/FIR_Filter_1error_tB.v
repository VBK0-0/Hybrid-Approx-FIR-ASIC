`timescale 1ns / 1ps

module FIR_Filter_1error_tB;

    reg clk;
    reg rst;
    reg [7:0] x_in;
    wire [17:0] y_out; // Matches updated hardware

    FIR_Filter_4Tap_1error uut (
        .clk(clk), .rst(rst), .x_in(x_in), .y_out(y_out)
    );

    // SIGNED GOLDEN MODEL
    wire signed [7:0] x_in_s = x_in;
    reg signed [7:0] ex1, ex2, ex3;
    
    // Updated Golden Math to match Hardware Parameters (127, 119, 63, 85)
    wire signed [19:0] y_exact; 
    wire signed [19:0] y_approx_val;
    wire [19:0] error_margin;
    
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            ex1 <= 0; ex2 <= 0; ex3 <= 0;
        end else begin
            ex3 <= ex2; ex2 <= ex1; ex1 <= x_in_s;
        end
    end
    
    // FIXED: Coefficients now match hardware
    assign y_exact = (x_in_s * 127) + (ex1 * 119) + (ex2 * 63) + (ex3 * 85);
    
    // FIXED: Removed the -8192 adjustment. Hardware is unsigned/magnitude based.
    assign y_approx_val = $signed({2'b0, y_out});
    
    assign error_margin = (y_approx_val > y_exact) ? (y_approx_val - y_exact) : (y_exact - y_approx_val);

    // Clock and Stimulus
    always #5 clk = ~clk;

    integer i;
    initial begin
        clk = 0; rst = 1; x_in = 0;
        #15 rst = 0;

        // Sweep (Only Positive for Unsigned logic test)
        for (i = 0; i <= 127; i = i + 8) begin
            x_in = i[7:0];
            #40;
        end
        $display("Sweep Complete.");
        $stop; 
    end

    initial begin
        $display("---------------------------------------------------------------");
        $display("Time  | x_in | Approx Out | Exact Out | Absolute Error");
        $display("---------------------------------------------------------------");
    end

    always @(posedge clk) begin
        if ($time >= 55 && ($time - 55) % 40 == 0) begin 
            $display("%0t | %4d |   %8d   |   %8d   |     %5d", 
                     $time, x_in, y_approx_val, y_exact, error_margin);
        end
    end
endmodule