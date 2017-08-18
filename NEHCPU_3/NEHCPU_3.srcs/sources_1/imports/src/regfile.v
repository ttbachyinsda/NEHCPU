`include "defines.v"

module regfile(

	input wire					  clk,
	input wire					  rst,
	
	// write port
	input wire					  we,
	input wire[`RegAddrBus]	  waddr,
	input wire[`RegBus]		  wdata,
	
	// read port_1
	input wire					  re1,
	input wire[`RegAddrBus]	  raddr1,
	output reg[`RegBus]       rdata1,
	
	// read port_2
	input wire					  re2,
	input wire[`RegAddrBus]	  raddr2,
	output reg[`RegBus]       rdata2,

    input wire[31: 0] reg_sel,
    output wire[`RegBus] reg_out,

    output wire[31:0] led,	
	input wire[31:0] sw
	
);

	reg[`RegBus]  regs[0: `RegNum - 1];

	assign reg_out = reg_sel[0]? regs[0]: (
							reg_sel[1]? regs[1]: (
							reg_sel[2]? regs[2]: 
							`ZeroWord));

	always @ (posedge clk) begin
		if (rst == `RstDisable) begin
			if((we == `WriteEnable) && (waddr != `RegNumLog2'h0)) begin // if not $0 rigister
				regs[waddr] <= wdata;
			end
		end
	end
	
	always @ (*) begin
		if(rst == `RstEnable) begin
			rdata1 <= `ZeroWord;
	  	end 
	  	else if(raddr1 == `RegNumLog2'h0) begin
	  		rdata1 <= `ZeroWord;
	  	end 
	  	else if((raddr1 == waddr) && (we == `WriteEnable) // the one to read is exactly what to write
	  	            && (re1 == `ReadEnable)) begin
	  	 	rdata1 <= wdata;
	 	end 
	 	else if(re1 == `ReadEnable) begin
	      	rdata1 <= regs[raddr1];
	  	end 
	  	else begin
	      	rdata1 <= `ZeroWord;
	  	end
	end

	always @ (*) begin
		if(rst == `RstEnable) begin
			rdata2 <= `ZeroWord;
	  	end 
	  	else if(raddr2 == `RegNumLog2'h0) begin
	  		rdata2 <= `ZeroWord;
	  	end 
	  	else if((raddr2 == waddr) && (we == `WriteEnable) 
	  	            && (re2 == `ReadEnable)) begin
	  	  	rdata2 <= wdata;
	  	end 
	  	else if(re2 == `ReadEnable) begin
	      	rdata2 <= regs[raddr2];
	  	end 
	  	else begin
	      	rdata2 <= `ZeroWord;
	  	end
	end

endmodule