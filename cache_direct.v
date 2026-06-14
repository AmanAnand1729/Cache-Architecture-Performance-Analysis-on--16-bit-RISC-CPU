`timescale 1ns/1ps

//////////////////////////////////////////////////////////////////////////////////
// Direct Mapped Cache
//
// Cache Lines : 8
// Block Size  : 1 Word
//
// Address Format
// ----------------
// Address[5:3] = Tag
// Address[2:0] = Index
//
//////////////////////////////////////////////////////////////////////////////////

module cache_direct(

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

    reg [2:0] tag_array [0:7];

    reg valid [0:7];

    /////////////////////////////////////////////////////////
    // Saved Request
    /////////////////////////////////////////////////////////

    reg [5:0] saved_address;

    wire [2:0] saved_tag;
    wire [2:0] saved_index;

    assign saved_tag   = saved_address[5:3];
    assign saved_index = saved_address[2:0];

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

    integer i;

    initial
    begin

        for(i=0;i<8;i=i+1)
        begin
            cache_data[i] = 16'd0;
            tag_array[i]  = 3'd0;
            valid[i]      = 1'b0;
        end

        hit_count    = 0;
        miss_count   = 0;
        access_count = 0;
        stall_cycles = 0;

        hit = 0;
        busy = 0;

        mem_read = 0;
        mem_address = 0;

        data_out = 0;

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
                tag_array[i]  <= 3'd0;
                valid[i]      <= 1'b0;
            end

            hit_count    <= 0;
            miss_count   <= 0;
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

                if(valid[saved_index] &&
                   tag_array[saved_index] == saved_tag)
                begin

                    //----------------------------------------
                    // CACHE HIT
                    //----------------------------------------

                    hit <= 1'b1;

                    hit_count <= hit_count + 1;

                    data_out <= cache_data[saved_index];

                    state <= DONE;

                end

                else
                begin

                    //----------------------------------------
                    // CACHE MISS
                    //----------------------------------------

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

    //---------------------------------------
    // Generate only a single-cycle request
    //---------------------------------------

    mem_read <= 1'b0;

    //---------------------------------------
    // Count stall cycles
    //---------------------------------------

    stall_cycles <= stall_cycles + 1;

    //---------------------------------------
    // Wait for memory response
    //---------------------------------------

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

                cache_data[saved_index] <= mem_data;

                tag_array[saved_index] <= saved_tag;

                valid[saved_index] <= 1'b1;

                data_out <= mem_data;

                state <= DONE;

            end

            //////////////////////////////////////////////////
            // COMPLETE REQUEST
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