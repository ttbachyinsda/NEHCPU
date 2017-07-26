`include "defines.v"

module if_id(

	input wire                          clk,
	input wire                          rst,
	input wire[5: 0]                    stall,
		
	input wire[`InstAddrBus]            if_pc,
	input wire[`InstBus]                if_inst,
	input wire                          flush, 
	input wire   is_inst_tlbl_i,
	output reg is_inst_tlbl_o,

	output reg[`InstAddrBus]            id_pc,
	output reg[`InstBus]                id_inst  
	
);

	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			id_pc <= `ZeroWord;
			id_inst <= `ZeroWord;
			is_inst_tlbl_o <= 1'b0;
	  	end 
	  	else if(flush == 1'b1) begin
	  		id_pc <= `ZeroWord;
	  		id_inst <= `ZeroWord;
	  		is_inst_tlbl_o <= 1'b0;
	  	end
	  	else if(stall[1] == `Stop && stall[2] == `NoStop) begin 
	  		id_pc <= `ZeroWord;
			id_inst <= `ZeroWord;
			is_inst_tlbl_o <= 1'b0;
	  	end
	  	else if(stall[1] == `NoStop) begin
		 	id_pc <= if_pc;
		  	is_inst_tlbl_o <= is_inst_tlbl_i;
		  	id_inst <= (is_inst_tlbl_i? `ZeroWord: if_inst);
		end
	end

endmodule