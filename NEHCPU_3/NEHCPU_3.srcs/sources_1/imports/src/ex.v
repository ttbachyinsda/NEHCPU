`include "defines.v"

module ex(

	input wire                    rst,
	
	input wire[`AluOpBus]         aluop_i,
	input wire[`AluSelBus]        alusel_i,
	input wire[`RegBus]           reg1_i,		// 32bit 
	input wire[`RegBus]           reg2_i,		// 32bit
	input wire[`RegAddrBus]       wd_i,			// 5bit, register addr
	input wire                    wreg_i,		// 1bit, write enable
	input wire                    is_in_delayslot_i,
	input wire[`RegBus]           link_addr_i,
	input wire[`RegBus] 		  inst_i,

	//hilo_reg
	input wire[`RegBus]			  hi_i,
	input wire[`RegBus] 		  lo_i,

	// from mem
	input wire 					  mem_whilo_i,
	input wire[`RegBus]			  mem_hi_i,
	input wire[`RegBus]			  mem_lo_i,
	input wire                    mem_cp0_reg_we,
	input wire[4: 0]              mem_cp0_reg_write_addr,
	input wire[`RegBus]	          mem_cp0_reg_data,

	// from wb
	input wire 					  wb_whilo_i,
	input wire[`RegBus]			  wb_hi_i,
	input wire[`RegBus]			  wb_lo_i,
	input wire                    wb_cp0_reg_we,
	input wire[4: 0]              wb_cp0_reg_write_addr,
	input wire[`RegBus]	          wb_cp0_reg_data,

	//cp0
	input wire[`RegBus]           cp0_reg_data_i,

	//exception
	input wire[31: 0]             excepttype_i,
	input wire[`RegBus]           current_inst_addr_i,

	output reg[`RegAddrBus]       wd_o,			// 5bit, register addr
	output reg                    wreg_o,		// 1bit, write enable
	output reg[`RegBus]			  wdata_o,		// 32bit, data to write

	output reg 					  whilo_o,
	output reg[`RegBus]			  hi_o,
	output reg[`RegBus]			  lo_o,

 	// cp0
	output reg[4: 0]              cp0_reg_read_addr_o,	
	output reg 	                  cp0_reg_we_o,
	output reg[4: 0] 	          cp0_reg_write_addr_o,
	output reg[`RegBus]           cp0_reg_data_o,

	output wire[`AluOpBus]  	  aluop_o,
	output wire[`RegBus]	      mem_addr_o,
	output wire[`RegBus]		  reg2_o, 	 	// data to store in mem
	
	//exception
	output wire[31: 0]            excepttype_o,
	output wire[`RegBus]          current_inst_addr_o,
	
	output wire                   is_in_delayslot_o
);

	reg[`RegBus] logicout;
	reg[`RegBus] shiftres;
	reg[`RegBus] moveres;
	reg[`RegBus] arithres;
	reg[`RegBus] HI;
	reg[`RegBus] LO;

	wire reg1_lt_reg2;
	wire[`RegBus] reg2_i_mux;
	wire[`RegBus] result_sum;
	wire[`RegBus] mult_op1;
	wire[`RegBus] mult_op2;
	wire[`DoubleRegBus] hilo_temp;
	reg[`DoubleRegBus] mulres;

    wire is_ADEL, is_ADES;
    assign is_ADES = (aluop_o == `EXE_SW_OP && mem_addr_o[1: 0] != 2'b00);
    assign is_ADEL = (aluop_o == `EXE_LHU_OP && mem_addr_o[0] != 1'b0) || 
                     (aluop_o == `EXE_LW_OP && mem_addr_o[1: 0] != 2'b00);

	assign excepttype_o = {excepttype_i[31: 12], is_ADES, is_ADEL, excepttype_i[9: 0]};

	assign current_inst_addr_o = current_inst_addr_i;
	assign is_in_delayslot_o = is_in_delayslot_i;


    always @ (*) begin 
        if(|excepttype_o) begin 
            $display("excepttype_o = %h, inst = %h", excepttype_o, inst_i);
        end
    end

	always @ (*) begin
		if(rst == `RstEnable) begin
			logicout <= `ZeroWord;
		end 
		else begin
			case (aluop_i)
				`EXE_OR_OP: begin
					logicout <= reg1_i | reg2_i;
				end
				`EXE_AND_OP: begin
					logicout <= reg1_i & reg2_i;
				end
				`EXE_NOR_OP: begin
					logicout <= ~(reg1_i | reg2_i);
				end
				`EXE_XOR_OP: begin
					logicout <= reg1_i ^ reg2_i;
				end
				default: begin
					logicout <= `ZeroWord;
				end
			endcase
		end //if
	end //always

	always @ (*) begin
		if(rst == `RstEnable) begin
			shiftres <= `ZeroWord;
		end 
		else begin
			case (aluop_i)
				`EXE_SLL_OP: begin
					shiftres <= reg2_i << reg1_i[4: 0];
				end
				`EXE_SRL_OP: begin
					shiftres <= reg2_i >> reg1_i[4: 0];
				end
				`EXE_SRA_OP: begin
					shiftres <= ({32{reg2_i[31]}} << (6'd32 - {1'b0, reg1_i[4: 0]})) 
							| (reg2_i >> reg1_i[4: 0]);
				end
				default: begin
					shiftres <= `ZeroWord;
				end
			endcase
		end //if
	end //always

	always @ (*) begin 
		if(rst == `RstEnable) begin	
			{HI, LO} <= {`ZeroWord, `ZeroWord};
		end
		else if(mem_whilo_i == `WriteEnable) begin
			{HI, LO} <= {mem_hi_i, mem_lo_i};
		end
		else if(wb_whilo_i == `WriteEnable) begin
			{HI, LO} <= {wb_hi_i, wb_lo_i};
		end	
		else begin
			{HI, LO} <= {hi_i, lo_i};
		end
	end

	// mf instructions
	always @ (*) begin
		if(rst == `RstEnable) begin	
			moveres <= `ZeroWord;
		end
		else begin 
			case (aluop_i)
				`EXE_MFHI_OP: begin
					moveres <= HI;
				end
				`EXE_MFLO_OP: begin
					moveres <= LO;
				end
				`EXE_MFC0_OP: begin 
					cp0_reg_read_addr_o <= inst_i[15: 11];
					moveres <= cp0_reg_data_i;

					if(mem_cp0_reg_we == `WriteEnable && 
						mem_cp0_reg_write_addr == inst_i[15: 11]) begin 
						moveres <= mem_cp0_reg_data;
					end

					else if(wb_cp0_reg_we == `WriteEnable && 
						wb_cp0_reg_write_addr == inst_i[15: 11]) begin 
						moveres <= wb_cp0_reg_data;
					end 
 				end
				default : begin
				end // default
			endcase
		end // else
	end // always
	
	//hi lo
	always @ (*) begin 
		if(rst == `RstEnable) begin
			whilo_o <= `WriteDisable;
			hi_o <= `ZeroWord;
			lo_o <= `ZeroWord;
		end
		else begin 
			case (aluop_i)
				`EXE_MTHI_OP: begin 
					whilo_o <= `WriteEnable;
					hi_o <= reg1_i;
					lo_o <= LO;
				end
				`EXE_MTLO_OP: begin 
					whilo_o <= `WriteEnable;
					hi_o <= HI;
					lo_o <= reg1_i;
				end
				`EXE_MULT_OP: begin 
					whilo_o <= `WriteEnable;
					hi_o <= mulres[63: 32];
					lo_o <= mulres[31: 0];
				end
				default : begin
					whilo_o <= `WriteDisable;
					hi_o <= `ZeroWord;
					lo_o <= `ZeroWord;
				end // default
			endcase
		end // else
	end

	//MTC0
	always @ (*) begin
		if(rst == `RstEnable) begin
			cp0_reg_write_addr_o <= 5'b00000;
			cp0_reg_we_o <= `WriteDisable;
			cp0_reg_data_o <= `ZeroWord;
		end
		else if(aluop_i == `EXE_MTC0_OP) begin
			cp0_reg_write_addr_o <= inst_i[15: 11];
			cp0_reg_we_o <= `WriteEnable;
			cp0_reg_data_o <= reg1_i;
		end 
		else begin
			cp0_reg_write_addr_o <= 5'b00000;
			cp0_reg_we_o <= `WriteDisable;
			cp0_reg_data_o <= `ZeroWord;
		end
	end

	assign reg2_i_mux = ((aluop_i == `EXE_SUBU_OP) || (aluop_i == `EXE_SLT_OP))?
						(~reg2_i + 1): reg2_i;
    assign result_sum = reg1_i + reg2_i_mux;
    assign reg1_lt_reg2 = (aluop_i == `EXE_SLT_OP)? ((reg1_i[31] && !reg2_i[31]) // signed, - <гл 
    	|| (!reg1_i[31] && !reg2_i[31] && result_sum[31]) // signed, - < -
    	|| (reg1_i[31] && reg2_i[31] && result_sum[31])) // signed, + < +
    	: (reg1_i < reg2_i);				// unsigned, reg1 < reg2

    always @ (*) begin 
    	if(rst == `RstEnable) begin
    		arithres <= `ZeroWord;
    	end
    	else begin 
    		case (aluop_i)
    			`EXE_SLT_OP, `EXE_SLTU_OP: begin  // slt slti slti sltiu
    				arithres <= reg1_lt_reg2;
    			end
    			`EXE_ADDIU_OP, `EXE_ADDU_OP, `EXE_SUBU_OP: begin // addu addiu subu
    				arithres <= result_sum;
    			end    		
    			default: begin 
    				arithres <= `ZeroWord;
    			end
    		endcase
    	end // else
    end // always

    // multiplication 
    assign mult_op1 = (reg1_i[31] == 1'b1)? (~reg1_i + 1): reg1_i;
    assign mult_op2 = (reg2_i[31] == 1'b1)? (~reg2_i + 1): reg2_i;
    assign hilo_temp = mult_op1 * mult_op2;
    always @ (*) begin 
    	if(rst == `RstEnable) begin
    		mulres <= {`ZeroWord, `ZeroWord};
    	end
    	else if(aluop_i == `EXE_MULT_OP) begin
    		if(reg1_i[31] ^ reg2_i[31] == 1'b1) begin
    			mulres <= ~hilo_temp + 1;
    		end
    		else begin
    			mulres <= hilo_temp;
    		end // else
    	end	 // else if 
    end // always

    // load and store and tlbwi
    assign aluop_o = aluop_i;
    assign mem_addr_o = reg1_i + {{16{inst_i[15]}}, inst_i[15: 0]};
    assign reg2_o = reg2_i;	

 	always @ (*) begin
		wd_o <= wd_i;	 	 	
		wreg_o <= wreg_i;
	 	case (alusel_i) 
	 		`EXE_RES_LOGIC: begin
	 			wdata_o <= logicout;
	 		end
	 		`EXE_RES_SHIFT:	begin
	 			wdata_o <= shiftres;
	 		end
	 		`EXE_RES_MOVE: begin
	 			wdata_o <= moveres;
	 		end
	 		`EXE_RES_ARITHMETIC: begin
	 			wdata_o <= arithres;
	 		end
	 		`EXE_RES_JUMP_BRANCH: begin 
	 			wdata_o <= link_addr_i;
	 		end
	 		default: begin
	 			wdata_o <= `ZeroWord;
	 		end
	 	endcase
 	end	

endmodule