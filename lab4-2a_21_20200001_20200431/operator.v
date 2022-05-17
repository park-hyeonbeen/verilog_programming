// Custom file for ALU, ADD, ALUControlUnit and MUX

`include "opcodes.v"

// HB code
module ALU (
    input [3:0] alu_op,      // input
    input [31:0] alu_in_1,    // input  
    input [31:0] alu_in_2,    // input
    output [31:0] alu_result,  // output
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
     	alu_bcond_reg = 0;
   end
   
   else if(alu_op==`ALUOp_SUB) begin
   	alu_result_reg = alu_in_1 - alu_in_2;
     	alu_bcond_reg = 0;
   end
   
   else if(alu_op==`ALUOp_AND) begin
   	alu_result_reg = alu_in_1 & alu_in_2;
     	alu_bcond_reg = 0;
   end
   
   else if(alu_op==`ALUOp_OR) begin
   	alu_result_reg = alu_in_1 | alu_in_2;
     	alu_bcond_reg = 0;
   end
   
   else if(alu_op==`ALUOp_XOR) begin
   	alu_result_reg = alu_in_1 ^ alu_in_2;
     	alu_bcond_reg = 0;
   end
   
   else if(alu_op==`ALUOp_SLL) begin
   	alu_result_reg = alu_in_1 << alu_in_2;
     	alu_bcond_reg = 0;
   end
   
   else if(alu_op==`ALUOp_SRL) begin
   	alu_result_reg = alu_in_1 >>> alu_in_2;
     	alu_bcond_reg = 0;
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
        out_reg = input2;
   end
   else begin
   	out_reg = input1;
   end
   end
   
   assign out = out_reg;
   
  endmodule
  
  module five_bit_mux(
   input control,
   input[4:0] input1,
   input[4:0] input2,
   output [4:0] out
  );
  reg [4:0] out_reg;
  
  
  always@(*) begin
   if(control) begin
        out_reg = input2;
   end
   else begin
   	out_reg = input1;
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
   
   // Get 4 inputs
  module mux2bit(
   input[1:0] control,
   input[31:0] input1,
   input[31:0] input2,
   input[31:0] input3,
   input[31:0] input4,
   output [31:0] out
  );
  reg [31:0] out_reg;
  
  always@(*) begin
   	if(control == 2'b00) begin
   	     out_reg = input1;
   	end
   	else if(control == 2'b01) begin
   		out_reg = input2;
   	end
   	else if(control == 2'b10) begin
   		out_reg = input3;
   	end
   	else begin
		out_reg = input4;
	end
   end
   
   assign out = out_reg;
   
  endmodule
  
  //added haszard detection unit
  module hazard_detection_unit(
   input [31:0] IF_ID_inst_out,
   input ID_EX_MemRead,
   input [4:0] EX_MEM_rd,
   input MEM_WB_is_halt,
   output reg HDU_out
  );
   wire [4:0]ID_rs1;
   wire [4:0]ID_rs2;
   assign ID_rs1 = IF_ID_inst_out[19:15];
   assign ID_rs2 = IF_ID_inst_out[24:20];
   
   always@(*) begin
    HDU_out = 0;
    if(ID_EX_MemRead) begin
        if((ID_rs1 == EX_MEM_rd) && (ID_rs1 != 5'b00000)) begin
            HDU_out = 1;
        end
        else if((ID_rs2 == EX_MEM_rd) && (ID_rs2 != 5'b00000)) begin
            HDU_out = 1;
        end
        else
            HDU_out = 0;
    end
    if(IF_ID_inst_out == 32'b00000000000000000000000001110011 & (!MEM_WB_is_halt)) begin
            HDU_out = 1;
    end
   end
  endmodule
  
 module forwarding_unit(
   input [4:0] ID_EX_rs1,
   input [4:0] ID_EX_rs2,
   input [4:0] EX_MEM_rd,
   input [4:0] MEM_WB_rd,
   input [31:0] IF_ID_inst_out,
   input EX_MEM_reg_write,
   input MEM_WB_reg_write,
   input alu_src,
   output reg [1:0] ForwardingA,
   output reg [1:0] ForwardingB,
   output reg ForwardingC,
   output reg ForwardingD,
   output reg [1:0] ForwardingE
  );
    wire [4:0] IF_ID_rs1; 
    wire [4:0] IF_ID_rs2;
    assign IF_ID_rs1 = IF_ID_inst_out[19:15];
    assign IF_ID_rs2 = IF_ID_inst_out[24:20];
    always@(*) begin
        ForwardingA = 2'b00;
        ForwardingB = 2'b00;
        ForwardingC = 1'b0;
        ForwardingD = 1'b0;
        ForwardingE = 2'b00;
        
        if((ID_EX_rs1 != 0) && (ID_EX_rs1 == MEM_WB_rd) && MEM_WB_reg_write) begin
            ForwardingA = 2'b10;
        end        
        if((ID_EX_rs1 != 0) && (ID_EX_rs1 == EX_MEM_rd) && EX_MEM_reg_write) begin
            ForwardingA = 2'b01;
        end

       if((ID_EX_rs2 != 0) && (ID_EX_rs2 == MEM_WB_rd) && MEM_WB_reg_write && !alu_src) begin
            ForwardingB = 2'b10;
        end 
        if((ID_EX_rs2 != 0) && (ID_EX_rs2 == EX_MEM_rd) && EX_MEM_reg_write && !alu_src) begin
            ForwardingB = 2'b01;
        end
       
        
        if((IF_ID_rs1 != 0) && (IF_ID_rs1 == MEM_WB_rd) && MEM_WB_reg_write) begin
            ForwardingC = 1'b1;
        end     
        if((IF_ID_rs2 != 0) && (IF_ID_rs2 == MEM_WB_rd) && MEM_WB_reg_write) begin
            ForwardingD = 1'b1;
        end
        
        if((ID_EX_rs2 != 0) && (ID_EX_rs2 == MEM_WB_rd) && MEM_WB_reg_write) begin
            ForwardingE = 2'b10;
        end
        if((ID_EX_rs2 != 0) && (ID_EX_rs2 == EX_MEM_rd) && EX_MEM_reg_write) begin
            ForwardingE = 2'b01;
        end

    end 
  
  endmodule
  
module ADDER (
    input [31:0] alu_in_1,    // input  
    input [31:0] alu_in_2,    // input
    output [31:0] alu_result  // output
  );
  reg [31:0] alu_result_reg;
  always@(*) begin
   	alu_result_reg = alu_in_1 + alu_in_2;
  end
  assign alu_result = alu_result_reg;
endmodule