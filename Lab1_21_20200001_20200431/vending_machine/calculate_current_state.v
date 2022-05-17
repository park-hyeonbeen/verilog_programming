
`include "vending_machine_def.v"
	

module calculate_current_state(clk,reset_n,i_input_coin,i_select_item,item_price,coin_value,current_total,
input_total, output_total, return_total,current_total_nxt,wait_time,o_return_coin,o_available_item,o_output_item);


	input clk;
	input reset_n;
	input [`kNumCoins-1:0] i_input_coin,o_return_coin;
	input [`kNumItems-1:0]	i_select_item;			
	input [31:0] item_price [`kNumItems-1:0];
	input [31:0] coin_value [`kNumCoins-1:0];	
	input [`kTotalBits-1:0] current_total;
	input [31:0] wait_time;
	output reg [`kNumItems-1:0] o_available_item,o_output_item;
	output reg  [`kTotalBits-1:0] input_total, output_total, return_total,current_total_nxt;
	integer i;
	integer temp_return;	


	// custom setting
	initial begin
		input_total = 0;
		output_total = 0;
		return_total = 0;
		o_available_item = 4'b0000;
		o_output_item = 4'b0000;
		current_total_nxt = 0;
	end


	//custom, module for o_return_coin
	always @(*) begin
		if(o_return_coin != 0) begin
			temp_return = 0;
			for(i = 0; i <`kNumCoins; i = i + 1) begin
				if(o_return_coin[i] == 1) begin
					temp_return = temp_return + coin_value[i];
				end
			end

			return_total = return_total + temp_return;
			current_total_nxt = current_total - temp_return;
		end
	end


	// Combinational logic for the next states
	always @(i_input_coin) begin
		// TODO: current_total_nxt
		// You don't have to worry about concurrent activations in each input vector (or array).
		// Calculate the next current_total state.
		
		// 1. coin insertion	2. buy something
		
		if (i_input_coin != 0) begin

			if (i_input_coin[0] == 1) begin
			current_total_nxt = current_total + 100;
			input_total = input_total + 100;
			end

			if (i_input_coin[1] == 1) begin
			current_total_nxt = current_total + 500;
			input_total = input_total + 500;
			end

			if (i_input_coin[2] == 1) begin
			current_total_nxt = current_total + 1000;
			input_total = input_total + 1000;
			end
		end
	end

	
	
	// Combinational logic for the outputs
	always @(i_select_item) begin
		// TODO: o_available_item
		// TODO: o_output_item
		if (i_select_item [0] == 1) begin
			if(o_available_item[0] == 1) begin
			current_total_nxt = current_total - 400;
			output_total = output_total + 400;
			o_output_item = 4'b0001;
			end
		end			

		else if (i_select_item [1] == 1) begin
			if(o_available_item[1] == 1) begin
			current_total_nxt = current_total - 500;
			output_total = output_total + 500;
			o_output_item = 4'b0010;
			end
		end			
	
		else if (i_select_item [2] == 1) begin
			if(o_available_item[2] == 1) begin
			current_total_nxt = current_total - 1000;
			output_total = output_total + 1000;
			o_output_item = 4'b0100;
			end
		end			

		else if (i_select_item [3] == 1) begin
			if(o_available_item[3] == 1) begin
			current_total_nxt = current_total - 2000;
			output_total = output_total + 2000;
			o_output_item = 4'b1000;
			end
		end			
		
		else begin
			o_output_item = 4'b0000;
		end
	end


	always @(*) begin	
		//o_available_item update
		if(current_total >= 2000) begin
			o_available_item = 4'b1111;
		end
		
		else if(current_total >= 1000) begin
			o_available_item = 4'b0111;
		end

		else if(current_total >= 500) begin
			o_available_item = 4'b0011;
		end

		else if(current_total >= 400) begin
			o_available_item = 4'b0001;
		end

		else begin
			o_available_item = 4'b0000;
		end
	end

	always @(*) begin
		if (!reset_n) begin
			o_output_item = 4'b0000;
			current_total_nxt = 0;
		end
	end

endmodule 