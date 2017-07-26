`include "defines.v"

module inst_rom_top(

	input              clk_i,
    input              rst_i,
   
    input              wb_stb_i,
    input              wb_cyc_i,
    output reg         wb_ack_o,
    input      [31: 0] wb_addr_i,
    input      [ 3: 0] wb_sel_i,
    input              wb_we_i,
    input      [31: 0] wb_data_i,
    output reg [31: 0] wb_data_o
);
	
	reg[`InstBus]  inst_mem[0: `InstMemNum-1]; 		//inst_mem['InstMemNum - 1][32]

	initial $readmemh ( "inst_rom.data", inst_mem );

    // wb read/write accesses
    wire wb_acc = wb_cyc_i & wb_stb_i;    // wb access
    wire wb_wr  = wb_acc & wb_we_i;       // wb write access
    wire wb_rd  = wb_acc & ~wb_we_i;      // wb read access


	always @ (*) begin
		if (rst_i == `RstEnable) begin
			wb_ack_o <= 1'b0;
			wb_data_o <= 32'h00000000;
	  	end else if (wb_acc == 1'b0) begin
	  		wb_ack_o <= 1'b0;
	  		wb_data_o <= 32'h00000000;
	  	end else begin
	  		wb_ack_o <= 1'b1;
	  		wb_data_o <= inst_mem[wb_addr_i[`InstMemNumLog2 + 1: 2]];
	  	end
	end

endmodule