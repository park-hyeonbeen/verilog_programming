// Submit this file with other files you created.
// Do not touch port declarations of the module 'CPU'.

// Guidelines
// 1. It is highly recommened to `define opcodes and something useful.
// 2. You can modify modules (except InstMemory, DataMemory, and RegisterFile)
// (e.g., port declarations, remove modules, define new modules, ...)
// 3. You might need to describe combinational logics to drive them into the module (e.g., mux, and, or, ...)
// 4. `include files if required

module CPU(input reset,       // positive reset signal
           input clk,         // clock signal
           output is_halted); // Whehther to finish simulation
  /***** Wire declarations *****/
  wire [31:0] instruction;		// instruction memory output
  wire [31:0] current_pc;
  wire [31:0] next_pc;
  wire [31:0] next_pc_in1;
  wire [31:0] next_pc_in2;
  wire [10:0] alu_part_inst;		// ALU control input
	assign alu_part_inst = { instruction[30], instruction[14:12], instruction[6:0] };

  wire [3:0] alu_op;
  wire [31:0] alu_in_1;			// ALU input1 = Register output1
  wire [31:0] alu_result;
  wire [31:0] PC_alu_result;
  wire [31:0] PC_selector_1_out;
  wire [31:0] Write_data;
  
  wire bcond;
  wire [31:0] rs2_dout;
  wire [31:0] imm_gen_out;
  wire [31:0] mem_data;
  wire [31:0] pc_imm;
  wire [31:0] pc_add;
  wire [4:0] rs_1_input;
  wire EX_branch;
  wire jump;
  
  wire [1:0] ForwardA;      // for forward output
  wire [1:0] ForwardB;
  wire ForwardC;
  wire ForwardD;
  wire [1:0] ForwardE;
  
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
  
  //MUX_out value
  wire [31:0] MUX0_out;
  wire [31:0] MUX1_out;
  wire [31:0] MUX2_out;
  wire [31:0] MUX3_out;
  wire [31:0] MUX4_out;
  wire [31:0] MUX5_out;
  wire [31:0] MUX6_out;

  wire is_ecall;
  wire rf_17;
  
  reg flush;
 
  
  /***** Register declarations *****/
  // You need to modify the width of registers
  // In addition, 
  // 1. You might need other pipeline registers that are not described below
  // 2. You might not need registers described below
  
  wire HDU_out;                  // 1 while stall, 0 for else
  wire ID_is_halted;

  
  assign rf_17 = ((alu_in_1 == 32'b1010) && (HDU_out == 0)) ? 1 : 0;    
  assign ID_is_halted = rf_17 & is_ecall;
  
  
  /***** IF/ID pipeline registers *****/
  reg [31:0] IF_ID_inst;           // will be used in ID stage
  reg [31:0] IF_ID_PC;
  reg [31:0] IF_ID_PC4;
  
  /***** ID/EX pipeline registers *****/
  // From the control unit
  reg [3:0] ID_EX_alu_op;         // will be used in EX stage
  reg ID_EX_alu_src;        // will be used in EX stage
  reg ID_EX_mem_write;      // will be used in MEM stage
  reg ID_EX_mem_read;       // will be used in MEM stage
  reg ID_EX_mem_to_reg;     // will be used in WB stage
  reg ID_EX_reg_write;      // will be used in WB stage
  reg ID_EX_JAL;     // will be used in WB stage
  reg ID_EX_JALR;      // will be used in WB stage
  // From others
  reg [31:0] ID_EX_rs1_data;
  reg [31:0] ID_EX_rs2_data;
  reg [4:0] ID_EX_rs1;
  reg [4:0] ID_EX_rs2;
  reg [31:0] ID_EX_imm;
  reg [10:0] ID_EX_ALU_ctrl_unit_input;
  reg [4:0] ID_EX_rd;
  reg ID_EX_is_halted;
  reg ID_EX_HDU_out;
  reg HDU_out_reg;
  
  reg [31:0] ID_EX_PC;
  reg [31:0] ID_EX_PC4;
  reg ID_EX_branch;

  /***** EX/MEM pipeline registers *****/
  // From the control unit
  reg EX_MEM_mem_write;     // will be used in MEM stage
  reg EX_MEM_mem_read;      // will be used in MEM stage
  reg EX_MEM_is_branch;     // will be used in MEM stage
  reg EX_MEM_mem_to_reg;    // will be used in WB stage
  reg EX_MEM_reg_write;     // will be used in WB stage
  reg EX_MEM_is_halted;
  reg EX_MEM_HDU_out;
  
  reg EX_MEM_branch;
  reg EX_MEM_JAL;     // will be used in WB stage
  reg EX_MEM_JALR;      // will be used in WB stage
  // From others
  reg [31:0] EX_MEM_alu_out;
  reg [31:0] EX_MEM_PC_alu;
  reg [31:0] EX_MEM_dmem_data;
  reg [4:0] EX_MEM_rd;
  reg [31:0] EX_MEM_rs2_data;
  reg [31:0] EX_MEM_MUX6;
  reg [31:0] EX_MEM_PC4;
  
  reg EX_MEM_bcond;
  reg EX_MEM_is_PC_pre_right;

  /***** MEM/WB pipeline registers *****/
  // From the control unit
  reg MEM_WB_mem_to_reg;    // will be used in WB stage
  reg MEM_WB_reg_write;     // will be used in WB stage
  reg MEM_WB_is_halted;
  reg MEM_WB_HDU_out;
  // From others
  reg [31:0]MEM_WB_mem_to_reg_src_1;
  reg [31:0]MEM_WB_mem_to_reg_src_2;
  reg [4:0] MEM_WB_rd;
  reg MEM_WB_JAL;     // will be used in WB stage
  reg MEM_WB_JALR;      // will be used in WB stage
  
  reg [31:0] MEM_WB_PC4;

  // ---------- Update program counter ----------
  // PC must be updated on the rising edge (positive edge) of the clock.
  PC pc(
    .reset(reset),       // input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),         // input
    .next_pc(next_pc),     // input
    .HDU_out(HDU_out),
    .current_pc(current_pc)   // output
  );
  
  // ---------- Instruction Memory ----------
  InstMemory imem(
    .reset(reset),   // input
    .clk(clk),     // input
    .addr(current_pc),    // input
    .dout(instruction)     // output
  );

  // Update IF/ID pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
        IF_ID_inst <= 32'b0;
        IF_ID_PC <= 32'b0;
        IF_ID_PC4 <= 32'b0;
    end
    else begin
    	if(HDU_out == 0) begin
            IF_ID_inst <= instruction;
            IF_ID_PC <= current_pc;
            IF_ID_PC4 <= next_pc_in1;
    	end
    end
  end
  
  wire [31:0] IF_ID_inst_out;
  wire [31:0] IF_ID_PC_out;
  wire [31:0] IF_ID_PC4_out;
  assign IF_ID_inst_out = IF_ID_inst;
  assign IF_ID_PC_out = IF_ID_PC;
  assign IF_ID_PC4_out = IF_ID_PC4;

  // ---------- Register File ----------
  RegisterFile reg_file (
    .reset (reset),        // input
    .clk (clk),          // input
    .rs1 (rs_1_input),          // input
    .rs2 (IF_ID_inst_out[24:20]),          // input
    .rd (MEM_WB_rd),           // input
    .rd_din (Write_data),       // input
    .write_enable (MEM_WB_reg_write),    // input
    .rs1_dout (alu_in_1),     // output
    .rs2_dout (rs2_dout)      // output
  );


  // ---------- Control Unit ----------
  ControlUnit ctrl_unit (
    .part_of_inst(IF_ID_inst_out[6:0]),  // input
    .is_jal(is_jal),
    .is_jalr(is_jalr),
    .branch(branch),
    .mem_read(mem_read),      // output
    .mem_to_reg(mem_to_reg),    // output
    .mem_write(mem_write),     // output
    .alu_src(alu_src),       // output
    .write_enable(write_enable),  // output
    .pc_to_reg(pc_to_reg),     // output
    .is_ecall(is_ecall)       // output (ecall inst)
  );

  // ---------- Immediate Generator ----------
  ImmediateGenerator imm_gen(
    .part_of_inst(IF_ID_inst_out[31:0]),  // input
    .imm_gen_out(imm_gen_out)    // output
  );
  
  assign alu_part_inst = { IF_ID_inst_out[30], IF_ID_inst_out[14:12], IF_ID_inst_out[6:0] };
  ALUControlUnit alu_ctrl_unit (
    .part_of_inst(alu_part_inst),  // input
    .alu_op(alu_op)         // output
  );

  // Update ID/EX pipeline registers here
  
  always @(posedge clk) begin
    if (reset) begin
        ID_EX_alu_op <= 3'b0;         // will be used in EX stage
        ID_EX_alu_src <= 1'b0;        // will be used in EX stage
        ID_EX_mem_write <= 1'b0;      // will be used in MEM stage
        ID_EX_mem_read <= 1'b0;       // will be used in MEM stage
        ID_EX_mem_to_reg <= 1'b0;     // will be used in WB stage
        ID_EX_reg_write <= 1'b0;
        ID_EX_is_halted <= 1'b0;
        ID_EX_rs1_data <= 32'b0;
        ID_EX_rs2_data <= 32'b0;
        ID_EX_imm <= 32'b0;
        ID_EX_rd <= 5'b0;
        ID_EX_rs1 <= 5'b0;
        ID_EX_rs2 <= 5'b0;
        ID_EX_PC <= 32'b0;
        ID_EX_PC4 <= 32'b0;
        ID_EX_branch <= 1'b0;
        ID_EX_JAL <= 1'b0;
        ID_EX_JALR <= 1'b0;
        flush <= 1'b0;
    end
    else begin
    	if(HDU_out == 0 && is_PC_pre_right == 1 && EX_MEM_is_PC_pre_right_out == 1) begin
            ID_EX_alu_op <= alu_op;         // will be used in EX stage
            ID_EX_alu_src <= alu_src;        // will be used in EX stage
            ID_EX_mem_write <= mem_write;      // will be used in MEM stage
            ID_EX_mem_read <= mem_read;       // will be used in MEM stage
            ID_EX_mem_to_reg <= mem_to_reg;     // will be used in WB stage
            ID_EX_reg_write <= write_enable;
            ID_EX_branch <= branch;
            ID_EX_JAL <= is_jal;
            ID_EX_JALR <= is_jalr;
            flush <= 1'b0;
    	end
    	else begin
            ID_EX_alu_op <= 1'b0;         // will be used in EX stage
            ID_EX_alu_src <= 1'b0;        // will be used in EX stage
            ID_EX_mem_write <= 1'b0;      // will be used in MEM stage
            ID_EX_mem_read <= 1'b0;       // will be used in MEM stage
            ID_EX_mem_to_reg <= 1'b0;     // will be used in WB stage
            ID_EX_reg_write <= 1'b0;
            ID_EX_branch <= 1'b0;
            ID_EX_JAL <= 1'b0;
            ID_EX_JALR <= 1'b0;
            flush <= 1'b1;
        end
        ID_EX_rs1_data <= MUX0_out;
        ID_EX_rs2_data <= MUX1_out;
        ID_EX_imm <= imm_gen_out;
        ID_EX_rd <= IF_ID_inst_out[11:7];
        ID_EX_rs1 <= rs_1_input;
        ID_EX_rs2 <= IF_ID_inst_out[24:20];
        ID_EX_is_halted <= ID_is_halted;
        HDU_out_reg <= HDU_out;
        ID_EX_PC <= IF_ID_PC_out;
        ID_EX_PC4 <= IF_ID_PC4_out;
        if(HDU_out != HDU_out_reg && HDU_out == 1) begin
            ID_EX_HDU_out <= 1;
        end
        else
            ID_EX_HDU_out <= 0;
    end
  end
  
  // wire declaration
  wire [3:0] ID_EX_alu_op_out;
  wire ID_EX_alu_src_out;
  wire ID_EX_mem_write_out;
  wire ID_EX_mem_read_out;
  wire ID_EX_mem_to_reg_out;
  wire ID_EX_reg_write_out;
  wire [31:0] ID_EX_rs1_data_out;
  wire [31:0] ID_EX_rs2_data_out;
  wire [31:0]ID_EX_imm_out;
  wire [4:0] ID_EX_rd_out;
  wire [4:0] ID_EX_rs1_out;
  wire [4:0] ID_EX_rs2_out;
  wire ID_EX_is_halted_out;
  wire ID_EX_is_HDU_out_out;

  wire [31:0] ID_EX_PC_out;
  wire [31:0] ID_EX_PC4_out;
  wire ID_EX_branch_out;
  wire ID_EX_JAL_out;
  wire ID_EX_JALR_out;
  
  // assign wire to reg
  assign ID_EX_alu_op_out = ID_EX_alu_op;
  assign ID_EX_alu_src_out = ID_EX_alu_src;
  assign ID_EX_mem_write_out = ID_EX_mem_write;
  assign ID_EX_mem_read_out = ID_EX_mem_read;
  assign ID_EX_mem_to_reg_out = ID_EX_mem_to_reg;   //
  assign ID_EX_reg_write_out = ID_EX_reg_write;
  assign ID_EX_rs1_data_out = ID_EX_rs1_data;
  assign ID_EX_rs2_data_out = ID_EX_rs2_data;
  assign ID_EX_imm_out = ID_EX_imm;
  assign ID_EX_rd_out = ID_EX_rd;
  assign ID_EX_rs1_out = ID_EX_rs1;
  assign ID_EX_rs2_out = ID_EX_rs2;
  assign ID_EX_is_halted_out = ID_EX_is_halted;
  assign ID_EX_HDU_out_out = ID_EX_HDU_out;
  
  assign ID_EX_PC_out = ID_EX_PC;
  assign ID_EX_PC4_out = ID_EX_PC4;
  assign ID_EX_branch_out = ID_EX_branch;
  assign ID_EX_JAL_out = ID_EX_JAL;
  assign ID_EX_JALR_out = ID_EX_JALR;

  // ---------- ALU ----------
  ALU alu (
    .alu_op(ID_EX_alu_op_out),      // input
    .alu_in_1(MUX2_out),    // input  
    .alu_in_2(MUX3_out),    // input
    .alu_result(alu_result),  // output
    .alu_bcond(bcond)     // output
  );
  
  ADDER PC_adder (
    .alu_in_1(ID_EX_PC_out),    // input  
    .alu_in_2(ID_EX_imm_out),   // input
    .alu_result(PC_alu_result)  // output  
  );
  
  assign EX_branch = (bcond & ID_EX_branch_out) | ID_EX_JAL_out | ID_EX_JALR_out;

  // Update EX/MEM pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
        EX_MEM_mem_write <= 0;     // will be used in MEM stage
        EX_MEM_mem_read <= 0;      // will be used in MEM stage
        EX_MEM_is_branch <= 0;     // will be used in MEM stage
        EX_MEM_mem_to_reg <= 0;    // will be used in WB stage
        EX_MEM_reg_write <= 0;     // will be used in WB stage
        EX_MEM_is_halted <= 0;
        EX_MEM_branch <= 1'b0;
    // From others
        EX_MEM_alu_out <= 32'b0;
        EX_MEM_dmem_data <= 32'b0;
        EX_MEM_rd <= 5'b0;
        EX_MEM_rs2_data <= 32'b0;
        EX_MEM_MUX6 <= 32'b0;
        
        EX_MEM_PC_alu <= 32'b0;
        EX_MEM_PC4 <= 32'b0;
        EX_MEM_JAL <= 1'b0;
        EX_MEM_JALR <= 1'b0;
        EX_MEM_is_PC_pre_right <= 1'b0;
    end
    else begin
        EX_MEM_mem_write <= ID_EX_mem_write_out;     // will be used in MEM stage
        EX_MEM_mem_read <= ID_EX_mem_read_out;      // will be used in MEM stage
        EX_MEM_is_branch <= EX_branch;     // will be used in MEM stage
        EX_MEM_mem_to_reg <= ID_EX_mem_to_reg_out;    // will be used in WB stage
        EX_MEM_reg_write <= ID_EX_reg_write_out;     // will be used in WB stage
        EX_MEM_is_halted <= ID_EX_is_halted_out;
        EX_MEM_HDU_out <= ID_EX_HDU_out_out;
        
        EX_MEM_JAL <= ID_EX_JAL;
        EX_MEM_JALR <= ID_EX_JALR;
    // From others
        EX_MEM_alu_out <= alu_result;
        EX_MEM_dmem_data <= MUX3_out;
        EX_MEM_rd <= ID_EX_rd_out;
        EX_MEM_rs2_data <= ID_EX_rs2_data_out;
        EX_MEM_MUX6 <= MUX6_out;
        EX_MEM_branch <= EX_branch;
        EX_MEM_bcond <= bcond;
        
        EX_MEM_PC_alu <= PC_alu_result;
        EX_MEM_PC4 <=ID_EX_PC4_out;
        EX_MEM_is_PC_pre_right <= is_PC_pre_right;
    end
  end
  
  //wire declaration
  wire EX_MEM_mem_write_out;     // will be used in MEM stage
  wire EX_MEM_mem_read_out;      // will be used in MEM stage
  wire EX_MEM_is_branch_out;     // will be used in MEM stage
  wire EX_MEM_mem_to_reg_out;    // will be used in WB stage
  wire EX_MEM_reg_write_out;     // will be used in WB stage
  wire [31:0] EX_MEM_alu_out_out;
  wire [31:0] EX_MEM_dmem_data_out;
  wire [4:0] EX_MEM_rd_out;
  wire EX_MEM_is_halted_out;
  wire EX_MEM_HDU_out_out;
  wire [31:0] EX_MEM_rs2_data_out;
  wire [31:0] EX_MEM_MUX6_out;
  
  wire EX_MEM_branch_out;
  wire EX_MEM_bcond_out;
  wire EX_MEM_JAL_out;
  wire EX_MEM_JALR_out;
  wire [31:0] EX_MEM_PC4_out;
  wire EX_MEM_is_PC_pre_right_out;
  
  //assign wire to reg
  assign EX_MEM_mem_write_out = EX_MEM_mem_write;     // will be used in MEM stage
  assign EX_MEM_mem_read_out = EX_MEM_mem_read;      // will be used in MEM stage
  assign EX_MEM_is_branch_out = EX_MEM_is_branch;     // will be used in MEM stage
  assign EX_MEM_mem_to_reg_out = EX_MEM_mem_to_reg;    // will be used in WB stage
  assign EX_MEM_reg_write_out = EX_MEM_reg_write;     // will be used in WB stage
  assign EX_MEM_alu_out_out = EX_MEM_alu_out;
  assign EX_MEM_dmem_data_out = EX_MEM_dmem_data;
  assign EX_MEM_rd_out = EX_MEM_rd;
  assign EX_MEM_is_halted_out = EX_MEM_is_halted;
  assign EX_MEM_HDU_out_out = EX_MEM_HDU_out;
  assign EX_MEM_rs2_data_out = EX_MEM_rs2_data;
  assign EX_MEM_MUX6_out = EX_MEM_MUX6;
  
  assign EX_MEM_branch_out = EX_MEM_branch;
  assign EX_MEM_bcond_out = EX_MEM_bcond;
  assign next_pc_in2 = EX_MEM_PC_alu;
  assign EX_MEM_JAL_out = EX_MEM_JAL;
  assign EX_MEM_JALR_out = EX_MEM_JALR;
  assign EX_MEM_PC4_out = EX_MEM_PC4;
  assign EX_MEM_is_PC_pre_right_out = EX_MEM_is_PC_pre_right;
  

  // ---------- Data Memory ----------
  DataMemory dmem(
    .reset (reset),         // input
    .clk (clk),             // input
    .addr (EX_MEM_alu_out_out),     // input
    .din (EX_MEM_MUX6_out),        // input
    .mem_read (EX_MEM_mem_read_out),   // input
    .mem_write (EX_MEM_mem_write_out),  // input
    .dout (mem_data)        // output
  );

  // Update MEM/WB pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
        MEM_WB_mem_to_reg <= 1'b0;    // will be used in WB stage
        MEM_WB_reg_write <= 1'b0;     // will be used in WB stage
        MEM_WB_is_halted <= 1'b0;
        
        MEM_WB_JAL <= 1'b0;
        MEM_WB_JALR <= 1'b0;
  // From others
        MEM_WB_mem_to_reg_src_1 <= 32'b0;
        MEM_WB_mem_to_reg_src_2 <= 32'b0;
        MEM_WB_rd <= 5'b0;
        MEM_WB_PC4 <= 32'b0;
    end
    else begin
        MEM_WB_mem_to_reg <= EX_MEM_mem_to_reg_out;    // will be used in WB stage
        MEM_WB_reg_write <= EX_MEM_reg_write_out;     // will be used in WB stage
  // From others
        MEM_WB_mem_to_reg_src_1 <= mem_data;
        MEM_WB_mem_to_reg_src_2 <= EX_MEM_alu_out_out;
        MEM_WB_rd <= EX_MEM_rd_out;
        MEM_WB_is_halted <= EX_MEM_is_halted_out;
        MEM_WB_HDU_out <= EX_MEM_HDU_out_out;
        
        MEM_WB_JAL <= EX_MEM_JAL_out;
        MEM_WB_JALR <= EX_MEM_JALR_out;
        MEM_WB_PC4 <= EX_MEM_PC4_out;
    end
  end
  
  //wire declaration
  wire MEM_WB_mem_to_reg_out;    // will be used in WB stage
  wire MEM_WB_reg_write_out;     // will be used in WB stage
  wire [31:0]MEM_WB_mem_to_reg_src_1_out;
  wire [31:0]MEM_WB_mem_to_reg_src_2_out;
  wire [4:0] MEM_WB_rd_out;
  wire MEM_WB_HDU_out_out;
  
  wire MEM_WB_JAL_out;
  wire MEM_WB_JALR_out;
  wire [31:0] MEM_WB_PC4_out;
  
  //assign wire to reg
  assign MEM_WB_mem_to_reg_out = MEM_WB_mem_to_reg;    // will be used in WB stage
  assign MEM_WB_reg_write_out = MEM_WB_reg_write;     // will be used in WB stage
  // From others
  assign MEM_WB_mem_to_reg_src_1_out = MEM_WB_mem_to_reg_src_1;
  assign MEM_WB_mem_to_reg_src_2_out = MEM_WB_mem_to_reg_src_2;
  assign MEM_WB_rd_out = MEM_WB_rd;
  assign is_halted = MEM_WB_is_halted;
  assign MEM_WB_HDU_out_out = MEM_WB_HDU_out;
  
  assign MEM_WB_JAL_out = MEM_WB_JAL;
  assign MEM_WB_JALR_out = MEM_WB_JALR;
  assign MEM_WB_PC4_out = MEM_WB_PC4;
  
five_bit_mux rs_1(
.control(is_ecall),
.input1(IF_ID_inst_out[19:15]),
.input2(5'b10001),
.out(rs_1_input)
);
    
mux mux0(
.control(ForwardC),
.input1(alu_in_1),
.input2(Write_data),
.out(MUX0_out)
);

mux mux1(
.control(ForwardD),
.input1(rs2_dout),
.input2(Write_data),
.out(MUX1_out)
);
  
mux2bit mux2(
.control(ForwardA),
.input1(ID_EX_rs1_data_out),
.input2(EX_MEM_alu_out_out),
.input3(Write_data),
.input4(EX_MEM_alu_out_out),
.out(MUX2_out)
);
  
mux2bit mux3(
.control(ForwardB),
.input1(MUX5_out),
.input2(EX_MEM_alu_out_out),
.input3(Write_data),
.input4(Write_data),
.out(MUX3_out)
);
  
mux mux4(
.control(MEM_WB_mem_to_reg_out),
.input1(MEM_WB_mem_to_reg_src_2_out),
.input2(MEM_WB_mem_to_reg_src_1_out),
.out(MUX4_out)
);
  
mux RD_select(
.control(MEM_WB_JAL_out || MEM_WB_JALR_out),
.input1(MUX4_out),
.input2(MEM_WB_PC4_out),
.out(Write_data)
);

mux2bit mux6(
  .control(ForwardE),
  .input1(ID_EX_rs2_data_out),
  .input2(EX_MEM_alu_out_out),
  .input3(Write_data),
  .input4(Write_data),
  .out(MUX6_out)
);
  
  hazard_detection_unit HDU(
   .IF_ID_inst_out(IF_ID_inst_out),
   .ID_EX_MemRead(ID_EX_mem_read_out),
   .EX_MEM_rd(ID_EX_rd_out),
   .MEM_WB_is_halt(MEM_WB_HDU_out_out),
   .HDU_out(HDU_out)
  );
  
  forwarding_unit FU(
   .ID_EX_rs1(ID_EX_rs1_out),
   .ID_EX_rs2(ID_EX_rs2_out),
   .EX_MEM_rd(EX_MEM_rd_out),
   .MEM_WB_rd(MEM_WB_rd_out),
   .IF_ID_inst_out(IF_ID_inst_out),
   .EX_MEM_reg_write(EX_MEM_reg_write_out),
   .MEM_WB_reg_write(MEM_WB_reg_write_out),
   .alu_src(ID_EX_alu_src_out),
   .ForwardingA(ForwardA),
   .ForwardingB(ForwardB),
   .ForwardingC(ForwardC),
   .ForwardingD(ForwardD),
   .ForwardingE(ForwardE)
  );
  
  add_4 PCadd(
   .current_pc(current_pc),
   .next_pc(next_pc_in1)
  );
  
  //added for always taken
  wire [1:0] ctrl_flow_unit_out1;
  wire [1:0] ctrl_flow_unit_out2;
  wire is_PC_pre_right;
  wire [31:0] new_PC_selector_1_out;
  wire BTB_tag_match;
  wire [31:0] take_BTB_out;
  wire [31:0] BTB_out;
  assign is_PC_pre_right = flush | (new_PC_selector_1_out == IF_ID_PC_out);

  
  //added for always taken
  mux2bit new_PC_selector_1(
  .control(ctrl_flow_unit_out1),
  .input1(PC_alu_result),
  .input2(alu_result),
  .input3(ID_EX_PC4_out),
  .input4(ID_EX_PC4_out),
  .out(new_PC_selector_1_out)
  );
  
  //addee for always taken
  mux new_PC_selector_2(
  .control(is_PC_pre_right),
  .input1(new_PC_selector_1_out),
  .input2(take_BTB_out),
  .out(next_pc)
  );
  
  //added for always taken
  ControlFlowUnit ctrl_flow_unit(
  .branch(ID_EX_branch_out),
  .jalr(ID_EX_JALR_out),
  .jal(ID_EX_JAL_out),
  .bcond(bcond),
  .out1(ctrl_flow_unit_out1),
  .out2(ctrl_flow_unit_out2)
  );
  
  reg[1:0] BHT;
  
  always @(posedge clk) begin        //use saturation medel, 11 <-> 10 <-> 01 <-> 00
    if(reset) begin
        BHT <= 2'b10;
    end
    else if (ID_EX_branch_out == 1) begin
        if (bcond == 0) begin          // branch not taken
            if(BHT != 2'b00)
                BHT <= BHT - 1;
        end
        else begin                     // branch taken
            if(BHT != 2'b11)
                BHT <= BHT + 1;
        end
    end
  end
  
  
  //added for always taken
  BTB BTB(
  .clk(clk),
  .reset(reset),
  .addr1(current_pc),
  .addr2(ID_EX_PC),
  .control(ctrl_flow_unit_out2),
  .input1(PC_alu_result),
  .input2(alu_result),
  // .BHT_Predict(BHT[1] | ID_EX_JAL_out | ID_EX_JALR_out ),
  .out1(BTB_out),
  .out2(BTB_tag_match)
  );
  
  //added for always taken
  mux take_BTB(
  .control(BTB_tag_match && ( (instruction[6:0]!= 7'b1100011) | BHT[1]) ),          //BTB_tag_match가 1이고, branch의 경우 BHT가 1인 case
  .input1(next_pc_in1),
  .input2(BTB_out),
  .out(take_BTB_out)
  );
  
  /* deleted for always taken
  mux PC_selector_1(
.control(EX_branch),
.input1(next_pc_in1),
.input2(PC_alu_result),
.out(PC_selector_1_out)
);

  mux PC_selector_2(
.control(ID_EX_JALR_out),
.input1(PC_selector_1_out),
.input2(alu_result),
.out(next_pc)
);*/ 
  
  mux imm_detection(
.control(ID_EX_alu_src_out),
.input1(ID_EX_rs2_data_out),
.input2(ID_EX_imm_out),
.out(MUX5_out)
);
endmodule

