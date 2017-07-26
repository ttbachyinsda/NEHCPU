`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/07/17 02:19:52
// Design Name: 
// Module Name: uartsignal
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


module uartsignal(
input wire clk,
output reg [5:0] stall,
output reg flush,
output reg ce_o,
output reg [31:0] ram_data_o,
output reg [`RegBus] mmu_data_addr,
output reg  ram_we_o,
output reg [3:0] ram_sel_o,
input wire [`RegBus] ram_data_i,
input wire stallreq_from_mem
);
always @(posedge clk) begin
stall <= 0;
flush <= 0;
ce_o <= 1;
ram_data_o <= {24'b0, 8'h8c};
mmu_data_addr <= 32'h1fd003f8;
ram_we_o <= 1;
ram_sel_o <= 4'b0001;
end
endmodule
