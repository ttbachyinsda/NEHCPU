`include "defines.v"

module mem(

	input wire					rst,
	
	//	
	input wire[`RegAddrBus]     wd_i,
	input wire                  wreg_i,
	input wire[`RegBus]			wdata_i,
	input wire 					whilo_i,
	input wire[`RegBus]			hi_i,
	input wire[`RegBus]			lo_i,
	input wire[`AluOpBus] 		aluop_i,
	input wire[`RegBus] 		mem_addr_i,
	input wire[`RegBus]			reg2_i,

	// write cp0
	input wire                  cp0_reg_we_i,
	input wire[4:0]             cp0_reg_write_addr_i,
	input wire[`RegBus]         cp0_reg_data_i,

	// from RAM
	input wire[`RegBus] 		mem_data_i,

	//exception
	input wire[31: 0] excepttype_i,
	input wire[`RegBus] current_inst_addr_i,
	input wire is_in_delayslot_i,
	input wire[`RegBus] cp0_status_i,
	input wire[`RegBus] cp0_cause_i,
	input wire[`RegBus] cp0_epc_i,
	// data confliction when except
	input wire wb_cp0_reg_we,
	input wire[4: 0] wb_cp0_reg_write_addr,
	input wire[`RegBus] wb_cp0_reg_data,

	// to RAM
	output reg[`RegBus] 		mem_addr_o,
	output wire 				mem_we_o,	// write RAM or not
	output reg[3: 0]			mem_sel_o,
	output reg[`RegBus]			mem_data_o,
	output reg 					mem_ce_o,

	output reg[`RegAddrBus]		wd_o,
	output reg                  wreg_o,
	output reg[`RegBus]			wdata_o,
	output reg 				    whilo_o,
	output reg[`RegBus]		    hi_o,
	output reg[`RegBus]		    lo_o,
	//cp0
	output reg                  cp0_reg_we_o,
	output reg[4:0]             cp0_reg_write_addr_o,
	output reg[`RegBus]         cp0_reg_data_o,

	//exception
	output reg[31: 0] excepttype_o,
	output wire[`RegBus] current_inst_addr_o,
    output wire[`RegBus] unaligned_addr_o,
	output wire[`RegBus] cp0_epc_o,
	output wire is_in_delayslot_o,
	input wire is_tlb_modify,
    input wire is_tlbl_data,
    input wire is_tlbs,
    input wire[31: 0] badvaddr_i,
    output wire[31: 0] badvaddr_o,
    output wire is_save_inst,

	// tlb
	input wire[`RegBus] cp0_index_i,
	input wire[`RegBus] cp0_entrylo0_i,
	input wire[`RegBus] cp0_entrylo1_i,
	input wire[`RegBus] cp0_entryhi_i,
	output wire[`TLB_WRITE_STRUCT_WIDTH - 1:0] tlb_write_struct_o
	
);

