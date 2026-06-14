`timescale 1ns/1ps

//////////////////////////////////////////////////////////////////////////////////
// CPU + Cache Comparison Testbench
//////////////////////////////////////////////////////////////////////////////////

module tb_cpu_cache_compare;

////////////////////////////////////////////////////////////
// Clock & Reset
////////////////////////////////////////////////////////////

reg clk;
reg rst;
reg [1:0] pattern_select;
initial
begin
    clk = 0;
    forever #5 clk = ~clk;
end

////////////////////////////////////////////////////////////
// Cache Select
////////////////////////////////////////////////////////////

reg [1:0] cache_type;

////////////////////////////////////////////////////////////
// CPU Outputs
////////////////////////////////////////////////////////////

wire [31:0] hit_count;
wire [31:0] miss_count;
wire [31:0] total_access;
wire [31:0] stall_cycles;

////////////////////////////////////////////////////////////
// DUT
////////////////////////////////////////////////////////////

Risc_16_bit DUT
(
    .clk(clk),
    .rst(rst),
 .pattern_select(pattern_select),
    .cache_type(cache_type),

    .hit_count(hit_count),
    .miss_count(miss_count),
    .total_access(total_access),
    .stall_cycles(stall_cycles)
);

////////////////////////////////////////////////////////////
// Task
////////////////////////////////////////////////////////////

task run_cache_test;

input [1:0] cache_select;

begin

    cache_type = cache_select;

    rst = 1'b1;
    #20;

    rst = 1'b0;

    //-----------------------------------------
    // Run CPU
    //-----------------------------------------

    #5000;

    //-----------------------------------------
    // Results
    //-----------------------------------------

    $display("");
    $display("==================================");

    case(cache_select)

        2'd0:
        $display("DIRECT MAPPED CACHE");

        2'd1:
        $display("FULLY ASSOCIATIVE CACHE");

        2'd2:
        $display("2-WAY SET ASSOCIATIVE CACHE");

    endcase

    $display("----------------------------------");

    $display("Accesses     = %0d", total_access);

    $display("Hits         = %0d", hit_count);

    $display("Misses       = %0d", miss_count);

    if(total_access != 0)
    begin

        $display("Hit Ratio    = %0d %%",

                 (hit_count*100)/total_access);

        $display("Miss Ratio   = %0d %%",

                 (miss_count*100)/total_access);

    end

    $display("Stall Cycles = %0d", stall_cycles);

    $display("==================================");
    $display("");

end

endtask

////////////////////////////////////////////////////////////
// Simulation
////////////////////////////////////////////////////////////

initial
begin

    ////////////////////////////////////////////
    // TEMPORAL
    ////////////////////////////////////////////
$display("");
$display("==========================================");
$display("PATTERN 0 : TEMPORAL LOCALITY");
$display("Address Sequence : 5 5 5 5 5 5 ...");
$display("==========================================");
    pattern_select = 2'b00;
#20
    run_cache_test(2'd0);
    run_cache_test(2'd1);
    run_cache_test(2'd2);

    ////////////////////////////////////////////
    // SPATIAL
    ////////////////////////////////////////////
$display("");
$display("==========================================");
$display("PATTERN 1 : SPATIAL LOCALITY");
$display("Address Sequence : 0 1 2 3 4 5 ...");
$display("==========================================");
    pattern_select = 2'b01;
#20
    run_cache_test(2'd0);
    run_cache_test(2'd1);
    run_cache_test(2'd2);

    ////////////////////////////////////////////
    // CONFLICT
    ////////////////////////////////////////////
$display("");
$display("==========================================");
$display("PATTERN 2 : CONFLICT LOCALITY");
$display("Address Sequence : 0 8 0 8 0 8 ...");
$display("==========================================");
    pattern_select = 2'b10;
#20
    run_cache_test(2'd0);
    run_cache_test(2'd1);
    run_cache_test(2'd2);

    ////////////////////////////////////////////
    // RANDOM
    ////////////////////////////////////////////
$display("");
$display("==========================================");
$display("PATTERN 3 : RANDOM ACCESS");
$display("Address Sequence : 0 13 26 39 52 ...");
$display("==========================================");
    pattern_select = 2'b11;
#20
    run_cache_test(2'd0);
    run_cache_test(2'd1);
    run_cache_test(2'd2);

    $display("");
    $display("==========================================");
    $display("CPU CACHE COMPARISON COMPLETE");
    $display("==========================================");

    $finish;

end

    



endmodule