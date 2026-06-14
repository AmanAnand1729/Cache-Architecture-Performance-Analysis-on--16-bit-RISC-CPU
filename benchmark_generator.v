`timescale 1ns/1ps

//////////////////////////////////////////////////////////////////////////////////
// Benchmark Generator
//
// Pattern 0 -> Temporal Locality
// Pattern 1 -> Spatial Locality
// Pattern 2 -> Conflict Miss Pattern
// Pattern 3 -> Random Pattern
//
//////////////////////////////////////////////////////////////////////////////////

module benchmark_generator(

    input clk,
    input rst,

    input enable,
    input cache_busy,

    input [1:0] pattern_select,

    output reg access_en,
    output reg [5:0] address,
    output reg done

);

    reg [5:0] count;

    // Prevent multiple requests before cache acknowledges
    reg request_pending;

    initial
    begin
        count           = 0;
        access_en       = 0;
        address         = 0;
        done            = 0;
        request_pending = 0;
    end

    always @(posedge clk)
    begin

        //--------------------------------------------------
        // RESET
        //--------------------------------------------------

        if(rst)
        begin
            count           <= 0;
            access_en       <= 0;
            address         <= 0;
            done            <= 0;
            request_pending <= 0;
        end

        //--------------------------------------------------
        // Default: access_en is a pulse
        //--------------------------------------------------

        else
        begin

            access_en <= 1'b0;

            //--------------------------------------------------
            // Cache has accepted request
            //--------------------------------------------------

            if(cache_busy)
                request_pending <= 1'b1;

            //--------------------------------------------------
            // Cache finished previous request
            //--------------------------------------------------

            if(!cache_busy && request_pending)
                request_pending <= 1'b0;

            //--------------------------------------------------
            // Generate new request
            //--------------------------------------------------

            if(enable &&
               !done &&
               !cache_busy &&
               !request_pending)
            begin

                access_en <= 1'b1;

                //--------------------------------------------------
                // Pattern 0 : Temporal
                //--------------------------------------------------

                if(pattern_select == 2'd0)
                begin
                    address <= 6'd5;
                end

                //--------------------------------------------------
                // Pattern 1 : Spatial
                //--------------------------------------------------

                else if(pattern_select == 2'd1)
                begin
                    address <= count;
                end

                //--------------------------------------------------
                // Pattern 2 : Conflict
                //--------------------------------------------------

                else if(pattern_select == 2'd2)
                begin

                    case(count[1:0])

                        2'd0: address <= 6'd0;
                        2'd1: address <= 6'd8;
                        2'd2: address <= 6'd16;
                        2'd3: address <= 6'd24;

                    endcase

                end

                //--------------------------------------------------
                // Pattern 3 : Pseudo Random
                //--------------------------------------------------

                else
                begin
                    address <= (count * 13) % 64;
                end

                count <= count + 1;

                if(count == 31)
                    done <= 1'b1;

            end

        end

    end

endmodule