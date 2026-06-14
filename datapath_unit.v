`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Datapath Unit
//
// Integrated With:
//
// cache_system
//
// Supports:
// cache_type = 0 -> Direct
// cache_type = 1 -> Fully Associative
// cache_type = 2 -> 2-Way Set Associative
//
//////////////////////////////////////////////////////////////////////////////////

module Datapath_Unit(

input clk,
input rst,

input [1:0] cache_type,

input jump,
input beq,
input mem_read,
input mem_write,
input alu_src,
input reg_dst,
input mem_to_reg,
input reg_write,
input bne,

input [1:0] alu_op,
input [1:0] pattern_select,
output [3:0] opcode,

output [31:0] hit_count_out,
output [31:0] miss_count_out,
output [31:0] total_access_out,
output [31:0] stall_cycles_out,
output [31:0] cycle_count_out,
output [31:0] instruction_count_out
);
reg [31:0] cycle_count;
reg [31:0] instruction_count;
////////////////////////////////////////////////////////////
// PC
////////////////////////////////////////////////////////////

reg [15:0] pc_current;

wire [15:0] pc_next;
wire [15:0] pc2;

////////////////////////////////////////////////////////////
// Instruction
////////////////////////////////////////////////////////////

wire [15:0] instr;

////////////////////////////////////////////////////////////
// Register File
////////////////////////////////////////////////////////////

wire [2:0] reg_write_dest;

wire [15:0] reg_write_data;

wire [2:0] reg_read_addr_1;
wire [2:0] reg_read_addr_2;

wire [15:0] reg_read_data_1;
wire [15:0] reg_read_data_2;

////////////////////////////////////////////////////////////
// ALU
////////////////////////////////////////////////////////////

wire [15:0] ext_im;
wire [15:0] read_data2;

wire [2:0] ALU_Control;

wire [15:0] ALU_out;

wire zero_flag;

////////////////////////////////////////////////////////////
// Branch Logic
////////////////////////////////////////////////////////////

wire [15:0] PC_j;
wire [15:0] PC_beq;
wire [15:0] PC_bne;
wire [15:0] PC_2beq;
wire [15:0] PC_2bne;

wire beq_control;
wire bne_control;

wire [12:0] jump_shift;

////////////////////////////////////////////////////////////
// Cache Signals
////////////////////////////////////////////////////////////

wire [15:0] cache_read_data;

wire cache_busy;

wire [31:0] hit_count;
wire [31:0] miss_count;
wire [31:0] total_access;
wire [31:0] stall_cycles;


////////////////////////////////////////////////////////////
// Memory Request Pulse Generation
////////////////////////////////////////////////////////////

reg mem_read_d;

wire mem_read_pulse;

////////////////////////////////////////////////////////////
// PC Logic
////////////////////////////////////////////////////////////

initial
begin
    pc_current = 16'd0;
end

always @(posedge clk)
begin

    if(rst)
        pc_current <= 16'd0;

    else if(!cache_busy)
        pc_current <= pc_next;

end

assign pc2 = pc_current + 16'd2;

always @(posedge clk)
begin

    if(rst)
        mem_read_d <= 1'b0;

    else
        mem_read_d <= mem_read;

end
assign mem_read_pulse =
       mem_read & ~mem_read_d;

////////////////////////////////////////////////////////////
// Instruction Memory
////////////////////////////////////////////////////////////

Instruction_Memory im(
    .pc(pc_current),
    .pattern_select(pattern_select),
    .instruction(instr)
);
////////////////////////////////////////////////////////////
// Register Selection
////////////////////////////////////////////////////////////

assign reg_write_dest =
        (reg_dst) ?
        instr[5:3] :
        instr[8:6];

assign reg_read_addr_1 = instr[11:9];
assign reg_read_addr_2 = instr[8:6];

////////////////////////////////////////////////////////////
// Register File
////////////////////////////////////////////////////////////

GPRs reg_file
(
    .clk(clk),

    .reg_write_en(reg_write),

    .reg_write_dest(reg_write_dest),

    .reg_write_data(reg_write_data),

    .reg_read_addr_1(reg_read_addr_1),

    .reg_read_data_1(reg_read_data_1),

    .reg_read_addr_2(reg_read_addr_2),

    .reg_read_data_2(reg_read_data_2)
);

////////////////////////////////////////////////////////////
// Sign Extension
////////////////////////////////////////////////////////////

assign ext_im =
{
    {10{instr[5]}},
    instr[5:0]
};

////////////////////////////////////////////////////////////
// ALU Control
////////////////////////////////////////////////////////////

alu_control ALU_Control_unit
(
    .ALUOp(alu_op),

    .Opcode(instr[15:12]),

    .ALU_Cnt(ALU_Control)
);

////////////////////////////////////////////////////////////
// ALU Source MUX
////////////////////////////////////////////////////////////

assign read_data2 =
       (alu_src) ?
       ext_im :
       reg_read_data_2;

////////////////////////////////////////////////////////////
// ALU
////////////////////////////////////////////////////////////

ALU alu_unit
(
    .a(reg_read_data_1),

    .b(read_data2),

    .alu_control(ALU_Control),

    .result(ALU_out),

    .zero(zero_flag)
);

////////////////////////////////////////////////////////////
// Branch Logic
////////////////////////////////////////////////////////////

assign PC_beq =
       pc2 + {ext_im[14:0],1'b0};

assign PC_bne =
       pc2 + {ext_im[14:0],1'b0};

assign beq_control =
       beq & zero_flag;

assign bne_control =
       bne & (~zero_flag);

assign PC_2beq =
       (beq_control) ?
       PC_beq :
       pc2;

assign PC_2bne =
       (bne_control) ?
       PC_bne :
       PC_2beq;

////////////////////////////////////////////////////////////
// Jump Logic
////////////////////////////////////////////////////////////

assign jump_shift =
{
    instr[11:0],
    1'b0
};

assign PC_j =
{
    pc2[15:13],
    jump_shift
};

////////////////////////////////////////////////////////////
// PC Next
////////////////////////////////////////////////////////////

assign pc_next =
       (pc_current >= 16'd28) ?
       16'd0 :
       ((jump) ? PC_j : PC_2bne);

////////////////////////////////////////////////////////////
// CACHE SYSTEM
////////////////////////////////////////////////////////////

cache_system CACHE
(
    .clk(clk),
    .rst(rst),

    .cache_type(cache_type),

   // .mem_read(mem_read_pulse),
 .mem_read(mem_read),
    .cpu_addr(ALU_out[5:0]),

    .cpu_read_data(cache_read_data),

    .cache_busy(cache_busy),

    .hit_count(hit_count),

    .miss_count(miss_count),

    .access_count(total_access),

    .stall_cycles(stall_cycles)
);
/*always @(posedge clk)
begin
    if(mem_read)
    begin
        $display(
        "Time=%0t PC=%d Opcode=%b ALU_out=%d",
        $time,
        pc_current,
        opcode,
        ALU_out
        );
    end
end*/
////////////////////////////////////////////////////////////
// WRITE BACK
////////////////////////////////////////////////////////////

assign reg_write_data =
       (mem_to_reg) ?
       cache_read_data :
       ALU_out;

////////////////////////////////////////////////////////////
// Statistics Outputs
////////////////////////////////////////////////////////////

assign hit_count_out    = hit_count;
assign miss_count_out   = miss_count;
assign total_access_out = total_access;
assign stall_cycles_out = stall_cycles;

////////////////////////////////////////////////////////////
// Opcode
////////////////////////////////////////////////////////////

assign opcode = instr[15:12];
/*always @(posedge clk)
begin
    $display(
    "PC=%d ALU=%d mem_read=%b busy=%b",
    pc_current,
    ALU_out,
    mem_read,
    cache_busy
    );
end*/
/*always @(posedge clk)
begin
    $display(
      "Instr=%b Opcode=%b Rs=%d Rt=%d Imm=%d ALU=%d",
      instr,
      instr[15:12],
      instr[11:9],
      instr[8:6],
      instr[5:0],
      ALU_out
    );
end*/
endmodule