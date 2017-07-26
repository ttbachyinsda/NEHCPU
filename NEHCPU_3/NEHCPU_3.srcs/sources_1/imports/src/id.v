`include "defines.v"

module id(

	input wire                    rst,
	input wire[`InstAddrBus]      pc_i,				// 32bit, address
	input wire[`InstBus]          inst_i,			// 32bit, instruction

	input wire[`RegBus]           reg1_data_i,		// data read from register 1
	input wire[`RegBus]           reg2_data_i,		// ... 					   2

	// message from ex => solve correlated data
	input wire                    ex_wreg_i,
	input wire[`RegAddrBus]       ex_wd_i,
	input wire[`RegBus]           ex_wdata_i,
	// message from mem => solve correlated data
	input wire                    mem_wreg_i,
	input wire[`RegAddrBus]       mem_wd_i,
	input wire[`RegBus]           mem_wdata_i,

	// branch 
	input wire                    is_in_delayslot_i,

    // load confliction  
    input wire[`AluOpBus]         ex_aluop_i,

	output reg                    reg1_read_o,     	// register 1, read, enable
	output reg                    reg2_read_o,     
	output reg[`RegAddrBus]       reg1_addr_o,		// 5bit, register address 1
	output reg[`RegAddrBus]       reg2_addr_o, 	      
	
	output reg[`AluOpBus]         aluop_o,			// 8bit, operation subtype 
	output reg[`AluSelBus]        alusel_o,		// 3bit, operation type
	output reg[`RegBus]           reg1_o,			// 32bit, src operation number 1
	output reg[`RegBus]           reg2_o,
	output reg[`RegAddrBus]       wd_o,				// 5bit, address of register to write
	output reg                    wreg_o,			// 1bit, write enable 

	// branch 
	output reg                    next_inst_in_delayslot_o,

	output reg                    branch_flag_o,
	output reg[`RegBus]           branch_target_addr_o,
	output reg[`RegBus]           link_addr_o,
	output reg                    is_in_delayslot_o,

	// load_store
	output wire[`RegBus]          inst_o,
	output wire                   stallreq,


    // exception
    input wire 					  is_tlbl_inst,
    output wire[31: 0]            excepttype_o,
    output wire[`RegBus]          current_inst_addr_o

);

	wire[5:0] op = inst_i[31:26];
	wire[4:0] op2 = inst_i[10:6];
	wire[5:0] op3 = inst_i[5:0];
	wire[4:0] op4 = inst_i[20:16];
	reg[`RegBus]    imm;
	reg instvalid;

  	//branch and delayslot
  	wire[`RegBus] pc_plus_4;
  	wire[`RegBus] pc_plus_8;
	wire[`RegBus] imm_sll2_signed;

	//exception
	reg excepttype_is_syscall;
	reg excepttype_is_eret;

	wire exc_is_tlbl_inst;
	assign exc_is_tlbl_inst = is_tlbl_inst && (pc_i != `ZeroWord);

	assign excepttype_o = {18'b0, exc_is_tlbl_inst, excepttype_is_eret, 2'b00, instvalid, excepttype_is_syscall, 8'b0};
	assign current_inst_addr_o = pc_i;


    reg stallreq_for_reg1_loadrelate;
    reg stallreq_for_reg2_loadrelate;
    wire pre_inst_is_load;

    assign stallreq = stallreq_for_reg1_loadrelate | stallreq_for_reg2_loadrelate;
    assign pre_inst_is_load = ((ex_aluop_i == `EXE_LB_OP) || (ex_aluop_i == `EXE_LBU_OP) ||
                    (ex_aluop_i == `EXE_LHU_OP) || (ex_aluop_i == `EXE_LW_OP))? 1'b1: 1'b0;

    // branch and jump
	assign pc_plus_4 = pc_i + 4;
	assign pc_plus_8 = pc_i + 8;
  	assign imm_sll2_signed = {{14{inst_i[15]}}, inst_i[15: 0], 2'b00};

  	assign inst_o = inst_i;
 
	always @ (*) begin	
		if (rst == `RstEnable) begin
			aluop_o <= `EXE_NOP_OP;
			alusel_o <= `EXE_RES_NOP;
			wd_o <= `NOPRegAddr;		// $0
			wreg_o <= `WriteDisable;
			reg1_read_o <= 1'b0;
			reg2_read_o <= 1'b0;
			reg1_addr_o <= `NOPRegAddr;
			reg2_addr_o <= `NOPRegAddr;
			imm <= `ZeroWord;	
			//branch 
			link_addr_o <= `ZeroWord;
			branch_target_addr_o <= `ZeroWord;
			branch_flag_o <= `NotBranch;
			next_inst_in_delayslot_o <= `NotInDelaySlot;
	  	end 
	  	else begin
			aluop_o <= `EXE_NOP_OP;
			alusel_o <= `EXE_RES_NOP;
			wd_o <= inst_i[15:11];
			wreg_o <= `WriteDisable;
			instvalid <= `InstInvalid;	   
			reg1_read_o <= 1'b0;
			reg2_read_o <= 1'b0;
			reg1_addr_o <= inst_i[25:21];
			reg2_addr_o <= inst_i[20:16];		
			imm <= `ZeroWord;
			//branch 
			link_addr_o <= `ZeroWord;
			branch_target_addr_o <= `ZeroWord;
			branch_flag_o <= `NotBranch;
			next_inst_in_delayslot_o <= `NotInDelaySlot;	
			//exception
			excepttype_is_syscall <= 1'b0;
			excepttype_is_eret <= 1'b0;
			instvalid <= `InstInvalid;	
            // $display("op = %b", op);	
		  	case (op)
		  		`EXE_SPECIAL_INST: begin 
		  			case (op2)
		  				5'b00000: begin 
		  					case (op3)
		  						// logic
		  						`EXE_OR: begin 
		  							wreg_o <= `WriteEnable;
		  							aluop_o <= `EXE_OR_OP;
		  							alusel_o <= `EXE_RES_LOGIC;
		  							reg1_read_o <= 1'b1;
		  							reg2_read_o <= 1'b1;
		  							instvalid <= `InstValid;
		  						end
		  						`EXE_AND: begin 
		  							wreg_o <= `WriteEnable;
		  							aluop_o <= `EXE_AND_OP;
		  							alusel_o <= `EXE_RES_LOGIC;
		  							reg1_read_o <= 1'b1;
		  							reg2_read_o <= 1'b1;
		  							instvalid <= `InstValid;
		  						end
		  						`EXE_XOR: begin 
		  							wreg_o <= `WriteEnable;
		  							aluop_o <= `EXE_XOR_OP;
		  							alusel_o <= `EXE_RES_LOGIC;
		  							reg1_read_o <= 1'b1;
		  							reg2_read_o <= 1'b1;
		  							instvalid <= `InstValid;
		  						end
		  						`EXE_NOR: begin 
		  							wreg_o <= `WriteEnable;
		  							aluop_o <= `EXE_NOR_OP;
		  							alusel_o <= `EXE_RES_LOGIC;
		  							reg1_read_o <= 1'b1;
		  							reg2_read_o <= 1'b1;
		  							instvalid <= `InstValid;
		  						end

		  						//shift
		  						`EXE_SLLV: begin 
		  							wreg_o <= `WriteEnable;
		  							aluop_o <= `EXE_SLL_OP;
		  							alusel_o <= `EXE_RES_SHIFT;
		  							reg1_read_o <= 1'b1;
		  							reg2_read_o <= 1'b1;
		  							instvalid <= `InstValid;
		  						end
		  						`EXE_SRLV: begin 
		  							wreg_o <= `WriteEnable;
		  							aluop_o <= `EXE_SRL_OP;
		  							alusel_o <= `EXE_RES_SHIFT;
		  							reg1_read_o <= 1'b1;
		  							reg2_read_o <= 1'b1;
		  							instvalid <= `InstValid;
		  						end
		  						`EXE_SRAV: begin 
		  							wreg_o <= `WriteEnable;
		  							aluop_o <= `EXE_SRA_OP;
		  							alusel_o <= `EXE_RES_SHIFT;
		  							reg1_read_o <= 1'b1;
		  							reg2_read_o <= 1'b1;
		  							instvalid <= `InstValid;
		  						end	

		  						//move
		  						`EXE_MFHI: begin
		  							wreg_o <= `WriteEnable;
		  							aluop_o <= `EXE_MFHI_OP;
		  							alusel_o <= `EXE_RES_MOVE;
		  							reg1_read_o <= 1'b0;
		  							reg2_read_o <= 1'b0;
		  							instvalid <= `InstValid;
		  						end
		  						`EXE_MFLO: begin
		  							wreg_o <= `WriteEnable;
		  							aluop_o <= `EXE_MFLO_OP;
		  							alusel_o <= `EXE_RES_MOVE;
		  							reg1_read_o <= 1'b0;
		  							reg2_read_o <= 1'b0;
		  							instvalid <= `InstValid;
		  						end
		  						`EXE_MTHI: begin
		  							wreg_o <= `WriteDisable;
		  							aluop_o <= `EXE_MTHI_OP;
		  							alusel_o <= `EXE_RES_MOVE;
		  							reg1_read_o <= 1'b1;
		  							reg2_read_o <= 1'b0;
		  							instvalid <= `InstValid;
		  						end
		  						`EXE_MTLO: begin
		  							wreg_o <= `WriteDisable;
		  							aluop_o <= `EXE_MTLO_OP;
		  							alusel_o <= `EXE_RES_MOVE;
		  							reg1_read_o <= 1'b1;
		  							reg2_read_o <= 1'b0;
		  							instvalid <= `InstValid;
		  						end

		  						// arithmetic
		  						`EXE_ADDU: begin
		  							wreg_o <= `WriteEnable;
		  							aluop_o <= `EXE_ADDU_OP;
		  							alusel_o <= `EXE_RES_ARITHMETIC;
		  							reg1_read_o <= 1'b1;
		  							reg2_read_o <= 1'b1;
		  							instvalid <= `InstValid;
		  						end
		  						`EXE_SLT: begin
		  							wreg_o <= `WriteEnable;
		  							aluop_o <= `EXE_SLT_OP;
		  							alusel_o <= `EXE_RES_ARITHMETIC;
		  							reg1_read_o <= 1'b1;
		  							reg2_read_o <= 1'b1;
		  							instvalid <= `InstValid;
		  						end
		  						`EXE_SLTU: begin
		  							wreg_o <= `WriteEnable;
		  							aluop_o <= `EXE_SLTU_OP;
		  							alusel_o <= `EXE_RES_ARITHMETIC;
		  							reg1_read_o <= 1'b1;
		  							reg2_read_o <= 1'b1;
		  							instvalid <= `InstValid;
		  						end
		  						`EXE_SUBU: begin
		  							wreg_o <= `WriteEnable;
		  							aluop_o <= `EXE_SUBU_OP;
		  							alusel_o <= `EXE_RES_ARITHMETIC;
		  							reg1_read_o <= 1'b1;
		  							reg2_read_o <= 1'b1;
		  							instvalid <= `InstValid;
		  						end
		  						`EXE_MULT: begin
		  							wreg_o <= `WriteDisable;
		  							aluop_o <= `EXE_MULT_OP;
		  							// alusel_o <= `EXE_RES_NOP;
		  							reg1_read_o <= 1'b1;
		  							reg2_read_o <= 1'b1;
		  							instvalid <= `InstValid;
		  						end

		  						//branch and jump
		  						`EXE_JR: begin
		  							wreg_o <= `WriteDisable;
		  							aluop_o <= `EXE_JR_OP;
		  							alusel_o <= `EXE_RES_JUMP_BRANCH;
		  							reg1_read_o <= 1'b1;
		  							reg2_read_o <= 1'b0;
		  							
		  							link_addr_o <= `ZeroWord;
									branch_target_addr_o <= reg1_o;
									branch_flag_o <= `Branch;
									next_inst_in_delayslot_o <= `InDelaySlot;	
		  							instvalid <= `InstValid;
		  						end	
		  						`EXE_JALR: begin
		  							wreg_o <= `WriteEnable;
		  							aluop_o <= `EXE_JALR_OP;
		  							alusel_o <= `EXE_RES_JUMP_BRANCH;
		  							reg1_read_o <= 1'b1;
		  							reg2_read_o <= 1'b0;
		  							wd_o <= inst_i[15: 11];
		  							
		  							link_addr_o <= pc_plus_8;
									branch_target_addr_o <= reg1_o;
									branch_flag_o <= `Branch;
									next_inst_in_delayslot_o <= `InDelaySlot;	
		  							instvalid <= `InstValid;
		  						end			  				
		  						// syscall
		  						`EXE_SYSCALL: begin 
		  							wreg_o <= `WriteDisable;
		  							aluop_o <= `EXE_SYSCALL_OP;
		  							alusel_o <= `EXE_RES_NOP;
		  							reg1_read_o <= 1'b0;
		  							reg2_read_o <= 1'b0;
		  							instvalid <= `InstValid;
		  							excepttype_is_syscall <= 1'b1;
		  						end		
		  						default : begin
		  						end // end default
		  					endcase
		  				end // 5'b00000
		  			endcase // op2
		  		end // EXE_SPECIAL_INST
		  			
			  	`EXE_ORI: 			begin                //ORI
			  		wreg_o <= `WriteEnable;		
			  		aluop_o <= `EXE_OR_OP;
			  		alusel_o <= `EXE_RES_LOGIC; 
			  		reg1_read_o <= 1'b1;	
			  		reg2_read_o <= 1'b0;	  	
					imm <= {16'h0, inst_i[15:0]};		// unsigned 	
					wd_o <= inst_i[20:16];
					instvalid <= `InstValid;	
				end 
				`EXE_ANDI: 			begin                //ANDI
			  		wreg_o <= `WriteEnable;		
			  		aluop_o <= `EXE_AND_OP;
			  		alusel_o <= `EXE_RES_LOGIC; 
			  		reg1_read_o <= 1'b1;	
			  		reg2_read_o <= 1'b0;	  	
					imm <= {16'h0, inst_i[15:0]};		// unsigned 	
					wd_o <= inst_i[20:16];
					instvalid <= `InstValid;	
				end 	
				`EXE_XORI: 			begin                //XORI
			  		wreg_o <= `WriteEnable;		
			  		aluop_o <= `EXE_XOR_OP;
			  		alusel_o <= `EXE_RES_LOGIC; 
			  		reg1_read_o <= 1'b1;	
			  		reg2_read_o <= 1'b0;	  	
					imm <= {16'h0, inst_i[15:0]};		// unsigned 	
					wd_o <= inst_i[20:16];
					instvalid <= `InstValid;	
				end 			
				`EXE_LUI: 			begin                //LUI
			  		wreg_o <= `WriteEnable;		
			  		aluop_o <= `EXE_OR_OP;				// convert to (ori rt $0 imm)
			  		alusel_o <= `EXE_RES_LOGIC; 
			  		reg1_read_o <= 1'b1;				// reg1_addr_o == 5'b00000
			  		reg2_read_o <= 1'b0;	  	
					imm <= {inst_i[15:0], 16'h0};		
					wd_o <= inst_i[20:16];
					instvalid <= `InstValid;	
				end 
				// arithmetic imm
				`EXE_SLTI: 			begin                
			  		wreg_o <= `WriteEnable;		
			  		aluop_o <= `EXE_SLT_OP;				
			  		alusel_o <= `EXE_RES_ARITHMETIC; 
			  		reg1_read_o <= 1'b1;				
			  		reg2_read_o <= 1'b0;	  	
					imm <= {{16{inst_i[15]}}, inst_i[15:0]};		
					wd_o <= inst_i[20:16];
					instvalid <= `InstValid;	
				end
				`EXE_SLTIU: 			begin                
			  		wreg_o <= `WriteEnable;		
			  		aluop_o <= `EXE_SLTU_OP;				
			  		alusel_o <= `EXE_RES_ARITHMETIC; 
			  		reg1_read_o <= 1'b1;				
			  		reg2_read_o <= 1'b0;	  	
					imm <= {16'h0, inst_i[15:0]};		
					wd_o <= inst_i[20:16];
					instvalid <= `InstValid;	
				end
				`EXE_ADDIU: 			begin                
			  		wreg_o <= `WriteEnable;		
			  		aluop_o <= `EXE_ADDIU_OP;				
			  		alusel_o <= `EXE_RES_ARITHMETIC; 
			  		reg1_read_o <= 1'b1;				
			  		reg2_read_o <= 1'b0;	  	
					imm <= {{16{inst_i[15]}}, inst_i[15:0]};		
					wd_o <= inst_i[20:16];
					instvalid <= `InstValid;	
				end
				`EXE_J: begin
					wreg_o <= `WriteDisable;
					aluop_o <= `EXE_J_OP;
					alusel_o <= `EXE_RES_JUMP_BRANCH;
					reg1_read_o <= 1'b0;
					reg2_read_o <= 1'b0;
					
					link_addr_o <= `ZeroWord;
					branch_target_addr_o <= {pc_plus_4[31: 28], inst_i[25: 0], 2'b00};
					branch_flag_o <= `Branch;
					next_inst_in_delayslot_o <= `InDelaySlot;	
					instvalid <= `InstValid;
				end	
				`EXE_JAL: begin
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_JAL_OP;
					alusel_o <= `EXE_RES_JUMP_BRANCH;
					reg1_read_o <= 1'b0;
					reg2_read_o <= 1'b0;
					wd_o <= 5'b11111;
					
					link_addr_o <= pc_plus_8;
					branch_target_addr_o <= {pc_plus_4[31: 28], inst_i[25: 0], 2'b00};
					branch_flag_o <= `Branch;
					next_inst_in_delayslot_o <= `InDelaySlot;	
					instvalid <= `InstValid;
				end
				//beq bgtz blez bne 	
				`EXE_BEQ: begin
					wreg_o <= `WriteDisable;
					aluop_o <= `EXE_BEQ_OP;
					alusel_o <= `EXE_RES_JUMP_BRANCH;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b1;
					if(reg1_o == reg2_o) begin
						link_addr_o <= `ZeroWord;
						branch_target_addr_o <= pc_plus_4 + imm_sll2_signed;
						branch_flag_o <= `Branch;
						next_inst_in_delayslot_o <= `InDelaySlot;
					end	
					instvalid <= `InstValid;
				end
				`EXE_BGTZ: begin
					wreg_o <= `WriteDisable;
					aluop_o <= `EXE_BGTZ_OP;
					alusel_o <= `EXE_RES_JUMP_BRANCH;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					if((reg1_o[31] == 1'b0) && (reg1_o != `ZeroWord)) begin
						link_addr_o <= `ZeroWord;
						branch_target_addr_o <= pc_plus_4 + imm_sll2_signed;
						branch_flag_o <= `Branch;
						next_inst_in_delayslot_o <= `InDelaySlot;
					end	
					instvalid <= `InstValid;
				end
				`EXE_BLEZ: begin 
							wreg_o <= `WriteDisable;
							aluop_o <= `EXE_BLEZ_OP;
							alusel_o <= `EXE_RES_JUMP_BRANCH;
							reg1_read_o <= 1'b1;
							reg2_read_o <= 1'b0;
							if((reg1_o[31] == 1'b1) || (reg1_o == `ZeroWord)) begin
								link_addr_o <= `ZeroWord;
								branch_target_addr_o <= pc_plus_4 + imm_sll2_signed;
								branch_flag_o <= `Branch;
								next_inst_in_delayslot_o <= `InDelaySlot;
							end	
							instvalid <= `InstValid;
						end
				`EXE_BNE: begin
					wreg_o <= `WriteDisable;
					aluop_o <= `EXE_BNE_OP;
					alusel_o <= `EXE_RES_JUMP_BRANCH;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b1;
					if(reg1_o != reg2_o) begin
						link_addr_o <= `ZeroWord;
						branch_target_addr_o <= pc_plus_4 + imm_sll2_signed;
						branch_flag_o <= `Branch;
						next_inst_in_delayslot_o <= `InDelaySlot;
					end	
					instvalid <= `InstValid;
				end
				`EXE_REGIMM_INST:
					case (op4) // bgez bltz
						`EXE_BGEZ: begin 
							wreg_o <= `WriteDisable;
							aluop_o <= `EXE_BGEZ_OP;
							alusel_o <= `EXE_RES_JUMP_BRANCH;
							reg1_read_o <= 1'b1;
							reg2_read_o <= 1'b0;
							if(reg1_o[31] == 1'b0) begin
								link_addr_o <= `ZeroWord;
								branch_target_addr_o <= pc_plus_4 + imm_sll2_signed;
								branch_flag_o <= `Branch;
								next_inst_in_delayslot_o <= `InDelaySlot;
							end	
							instvalid <= `InstValid;
						end
						`EXE_BLTZ: begin 
							wreg_o <= `WriteDisable;
							aluop_o <= `EXE_BLTZ_OP;
							alusel_o <= `EXE_RES_JUMP_BRANCH;
							reg1_read_o <= 1'b1;
							reg2_read_o <= 1'b0;
							if(reg1_o[31] == 1'b1) begin
								link_addr_o <= `ZeroWord;
								branch_target_addr_o <= pc_plus_4 + imm_sll2_signed;
								branch_flag_o <= `Branch;
								next_inst_in_delayslot_o <= `InDelaySlot;
							end	
							instvalid <= `InstValid;
						end
						default: begin 
						end
					endcase
				// load_store
				`EXE_LB: begin
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_LB_OP;
					alusel_o <= `EXE_RES_LOAD_STORE;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					wd_o <= inst_i[20: 16];
					instvalid <= `InstValid;
				end
				`EXE_LBU: begin
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_LBU_OP;
					alusel_o <= `EXE_RES_LOAD_STORE;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					wd_o <= inst_i[20: 16];
					instvalid <= `InstValid;
				end
				6'b100101: begin //`EXE_LHU: begin `define EXE_LHU 6'b100101
                    // $display("oprt = lhu");
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_LHU_OP;
					alusel_o <= `EXE_RES_LOAD_STORE;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					wd_o <= inst_i[20: 16];
					instvalid <= `InstValid;
				end
				`EXE_LW: begin
                    // $display("oprt = lw");
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_LW_OP;
					alusel_o <= `EXE_RES_LOAD_STORE;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					wd_o <= inst_i[20: 16];
					instvalid <= `InstValid;
				end
				`EXE_SB: begin
					wreg_o <= `WriteDisable;
					aluop_o <= `EXE_SB_OP;
					alusel_o <= `EXE_RES_LOAD_STORE;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b1;
					instvalid <= `InstValid;
				end
				`EXE_SW: begin
					wreg_o <= `WriteDisable;
					aluop_o <= `EXE_SW_OP;
					alusel_o <= `EXE_RES_LOAD_STORE;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b1;
					instvalid <= `InstValid;
				end
				// CACHE, NOP actually
				`EXE_CACHE: begin 
					wreg_o <= `WriteDisable;
			  		aluop_o <= `EXE_NOP_OP;
			  		alusel_o <= `EXE_RES_NOP; 
			  		reg1_read_o <= 1'b0;
			  		reg2_read_o <= 1'b0;
					instvalid <= `InstValid;
				end
			   	default: begin
						instvalid <= `InstInvalid;
			   	end //default
		  	endcase //case op	

		  	if(inst_i[31: 21] == 11'b00000000000) begin
		  		if(op3 == `EXE_SLL) begin
					// $display("OP = SLL");
		  			wreg_o <= `WriteEnable;
		  			aluop_o <= `EXE_SLL_OP;
		  			alusel_o <= `EXE_RES_SHIFT;
		  			reg1_read_o <= 1'b0;
		  			reg2_read_o <= 1'b1;
		  			imm[4: 0] <= inst_i[10: 6];
		  			wd_o <= inst_i[15: 11];
		  			instvalid <= `InstValid;
		  		end
		  		if(op3 == `EXE_SRL) begin
		  			wreg_o <= `WriteEnable;
		  			aluop_o <= `EXE_SRL_OP;
		  			alusel_o <= `EXE_RES_SHIFT;
		  			reg1_read_o <= 1'b0;
		  			reg2_read_o <= 1'b1;
		  			imm[4: 0] <= inst_i[10: 6];
		  			wd_o <= inst_i[15: 11];
		  			instvalid <= `InstValid;
		  		end
		  		if(op3 == `EXE_SRA) begin
		  			wreg_o <= `WriteEnable;
		  			aluop_o <= `EXE_SRA_OP;
		  			alusel_o <= `EXE_RES_SHIFT;
		  			reg1_read_o <= 1'b0;
		  			reg2_read_o <= 1'b1;
		  			imm[4: 0] <= inst_i[10: 6];
		  			wd_o <= inst_i[15: 11];
		  			instvalid <= `InstValid;
		  		end
		  	end	// if(inst_i[31: 21] == 11'b00000000000) begin

		  	// cp0 - mfc0
		  	if(inst_i[31: 21] == 11'b01000000000 && 
		  	inst_i[10: 0] == 11'b00000000000) begin 
		  		aluop_o <= `EXE_MFC0_OP;
		  		alusel_o <= `EXE_RES_MOVE;
		  		wd_o <= inst_i[20: 16];
		  		wreg_o <= `WriteEnable;
		  		instvalid <= `InstValid;
		  		reg1_read_o <= 1'b0;
		  		reg2_read_o <= 1'b0;	
		  	end
		  	// cp0 - mtc0
		  	// ignore the 'sel' field
		  	if(inst_i[31: 21] == 11'b01000000100 && ( 
		  	inst_i[10: 0] == 11'b00000000000 || inst_i[10: 0] == 11'b00000000001 
		  	|| inst_i[10: 0] == 11'b00000000010  || inst_i[10: 0] == 11'b00000000011 )) begin 
		  		aluop_o <= `EXE_MTC0_OP;
		  		alusel_o <= `EXE_RES_NOP;
		  		wreg_o <= `WriteDisable;
		  		instvalid <= `InstValid;
		  		reg1_read_o <= 1'b1;
		  		reg1_addr_o <= inst_i[20: 16];
		  		reg2_read_o <= 1'b0;	
		  	end	

		  	//eret
		  	if(inst_i == `EXE_ERET) begin 
		  		wreg_o <= `WriteDisable;
		  		aluop_o <= `EXE_ERET_OP;
		  		alusel_o <= `EXE_RES_NOP;
		  		reg1_read_o <= 1'b0;
		  		reg2_read_o <= 1'b0;
		  		instvalid <= `InstValid;
		  		excepttype_is_eret <= 1'b1;
		  	end

		  	// tlbwi
		  	if(inst_i == `EXE_TLBWI) begin
		  		wreg_o <= `WriteDisable; // don't write reg_files
		  		aluop_o <= `EXE_TLBWI_OP;
		  		alusel_o <= `EXE_RES_NOP;
		  		reg1_read_o <= 1'b0;
		  		reg2_read_o <= 1'b0;
		  		instvalid <= `InstValid;
		  	end
		end // else
	end //always


	always @ (*) begin
        stallreq_for_reg1_loadrelate <= `NoStop;
		if(rst == `RstEnable) begin
			reg1_o <= `ZeroWord;
		end 
        else if(pre_inst_is_load == 1'b1 && ex_wd_i == reg1_addr_o 
                    && reg1_read_o == 1'b1 ) begin
            stallreq_for_reg1_loadrelate <= `Stop;
   		end
		else if((reg1_read_o == 1'b1) && (ex_wreg_i == 1'b1)
					&& (ex_wd_i == reg1_addr_o)) begin
			reg1_o <= ex_wdata_i;
		end
		else if((reg1_read_o == 1'b1) && (mem_wreg_i == 1'b1)
					&& (mem_wd_i == reg1_addr_o)) begin
			reg1_o <= mem_wdata_i;
		end
		else if(reg1_read_o == 1'b1) begin
	  		reg1_o <= reg1_data_i;
	  	end else if(reg1_read_o == 1'b0) begin
	  		reg1_o <= imm;
	  	end else begin
	   	 	reg1_o <= `ZeroWord;
	  	end
	end
	
	always @ (*) begin
        stallreq_for_reg2_loadrelate <= `NoStop;
		if(rst == `RstEnable) begin
			reg2_o <= `ZeroWord;
	  	end 
        else if(pre_inst_is_load == 1'b1 && ex_wd_i == reg2_addr_o 
                    && reg2_read_o == 1'b1 ) begin
            stallreq_for_reg2_loadrelate <= `Stop;
    	end
		else if((reg2_read_o == 1'b1) && (ex_wreg_i == 1'b1)
					&& (ex_wd_i == reg2_addr_o)) begin
			reg2_o <= ex_wdata_i;
		end
		else if((reg2_read_o == 1'b1) && (mem_wreg_i == 1'b1)
					&& (mem_wd_i == reg2_addr_o)) begin
			reg2_o <= mem_wdata_i;
		end
	  	else if(reg2_read_o == 1'b1) begin
	  		reg2_o <= reg2_data_i;
	  	end 
	  	else if(reg2_read_o == 1'b0) begin
	  		reg2_o <= imm;
	  	end 
	  	else begin
	    	reg2_o <= `ZeroWord;
	  	end // if
	end // always

    always @ (*) begin
        if(rst == `RstEnable) begin
            is_in_delayslot_o <= `NotInDelaySlot;
        end 
        else begin
            is_in_delayslot_o <= is_in_delayslot_i;       
        end
    end

endmodule