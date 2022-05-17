// Custom file for ALU, ADD, ALUControlUnit and MUX

`include "opcodes.v"

// HB code
module ALU (
    input [3:0] alu_op,      // input
    input [31:0] alu_in_1,    // input  
    input [31:0] alu_in_2,    // input
    output [31:0] alu_result,  // output//
    output alu_bcond     // output
  );
  reg [31:0] cond;
  reg SF;
  reg OF;
  reg [31:0] alu_result_reg;
  reg alu_bcond_reg;
  always@(*) begin
  cond = alu_in_1 - alu_in_2;
  SF = cond[31];
  OF = (!alu_in_1[31] && alu_in_2[31] && SF) || (alu_in_1[31] && !alu_in_2[31] && !SF);
 
   if(alu_op==`ALUOp_ADD) begin
   	alu_result_reg = alu_in_1 + alu_in_2;
   end
   
   else if(alu_op==`ALUOp_SUB) begin
   	alu_result_reg = alu_in_1 - alu_in_2;
   end
   
   else if(alu_op==`ALUOp_AND) begin
   	alu_result_reg = alu_in_1 & alu_in_2;
   end
   
   else if(alu_op==`ALUOp_OR) begin
   	alu_result_reg = alu_in_1 | alu_in_2;
   end
   
   else if(alu_op==`ALUOp_XOR) begin
   	alu_result_reg = alu_in_1 ^ alu_in_2;
   end
   
   else if(alu_op==`ALUOp_SLL) begin
   	alu_result_reg = alu_in_1 << alu_in_2;
   end
   
   else if(alu_op==`ALUOp_SRL) begin
   	alu_result_reg = alu_in_1 >>> alu_in_2;
   end
   
   else if(alu_op==`ALUOp_EQ) begin
    if(alu_in_1 == alu_in_2) begin
     	alu_bcond_reg = 1;
    end 
    else begin
     	alu_bcond_reg = 0;
    end
   end
   
   else if(alu_op==`ALUOp_NE) begin
    if(alu_in_1 != alu_in_2) begin
     	alu_bcond_reg = 1;
    end 
    else begin
     	alu_bcond_reg = 0;
    end
   end
   
   else if(alu_op==`ALUOp_LT) begin
    if(SF^OF) begin
     	alu_bcond_reg = 1;
    end 
    else begin
     	alu_bcond_reg = 0;
    end
   end
   
   else if(alu_op==`ALUOp_GE) begin    
    if(!(SF^OF)) begin
     	alu_bcond_reg = 1;
    end 
    else begin
     	alu_bcond_reg = 0;
    end
   end

  end
  assign alu_result = alu_result_reg;
  assign alu_bcond = alu_bcond_reg;
  
  
  endmodule
  
  module  ALUControlUnit(
    input [10:0] part_of_inst,   // input
    output [3:0] alu_op         // output
  );
  reg [6:0] opcode;
  reg [2:0] funct3;
  reg funct7;
  reg [3:0] alu_op_reg;
  
  always@(*) begin
  opcode = part_of_inst[6:0];
  funct3 = part_of_inst[9:7];
  funct7 = part_of_inst[10];
  
  if((opcode == `LOAD) || (opcode == `STORE) || (opcode == `JALR)) begin
  	alu_op_reg = `ALUOp_ADD;
  end
 
  else if((opcode == `ARITHMETIC) || (opcode == `ARITHMETIC_IMM)) begin
  	if((funct7 == 1)&&(opcode==`ARITHMETIC)) begin
    		alu_op_reg = `ALUOp_SUB;
  	end
  	else if(funct3 == `FUNCT3_ADD) begin
    		alu_op_reg = `ALUOp_ADD;
  	end
  	else if(funct3 == `FUNCT3_AND) begin
  	  	alu_op_reg = `ALUOp_AND;
  	end
  	else if(funct3 == `FUNCT3_OR) begin
  	  	alu_op_reg = `ALUOp_OR;
  	end
  	else if(funct3 == `FUNCT3_XOR) begin
  	  	alu_op_reg = `ALUOp_XOR;
  	end
  	else if(funct3 == `FUNCT3_SLL) begin
  	  	alu_op_reg = `ALUOp_SLL;
  	end
  	else if(funct3 == `FUNCT3_SRL) begin
  	  	alu_op_reg = `ALUOp_SRL;
  	end
  end
   
  else if(opcode == `BRANCH) begin
  	if(funct3 == `FUNCT3_BEQ) begin
  	  	alu_op_reg = `ALUOp_EQ;
  	end
  	else if(funct3 == `FUNCT3_BNE) begin
  	  	alu_op_reg = `ALUOp_NE;
  	end
  	else if(funct3 == `FUNCT3_BLT) begin
  	  	alu_op_reg = `ALUOp_LT;
  	end
  	else if(funct3 == `FUNCT3_BGE) begin
  	 	alu_op_reg = `ALUOp_GE;
  	end
  end
  end
   
   assign alu_op = alu_op_reg;
   
  endmodule
  
  module mux(
   input control,
   input[31:0] input1,
   input[31:0] input2,
   output [31:0] out
  );
  reg [31:0] out_reg;
  
  always@(*) begin
   if(control) begin
        out_reg = input1;
   end
   else begin
   	out_reg = input2;
   end
   end
   
   assign out = out_reg;
   
  endmodule
  
  module addout(
   input [31:0] input1,
   input [31:0] input2,
   output [31:0] out);
   
   assign out = input1 + input2;
   endmodule

//add 4 to pc
  module add_4(
   input [31:0] input1,
   output [31:0] out);
   
   assign out = input1 + 4;
   endmodule