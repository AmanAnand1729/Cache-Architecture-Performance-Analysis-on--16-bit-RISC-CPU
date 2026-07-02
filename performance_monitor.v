`timescale 1ns/1ps

//////////////////////////////////////////////////////////////////////////////////
// Performance Monitor
//
// Calculates:
//
// Hit Ratio
// Miss Ratio
// AMAT
// CPI
// IPC
// Throughput
//
//////////////////////////////////////////////////////////////////////////////////

module performance_monitor
(
    input clk,
    input rst,

    input [31:0] hit_count,
    input [31:0] miss_count,
    input [31:0] access_count,
    input [31:0] stall_cycles,

    output reg [31:0] hit_ratio,
    output reg [31:0] miss_ratio,

    output reg [31:0] amat,
    output reg [31:0] cpi,
    output reg [31:0] ipc,

    output reg [31:0] throughput
);

/////////////////////////////////////////////////////
// Parameters
/////////////////////////////////////////////////////

parameter HIT_TIME     = 1;
parameter MISS_PENALTY = 7;

/////////////////////////////////////////////////////
// Internal
/////////////////////////////////////////////////////

reg [31:0] total_cycles;

always @(posedge clk)
begin

    if(rst)
    begin

        total_cycles <= 0;

        hit_ratio <= 0;
        miss_ratio <= 0;

        amat <= 0;

        cpi <= 0;
        ipc <= 0;

        throughput <= 0;

    end

    else
    begin

        total_cycles <= total_cycles + 1;

        /////////////////////////////////////////////
        // Hit Ratio
        /////////////////////////////////////////////

        if(access_count != 0)
        begin

            hit_ratio <=
            (hit_count * 100) / access_count;

            miss_ratio <=
            (miss_count * 100) / access_count;

        end

        /////////////////////////////////////////////
        // AMAT
        //
        // AMAT =
        // Hit Time +
        // Miss Rate × Miss Penalty
        /////////////////////////////////////////////

        amat <=
        HIT_TIME +
        ((miss_ratio * MISS_PENALTY) / 100);

        /////////////////////////////////////////////
        // CPI
        /////////////////////////////////////////////

        if(access_count != 0)
        begin

            cpi <=
            (total_cycles )
            / access_count;

        end

        /////////////////////////////////////////////
        // IPC
        /////////////////////////////////////////////

        if(total_cycles != 0)
        begin

            ipc <=
            access_count / total_cycles;

        end

        /////////////////////////////////////////////
        // Throughput
        /////////////////////////////////////////////

        throughput <= access_count;

    end

end

endmodule
