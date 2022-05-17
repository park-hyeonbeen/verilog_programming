// Submit this file with other files you created.
// Do not touch port declarations of the module 'CPU'.

// Guidelines
// 1. It is highly recommened to `define opcodes and something useful.
// 2. You can modify the module.
// (e.g., port declarations, remove modules, define new modules, ...)
// 3. You might need to describe combinational logics to drive them into the module (e.g., mux, and, or, ...)
// 4. `include files if required

module CPU(input reset,       // positive reset signal
           input clk,         // clock signal
           output is_halted); // Whehther to finish simulation
  /***** Wire declarations *****/


  // control unit output
    wire PCWriteCond;
    wire PCWrite;
    wire IorD;
    wire MemRead;
    wire MemWrite;
    wire MemtoReg;
    wire IRWrite;
    wire PCSource;
    wire [1:0] ALUOp;
    wire AluSrcA;
    wire [1:0] AluSrcB;
    wire RegWrite;
    wire RegDst;
    wire is_ecall;
    wire [4:0] Curr_State;
    wire [4:0] Next_State;
        assign is_halted = is_ecall;

  // Others

  wire [31:0] current_pc;
  wire [31:0] next_pc;
  wire [10:0] alu_part_inst;		// ALU control input

  wire [31:0] address;
  wire [3:0] alu_op;
  wire [31:0] rd_din;
  wire [31:0] imm_gen_out;
  reg [31:0] four = 32'b100;
  reg [31:0] zero = 32'b0;
  
  wire [4:0] Wreg;
  
  wire [31:0] alu_in_1;
  wire [31:0] alu_in_2;
  wire [31:0] alu_result;
  wire bcond;

    wire PCcontinue;
        assign PCcontinue = (PCWriteCond & !bcond) | PCWrite;
  wire [31:0] IR_wire;
  wire [31:0] MDR_wire;
  wire [31:0] A_wire;
  wire [31:0] B_wire;

  /***** Register declarations *****/
  reg [31:0] IR; // instruction register
  reg [31:0] MDR; // memory data register
  reg [31:0] A; // Read 1 data register
  reg [31:0] B; // Read 2 data register
  reg [31:0] ALUOut; // ALU output register
  // Do not modify and use registers declared above.
    
    wire [6:0] opcode;
    wire [31:0] IR_wire2;
    wire [31:0] A_Out;
    wire [31:0] B_Out;
    wire [31:0] ALUOut_Out;
    wire [31:0] MDR_Out;

	assign alu_part_inst = { IR_wire[30], IR_wire[14:12], IR_wire[6:0] };
	assign IR_wire = MDR_wire;
	
 
    
    always @(posedge clk) begin
        if (IRWrite || reset) begin
            IR <= IR_wire;
        end
        A <= A_wire;
        B <= B_wire;
        ALUOut <= alu_result;
        MDR <= MDR_wire;
    end
    
    assign opcode = IR[6:0];
    assign IR_wire2 = IR;
    assign A_Out = A;
    assign B_Out = B;
    assign ALUOut_Out = ALUOut;
    assign MDR_Out = MDR;
   

  

  // ---------- Update program counter ----------
  // PC must be updated on the rising edge (positive edge) of the clock.
  PC pc(
    .reset(reset),       // input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),         // input
    .next_pc(next_pc),     // input
    .PCcontinue(PCcontinue),
    .current_pc(current_pc)   // output
  );

  // ---------- Memory ----------
  Memory memory(
    .reset(reset),        // input
    .clk(clk),          // input
    .addr(address),         // input
    .din(B_Out),          // input
    .mem_read(MemRead),     // input
    .mem_write(MemWrite),    // input
    .dout(MDR_wire)          // output
  );

  // ---------- Register File ----------
  RegisterFile reg_file(
    .reset(reset),        // input
    .clk(clk),          // input
    .rs1(IR_wire2[19:15]),          // input
    .rs2(IR_wire2[24:20]),          // input
    .rd(IR_wire2[11:7]),           // input
    .rd_din(rd_din),       // input
    .write_enable(RegWrite),    // input
    .rs1_dout(A_wire),     // output
    .rs2_dout(B_wire)      // output
  );

  // ---------- Control Unit ----------
  ControlUnit ctrl_unit(
    .part_of_inst(opcode),  // input
    .reset(reset),	//input
    .clk(clk),		//input
    .Curr_State_in(Curr_State),
    .Next_State_out(Next_State),
    .bcond(bcond)
  );
  
  ControlUnit2 ctrl_unit2(
    .reset(reset),
    .clk(clk),
    .Curr_State(Curr_State),
    .Next_State(Next_State), //input
    .part_of_inst(opcode), //input
    .PCWriteCond(PCWriteCond),        // output
    .PCWrite(PCWrite),       // output
    .IorD(IorD),        // output
    .MemRead(MemRead),      // output
    .MemWrite(MemWrite),    // output
    .MemtoReg(MemtoReg),     // output
    .IRWrite(IRWrite),       // output
    .PCSource(PCSource),     // output
    .ALUOp(ALUOp[1:0]),     // output
    .AluSrcA(AluSrcA),     // output
    .AluSrcB(AluSrcB[1:0]),     // output
    .RegWrite(RegWrite),       // output
    .RegDst(RegDst),     // output
    .is_ecall(is_ecall)       // output (ecall inst)
  );

  // ---------- Immediate Generator ----------
  ImmediateGenerator imm_gen(
    .part_of_inst(IR_wire2[31:0]),  // input
    .imm_gen_out(imm_gen_out)    // output
  );

  // ---------- ALU Control Unit ----------
  ALUControlUnit alu_ctrl_unit(
    .part_of_inst(alu_part_inst),  // input
    .ALUOp(ALUOp),                  //input
    .alu_op(alu_op[3:0])         // output
  );

  // ---------- ALU ----------
  ALU alu(
    .alu_op(alu_op[3:0]),      // input
    .alu_in_1(alu_in_1),    // input  
    .alu_in_2(alu_in_2),    // input
    .alu_result(alu_result),  // output
    .alu_bcond(bcond)     // output
  );

 mux mux1( 
.control(IorD),
.input1(current_pc),
.input2(ALUOut_Out),
.out(address)
);

 fivebit_mux mux2( 
.control(RegDst),
.input1(IR_wire2[24:20]),
.input2(IR_wire2[11:7]),
.out(Wreg)
);

mux mux3(
.control(MemtoReg),
.input1(ALUOut_Out),
.input2(MDR_Out),
.out(rd_din)
);

mux mux4(
.control(AluSrcA),
.input1(current_pc),
.input2(A_Out),
.out(alu_in_1)
);

mux2bit mux5(
.control(AluSrcB),
.input1(B_Out),
.input2(four),
.input3(imm_gen_out),
.input4(zero),
.out(alu_in_2)
);

mux mux6(
.control(PCSource),
.input1(alu_result),
.input2(ALUOut_Out),
.out(next_pc)
);

endmodule
