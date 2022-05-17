`include "vending_machine_def.v"

	

module check_time_and_coin(i_input_coin,i_select_item,clk,reset_n,wait_time,i_trigger_return,current_total,o_return_coin, o_available_item);
 	input clk;
 	input reset_n;
	input [`kNumCoins-1:0] i_input_coin;
 	input [`kNumItems-1:0] i_select_item;
        input [`kNumItems-1:0] o_available_item;
	input i_trigger_return;
	input [`kTotalBits-1:0] current_total;
 	output reg  [`kNumCoins-1:0] o_return_coin;
	output reg [31:0] wait_time;
	integer make_curr_0;

	// initiate values
	initial begin
		// TODO: initiate values
                o_return_coin = 0;
                wait_time = 0;
	end


	// update coin return time
 	always @(i_input_coin, i_select_item) begin
		// TODO: update coin return time
		if(i_input_coin!=0) begin
			wait_time = `kWaitTime;
		end
		else if((i_select_item & o_available_item) != 0) begin
			wait_time = `kWaitTime;
		end
	end

   always @(*) begin
      	// TODO: o_return_coin

	if(i_trigger_return == 1 || wait_time == 0) begin
		make_curr_0 = 1;
	end

	if(current_total == 0) begin
		make_curr_0 = 0;
	end
	
	if(make_curr_0 == 1)begin
		if(current_total >= 1600) begin
			o_return_coin = 3'b111;
		end
		else if(current_total >=1500) begin
			o_return_coin = 3'b110;
		end
		else if(current_total >= 1100) begin
			o_return_coin = 3'b101;
		end
		else if (current_total >= 1000) begin
			o_return_coin = 3'b100;
		end
		else if (current_total >= 600) begin
			o_return_coin = 3'b011;
		end
		else if (current_total >= 500) begin
			o_return_coin = 3'b010;
		end
		else if (current_total >= 100) begin
			o_return_coin = 3'b001;
		end
	end
		
	else begin
		o_return_coin = 3'b000;
	end

   end

   always @(posedge clk ) begin
      // TODO: reset all states.
      if (!reset_n) begin
		o_return_coin = 0;
                wait_time = 0;
      end
      else begin
                // TODO: update all states.
      		if (wait_time != 0) begin
                	wait_time = wait_time -1;
		end
      end
   end
endmodule 