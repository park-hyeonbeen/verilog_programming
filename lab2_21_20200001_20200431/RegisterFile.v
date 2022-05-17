module RegisterFile(input	reset,
                    input clk,
                    input [4:0] rs1,          // source register 1
                    input [4:0] rs2,          // source register 2
                    input [4:0] rd,           // destination register
                    input [31:0] rd_din,      // input data for rd
                    input write_enable,          // RegWrite signal
                    output [31:0] rs1_dout,   // output of rs 1
                    output [31:0] rs2_dout,   // output of rs 2
		    output rf_17);
  integer i;
  // Register file
  reg [31:0] rf[0:31];

  // TODO
  // Asynchronously read register file
  // Synchronously write data to the register file
	// 22.03.26 16:10 Eun
	// assume that all memories are in rf
	reg is_ecall_reg;
	assign rs1_dout = rf[rs1];
	assign rs2_dout = rf[rs2];
	assign rf_17 = is_ecall_reg;
   	always @(posedge clk) begin
		if (rf[17] == 10) begin
			is_ecall_reg <= 1'b1;//blocking to nonblocking
		end
		else begin
			is_ecall_reg <= 1'b0;//blocking to nonblocking
		end
			
		if (write_enable) begin
			rf[rd] <= rd_din;//blocking to nonblocking
		end
        	rf[0] <= 32'b0;//blocking to nonblocking
   	end
	

  // Initialize register file (do not touch)
  always @(posedge clk) begin
    // Reset register file
    if (reset) begin
      for (i = 0; i < 32; i = i + 1)
        rf[i] = 32'b0;
      rf[2] = 32'h2ffc; // stack pointer
    end
  end
endmodule
