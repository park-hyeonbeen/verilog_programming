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
           output is_halted); // Whether to finish simulation
  /***** Wire declarations *****/
  wire [31:0] instruction;		// instruction memory output
  wire [31:0] current_pc;
  wire [31:0] next_pc;
  wire [10:0] alu_part_inst;		// ALU control input
	assign alu_part_inst = { instruction[30], instruction[14:12], instruction[6:0] };

  wire [3:0] alu_op;
  wire [31:0] alu_in_1;			// ALU input1 = Register output1
  wire [31:0] alu_in_2;			// ALU input1 = Mux2 output
  wire [31:0] alu_result;
  wire bcond;
  wire [31:0] rs2_dout;
  wire [31:0] rd_din;
  wire [31:0] pc_4;			// pc +4 value
  wire [31:0] imm_gen_out;
  wire [31:0] write_back;
  wire [31:0] mem_data;
  wire [31:0] pc_imm;
  wire [31:0] pc_add;

  // control unit output
  wire is_jal;
  wire is_jalr;
  wire branch;
  wire mem_read;
  wire mem_to_reg;
  wire mem_write;
  wire alu_src;
  wire write_enable;
  wire pc_to_reg;
  wire pc_src1;
  assign pc_src1 = (bcond & branch) | is_jal;

  wire is_ecall;
  wire rf_17;
  assign is_halted = (is_ecall | rf_17);
  /***** Register declarations *****/
  //reg [31:0] a;
  //a = 4;

  // ---------- Update program counter ----------
  // PC must be updated on the rising edge (positive edge) of the clock.
  PC pc(
    .reset(reset),       // input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),         // input
    .next_pc(next_pc),     // input
    .current_pc(current_pc)   // output
  );
  
  // ---------- Instruction Memory ----------
  InstMemory imem(
    .reset(reset),   // input
    .clk(clk),     // input
    .addr(current_pc),    // input
    .dout(instruction)     // output
  );

  // ---------- Register File ----------
  RegisterFile reg_file (
    .reset (reset),        // input
    .clk (clk),          // input
    .rs1 (instruction[19:15]),          // input //instruction[19:15]
    .rs2 (instruction[24:20]),          // input
    .rd (instruction[11:7]),           // input
    .rd_din (rd_din),       		// input //MUX1 output
    .write_enable (write_enable),    // input
    .rs1_dout (alu_in_1),     // output  //ALU input
    .rs2_dout (rs2_dout),      // output  //MUX2 input
    .rf_17(rf_17)
  );


  // ---------- Control Unit ----------
  ControlUnit ctrl_unit (
    .part_of_inst(instruction[6:0]),  // input
    .is_jal(is_jal),        // output
    .is_jalr(is_jalr),       // output
    .branch(branch),        // output
    .mem_read(mem_read),      // output
    .mem_to_reg(mem_to_reg),    // output
    .mem_write(mem_write),     // output
    .alu_src(alu_src),       // output
    .write_enable(write_enable),     // output
    .pc_to_reg(pc_to_reg),     // output
    .is_ecall(is_ecall)       // output (ecall inst)
  );

  // ---------- Immediate Generator ----------
  ImmediateGenerator imm_gen(
    .part_of_inst(instruction[31:0]),  // input
    .imm_gen_out(imm_gen_out)    // output
  );

  // ---------- ALU Control Unit ----------
  ALUControlUnit alu_ctrl_unit (
    .part_of_inst(alu_part_inst),  // input
    .alu_op(alu_op)         // output
  );

  // ---------- ALU ----------
  ALU alu (
    .alu_op(alu_op),      // input
    .alu_in_1(alu_in_1),    // input  
    .alu_in_2(alu_in_2),    // input // MUX2 output
    .alu_result(alu_result),  // output
    .alu_bcond(bcond)     // output
  );

  // ---------- Data Memory ----------
  DataMemory dmem(
    .reset (reset),      // input
    .clk (clk),        // input
    .addr (alu_result),       // input
    .din (rs2_dout),        // input
    .mem_read (mem_read),   // input
    .mem_write (mem_write),  // input
    .dout (mem_data)        // output //MUX5 input
  );

 mux mux1( 
.control(pc_to_reg),
.input1(pc_4),
.input2(write_back),
.out(rd_din)
);

mux mux2(
.control(alu_src),
.input1(imm_gen_out),
.input2(rs2_dout),
.out(alu_in_2)
);

mux mux3(
.control(pc_src1),
.input1(pc_imm),
.input2(pc_4),
.out(pc_add)
);

mux mux4(
.control(is_jalr),
.input1(alu_result),
.input2(pc_add),
.out(next_pc)
);

mux mux5(
.control(mem_to_reg),
.input1(mem_data),
.input2(alu_result),
.out(write_back)
);

//addout -> add_4, add 4 to current_pc
add_4 add1(
.input1(current_pc),
.out(pc_4)
);

addout add2(
.input1(current_pc),
.input2(imm_gen_out),
.out(pc_imm)
);
endmodule

//addout module declaration deleted by hyeonbeen
