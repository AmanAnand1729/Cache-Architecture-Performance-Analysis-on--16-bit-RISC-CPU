`timescale 1ns/1ps

//////////////////////////////////////////////////////////////////////////////////
// Cache System
//
// cache_type = 0 -> Direct Mapped
// cache_type = 1 -> Fully Associative
// cache_type = 2 -> 2-Way Set Associative
//
//////////////////////////////////////////////////////////////////////////////////

module cache_system
(

    input clk,
    input rst,

    //--------------------------------------------------
    // Cache Selection
    //--------------------------------------------------

    input [1:0] cache_type,

    //--------------------------------------------------
    // CPU Interface
    //--------------------------------------------------

    input mem_read,
    input [5:0] cpu_addr,

    output [15:0] cpu_read_data,
    output cache_busy,

    //--------------------------------------------------
    // Statistics
    //--------------------------------------------------

    output [31:0] hit_count,
    output [31:0] miss_count,
    output [31:0] access_count,
    output [31:0] stall_cycles

);

/////////////////////////////////////////////////////////
// DIRECT CACHE SIGNALS
/////////////////////////////////////////////////////////

wire [15:0] direct_data;
wire direct_busy;

wire direct_mem_read;
wire [5:0] direct_mem_addr;

wire [15:0] direct_mem_data;
wire direct_mem_ready;

wire [31:0] direct_hits;
wire [31:0] direct_misses;
wire [31:0] direct_accesses;
wire [31:0] direct_stalls;

/////////////////////////////////////////////////////////
// FULLY CACHE SIGNALS
/////////////////////////////////////////////////////////

wire [15:0] fully_data;
wire fully_busy;

wire fully_mem_read;
wire [5:0] fully_mem_addr;

wire [15:0] fully_mem_data;
wire fully_mem_ready;

wire [31:0] fully_hits;
wire [31:0] fully_misses;
wire [31:0] fully_accesses;
wire [31:0] fully_stalls;

/////////////////////////////////////////////////////////
// 2-WAY CACHE SIGNALS
/////////////////////////////////////////////////////////

wire [15:0] way2_data;
wire way2_busy;

wire way2_mem_read;
wire [5:0] way2_mem_addr;

wire [15:0] way2_mem_data;
wire way2_mem_ready;

wire [31:0] way2_hits;
wire [31:0] way2_misses;
wire [31:0] way2_accesses;
wire [31:0] way2_stalls;

/////////////////////////////////////////////////////////
// DIRECT CACHE
/////////////////////////////////////////////////////////

cache_direct DIRECT
(
    .clk(clk),
    .rst(rst),

    .access_en(mem_read && (cache_type == 2'd0)),
    .address(cpu_addr),

    .data_out(direct_data),

    .hit(),
    .busy(direct_busy),

    .mem_read(direct_mem_read),
    .mem_address(direct_mem_addr),

    .mem_data(direct_mem_data),
    .mem_ready(direct_mem_ready),

    .hit_count(direct_hits),
    .miss_count(direct_misses),
    .access_count(direct_accesses),
    .stall_cycles(direct_stalls)
);

/////////////////////////////////////////////////////////
// FULLY ASSOCIATIVE CACHE
/////////////////////////////////////////////////////////

cache_fully FULLY
(
    .clk(clk),
    .rst(rst),

    .access_en(mem_read && (cache_type == 2'd1)),
    .address(cpu_addr),

    .data_out(fully_data),

    .hit(),
    .busy(fully_busy),

    .mem_read(fully_mem_read),
    .mem_address(fully_mem_addr),

    .mem_data(fully_mem_data),
    .mem_ready(fully_mem_ready),

    .hit_count(fully_hits),
    .miss_count(fully_misses),
    .access_count(fully_accesses),
    .stall_cycles(fully_stalls)
);

/////////////////////////////////////////////////////////
// 2-WAY CACHE
/////////////////////////////////////////////////////////

cache_2way WAY2
(
    .clk(clk),
    .rst(rst),

    .access_en(mem_read && (cache_type == 2'd2)),
    .address(cpu_addr),

    .data_out(way2_data),

    .hit(),
    .busy(way2_busy),

    .mem_read(way2_mem_read),
    .mem_address(way2_mem_addr),

    .mem_data(way2_mem_data),
    .mem_ready(way2_mem_ready),

    .hit_count(way2_hits),
    .miss_count(way2_misses),
    .access_count(way2_accesses),
    .stall_cycles(way2_stalls)
);

/////////////////////////////////////////////////////////
// SINGLE MAIN MEMORY
/////////////////////////////////////////////////////////

wire mem_read_mux;
wire [5:0] mem_addr_mux;

assign mem_read_mux =
       (cache_type == 2'd0) ? direct_mem_read :
       (cache_type == 2'd1) ? fully_mem_read :
                              way2_mem_read;

assign mem_addr_mux =
       (cache_type == 2'd0) ? direct_mem_addr :
       (cache_type == 2'd1) ? fully_mem_addr :
                              way2_mem_addr;

wire [15:0] shared_mem_data;
wire shared_mem_ready;

main_memory MEM
(
    .clk(clk),
    .rst(rst),

    .read_en(mem_read_mux),
    .address(mem_addr_mux),

    .read_data(shared_mem_data),
    .ready(shared_mem_ready)
);

/////////////////////////////////////////////////////////
// MEMORY RETURN PATH
/////////////////////////////////////////////////////////

assign direct_mem_data = shared_mem_data;
assign fully_mem_data  = shared_mem_data;
assign way2_mem_data   = shared_mem_data;

assign direct_mem_ready = shared_mem_ready;
assign fully_mem_ready  = shared_mem_ready;
assign way2_mem_ready   = shared_mem_ready;

/////////////////////////////////////////////////////////
// OUTPUT MUX
/////////////////////////////////////////////////////////

assign cpu_read_data =
       (cache_type == 2'd0) ? direct_data :
       (cache_type == 2'd1) ? fully_data :
                              way2_data;

assign cache_busy =
       (cache_type == 2'd0) ? direct_busy :
       (cache_type == 2'd1) ? fully_busy :
                              way2_busy;

assign hit_count =
       (cache_type == 2'd0) ? direct_hits :
       (cache_type == 2'd1) ? fully_hits :
                              way2_hits;

assign miss_count =
       (cache_type == 2'd0) ? direct_misses :
       (cache_type == 2'd1) ? fully_misses :
                              way2_misses;

assign access_count =
       (cache_type == 2'd0) ? direct_accesses :
       (cache_type == 2'd1) ? fully_accesses :
                              way2_accesses;

assign stall_cycles =
       (cache_type == 2'd0) ? direct_stalls :
       (cache_type == 2'd1) ? fully_stalls :
                              way2_stalls;
                              
                     /*         always @(posedge clk)
begin
    $display(
      "CACHE_SYS mem_read=%b cache_type=%d cpu_addr=%d",
      mem_read,
      cache_type,
      cpu_addr
    );
end*/

endmodule