`timescale 1ns / 1ps
`include "defines.v"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:17:24 10/26/2016 
// Design Name: 
// Module Name:    hilo_reg 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module hilo_reg(
    input wire					rst,
    input wire					clk,
    input wire					we,
    input wire[`RegBus]		hi_i,
    input wire[`RegBus]		lo_i,
    output reg[`RegBus]		hi_o,
    output reg[`RegBus]		lo_o
    );

	always @ (posedge clk) begin
		if(rst == `RstEnable) begin
			hi_o <= `ZeroWord;
			lo_o <= `ZeroWord;
		end
		else if(we == `WriteEnable) begin
			hi_o <= hi_i;
			lo_o <= lo_i;
		end
	end
	
endmodule
