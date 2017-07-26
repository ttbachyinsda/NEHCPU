`include "defines.v"

module ex_mem(

	input wire                  clk,
	input wire                  rst,
	
	input wire[5: 0]            stall,

	// from ex	
	input wire[`RegAddrBus]     ex_wd,
	input wire                  ex_wreg,
	input wire[`RegBus]         ex_wdata,

	input wire                  ex_whilo,
	input wire[`RegBus]         ex_hi, 		
	input wire[`RegBus]         ex_lo,
	//load store
	input wire[`AluOpBus]       ex_aluop,
	input wire[`RegBus]         ex_mem_addr,
	input wire[`RegBus]         ex_reg2,

	//cp0
	input wire                  ex_cp0_reg_we,
	input wire[4:0]             ex_cp0_reg_write_addr,
	input wire[`RegBus]         ex_cp0_reg_data,

	//exception
	input wire                  flush,
	input wire[31: 0]           ex_excepttype,
	input wire[`RegBus]         ex_current_inst_addr,
	input wire                  ex_is_in_delayslot,

	// to mem
	output reg[`RegAddrBus]     mem_wd,
	output reg                  mem_wreg,
	output reg[`RegBus]         mem_wdata,

	output reg                  mem_whilo,
	output reg[`RegBus]         mem_hi, 		
	output reg[`RegBus]         mem_lo,
	// load store
	output reg[`AluOpBus]       mem_aluop,
	output reg[`RegBus]         mem_mem_addr,
	output reg[`RegBus]         mem_reg2,

	//cp0
	output reg                  mem_cp0_reg_we,
	output reg[4:0]             mem_cp0_reg_write_addr,
	output reg[`RegBus]         mem_cp0_reg_data,

	//exception
	output reg[31: 0]           mem_excepttype,
	output reg[`RegBus]         mem_current_inst_addr,
	output reg                  mem_is_in_delayslot		
	
);


	always @ (posedge clk) begin
		if(rst == `RstEnable) begin
			mem_wd <= `NOPRegAddr;
			mem_wreg <= `WriteDisable;
		  	mem_wdata <= `ZeroWord;	
		  	mem_whilo <= `WriteDisable;
		  	mem_hi <= `ZeroWord;
		  	mem_lo <= `ZeroWord;
		  	mem_aluop <= `EXE_NOP_OP;
		  	mem_mem_addr <= `ZeroWord;
		  	mem_reg2 <= `ZeroWord;
		  	//cp0
		  	mem_cp0_reg_we <= `WriteDisable;
			mem_cp0_reg_write_addr <= 5'b00000;
			mem_cp0_reg_data <= `ZeroWord;
			//exception
			mem_excepttype <= `ZeroWord;
			mem_current_inst_addr <= `ZeroWord;
			mem_is_in_delayslot <= `NotInDelaySlot;
		end
		else if(flush == 1'b1) begin
			mem_wd <= `NOPRegAddr;
			mem_wreg <= `WriteDisable;
		  	mem_wdata <= `ZeroWord;	
		  	mem_whilo <= `WriteDisable;
		  	mem_hi <= `ZeroWord;
		  	mem_lo <= `ZeroWord;
		  	mem_aluop <= `EXE_NOP_OP;
		  	mem_mem_addr <= `ZeroWord;
		  	mem_reg2 <= `ZeroWord;
		  	//cp0
		  	mem_cp0_reg_we <= `WriteDisable;
			mem_cp0_reg_write_addr <= 5'b00000;
			mem_cp0_reg_data <= `ZeroWord;
			//exception
			mem_excepttype <= `ZeroWord;
			mem_current_inst_addr <= `ZeroWord;
			mem_is_in_delayslot <= `NotInDelaySlot;
		end 
		else if(stall[3] == `Stop && stall[4] == `NoStop) begin
		    mem_wd <= `NOPRegAddr;
		    mem_wreg <= `WriteDisable;
		    mem_wdata <= `ZeroWord;
		    mem_hi <= `ZeroWord;
		    mem_lo <= `ZeroWord;
		    mem_whilo <= `WriteDisable;
  		    mem_aluop <= `EXE_NOP_OP;
			mem_mem_addr <= `ZeroWord;
			mem_reg2 <= `ZeroWord;		
			//cp0
			mem_cp0_reg_we <= `WriteDisable;
			mem_cp0_reg_write_addr <= 5'b00000;
			mem_cp0_reg_data <= `ZeroWord;	
			//exception
			mem_excepttype <= `ZeroWord;
			mem_current_inst_addr <= `ZeroWord;
			mem_is_in_delayslot <= `NotInDelaySlot;			  				    
		end 
		else if(stall[3] == `NoStop) begin
			mem_wd <= ex_wd;
			mem_wreg <= ex_wreg;
			mem_wdata <= ex_wdata;	
		  	mem_whilo <= ex_whilo;
		  	mem_hi <= ex_hi;
		  	mem_lo <= ex_lo;			
		  	mem_aluop <= ex_aluop;
		  	mem_mem_addr <= ex_mem_addr;
		  	mem_reg2 <= ex_reg2;
		  	//cp0
		  	mem_cp0_reg_we <= ex_cp0_reg_we;
			mem_cp0_reg_write_addr <= ex_cp0_reg_write_addr;
			mem_cp0_reg_data <= ex_cp0_reg_data;
			//exception
			mem_excepttype <= ex_excepttype;
			mem_current_inst_addr <= ex_current_inst_addr;
			mem_is_in_delayslot <= ex_is_in_delayslot;
		end //if
	end //always
			

endmodule