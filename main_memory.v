`timescale 1ns/1ps

//////////////////////////////////////////////////////////////////////////////////
// Module : main_memory
//
// Description:
// ------------
// Main Memory with configurable latency
//
// Size:
// ------
// 64 words
//
// Word Width:
// ------------
// 16 bits
//
// Latency:
// --------
// 5 clock cycles
//
//////////////////////////////////////////////////////////////////////////////////

module main_memory #

(
    parameter MEMORY_LATENCY = 5
)

(
    input clk,
    input rst,

    //------------------------------------------------------
    // Request Interface
    //------------------------------------------------------

    input read_en,

    input [5:0] address,

    //------------------------------------------------------
    // Response Interface
    //------------------------------------------------------

    output reg [15:0] read_data,

    output reg ready

);

    /////////////////////////////////////////////////////////
    // Memory Array
    /////////////////////////////////////////////////////////

    reg [15:0] memory [0:63];

    /////////////////////////////////////////////////////////
    // Internal Registers
    /////////////////////////////////////////////////////////

    reg [2:0] wait_counter;

    reg busy;

    reg [5:0] saved_address;

    integer i;

    /////////////////////////////////////////////////////////
    // Initialize Memory
    /////////////////////////////////////////////////////////

    initial
    begin

        for(i=0;i<64;i=i+1)
        begin
            memory[i] = i + 16'd100;
        end

        ready = 0;
        busy = 0;
        wait_counter = 0;
        read_data = 0;

    end

    /////////////////////////////////////////////////////////
    // Memory FSM
    /////////////////////////////////////////////////////////

    always @(posedge clk)
    begin

        if(rst)
        begin

            ready <= 0;
            busy <= 0;
            wait_counter <= 0;
            read_data <= 0;

        end

        //--------------------------------------------------
        // New Memory Request
        //--------------------------------------------------

        else if(read_en && !busy)
        begin

            busy <= 1'b1;

            ready <= 1'b0;

            wait_counter <= MEMORY_LATENCY - 1;

            saved_address <= address;

        end

        //--------------------------------------------------
        // Waiting
        //--------------------------------------------------

        else if(busy)
        begin

            if(wait_counter == 0)
            begin

                read_data <= memory[saved_address];

                ready <= 1'b1;

                busy <= 1'b0;

            end

            else
            begin

                wait_counter <= wait_counter - 1;

                ready <= 1'b0;

            end

        end

        else
        begin

            ready <= 1'b0;

        end

    end

endmodule