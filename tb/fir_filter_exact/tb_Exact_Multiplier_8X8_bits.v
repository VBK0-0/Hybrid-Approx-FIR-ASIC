`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.03.2026 15:16:20
// Design Name: 
// Module Name: tb_Exact_Multiplier_8X8_bits
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


module tb_Exact_Multiplier_8X8_bits;

reg  [7:0] A;
reg  [7:0] B;
wire [15:0] Z_T;

reg  [15:0] expected;

integer i;
integer errors;

/////////////////////////////////////////////////////
// Instantiate the DUT (Device Under Test)
/////////////////////////////////////////////////////

Exact_Multiplier_8X8_bits DUT (
    .A(A),
    .B(B),
    .Z_T(Z_T)
);

/////////////////////////////////////////////////////
// Test Procedure
/////////////////////////////////////////////////////

initial
begin

    errors = 0;

    $display("========================================");
    $display(" Starting 8x8 Exact Multiplier Test ");
    $display("========================================");

    /////////////////////////////////////////////////
    // Corner Cases
    /////////////////////////////////////////////////

    A = 0; B = 0; #10;
    expected = A * B;
    check_result();

    A = 8'hFF; B = 0; #10;
    expected = A * B;
    check_result();

    A = 0; B = 8'hFF; #10;
    expected = A * B;
    check_result();

    A = 8'hFF; B = 8'hFF; #10;
    expected = A * B;
    check_result();

    /////////////////////////////////////////////////
    // Random Tests
    /////////////////////////////////////////////////

    for(i = 0; i < 100; i = i + 1)
    begin
        A = $random;
        B = $random;

        #10;

        expected = A * B;

        check_result();
    end

    /////////////////////////////////////////////////
    // Final Result
    /////////////////////////////////////////////////

    if(errors == 0)
        $display("ALL TESTS PASSED");
    else
        $display("TEST FAILED with %0d errors", errors);

    $display("========================================");

    $finish;

end

/////////////////////////////////////////////////////
// Result Check Task
/////////////////////////////////////////////////////

task check_result;
begin

    if(Z_T !== expected)
    begin
        $display("ERROR: A=%d B=%d -> Expected=%d Got=%d", A, B, expected, Z_T);
        errors = errors + 1;
    end
    else
    begin
        $display("PASS: A=%d B=%d -> Result=%d", A, B, Z_T);
    end

end
endtask

endmodule


