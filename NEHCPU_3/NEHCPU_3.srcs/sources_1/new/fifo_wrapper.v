`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/07/18 16:26:07
// Design Name: 
// Module Name: fifo_wrapper
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fifo_wrapper(
    input wire clk,
    input wire rst,
    input wire[7:0] din,
    input wire wr_en,
    input wire rd_en,
    output wire[7:0] dout,
    output wire full,
    output wire empty
    );
    scfifo scfifo0(
        .clk(clk),
            .rst(rst),
            .din(din),
            .wr_en(wr_en),
            .rd_en(rd_en),
            .dout(dout),
            .full(full),
            .empty(empty)
    );
endmodule