//exception
	reg[`RegBus] cp0_status;
	reg[`RegBus] cp0_cause;
	reg[`RegBus] cp0_epc;
	reg[`RegBus] cp0_index;
	reg[`RegBus] cp0_entrylo0;
	reg[`RegBus] cp0_entrylo1;
	reg[`RegBus] cp0_entryhi;
	
	// tlb
	wire tlb_write_enable;
    wire [`TLB_INDEX_WIDTH-1: 0] tlb_write_index;
    wire [`TLB_ENTRY_WIDTH-1: 0] tlb_write_entry;

    assign tlb_write_enable = (aluop_i == `EXE_TLBWI_OP);
    assign tlb_write_index = cp0_index[3: 0];
    assign tlb_write_entry = {cp0_entryhi[31: 13], // VPN2
			cp0_entrylo1[25: 6], cp0_entrylo1[2: 1], // FPN1, V1, D1
			cp0_entrylo0[25: 6], cp0_entrylo0[2: 1]};// FPN0, V0, D0
	assign tlb_write_struct_o = {tlb_write_enable, tlb_write_index, tlb_write_entry};

	
	reg mem_we;

	assign is_in_delayslot_o = is_in_delayslot_i;
	assign current_inst_addr_o = current_inst_addr_i;
    assign unaligned_addr_o = mem_addr_i;
	assign cp0_epc_o = cp0_epc;	
	assign badvaddr_o = (excepttype_i[13] == 1'b1)? current_inst_addr_i: badvaddr_i;
	assign is_save_inst = mem_we;

 	always @ (*) begin
		if(rst == `RstEnable) begin
			excepttype_o <= `ZeroWord;
		end else begin
			excepttype_o <= `ZeroWord;	
			if(current_inst_addr_i != `ZeroWord) begin
				if(((cp0_cause[15:8] & (cp0_status[15:8])) != 8'h00) &&
				 	(cp0_status[1] == 1'b0) && (cp0_status[0] == 1'b1)) begin
					excepttype_o <= 32'h00000001;        //interrupt
				end 
				else if(excepttype_i[8] == 1'b1) begin
			  		excepttype_o <= 32'h00000008;        //syscall
				end
				else if(excepttype_i[13] == 1'b1) begin  
					excepttype_o <= 32'h0000000f;        // tlbl_inst
				end	 
				else if(is_tlbl_data && (mem_addr_i != `ZeroWord)) begin 
					excepttype_o <= 32'h00000011;        // is tlbl data
				end
				else if(is_tlbs && (mem_addr_i != `ZeroWord)) begin 
					excepttype_o <= 32'h00000012;        // is tlbs
				end
				else if(is_tlb_modify && (mem_addr_i != `ZeroWord)) begin 
					excepttype_o <= 32'h00000010;        // is tlb modify
				end
				else if(excepttype_i[9] == 1'b1) begin
					excepttype_o <= 32'h0000000a;        //inst_invalid
				end
				else if(excepttype_i[10] == 1'b1) begin 
					excepttype_o <= 32'h0000000b;        // ADEL
				end
				else if(excepttype_i[11] == 1'b1) begin 
					excepttype_o <= 32'h0000000c;        // ADES
				end 
				else if(excepttype_i[12] == 1'b1) begin  
					excepttype_o <= 32'h0000000e;        //eret
				end
			end //if		
		end // else
	end // always

	assign mem_we_o = mem_we & (~(|excepttype_o));
	
	always @ (*) begin
		if(rst == `RstEnable) begin
			wd_o <= `NOPRegAddr;
			wreg_o <= `WriteDisable;
		  	wdata_o <= `ZeroWord;
		  	whilo_o <= `WriteDisable;
		  	hi_o <=	`ZeroWord;
		  	lo_o <= `ZeroWord;
		
			mem_addr_o <= `ZeroWord;
			mem_we <= `WriteDisable;
			mem_sel_o <= 4'b0000;
			mem_data_o <= `ZeroWord;
			mem_ce_o <= `ChipDisable;
			//cp0
			cp0_reg_we_o <= `WriteDisable;
		  	cp0_reg_write_addr_o <= 5'b00000;
		  	cp0_reg_data_o <= `ZeroWord;	
		end 
		else begin
		  	wd_o <= wd_i;
			wreg_o <= wreg_i;
			wdata_o <= wdata_i;
		  	whilo_o <= whilo_i;
		  	hi_o <= hi_i;
		  	lo_o <= lo_i;
		  	cp0_reg_we_o <= cp0_reg_we_i;
		  	cp0_reg_write_addr_o <= cp0_reg_write_addr_i;
		  	cp0_reg_data_o <= cp0_reg_data_i;	
			
			mem_addr_o <= `ZeroWord;
			mem_we <= `WriteDisable;
			mem_sel_o <= 4'b1111;
			mem_ce_o <= `ChipDisable;

			case (aluop_i)
				`EXE_LB_OP: begin 
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteDisable;
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1: 0])
						2'b00: begin 
							wdata_o <= {{24{mem_data_i[7]}}, mem_data_i[7: 0]};
							mem_sel_o <= 4'b0001;
						end
						2'b01: begin
							wdata_o <= {{24{mem_data_i[15]}}, mem_data_i[15: 8]};
							mem_sel_o <= 4'b0010;
						end
						2'b10: begin
							wdata_o <= {{24{mem_data_i[23]}}, mem_data_i[23: 16]};
							mem_sel_o <= 4'b0100;
						end
						2'b11: begin
							wdata_o <= {{24{mem_data_i[31]}}, mem_data_i[31: 24]};
							mem_sel_o <= 4'b1000;
						end		
						default: begin
                            wdata_o <= `ZeroWord;
						end
					endcase
				end // exe_lb_op
				`EXE_LBU_OP: begin 
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteDisable;
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1: 0])
						2'b00: begin 
							wdata_o <= {{24{1'b0}}, mem_data_i[7: 0]};
							mem_sel_o <= 4'b0001;
						end
						2'b01: begin
							wdata_o <= {{24{1'b0}}, mem_data_i[15: 8]};
							mem_sel_o <= 4'b0010; 
						end
						2'b10: begin
							wdata_o <= {{24{1'b0}}, mem_data_i[23: 16]};
							mem_sel_o <= 4'b0100;
						end
						2'b11: begin
							wdata_o <= {{24{1'b0}}, mem_data_i[31: 24]};
							mem_sel_o <= 4'b1000;
						end
						default: begin
                            wdata_o <= `ZeroWord;
						end
					endcase
				end // exe_lbu_op
				`EXE_LHU_OP: begin 
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteDisable;
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1: 0])
						2'b00: begin 
							wdata_o <= {{16{1'b0}}, mem_data_i[15: 0]};
							mem_sel_o <= 4'b0011;
						end
						2'b10: begin
							wdata_o <= {{16{1'b0}}, mem_data_i[31: 15]};
							mem_sel_o <= 4'b1100;
						end
						default: begin
                            wdata_o <= `ZeroWord;
						end
					endcase
				end // exe_lhu_op
				`EXE_LW_OP: begin 
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteDisable;
					mem_ce_o <= `ChipEnable;
					wdata_o <= mem_data_i;
					mem_sel_o <= 4'b1111;
				end 
				`EXE_SB_OP: begin 
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteEnable;
					mem_ce_o <= `ChipEnable;
					mem_data_o <= {4{reg2_i[7: 0]}};
					case (mem_addr_i[1: 0])
						2'b00: begin 
							mem_sel_o <= 4'b0001;
						end
						2'b01: begin
							mem_sel_o <= 4'b0010;						
						end
						2'b10: begin
							mem_sel_o <= 4'b0100;						
						end
						2'b11: begin
							mem_sel_o <= 4'b1000;
						end
						default: begin
							mem_sel_o <= 4'b0000;
						end
					endcase
				end
				`EXE_SW_OP: begin 
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteEnable;
					mem_ce_o <= `ChipEnable;
					mem_data_o <= reg2_i;
					mem_sel_o <= 4'b1111;
				end 
				default : begin 
				end
			endcase // aluop_i
		end //if
	end //always

	always @ (*) begin
		if(rst == `RstEnable) begin
			cp0_status <= `ZeroWord;
		end 
		else if((wb_cp0_reg_we == `WriteEnable) && 
				(wb_cp0_reg_write_addr == `CP0_REG_STATUS ))begin
			cp0_status <= wb_cp0_reg_data;
		end 
		else begin
		  	cp0_status <= cp0_status_i;
		end
	end
	// get the newest value of cp0_epc
	always @ (*) begin
		if(rst == `RstEnable) begin
			cp0_epc <= `ZeroWord;
		end 
		else if((wb_cp0_reg_we == `WriteEnable) && 
				(wb_cp0_reg_write_addr == `CP0_REG_EPC ))begin
			cp0_epc <= wb_cp0_reg_data;
		end 
		else begin
		  	cp0_epc <= cp0_epc_i;
		end
	end
	// get the newest value of cp0_cause
  	always @ (*) begin
		if(rst == `RstEnable) begin
			cp0_cause <= `ZeroWord;
		end 
		else if((wb_cp0_reg_we == `WriteEnable) && 
				(wb_cp0_reg_write_addr == `CP0_REG_CAUSE ))begin
			cp0_cause[9: 8] <= wb_cp0_reg_data[9: 8];
			cp0_cause[22] <= wb_cp0_reg_data[22];
			cp0_cause[23] <= wb_cp0_reg_data[23];
		end 
		else begin
		  	cp0_cause <= cp0_cause_i;
		end
	end

	// get the newest value of cp0_index
  	always @ (*) begin
		if(rst == `RstEnable) begin
			cp0_index <= `ZeroWord;
		end 
		else if((wb_cp0_reg_we == `WriteEnable) && 
				(wb_cp0_reg_write_addr == `CP0_REG_INDEX ))begin
			cp0_index[3: 0] <= wb_cp0_reg_data[3: 0];
		end 
		else begin
		  	cp0_index <= cp0_index_i;
		end
	end

	// get the newest value of cp0_entrylo0
  	always @ (*) begin
		if(rst == `RstEnable) begin
			cp0_entrylo0 <= `ZeroWord;
		end 
		else if((wb_cp0_reg_we == `WriteEnable) && 
				(wb_cp0_reg_write_addr == `CP0_REG_ENTRYLO0 ))begin
			cp0_entrylo0[25: 6] <= wb_cp0_reg_data[25: 6];
            cp0_entrylo0[2: 0] <= wb_cp0_reg_data[2: 0];
		end 
		else begin
		  	cp0_entrylo0 <= cp0_entrylo0_i;
		end
	end

	// get the newest value of cp0_entrylo1
  	always @ (*) begin
		if(rst == `RstEnable) begin
			cp0_entrylo1 <= `ZeroWord;
		end 
		else if((wb_cp0_reg_we == `WriteEnable) && 
				(wb_cp0_reg_write_addr == `CP0_REG_ENTRYLO1 ))begin
			cp0_entrylo1[25: 6] <= wb_cp0_reg_data[25: 6];
            cp0_entrylo1[2: 0] <= wb_cp0_reg_data[2: 0];
		end 
		else begin
		  	cp0_entrylo1 <= cp0_entrylo1_i;
		end
	end

	// get the newest value of cp0_entrylo0
  	always @ (*) begin
		if(rst == `RstEnable) begin
			cp0_entryhi <= `ZeroWord;
		end 
		else if((wb_cp0_reg_we == `WriteEnable) && 
				(wb_cp0_reg_write_addr == `CP0_REG_ENTRYHI ))begin
			cp0_entryhi[31: 13] <= wb_cp0_reg_data[31: 13];
            cp0_entryhi[7: 0] <= wb_cp0_reg_data[7: 0];
		end 
		else begin
		  	cp0_entryhi <= cp0_entryhi_i;
		end
	end

endmodule