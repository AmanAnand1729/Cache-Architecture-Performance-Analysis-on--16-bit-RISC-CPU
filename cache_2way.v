`timescale 1ns/1ps

//////////////////////////////////////////////////////////////////////////////////
// 2-Way Set Associative Cache
//
// Total Lines : 8
// Sets        : 4
// Ways/Set    : 2
//
// Address Format
// ----------------
// Address[5:2] = Tag
// Address[1:0] = Set
//
// Replacement Policy : LRU
//
//////////////////////////////////////////////////////////////////////////////////

module cache_2way(

    input clk,
    input rst,

    /////////////////////////////////////////////////////////
    // CPU Interface
    /////////////////////////////////////////////////////////

    input access_en,
    input [5:0] address,

    output reg [15:0] data_out,

    output reg hit,
    output reg busy,

    /////////////////////////////////////////////////////////
    // Memory Interface
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
    // Cache Arrays
    /////////////////////////////////////////////////////////

    reg [15:0] cache_data [0:3][0:1];

    reg [3:0] tag_array [0:3][0:1];

    reg valid [0:3][0:1];

    /////////////////////////////////////////////////////////
    // LRU Bit Per Set
    /////////////////////////////////////////////////////////

    reg lru [0:3];

    /////////////////////////////////////////////////////////
    // Saved Request
    /////////////////////////////////////////////////////////

    reg [5:0] saved_address;

    wire [3:0] saved_tag;
    wire [1:0] saved_set;

    assign saved_tag = saved_address[5:2];
    assign saved_set = saved_address[1:0];

    /////////////////////////////////////////////////////////
    // Hit Detection
    /////////////////////////////////////////////////////////

    wire hit_way0;
wire hit_way1;

assign hit_way0 =
       valid[saved_set][0] &&
       (tag_array[saved_set][0] == saved_tag);

assign hit_way1 =
       valid[saved_set][1] &&
       (tag_array[saved_set][1] == saved_tag);
    /////////////////////////////////////////////////////////
    // FSM States
    /////////////////////////////////////////////////////////

    localparam IDLE        = 3'd0;
    localparam CHECK_HIT   = 3'd1;
    localparam MEM_REQUEST = 3'd2;
    localparam WAIT_MEMORY = 3'd3;
    localparam FILL_CACHE  = 3'd4;
    localparam DONE        = 3'd5;

    reg [2:0] state;

    integer i,j;

    /////////////////////////////////////////////////////////
    // Initialization
    /////////////////////////////////////////////////////////

    initial
    begin

        for(i=0;i<4;i=i+1)
        begin

            for(j=0;j<2;j=j+1)
            begin

                cache_data[i][j] = 0;
                tag_array[i][j]  = 0;
                valid[i][j]      = 0;

            end

            lru[i] = 0;

        end

        saved_address = 0;

        hit_count = 0;
        miss_count = 0;
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

        if(rst)
        begin

            for(i=0;i<4;i=i+1)
            begin

                for(j=0;j<2;j=j+1)
                begin

                    cache_data[i][j] <= 0;
                    tag_array[i][j] <= 0;
                    valid[i][j] <= 0;

                end

                lru[i] <= 0;

            end

            saved_address <= 0;

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

               if(access_en )
                begin

                    access_count <= access_count + 1;

                    saved_address <= address;

                    busy <= 1;

                    state <= CHECK_HIT;

                end

            end

            //////////////////////////////////////////////////
            // CHECK HIT
            //////////////////////////////////////////////////

            CHECK_HIT:
            begin

              
                //------------------------------------------
                // HIT WAY0
                //------------------------------------------

                if(hit_way0)
                begin

                    hit <= 1;

                    hit_count <= hit_count + 1;

                    data_out <= cache_data[saved_set][0];

                    lru[saved_set] <= 1;

                    state <= DONE;

                end
                // In CHECK_HIT, on hit:
/*    hit      <= 1;
    busy     <= 0;   // clear busy here
    data_out <= cache_data[saved_set][0];
    lru[saved_set] <= 1;
    state    <= IDLE; // skip DONE
end
*/
                //------------------------------------------
                // HIT WAY1
                //------------------------------------------

                else if(hit_way1)
                begin

                    hit <= 1;

                    hit_count <= hit_count + 1;

                    data_out <= cache_data[saved_set][1];

                    lru[saved_set] <= 0;

                    state <= DONE;

                end

                //------------------------------------------
                // MISS
                //------------------------------------------

                else
                begin

                    hit <= 0;

                    miss_count <= miss_count + 1;

                    state <= MEM_REQUEST;

                end

            end


            //////////////////////////////////////////////////
            // MEMORY REQUEST
            //////////////////////////////////////////////////

            MEM_REQUEST:
            begin

                mem_read <= 1'b1;

                mem_address <= saved_address;

                state <= WAIT_MEMORY;

            end

            //////////////////////////////////////////////////
            // WAIT MEMORY
            //////////////////////////////////////////////////

            WAIT_MEMORY:
            begin

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

    //------------------------------------------
    // First use empty way if available
    //------------------------------------------

    if(!valid[saved_set][0])
    begin

        cache_data[saved_set][0] <= mem_data;
        tag_array[saved_set][0]  <= saved_tag;
        valid[saved_set][0]      <= 1'b1;

        lru[saved_set] <= 1'b1;

    end

    else if(!valid[saved_set][1])
    begin

        cache_data[saved_set][1] <= mem_data;
        tag_array[saved_set][1]  <= saved_tag;
        valid[saved_set][1]      <= 1'b1;

        lru[saved_set] <= 1'b0;

    end

    //------------------------------------------
    // Both ways full -> LRU replacement
    //------------------------------------------

    else if(lru[saved_set] == 0)
    begin

        cache_data[saved_set][0] <= mem_data;
        tag_array[saved_set][0]  <= saved_tag;
        valid[saved_set][0]      <= 1'b1;

        lru[saved_set] <= 1'b1;

    end

    else
    begin

        cache_data[saved_set][1] <= mem_data;
        tag_array[saved_set][1]  <= saved_tag;
        valid[saved_set][1]      <= 1'b1;

        lru[saved_set] <= 1'b0;

    end

    data_out <= mem_data;

    state <= DONE;

end

            //////////////////////////////////////////////////
            // DONE
            //////////////////////////////////////////////////

         DONE:
begin
    busy <= 0;
    state <= IDLE;
end

            default:
                state <= IDLE;

            endcase

        end

    end
  /*  always @(posedge clk)
begin
    $display(
      "CACHE access_en=%b state=%d access_count=%d addr=%d",
      access_en,
      state,
      access_count,
      address
    );
end
always @(posedge clk)
begin
    $display(
      "CACHE2 access_en=%b addr=%d",
      access_en,
      address
    );
end
always @(posedge clk)
begin
    $display(
      "ADDR=%d SET=%d TAG=%d",
      saved_address,
      saved_set,
      saved_tag
    );
end
*/
endmodule