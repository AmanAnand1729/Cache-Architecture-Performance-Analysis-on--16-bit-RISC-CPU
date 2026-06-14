`timescale 1ns/1ps

//////////////////////////////////////////////////////////////////////////////////
// Fully Associative Cache
//
// Cache Lines : 8
// Block Size  : 1 Word
//
// Tag = Entire Address (6 bits)
//
// Replacement Policy : FIFO
//
//////////////////////////////////////////////////////////////////////////////////

module cache_fully(

    input clk,
    input rst,

    /////////////////////////////////////////////////////////
    // CPU / Benchmark Interface
    /////////////////////////////////////////////////////////

    input access_en,
    input [5:0] address,

    output reg [15:0] data_out,

    output reg hit,
    output reg busy,

    /////////////////////////////////////////////////////////
    // Main Memory Interface
    /////////////////////////////////////////////////////////

    output reg mem_read,
    output reg [5:0] mem_address,

    input [15:0] mem_data,
    input mem_ready,

    /////////////////////////////////////////////////////////
    // Statistics
    /////////////////////////////////////////////////////////

    output reg [31:0] hit_count,
    output reg [31:0] miss_count,
    output reg [31:0] access_count,
    output reg [31:0] stall_cycles

);

    /////////////////////////////////////////////////////////
    // Cache Storage
    /////////////////////////////////////////////////////////

    reg [15:0] cache_data [0:7];

    reg [5:0] tag_array [0:7];

    reg valid [0:7];

    /////////////////////////////////////////////////////////
    // FIFO Replacement Pointer
    /////////////////////////////////////////////////////////

    reg [2:0] fifo_ptr;

    /////////////////////////////////////////////////////////
    // Saved Request
    /////////////////////////////////////////////////////////

    reg [5:0] saved_address;

    /////////////////////////////////////////////////////////
    // Search Variables
    /////////////////////////////////////////////////////////

    integer i;

    reg found;
    reg [2:0] hit_line;

    /////////////////////////////////////////////////////////
    // FSM States
    /////////////////////////////////////////////////////////

    localparam IDLE         = 3'd0;
    localparam CHECK_HIT    = 3'd1;
    localparam MEM_REQUEST  = 3'd2;
    localparam WAIT_MEMORY  = 3'd3;
    localparam FILL_CACHE   = 3'd4;
    localparam DONE         = 3'd5;

    reg [2:0] state;

    /////////////////////////////////////////////////////////
    // Initialization
    /////////////////////////////////////////////////////////

    initial
    begin

        for(i=0;i<8;i=i+1)
        begin
            cache_data[i] = 16'd0;
            tag_array[i]  = 6'd0;
            valid[i]      = 1'b0;
        end

        fifo_ptr = 3'd0;

        hit_count    = 0;
        miss_count   = 0;
        access_count = 0;
        stall_cycles = 0;

        hit = 0;
        busy = 0;

        mem_read = 0;
        mem_address = 0;

        data_out = 0;

        saved_address = 0;

        state = IDLE;

    end

    /////////////////////////////////////////////////////////
    // FSM
    /////////////////////////////////////////////////////////

    always @(posedge clk)
    begin

        //---------------------------------------------------
        // RESET
        //---------------------------------------------------

        if(rst)
        begin

            for(i=0;i<8;i=i+1)
            begin
                cache_data[i] <= 16'd0;
                tag_array[i]  <= 6'd0;
                valid[i]      <= 1'b0;
            end

            fifo_ptr <= 3'd0;

            saved_address <= 6'd0;

            hit_count <= 0;
            miss_count <= 0;
            access_count <= 0;
            stall_cycles <= 0;

            hit <= 0;
            busy <= 0;

            mem_read <= 0;
            mem_address <= 0;

            data_out <= 0;

            state <= IDLE;

        end

        else
        begin

            case(state)

            //////////////////////////////////////////////////
            // IDLE
            //////////////////////////////////////////////////

            IDLE:
            begin

                hit <= 0;
                busy <= 0;

                mem_read <= 0;

                if(access_en)
                begin

                    access_count <= access_count + 1;

                    saved_address <= address;

                    busy <= 1'b1;

                    state <= CHECK_HIT;

                end

            end

            //////////////////////////////////////////////////
            // CHECK HIT
            //////////////////////////////////////////////////

            CHECK_HIT:
            begin

                found = 0;
                hit_line = 0;

                //------------------------------------------
                // Search Entire Cache
                //------------------------------------------

                for(i=0;i<8;i=i+1)
                begin

                    if(valid[i] &&
                       tag_array[i] == saved_address)
                    begin

                        found = 1'b1;

                        hit_line = i[2:0];

                    end

                end

                //------------------------------------------
                // HIT
                //------------------------------------------

                if(found)
                begin

                    hit <= 1'b1;

                    hit_count <= hit_count + 1;

                    data_out <= cache_data[hit_line];

                    state <= DONE;

                end

                //------------------------------------------
                // MISS
                //------------------------------------------

                else
                begin

                    hit <= 1'b0;

                    miss_count <= miss_count + 1;

                    state <= MEM_REQUEST;

                end

            end

            //////////////////////////////////////////////////
            // SEND MEMORY REQUEST
            //////////////////////////////////////////////////

            MEM_REQUEST:
            begin

                mem_read <= 1'b1;

                mem_address <= saved_address;

                state <= WAIT_MEMORY;

            end

            //////////////////////////////////////////////////
            // WAIT FOR MEMORY
            //////////////////////////////////////////////////

            WAIT_MEMORY:
            begin

                //------------------------------------------
                // Single Request Pulse
                //------------------------------------------

                mem_read <= 1'b0;

                stall_cycles <= stall_cycles + 1;

                if(mem_ready)
                begin

                    state <= FILL_CACHE;

                end

            end

            //////////////////////////////////////////////////
            // FILL CACHE
            //////////////////////////////////////////////////

            FILL_CACHE:
            begin

                cache_data[fifo_ptr] <= mem_data;

                tag_array[fifo_ptr] <= saved_address;

                valid[fifo_ptr] <= 1'b1;

                data_out <= mem_data;

                //------------------------------------------
                // FIFO Replacement
                //------------------------------------------

                fifo_ptr <= fifo_ptr + 1'b1;

                state <= DONE;

            end

            //////////////////////////////////////////////////
            // DONE
            //////////////////////////////////////////////////

            DONE:
            begin

                busy <= 1'b0;

                hit <= 1'b0;

                state <= IDLE;

            end

            //////////////////////////////////////////////////
            // DEFAULT
            //////////////////////////////////////////////////

            default:
            begin

                state <= IDLE;

            end

            endcase

        end

    end

endmodule