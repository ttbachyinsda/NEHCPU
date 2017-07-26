// actually, wb is achieved in regfile

`include "defines.v"

module mem_wb(

	input wire                  clk,
	input wire                  rst,

	input wire[5: 0]            stall,

	// from mem	
	input wire[`RegAddrBus]     mem_wd,
	input wire                  mem_wreg,
	input wire[`RegBus]         mem_wdata,
	input wire                  mem_whilo,
	input wire[`RegBus]         mem_hi,
	input wire[`RegBus]         mem_lo,
	//cp0
	input wire                  mem_cp0_reg_we,
	input wire[4:0]             mem_cp0_reg_write_addr,
	input wire[`RegBus]         mem_cp0_reg_data,

	// exception
	input wire                  flush,

	// to wb
	output reg[`RegAddrBus]     wb_wd,
	output reg                  wb_wreg,
	output reg[`RegBus]         wb_wdata,	       
	//hi lo
	output reg                  wb_whilo,
	output reg[`RegBus]         wb_hi,
	output reg[`RegBus]         wb_lo,
	//cp0
	output reg                   wb_cp0_reg_we,
	output reg[4:0]              wb_cp0_reg_write_addr,
	output reg[`RegBus]          wb_cp0_reg_data
);


	always @ (posedge clk) begin
		if(rst == `RstEnable) begin
			wb_wd <= `NOPRegAddr;
			wb_wreg <= `WriteDisable;
		  	wb_wdata <= `ZeroWord;	
			wb_whilo <= `WriteDisable;
		  	wb_hi <= `ZeroWord;
		  	wb_lo <= `ZeroWord;
		  	wb_cp0_reg_we <= `WriteDisable;
			wb_cp0_reg_write_addr <= 5'b00000;
			wb_cp0_reg_data <= `ZeroWord;	
		end 
		else if(flush == 1'b1) begin
			wb_wd <= `NOPRegAddr;
			wb_wreg <= `WriteDisable;
		  	wb_wdata <= `ZeroWord;	
			wb_whilo <= `WriteDisable;
		  	wb_hi <= `ZeroWord;
		  	wb_lo <= `ZeroWord;
		  	wb_cp0_reg_we <= `WriteDisable;
			wb_cp0_reg_write_addr <= 5'b00000;
			wb_cp0_reg_data <= `ZeroWord;
		end
		else if(stall[4] == `Stop && stall[5] == `NoStop) begin
		    wb_wd <= `NOPRegAddr;
		    wb_wreg <= `WriteDisable;
		    wb_wdata <= `ZeroWord;
		    wb_hi <= `ZeroWord;
		    wb_lo <= `ZeroWord;
		    wb_whilo <= `WriteDisable;
		    wb_cp0_reg_we <= `WriteDisable;
			wb_cp0_reg_write_addr <= 5'b00000;
			wb_cp0_reg_data <= `ZeroWord;			  	  
		end else if(stall[4] == `NoStop) begin
		    wb_wd <= mem_wd;
		    wb_wreg <= mem_wreg;
		    wb_wdata <= mem_wdata;
		    wb_whilo <= mem_whilo;
            wb_hi <= mem_hi;
            wb_lo <= mem_lo;
            wb_cp0_reg_we <= mem_cp0_reg_we;
			wb_cp0_reg_write_addr <= mem_cp0_reg_write_addr;
			wb_cp0_reg_data <= mem_cp0_reg_data;
		end //if
	end //always
			

endmodule