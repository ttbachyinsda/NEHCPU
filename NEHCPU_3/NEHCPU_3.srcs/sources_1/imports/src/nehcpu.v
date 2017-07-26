`include "defines.v"

module nehcpu(

	input wire                    clk,
	input wire                    rst,
	output wire[31:0]             debug_led,
	
 	input wire[7: 0]              int_i, // 

 	input wire[31: 0] regfile_reg_sel,
	output wire[31: 0] regfile_reg_out,

	input wire[`RegBus]           iwishbone_data_i,
	input wire                    iwishbone_ack_i,
	output wire[`RegBus]           iwishbone_addr_o,
	output wire[`RegBus]           iwishbone_data_o,
	output wire                    iwishbone_we_o,
	output wire[3:0]               iwishbone_sel_o,
	output wire                    iwishbone_stb_o,
	output wire                    iwishbone_cyc_o, 
	
	input wire[`RegBus]           dwishbone_data_i,
	input wire                    dwishbone_ack_i,
	output wire[`RegBus]           dwishbone_addr_o,
	output wire[`RegBus]           dwishbone_data_o,
	output wire                    dwishbone_we_o,
	output wire[3:0]               dwishbone_sel_o,
	output wire                    dwishbone_stb_o,
	output wire                    dwishbone_cyc_o,

	output wire                   rom_ce_o,
	
	output wire                   ram_ce_o,

	output wire                   timer_int_o,  // timer interruption

	input [15:0] sw,
	output [31:0] led
);
	
	


	wire[`InstAddrBus] pc;
	wire[`InstBus] inst_i;
	wire[`InstAddrBus] id_pc_i;
	wire[`InstBus] id_inst_i;

	wire[31:0] led_reg;
	
	wire[`AluOpBus] id_aluop_o;
	wire[`AluSelBus] id_alusel_o;
	wire[`RegBus] id_reg1_o;
	wire[`RegBus] id_reg2_o;
	wire id_wreg_o;
	wire[`RegAddrBus] id_wd_o;
	wire id_is_in_delayslot_o;
  	wire[`RegBus] id_link_addr_o;
  	wire[`RegBus] id_inst_o;
  	wire[31:0] id_excepttype_o;
    wire[`RegBus] id_current_inst_addr_o;
	
	wire[`AluOpBus] ex_aluop_i;
	wire[`AluSelBus] ex_alusel_i;
	wire[`RegBus] ex_reg1_i;
	wire[`RegBus] ex_reg2_i;
	wire ex_wreg_i;
	wire[`RegAddrBus] ex_wd_i;
	wire ex_is_in_delayslot_i;	
  	wire[`RegBus] ex_link_addr_i;
  	wire[`RegBus] ex_inst_i;
  	wire[31:0] ex_excepttype_i;	
  	wire[`RegBus] ex_current_inst_addr_i;
	
	wire ex_wreg_o;
	wire[`RegAddrBus] ex_wd_o;
	wire[`RegBus] ex_wdata_o;
	wire[`RegBus] ex_hi_o;
	wire[`RegBus] ex_lo_o;
	wire ex_whilo_o;
	wire[`AluOpBus] ex_aluop_o;
	wire[`RegBus] ex_mem_addr_o;
	wire[`RegBus] ex_reg1_o;
	wire[`RegBus] ex_reg2_o;
	wire ex_cp0_reg_we_o;
	wire[4:0] ex_cp0_reg_write_addr_o;
	wire[`RegBus] ex_cp0_reg_data_o; 
	wire[31:0] ex_excepttype_o;
	wire[`RegBus] ex_current_inst_addr_o;
	wire ex_is_in_delayslot_o;

	wire mem_wreg_i;
	wire[`RegAddrBus] mem_wd_i;
	wire[`RegBus] mem_wdata_i;
	wire[`RegBus] mem_hi_i;
	wire[`RegBus] mem_lo_i;
	wire mem_whilo_i;
	wire[`AluOpBus] mem_aluop_i;
	wire[`RegBus] mem_mem_addr_i;
	wire[`RegBus] mem_reg1_i;
	wire[`RegBus] mem_reg2_i;
	wire mem_cp0_reg_we_i;
	wire[4:0] mem_cp0_reg_write_addr_i;
	wire[`RegBus] mem_cp0_reg_data_i;
	wire[31:0] mem_excepttype_i;	
	wire mem_is_in_delayslot_i;
	wire[`RegBus] mem_current_inst_addr_i;

	wire mem_wreg_o;
	wire[`RegAddrBus] mem_wd_o;
	wire[`RegBus] mem_wdata_o;
	wire[`RegBus] mem_hi_o;
	wire[`RegBus] mem_lo_o;
	wire mem_whilo_o;
	wire mem_cp0_reg_we_o;
	wire[4:0] mem_cp0_reg_write_addr_o;
	wire[`RegBus] mem_cp0_reg_data_o;
	wire[31:0] mem_excepttype_o;
	wire mem_is_in_delayslot_o;
	wire[`RegBus] mem_current_inst_addr_o;
	wire[`RegBus] mem_unliagned_addr_o;

	
	wire wb_wreg_i;
	wire[`RegAddrBus] wb_wd_i;
	wire[`RegBus] wb_wdata_i;
	wire[`RegBus] wb_hi_i;
	wire[`RegBus] wb_lo_i;
	wire wb_whilo_i;
	wire wb_cp0_reg_we_i;
	wire[4:0] wb_cp0_reg_write_addr_i;
	wire[`RegBus] wb_cp0_reg_data_i;
	wire[31:0] wb_excepttype_i;
	wire wb_is_in_delayslot_i;
	wire[`RegBus] wb_current_inst_addr_i;

	
    wire reg1_read;
    wire reg2_read;
    wire[`RegBus] reg1_data;
    wire[`RegBus] reg2_data;
    wire[`RegAddrBus] reg1_addr;
    wire[`RegAddrBus] reg2_addr;

	wire[`RegBus] 	hi;
	wire[`RegBus]   lo;

	wire is_in_delayslot_i;
	wire is_in_delayslot_o;
	wire next_inst_in_delayslot_o;
	wire id_branch_flag_o;
	wire[`RegBus] branch_target_addr;

	wire[5: 0] stall;
	wire stallreq_from_id;	
	wire stallreq_from_if; // stall when getting inst
	wire stallreq_from_mem; // stall when r/w mem

	wire[`RegBus] cp0_data_o;
    wire[4:0] cp0_raddr_i;

    wire flush;
  	wire[`RegBus] new_pc;

	wire[`RegBus] 	cp0_count;
	wire[`RegBus]	cp0_compare;
	wire[`RegBus]	cp0_status;
	wire[`RegBus]	cp0_cause;
	wire[`RegBus]	cp0_epc;
	wire[`RegBus] cp0_index;
	wire[`RegBus] cp0_entrylo0;
	wire[`RegBus] cp0_entrylo1;
	wire[`RegBus] cp0_entryhi;
	wire[`TLB_WRITE_STRUCT_WIDTH - 1:0] mem_tlb_write_struct;

  	wire[`RegBus] latest_epc;

	wire rom_ce;

	wire[31:0] ram_addr_o;
 	wire ram_we_o;
 	wire[3:0] ram_sel_o;
 	wire[`RegBus] ram_data_o;
 	wire[`RegBus] ram_data_i;

 	wire[`RegBus] mmu_inst_addr;
	wire[`RegBus] mmu_data_addr;

	pc_reg pc_reg0(
		.clk(clk),
		.rst(rst),
        .stall(stall),
        .flush(flush),
		.new_pc(new_pc),
		.branch_flag_i(id_branch_flag_o),
		.branch_target_addr_i(branch_target_addr),
		.pc(pc),
		.ce(rom_ce_o)
			
	);
	

 	wire mmu_is_tlbl_inst;
	wire id_is_tlbl_inst;

	if_id if_id0(
		.clk(clk),
		.rst(rst),
		.stall(stall),
		.flush(flush),
		.if_pc(pc),
		.if_inst(inst_i),
		.id_pc(id_pc_i),
		.id_inst(id_inst_i),  

		.is_inst_tlbl_i(mmu_is_tlbl_inst),
		.is_inst_tlbl_o(id_is_tlbl_inst)    	
	);
	

	id id0(
		.rst(rst),
		.pc_i(id_pc_i),
		.inst_i(id_inst_i),

		.ex_aluop_i(ex_aluop_o),

		.reg1_data_i(reg1_data),
		.reg2_data_i(reg2_data),

		.ex_wreg_i(ex_wreg_o),
		.ex_wdata_i(ex_wdata_o),
		.ex_wd_i(ex_wd_o),

		.mem_wreg_i(mem_wreg_o),
		.mem_wdata_i(mem_wdata_o),
		.mem_wd_i(mem_wd_o),

		.reg1_read_o(reg1_read),
		.reg2_read_o(reg2_read), 	  

		.reg1_addr_o(reg1_addr),
		.reg2_addr_o(reg2_addr), 
	  
		.aluop_o(id_aluop_o),
		.alusel_o(id_alusel_o),
		.reg1_o(id_reg1_o),
		.reg2_o(id_reg2_o),
		.wd_o(id_wd_o),
		.wreg_o(id_wreg_o),
		.inst_o(id_inst_o),

		.is_tlbl_inst(id_is_tlbl_inst),
		.excepttype_o(id_excepttype_o),
		.current_inst_addr_o(id_current_inst_addr_o),

        .is_in_delayslot_i(is_in_delayslot_i),
		.next_inst_in_delayslot_o(next_inst_in_delayslot_o),	
		.branch_flag_o(id_branch_flag_o),
		.branch_target_addr_o(branch_target_addr),       
		.link_addr_o(id_link_addr_o),
		.is_in_delayslot_o(id_is_in_delayslot_o),

		.stallreq(stallreq_from_id)

	);

	
	regfile regfile1(
		.clk (clk),
		.rst (rst),
		.we	(wb_wreg_i),
		.waddr (wb_wd_i),
		.wdata (wb_wdata_i),
		.re1 (reg1_read),
		.raddr1 (reg1_addr),
		.rdata1 (reg1_data),
		.re2 (reg2_read),
		.raddr2 (reg2_addr),
		.rdata2 (reg2_data),
		.reg_sel(regfile_reg_sel),
		.reg_out(regfile_reg_out),
		.led(led_reg2),
		.sw(sw)
	);

	id_ex id_ex0(
		.clk(clk),
		.rst(rst),

		.stall(stall),
		.flush(flush),
		
		.id_aluop(id_aluop_o),
		.id_alusel(id_alusel_o),
		.id_reg1(id_reg1_o),
		.id_reg2(id_reg2_o),
		.id_wd(id_wd_o),
		.id_wreg(id_wreg_o),
		.id_link_addr(id_link_addr_o),
		.id_is_in_delayslot(id_is_in_delayslot_o),
		.next_inst_in_delayslot_i(next_inst_in_delayslot_o),	
		.id_inst(id_inst_o),
		.id_excepttype(id_excepttype_o),
		.id_current_inst_addr(id_current_inst_addr_o),

		.ex_aluop(ex_aluop_i),
		.ex_alusel(ex_alusel_i),
		.ex_reg1(ex_reg1_i),
		.ex_reg2(ex_reg2_i),
		.ex_wd(ex_wd_i),
		.ex_wreg(ex_wreg_i),
		.ex_link_addr(ex_link_addr_i),
  		.ex_is_in_delayslot(ex_is_in_delayslot_i),
		.is_in_delayslot_o(is_in_delayslot_i),	
		.ex_inst(ex_inst_i),
		.ex_excepttype(ex_excepttype_i),
		.ex_current_inst_addr(ex_current_inst_addr_i)	

	);		
	
	ex ex0(
		.rst(rst),
	
		.aluop_i(ex_aluop_i),
		.alusel_i(ex_alusel_i),
		.reg1_i(ex_reg1_i),
		.reg2_i(ex_reg2_i),
		.wd_i(ex_wd_i),
		.wreg_i(ex_wreg_i),
	  	.hi_i(hi),
		.lo_i(lo),
		.inst_i(ex_inst_i),

	  	.wb_hi_i(wb_hi_i),
	  	.wb_lo_i(wb_lo_i),
	  	.wb_whilo_i(wb_whilo_i),
	  	.mem_hi_i(mem_hi_o),
	  	.mem_lo_i(mem_lo_o),
	  	.mem_whilo_i(mem_whilo_o),
	  	
	  	.mem_cp0_reg_we(mem_cp0_reg_we_o),
		.mem_cp0_reg_write_addr(mem_cp0_reg_write_addr_o),
		.mem_cp0_reg_data(mem_cp0_reg_data_o),
		.wb_cp0_reg_we(wb_cp0_reg_we_i),
		.wb_cp0_reg_write_addr(wb_cp0_reg_write_addr_i),
		.wb_cp0_reg_data(wb_cp0_reg_data_i),

		.cp0_reg_data_i(cp0_data_o),
		.cp0_reg_read_addr_o(cp0_raddr_i),
		
		.cp0_reg_we_o(ex_cp0_reg_we_o),
		.cp0_reg_write_addr_o(ex_cp0_reg_write_addr_o),
		.cp0_reg_data_o(ex_cp0_reg_data_o),	

	  	.link_addr_i(ex_link_addr_i),
		.is_in_delayslot_i(ex_is_in_delayslot_i),

		.excepttype_i(ex_excepttype_i),
		.current_inst_addr_i(ex_current_inst_addr_i),
			  
		.wd_o(ex_wd_o),
		.wreg_o(ex_wreg_o),
		.wdata_o(ex_wdata_o),

		.hi_o(ex_hi_o),
		.lo_o(ex_lo_o),
		.whilo_o(ex_whilo_o),

		.excepttype_o(ex_excepttype_o),
		.is_in_delayslot_o(ex_is_in_delayslot_o),
		.current_inst_addr_o(ex_current_inst_addr_o),

		.aluop_o(ex_aluop_o),
		.mem_addr_o(ex_mem_addr_o),
		.reg2_o(ex_reg2_o)
		
	);

    ex_mem ex_mem0(
		.clk(clk),
		.rst(rst),

		.stall(stall),
		.flush(flush),
	  	
		.ex_wd(ex_wd_o),
		.ex_wreg(ex_wreg_o),
		.ex_wdata(ex_wdata_o),
		.ex_hi(ex_hi_o),
		.ex_lo(ex_lo_o),
		.ex_whilo(ex_whilo_o),		
  		.ex_aluop(ex_aluop_o),
		.ex_mem_addr(ex_mem_addr_o),
		.ex_reg2(ex_reg2_o),
		.ex_cp0_reg_we(ex_cp0_reg_we_o),
		.ex_cp0_reg_write_addr(ex_cp0_reg_write_addr_o),
		.ex_cp0_reg_data(ex_cp0_reg_data_o),
		.ex_excepttype(ex_excepttype_o),
		.ex_is_in_delayslot(ex_is_in_delayslot_o),
		.ex_current_inst_addr(ex_current_inst_addr_o),

		.mem_wd(mem_wd_i),
		.mem_wreg(mem_wreg_i),
		.mem_wdata(mem_wdata_i),
		.mem_hi(mem_hi_i),
		.mem_lo(mem_lo_i),
		.mem_whilo(mem_whilo_i),
		.mem_aluop(mem_aluop_i),
		.mem_mem_addr(mem_mem_addr_i),
		.mem_reg2(mem_reg2_i),
		.mem_cp0_reg_we(mem_cp0_reg_we_i),
		.mem_cp0_reg_write_addr(mem_cp0_reg_write_addr_i),
		.mem_cp0_reg_data(mem_cp0_reg_data_i),
		.mem_excepttype(mem_excepttype_i),
  		.mem_is_in_delayslot(mem_is_in_delayslot_i),
		.mem_current_inst_addr(mem_current_inst_addr_i)	

	);
	
	wire mmu_is_tlb_modify;
    wire mmu_is_tlbl_data;
    wire mmu_is_tlbs;
    wire[31: 0] cp0_badvaddr;
    wire[`RegBus] mmu_badvaddr; 
	wire mmu_we; // 1 - save_inst; 0 - load_inst 

	mem mem0(
		.rst(rst),
		.wd_i(mem_wd_i),
		.wreg_i(mem_wreg_i),
		.wdata_i(mem_wdata_i),
	  	.hi_i(mem_hi_i),
		.lo_i(mem_lo_i),
		.whilo_i(mem_whilo_i),	
		.aluop_i(mem_aluop_i),
		.mem_addr_i(mem_mem_addr_i),
		.reg2_i(mem_reg2_i),
		.cp0_reg_we_i(mem_cp0_reg_we_i),
		.cp0_reg_write_addr_i(mem_cp0_reg_write_addr_i),
		.cp0_reg_data_i(mem_cp0_reg_data_i),
		.excepttype_i(mem_excepttype_i),
		.is_in_delayslot_i(mem_is_in_delayslot_i),
		.current_inst_addr_i(mem_current_inst_addr_i),	
		
		.cp0_status_i(cp0_status),
		.cp0_cause_i(cp0_cause),
		.cp0_epc_i(cp0_epc),
  		.wb_cp0_reg_we(wb_cp0_reg_we_i),
		.wb_cp0_reg_write_addr(wb_cp0_reg_write_addr_i),
		.wb_cp0_reg_data(wb_cp0_reg_data_i),
		
		.mem_data_i(ram_data_i),	
	  
		.mem_addr_o(ram_addr_o),
		.mem_we_o(ram_we_o),
		.mem_sel_o(ram_sel_o),
		.mem_data_o(ram_data_o),
		.mem_ce_o(ram_ce_o),	

		.wd_o(mem_wd_o),
		.wreg_o(mem_wreg_o),
		.wdata_o(mem_wdata_o),
		.hi_o(mem_hi_o),
		.lo_o(mem_lo_o),
		.whilo_o(mem_whilo_o),
		.cp0_reg_we_o(mem_cp0_reg_we_o),
		.cp0_reg_write_addr_o(mem_cp0_reg_write_addr_o),
		.cp0_reg_data_o(mem_cp0_reg_data_o),
		.excepttype_o(mem_excepttype_o),
		.is_tlb_modify(mmu_is_tlb_modify),
    	.is_tlbl_data(mmu_is_tlbl_data),
    	.is_tlbs(mmu_is_tlbs),
		.cp0_epc_o(latest_epc),
		.is_in_delayslot_o(mem_is_in_delayslot_o),
		.current_inst_addr_o(mem_current_inst_addr_o),
		.unaligned_addr_o(mem_unliagned_addr_o),
		.badvaddr_i(mmu_badvaddr),
		.badvaddr_o(cp0_badvaddr),
		.is_save_inst(mmu_we),

		.cp0_index_i(cp0_index),
		.cp0_entrylo0_i(cp0_entrylo0),
		.cp0_entrylo1_i(cp0_entrylo1),
		.cp0_entryhi_i(cp0_entryhi),
		.tlb_write_struct_o(mem_tlb_write_struct)	

	);

	mem_wb mem_wb0(
		.clk(clk),
		.rst(rst),

		.stall(stall),
		.flush(flush),

		.mem_wd(mem_wd_o),
		.mem_wreg(mem_wreg_o),
		.mem_wdata(mem_wdata_o),
		.mem_hi(mem_hi_o),
		.mem_lo(mem_lo_o),
		.mem_whilo(mem_whilo_o),
		.mem_cp0_reg_we(mem_cp0_reg_we_o),
		.mem_cp0_reg_write_addr(mem_cp0_reg_write_addr_o),
		.mem_cp0_reg_data(mem_cp0_reg_data_o),
	
		.wb_wd(wb_wd_i),
		.wb_wreg(wb_wreg_i),
		.wb_wdata(wb_wdata_i),
		.wb_hi(wb_hi_i),
		.wb_lo(wb_lo_i),
		.wb_whilo(wb_whilo_i),
		.wb_cp0_reg_we(wb_cp0_reg_we_i),
		.wb_cp0_reg_write_addr(wb_cp0_reg_write_addr_i),
		.wb_cp0_reg_data(wb_cp0_reg_data_i)	
									       	
	);


	mmu mmu0(
		.clk(clk),
		.rst(rst),
 		.inst_addr_i(pc), 
     	.inst_addr_o(mmu_inst_addr), 
     	.data_addr_i(ram_addr_o), 
     	.data_addr_o(mmu_data_addr),
     	.is_write_mem(mmu_we),
   		.tlb_write_struct(mem_tlb_write_struct),
   		.is_tlb_modify(mmu_is_tlb_modify),
    	.is_tlbl_data(mmu_is_tlbl_data),
    	.is_tlbl_inst(mmu_is_tlbl_inst),
    	.is_tlbs(mmu_is_tlbs),
    	.badvaddr(mmu_badvaddr)
   		
	);

	hilo_reg hilo_reg0(
		.clk(clk),
		.rst(rst),
	
		.we(wb_whilo_i),
		.hi_i(wb_hi_i),
		.lo_i(wb_lo_i),
	
		.hi_o(hi),
		.lo_o(lo)	
	);

	wire[31: 0] exc_vector_addr;

	ctrl ctrl0(
		.rst(rst),

		.stallreq_from_id(stallreq_from_id),
		.stallreq_from_if(stallreq_from_if),
		.stallreq_from_mem(stallreq_from_mem),

		.stall(stall),
		.flush(flush),  

		.excepttype_i(mem_excepttype_o),
		.exc_vec_addr_i(exc_vector_addr),
	  	.cp0_epc_i(latest_epc),
	  	.new_pc(new_pc)

	);

	cp0_reg cp0_reg0(
		.clk(clk),
		.rst(rst),
		
		.we_i(wb_cp0_reg_we_i),
		.waddr_i(wb_cp0_reg_write_addr_i),
		.raddr_i(cp0_raddr_i),
		.data_i(wb_cp0_reg_data_i),
		
		.excepttype_i(mem_excepttype_o),
		.int_i(int_i),
		.current_inst_addr_i(mem_current_inst_addr_o),
		.unaligned_addr_i(mem_unliagned_addr_o),
		.is_in_delayslot_i(mem_is_in_delayslot_o),

    	.badvaddr_i(cp0_badvaddr),
		.exc_vec_addr_o(exc_vector_addr),

		.data_o(cp0_data_o),
		.count_o(cp0_count),
		.compare_o(cp0_compare),
		.status_o(cp0_status),
		.cause_o(cp0_cause),
		.epc_o(cp0_epc),
		.index_o(cp0_index),
		.entrylo0_o(cp0_entrylo0),
		.entrylo1_o(cp0_entrylo1),
		.entryhi_o(cp0_entryhi),
		
		.timer_int_o(timer_int_o)  			
	);

	assign cpu_ram_ce_o = ram_ce_o;

	wishbone_bus dwishbone_bus( 
		.clk(clk),
		.rst(rst),
	
		.stall_i(stall),
		.flush_i(flush),

	
		.cpu_ce_i(cpu_ram_ce_o),
		.cpu_data_i(ram_data_o),
		.cpu_addr_i(mmu_data_addr),
		.cpu_we_i(ram_we_o),
		.cpu_sel_i(ram_sel_o),
		.cpu_data_o(ram_data_i),
	
		.wishbone_data_i(dwishbone_data_i),
		.wishbone_ack_i(dwishbone_ack_i),
		.wishbone_addr_o(dwishbone_addr_o),
		.wishbone_data_o(dwishbone_data_o),
		.wishbone_we_o(dwishbone_we_o),
		.wishbone_sel_o(dwishbone_sel_o),
		.wishbone_stb_o(dwishbone_stb_o),
		.wishbone_cyc_o(dwishbone_cyc_o),

		.stallreq(stallreq_from_mem)	       
	
	);

	assign rom_ce = rom_ce_o;

	wishbone_bus iwishbone_bus( // instruction bus
		.clk(clk),
		.rst(rst),
	
		.stall_i(stall),
		.flush_i(flush),
	
		.cpu_ce_i(rom_ce),
		.cpu_data_i(32'h00000000),
		.cpu_addr_i(mmu_inst_addr),
		.cpu_we_i(1'b0),
		.cpu_sel_i(4'b1111),
		.cpu_data_o(inst_i),
	
		.wishbone_data_i(iwishbone_data_i),
		.wishbone_ack_i(iwishbone_ack_i),
		.wishbone_addr_o(iwishbone_addr_o),
		.wishbone_data_o(iwishbone_data_o),
		.wishbone_we_o(iwishbone_we_o),
		.wishbone_sel_o(iwishbone_sel_o),
		.wishbone_stb_o(iwishbone_stb_o),
		.wishbone_cyc_o(iwishbone_cyc_o),

		.stallreq(stallreq_from_if)	       
	
	);

endmodule