module ALU #(parameter data_width = 16) (
	input [data_width - 1 : 0] A, 
	input [data_width - 1 : 0] B, 
	input [3 : 0] FuncCode,
       	output reg [data_width - 1: 0] C,
       	output reg OverflowFlag);
// Do not use delay in your implementation.

// You can declare any variables as needed.
	reg [16:0] regC;

initial begin
	C = 0;
	OverflowFlag = 0;
end   	

// TODO: You should implement the functionality of ALU!
// (HINT: Use 'always @(...) begin ... end')

	always @(*) begin
		OverflowFlag = 0;

		if (FuncCode == 4'b0000) begin
			regC = A + B;
			C[15:0] = regC[15:0];
			if(A[15] == B[15]) begin
				if(C[15] != A[15])
				OverflowFlag = 1;
			end
		end

		else if (FuncCode == 4'b0001) begin
			C = A - B;
			if(A[15] != B[15]) begin
				if(C[15] != A[15])
				OverflowFlag = 1;
			end
		end

		else if (FuncCode == 4'b0010)
			C = A;

		else if (FuncCode == 4'b0011)
			C = ~A;

		else if (FuncCode == 4'b0100)
			C = A & B;

		else if (FuncCode == 4'b0101)
			C = A | B;

		else if (FuncCode == 4'b0110)
			C = ~(A & B);

		else if (FuncCode == 4'b0111)
			C = ~(A | B);

		else if (FuncCode == 4'b1000)
               	begin
               	C = (~(A&B)) & (A|B);
            	end

            	else if (FuncCode == 4'b1001)
            	begin
            	C = ~((~(A&B)) & (A|B));
            	end

            	else if (FuncCode == 4'b1010) 
            	begin
            	C = A<<1;
            	end

            	else if (FuncCode == 4'b1011)
            	begin
            	C = A>>1;
            	end

            	else if (FuncCode == 4'b1100)
            	begin
            	C = A <<< 1;
            	end

            	else if (FuncCode == 4'b1101)
            	begin
            	C = A >> 1;
            	C[15] = A[15];
            	end

            	else if (FuncCode == 4'b1110)
            	begin
            	C = ~A + 1;
            	end

            	else
            	C = 0;
   end
endmodule

