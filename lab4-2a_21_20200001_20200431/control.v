// Custom file for PC, Control unit and ImmediateGenerator

`include "opcodes.v"

// HB
module PC(
    input reset,       // input (Use reset to initialize PC. Initial value must be 0)
    input clk,
    input [31:0] next_pc,
    input HDU_out,
    output reg [31:0] current_pc //output reg -> output
    );
    
    //reg [31:0] current_pc_reg;
    //assign current_pc = current_pc_reg;
    
    always @(posedge clk) begin
    	if(reset) begin
		// 0 to 32'b0
	    	current_pc <= 32'b0;
	   end
    	else begin
    	   if(HDU_out == 0) begin
    			current_pc <= next_pc;
    		end
    	end
    end

endmodule

module add_4(
input[31:0] current_pc,
output reg [31:0] next_pc
);

 always @(*) begin
    next_pc = current_pc + 4;
 end

endmodule
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
		pc_to_reg = 1;
	end
	else begin
		pc_to_reg = 0;
	end

	// write_enable -> Register's write enable bit
	// not S-type, not SB-type
	if(part_of_inst != `STORE && part_of_inst != `BRANCH) begin
		write_enable = 1'b1;
	end
	else begin
		write_enable = 0;
	end

	// alu_src -> MUX that determines which would be input for ALU
	// not R-type, not SB-type
	if(part_of_inst != `ARITHMETIC && part_of_inst != `BRANCH) begin
		alu_src = 1;
	end
	else begin
		alu_src = 0;
	end

	// mem_write -> Data memory, store?
	// S-type
	if(part_of_inst == `STORE) begin
		mem_write = 1;
	end
	else begin
		mem_write = 0;
	end

	// mem_to_reg -> MUX that determines which would be input for write data(ALU output or Data memory output)
	// L-type
	if(part_of_inst == `LOAD) begin
		mem_to_reg = 1;
	end
	else begin
		mem_to_reg = 0;
	end

	// mem_read -> Data memory, read?
	// L-type
	if(part_of_inst == `LOAD) begin
		mem_read = 1;
	end
	else begin
		mem_read = 0;
	end

	// branch -> is B-type
	if(part_of_inst == `BRANCH) begin
		branch = 1;
	end
	else begin
		branch = 0;
	end

	if(part_of_inst == `JAL) begin
		is_jal = 1;
	end
	else begin
		is_jal = 0;
	end

	// is_jalr -> jalr
	if(part_of_inst == `JALR) begin
		is_jalr = 1;
	end
	else begin
		is_jalr = 0;
	end

	// is_ecall
	//22.03.27 20:00
	if(part_of_inst == `ECALL) begin
		is_ecall = 1;
	end
	else begin
		is_ecall = 0;
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


module ControlFlowUnit(
  input branch,
  input jalr,
  input jal,
  input bcond,
  output reg [1:0] out1,
  output reg [1:0] out2
);

always @(*) begin

    if((branch & bcond) | jal) begin
        out1 = 2'b00;
    end

    else if(jalr) begin
    out1 = 2'b01;
    end

    else if(branch & (!bcond)) begin
        out1 = 2'b10;
    end

    else begin
        out1 = 2'b11;
    end

    if(branch | jal) begin
        out2 = 2'b00;
    end

    else if(jalr) begin
        out2 = 2'b01;
    end
    
    else begin
        out2 = 2'b10;
    end
    
end

endmodule


module BTB(
  input clk,
  input reset,
  input [31:0] addr1,           //current_pc
  input [31:0] addr2,           //ID_EX_PC
  input [1:0] control,
  input [31:0] input1,          //PC_alu_result
  input [31:0] input2,          //alu_result
  output [31:0] out1,
  output out2
);
integer i;
wire [4:0] index1;
wire [4:0] index2;
wire [26:0] tag1;
wire [26:0] tag2;
reg [31:0] BTB[0:31];
reg [26:0] tag[0:31];

assign index1 = addr1[4:0];
assign index2 = addr2[4:0];
assign tag1 = addr1[31:5];
assign tag2 = addr2[31:5];
assign out1 = BTB[index1];
assign out2 = (tag1 == tag[index1]);

always @(posedge clk) begin
    if(reset) begin
        for(i = 0; i<32; i = i+1) begin
            BTB[i] = 32'b0;
            tag[i] = 26'b11111111111111111111111111;
        end
    end
    else begin
        if(control == 2'b00) begin
                //JAL, B-type
            BTB[index2] <= input1;
            tag[index2] <= tag2;
        end
        else if(control == 2'b01) begin
                //JALR
            BTB[index2] <= input2;
            tag[index2] <= tag2;
        end
    end
end

endmodule