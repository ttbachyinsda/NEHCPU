// w - write
// r - read 
// e - enable
// addr - 5bit, register address

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

    output wire[31:0] led,		//查看寄存器
	input wire[31:0] sw
	
);

	reg[`RegBus]  regs[0: `RegNum - 1];

	assign led = sw[0]?regs[0]:(
						sw[1]?regs[1]:(
						sw[2]?regs[2]:(
						sw[3]?regs[3]:(
						sw[4]?regs[4]:(
						sw[5]?regs[5]:(
						sw[6]?regs[6]:(
						sw[7]?regs[7]:(
						sw[8]?regs[8]:(
						sw[9]?regs[9]:(
						sw[10]?regs[10]:(
						sw[11]?regs[11]:(
						sw[12]?regs[12]:(
						sw[13]?regs[13]:(
						sw[14]?regs[14]:(
						sw[15]?regs[15]:(
						sw[16]?regs[16]:(
						sw[17]?regs[17]:(
						sw[18]?regs[18]:(
						sw[19]?regs[19]:(
						sw[20]?regs[20]:(
						sw[21]?regs[21]:(
						sw[22]?regs[22]:(
						sw[23]?regs[23]:(
						sw[24]?regs[24]:(
						sw[25]?regs[25]:(
						sw[26]?regs[26]:(
						sw[27]?regs[27]:(
						sw[28]?regs[28]:(
						sw[29]?regs[29]:(
						sw[30]?regs[30]:(
						sw[31]?regs[31]:`ZeroWord)))))))))))))))))))))))))))))));

	assign reg_out = reg_sel[0]? regs[0]: (
							reg_sel[1]? regs[1]: (
							reg_sel[2]? regs[2]: 
							`ZeroWord));

	// write
	always @ (posedge clk) begin
		if (rst == `RstDisable) begin
			if((we == `WriteEnable) && (waddr != `RegNumLog2'h0)) begin // if not $0 rigister
				regs[waddr] <= wdata;
			end
		end
	end
	
	//read 1
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

	// read 2
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