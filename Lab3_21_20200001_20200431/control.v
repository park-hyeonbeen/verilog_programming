// from SingleCycle

// Custom file for PC, Control unit and ImmediateGenerator

`include "opcodes.v"

// HB
// (22.04.17, 4:00)add PCcontinue
module PC(
    input reset,       // input (Use reset to initialize PC. Initial value must be 0)
    input clk,
    input [31:0] next_pc,
    input PCcontinue,
    output reg [31:0] current_pc //output reg -> output
    );
    
    //reg [31:0] current_pc_reg;
    //assign current_pc = current_pc_reg;
    
    always @(posedge clk) begin
    	if(reset) begin
		// 0 to 32'b0
	    	current_pc <= 0;
	   end
    	else begin
    	   if(PCcontinue == 1) begin
    			current_pc <= next_pc;
    		end
		end
    end

endmodule

// 22.04.17 00:54 Eun
// state/control bit determining
module ControlUnit(
    input [6:0] part_of_inst,
    input clk,
    input reset,
    input [4:0] Curr_State_in,
    input bcond,
    output [4:0] Next_State_out
    );

    reg [4:0] Curr_State;
    reg [4:0] Next_State;
    reg [6:0] opcode;
    assign Next_State_out = Next_State;
    // bit-setting for each state
   
    //next-state, transition
    
   always @(*) begin
    Curr_State <= Curr_State_in;
    opcode <= part_of_inst;
    
	if(reset) begin
		// 0 to 32'b0
	    	Next_State <= 5'b01111;
	end
	else if(Curr_State == 5'b01111) begin
	    	Next_State <= 5'b00001;
	   end
	else if(Curr_State == 5'b00000 || Next_State == 5'b10000 || Next_State == 5'b10001) begin
	    	Next_State <= 5'b01111;
	   end

	else if(Curr_State == 5'b00001) begin
		if((opcode == `LOAD) || (opcode == 7'b0100011)) begin
			Next_State <= 5'b00010;
		end
		else if(opcode == `ARITHMETIC) begin
			Next_State <= 5'b00110;
		end
		else if(opcode == `BRANCH) begin
			Next_State <= 5'b10010;
		end
		else if(opcode == `JAL || opcode == `JALR) begin
			Next_State <= 5'b01001;
		end
		else if(opcode == `ARITHMETIC_IMM) begin
			Next_State <= 5'b01010;
		end
	end

	else if(Curr_State == 5'b00010) begin
		if(opcode == `LOAD) begin
	    		Next_State <= 5'b00011;
		end
		else if(opcode == `STORE) begin
	    		Next_State <= 5'b00101;
		end
	end

	else if(Curr_State == 5'b00011) begin
	    	Next_State <= 5'b00100;
	end

	else if(Curr_State == 5'b00110) begin
	    	Next_State <= 5'b00111;
	end

	else if(Curr_State == 5'b01010) begin
	    	Next_State <= 5'b01100;
	end
	else if( Curr_State == 5'b01001) begin
	        if(opcode == `JAL) begin
	            Next_State <= 5'b01011;
	        end
	        else if(opcode == `JALR) begin
	            Next_State <= 5'b01101;
	        end
	end
	else if(Curr_State == 5'b01000) begin
	       if(bcond == 1) begin
	           Next_State = 5'b01110;
	       end
	       else if(bcond == 0) begin
	           Next_State = 5'b00000;
	       end
	end
	else if(Curr_State == 5'b01011 || Curr_State == 4'b01110) begin
	   Next_State = 5'b10000;
	end 
	else if(Curr_State == 5'b01101) begin
	   Next_State = 5'b10001;
	end
	else if(Curr_State ==5'b10010) begin
	   Next_State = 5'b01000;
	end
	else if(Curr_State == 5'b00100 || Curr_State == 5'b00101 || Curr_State == 5'b00111 || Curr_State == 5'b01100 ) begin
	    	Next_State <= 4'b00000;
	end

   end
	
endmodule


module ControlUnit2(
    input [4:0] Next_State,
    input [6:0] part_of_inst,
    input clk,
    input reset,
    output reg PCWriteCond,
    output reg PCWrite,
    output reg IorD,
    output reg MemRead,
    output reg MemWrite,
    output reg MemtoReg,
    output reg IRWrite,
    output reg PCSource,
    output reg [1:0] ALUOp,
    output reg AluSrcA,
    output reg [1:0] AluSrcB,
    output reg RegWrite,
    output reg RegDst,
    output reg is_ecall,
    output [4:0] Curr_State
    );
    
    
    reg [4:0] Curr_State_reg;

    
     always @(negedge clk) begin
        Curr_State_reg <= Next_State;
     
	if(part_of_inst == `ECALL) begin
		is_ecall <= 1;
	end
	else begin
		is_ecall <= 0;
	end

	// Complement of 'PCWriteCond' form FSM, state8
	if(Next_State == 5'b01000) begin
		PCWriteCond <= 1;
	end
	else begin
		PCWriteCond <= 0;
	end
 	

	if(Next_State == 5'b00000 || Next_State == 5'b10000 || Next_State == 5'b10001) begin
		PCWrite <= 1;
	end
	else begin
		PCWrite <= 0;
	end
 	

	if(Next_State == 5'b00011 || Next_State == 5'b00101) begin
		IorD <= 1;
	end
	else begin
		IorD <= 0;
	end
 	

	if(Next_State == 5'b00000 || Next_State == 5'b00011 || Next_State == 5'b01111 || Next_State == 5'b00001 || Next_State == 5'b10000 || Next_State == 5'b10001 || Next_State == 5'b10010 ) begin
		MemRead <= 1;
	end
	else begin
		MemRead <= 0;
	end
 	

	if(Next_State == 5'b00101) begin
		MemWrite <= 1;
	end
	else begin
		MemWrite <= 0;
	end
 	

	if(Next_State == 5'b00100) begin
		MemtoReg <= 1;
	end
	else begin
		MemtoReg <= 0;
	end
 	

	if(Next_State == 5'b00000 || Next_State == 5'b01111 || Next_State == 5'b00001 || Next_State == 5'b10000 || Next_State == 5'b10001 || Next_State == 5'b10010 ) begin
		IRWrite <= 1;
	end
	else begin
		IRWrite <= 0;
	end
 	

	if(Next_State == 5'b01000) begin
		PCSource <= 1;
	end
	else begin
		PCSource <= 0;
	end
 	

	if(Next_State == 5'b01000) begin
		ALUOp <= 2'b01;
	end
	else if(Next_State == 5'b00110 || Next_State == 5'b01010) begin
		ALUOp <= 2'b10;
	end
	else begin
		ALUOp <= 2'b00;
	end
 	

	if(Next_State == 5'b00000 || Next_State == 5'b01100 || Next_State == 5'b01111 || Next_State == 5'b01001) begin
		AluSrcB <= 2'b01;
	end
	else if(Next_State == 5'b00001 || Next_State == 5'b00010 || Next_State == 5'b01010 || Next_State == 5'b01011 || Next_State == 5'b01101 || Next_State == 5'b01110 || Next_State == 5'b10000 || Next_State == 5'b10001) begin
		AluSrcB <= 2'b10;
	end
	else if(Next_State == 5'b10010) begin
	    AluSrcB <= 2'b11;
	end 
	else begin
		AluSrcB <= 2'b00;
	end
 	

	if(Next_State == 5'b00010 || Next_State == 5'b00110 || Next_State == 5'b01000 || Next_State == 5'b01010 || Next_State == 5'b10001) begin
		AluSrcA <= 1;
	end
	else begin
		AluSrcA <= 0;
	end
 	

	if(Next_State == 5'b00100 || Next_State == 5'b00111 || Next_State == 5'b01100 || Next_State == 5'b01011 || Next_State == 5'b01101) begin
		RegWrite <= 1;
	end
	else begin
		RegWrite <= 0;
	end
 	

	if(Next_State == 5'b00111 || Next_State == 5'b01011 || Next_State == 5'b01101) begin
		RegDst <= 1;
	end
	else begin
		RegDst <= 0;
	end
    end

    assign Curr_State = Curr_State_reg;
    
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
	else if(opcode == `STORE) begin
		immvalue[11:0] = { part_of_inst[31:25], part_of_inst[11:7] };
		imm_gen_out = { { 20{immvalue[11]} }, immvalue[11:0] };
	end

	// SB-type
	else if(opcode == `BRANCH) begin
		immvalue[12:0] = { part_of_inst[31], part_of_inst[7], part_of_inst[30:25], part_of_inst[11:8], 1'b0 };
		imm_gen_out = { { 20{immvalue[12]} }, immvalue[11:0] };
	end

	// UJ-type
	else if(opcode == `JAL) begin
		imm_gen_out = { { 12{part_of_inst[31]} }, part_of_inst[19:12], part_of_inst[20], part_of_inst[30:21], 1'b0 };
	end

	// U-type
	else if(opcode == 7'b0110111) begin
		imm_gen_out = { part_of_inst[31:12], 12'b0 };
	end
	
	else begin
	   imm_gen_out = 0;
	end
   end

endmodule


// 22.03.26 17:00 Eun
// For SingleCycle CPU
/* module ControlUnit(
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
		pc_to_reg <= 1;
	end
	else begin
		pc_to_reg <= 0;
	end

	// write_enable -> Register's write enable bit
	// not S-type, not SB-type
	if(part_of_inst != `STORE && part_of_inst != `BRANCH) begin
		write_enable <= 1'b1;
	end
	else begin
		write_enable <= 0;
	end

	// alu_src -> MUX that determines which would be input for ALU
	// not R-type, not SB-type
	if(part_of_inst != `ARITHMETIC && part_of_inst != `BRANCH) begin
		alu_src <= 1;
	end
	else begin
		alu_src <= 0;
	end

	// mem_write -> Data memory, store?
	// S-type
	if(part_of_inst == `STORE) begin
		mem_write <= 1;
	end
	else begin
		mem_write <= 0;
	end

	// mem_to_reg -> MUX that determines which would be input for write data(ALU output or Data memory output)
	// L-type
	if(part_of_inst == `LOAD) begin
		mem_to_reg <= 1;
	end
	else begin
		mem_to_reg <= 0;
	end

	// mem_read -> Data memory, read?
	// L-type
	if(part_of_inst == `LOAD) begin
		mem_read <= 1;
	end
	else begin
		mem_read <= 0;
	end

	// branch -> is B-type
	if(part_of_inst == `BRANCH) begin
		branch <= 1;
	end
	else begin
		branch <= 0;
	end

	// is_jal -> JAL
	if(part_of_inst == `JAL) begin
		is_jal <= 1;
	end
	else begin
		is_jal <= 0;
	end

	// is_jalr -> jalr
	if(part_of_inst == `JALR) begin
		is_jalr <= 1;
	end
	else begin
		is_jalr <= 0;
	end

	// is_ecall
	//22.03.27 20:00
	if(part_of_inst == `ECALL) begin
		is_ecall <= 1;
	end
	else begin
		is_ecall <= 0;
	end
   end
	
endmodule
*/
