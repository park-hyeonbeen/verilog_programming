// Custom file for PC, Control unit and ImmediateGenerator

`include "opcodes.v"

// HB
module PC( input reset,       // input (Use reset to initialize PC. Initial value must be 0)
    input clk,
    // changed to [31:0]
    input [31:0] next_pc,
    output [31:0] current_pc //changed from output reg to output
    );

    reg [31:0] current_pc_reg;
    assign current_pc = current_pc_reg;
    always @(posedge clk) begin
    	if(reset) begin
		// 0 to 32'b0
	    	current_pc_reg <= 32'b0;
	end
    
    	else begin
    		current_pc_reg <= next_pc;
    	end
    end
endmodule

// HB modified arbitrarily
// 22.03.26 17:00 Eun
module ControlUnit(
    input [6:0] part_of_inst,
    output reg is_jal,
    output reg is_jalr,
    output reg branch,
    output reg mem_read,
    output reg mem_to_reg,
    output reg mem_write,
    output reg alu_src,
    output reg write_enable,
    output reg pc_to_reg,
    output reg is_ecall
    );

    always @(*) begin
	// pc_to_reg -> MUX that determines which would be input for write data(ALU output or PC)
	// JAL/JALR-type
	if(part_of_inst == `JALR || part_of_inst == `JAL) begin
		pc_to_reg = 1;//nonblocking to blocking
	end
	else begin
		pc_to_reg = 0;//nonblocking to blocking
	end

	// write_enable -> Register's write enable bit
	// not S-type, not SB-type
	if(part_of_inst != `STORE && part_of_inst != `BRANCH) begin
		write_enable = 1'b1;//nonblocking to blocking
	end
	else begin
		write_enable = 0;//nonblocking to blocking
	end

	// alu_src -> MUX that determines which would be input for ALU
	// not R-type, not SB-type
	if(part_of_inst != `ARITHMETIC && part_of_inst != `BRANCH) begin
		alu_src = 1;//nonblocking to blocking
	end
	else begin
		alu_src = 0;//nonblocking to blocking
	end

	// mem_write -> Data memory, store?
	// S-type
	if(part_of_inst == `STORE) begin
		mem_write = 1;//nonblocking to blocking
	end
	else begin
		mem_write = 0;//nonblocking to blocking
	end

	// mem_to_reg -> MUX that determines which would be input for write data(ALU output or Data memory output)
	// L-type
	if(part_of_inst == `LOAD) begin
		mem_to_reg = 1;//nonblocking to blocking
	end
	else begin
		mem_to_reg = 0;//nonblocking to blocking
	end

	// mem_read -> Data memory, read?
	// L-type
	if(part_of_inst == `LOAD) begin
		mem_read = 1;//nonblocking to blocking
	end
	else begin
		mem_read = 0;//nonblocking to blocking
	end

	// branch -> is B-type
	if(part_of_inst == `BRANCH) begin
		branch = 1;//nonblocking to blocking
	end
	else begin
		branch = 0;//nonblocking to blocking
	end

	// is_jal -> JAL
	if(part_of_inst == `JAL) begin
		is_jal = 1;//nonblocking to blocking
	end
	else begin
		is_jal = 0;//nonblocking to blocking
	end

	// is_jalr -> jalr
	if(part_of_inst == `JALR) begin
		is_jalr = 1;//nonblocking to blocking
	end
	else begin
		is_jalr = 0;//nonblocking to blocking
	end

	// is_ecall
	//22.03.27 20:00
	if(part_of_inst == `ECALL) begin
		is_ecall = 1;//nonblocking to blocking
	end
	else begin
		is_ecall = 0;//nonblocking to blocking
	end
   end
	
endmodule

// 22.03.26 20:45 Eun
module ImmediateGenerator(
    input [31:0]part_of_inst,
    output reg [31:0]imm_gen_out
  );

   wire [6:0] opcode;
   reg [12:0] immvalue;

   assign opcode = part_of_inst[6:0];

   always @(*) begin
	immvalue = 0;
	
	// I-type
	if(opcode == `LOAD || opcode == `ARITHMETIC_IMM || opcode == `JALR) begin
		immvalue[11:0] = part_of_inst[31:20];
		imm_gen_out = { { 20{immvalue[11]} }, immvalue[11:0] };
	end

	// S-type
	if(opcode == `STORE) begin
		immvalue[11:0] = { part_of_inst[31:25], part_of_inst[11:7] };
		imm_gen_out = { { 20{immvalue[11]} }, immvalue[11:0] };
	end

	// SB-type
	if(opcode == `BRANCH) begin
		immvalue[12:0] = { part_of_inst[31], part_of_inst[7], part_of_inst[30:25], part_of_inst[11:8], 1'b0 };
		imm_gen_out = { { 20{immvalue[12]} }, immvalue[11:0] };
	end

	// UJ-type
	if(opcode == `JAL) begin
		imm_gen_out = { { 12{part_of_inst[31]} }, part_of_inst[19:12], part_of_inst[20], part_of_inst[30:21], 1'b0 };
	end

	// U-type
	if(opcode == 7'b0110111) begin
		imm_gen_out = { part_of_inst[31:12], 12'b0 };
	end
   end

endmodule
