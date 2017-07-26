    `include "defines.v"

module testuart(

input wire                clk50M,
input wire             clkuart,
input wire                rstn,
input wire hand_clk,
//uart
input wire uart_in,
output wire uart_out,

output [15:0] led,
input [15:0] sw,
output [6:0] digit0,
output [6:0] digit1,

// sram
output [19:0] baseram_addr,
inout [31:0] baseram_data,
output baseram_ce,
output baseram_oe,
output baseram_we,
output [19:0] extram_addr,
inout [31:0] extram_data,
output extram_ce,
output extram_oe,
output extram_we,
// flash
output [22:0] flash_adr_o, 
inout [15:0] flash_dat_io, 
output [7:0] flash_ctrl

);
wire clk_o;
clk_master clk_master0 (
.clk_50m_i(clk50M),
.clk_11m_i(clkuart),
.clk_o(clk_o)
);
wire rst = rstn;
wire [15 : 0] regled;
wire [31 : 0] trueled;
wire [22 : 0] lamp;
// interrupt  
wire[7: 0] intrpt;
wire timer_int;
wire uart_int;
assign led = trueled[15:0];
assign intrpt = {timer_int, 1'b0, 1'b0, uart_int, 4'h0}; // 1'b0, uart_int};

//inst wb
wire [31:0] inst_data_i;
wire [31:0] inst_data_o;
wire [31:0] inst_addr_i;
wire [3:0] inst_sel_i;
wire inst_we_i;
wire inst_cyc_i;
wire inst_stb_i;
wire inst_ack_o;
//data wb
wire [31:0] data_data_i;
wire [31:0] data_data_o;
wire [31:0] data_addr_i;
wire [3:0] data_sel_i;
wire data_we_i;
wire data_cyc_i;
wire data_stb_i;
wire data_ack_o;

// sram wb
wire [31:0] sram_data_i;
wire [31:0] sram_data_o;
wire [31:0] sram_addr_o;
wire [3:0] sram_sel_o;
wire sram_we_o;
wire sram_cyc_o;
wire sram_stb_o;
wire sram_ack_i;

// flash wb
wire [31:0] flash_data_i;
wire [31:0] flash_data_o;
wire [31:0] flash_addr_o;
wire [3:0] flash_sel_o;
wire flash_we_o;
wire flash_cyc_o;
wire flash_stb_o;
wire flash_ack_i;

//rom  wb
wire [31:0] rom_data_i;
wire [31:0] rom_data_o;
wire [31:0] rom_addr_o;
wire [3:0] rom_sel_o;
wire rom_we_o;
wire rom_cyc_o;
wire rom_stb_o;
wire rom_ack_i;

//uart wb
wire [31:0] uart_data_i;
wire [31:0] uart_data_o;
wire [31:0] uart_addr_o;
wire [3:0] uart_sel_o;
wire uart_we_o;
wire uart_cyc_o;
wire uart_stb_o;
wire uart_ack_i;

wire [5:0] stall;
wire flush;
wire ce_o;
wire [31:0] ram_data_o;
wire[`RegBus] mmu_data_addr;
wire ram_we_o;
wire[3:0] ram_sel_o;
wire[`RegBus] ram_data_i;
wire stallreq_from_mem;
uartsignal uartsignal0(
    .clk(hand_clk),
    .stall(stall),
    .flush(flush),
    .ce_o(ce_o),
    .ram_data_o(ram_data_o),
    .mmu_data_addr(mmu_data_addr),
    .ram_we_o(ram_we_o),
    .ram_sel_o(ram_sel_o),
    .ram_data_i(ram_data_i),
    .stallreq_from_mem(stallreq_from_mem)
    );
	wishbone_bus dwishbone_bus( // data_bus
		.clk(clk_o),
		.rst(rst),
	
		//来自控制模块ctrl
		.stall_i(stall),
		.flush_i(flush),

	
		//CPU侧读写操作信息
		.cpu_ce_i(ce_o),
		.cpu_data_i(ram_data_o),
		.cpu_addr_i(mmu_data_addr),
		.cpu_we_i(ram_we_o),
		.cpu_sel_i(ram_sel_o),
		.cpu_data_o(ram_data_i),
	
		//Wishbone总线侧接口
		.wishbone_data_i(data_data_o),
            .wishbone_ack_i(data_ack_o),
            .wishbone_addr_o(data_addr_i),
            .wishbone_data_o(data_data_i),
            .wishbone_we_o(data_we_i),
            .wishbone_sel_o(data_sel_i),
            .wishbone_stb_o(data_stb_i),
            .wishbone_cyc_o(data_cyc_i),

		.stallreq(stallreq_from_mem)	       
	
	);
// sram control
sram_top sram_top0(
    .clk_i(clk_o),
    .rst_i(rst),
   
    .wb_stb_i(sram_stb_o),
    .wb_cyc_i(sram_cyc_o),
    .wb_ack_o(sram_ack_i),
    .wb_addr_i(sram_addr_o),
    .wb_sel_i(sram_sel_o),
    .wb_we_i(sram_we_o),
    .wb_data_i(sram_data_o),
    .wb_data_o(sram_data_i),
    .baseram_addr(baseram_addr),
    .baseram_data(baseram_data),
    .baseram_ce(baseram_ce),
    .baseram_oe(baseram_oe),
    .baseram_we(baseram_we),
    .extram_addr(extram_addr),
    .extram_data(extram_data),
    .extram_ce(extram_ce),
    .extram_oe(extram_oe),
    .extram_we(extram_we)
);

// flash control
flash_top flash_top0(
// Parallel FLASH Interface
    .wb_clk_i(clk_o),
    .lamp(lamp),
    .wb_rst_i(rst), 
    .wb_adr_i(flash_addr_o), 
    .wb_dat_o(flash_data_i), 
    .wb_dat_i(flash_data_o), 
    .wb_sel_i(flash_sel_o), 
    .wb_we_i(flash_we_o),
    .wb_stb_i(flash_stb_o), 
    .wb_cyc_i(flash_cyc_o), 
    .wb_ack_o(flash_ack_i),
    
    .flash_adr_o(flash_adr_o), 
    .flash_dat_io(flash_dat_io), 
    
    .flash_ctrl(flash_ctrl)
);

inst_rom_top inst_rom_top0(
    .clk_i(clk_o),
    .rst_i(rst),
    .wb_addr_i(rom_addr_o),
    .wb_data_i(rom_data_o),
    .wb_data_o(rom_data_i),
    .wb_we_i(rom_we_o),
    .wb_stb_i(rom_stb_o), 
    .wb_cyc_i(rom_cyc_o), 
    .wb_ack_o(rom_ack_i), 
    .wb_sel_i(rom_sel_o)
);
uart_controller uart_controller0(
    .clk(clk_o),
    .rst(rst),
    .data_i(uart_data_o),
    .data_o(uart_data_i),
    .wb_cyc_i(uart_cyc_o),
    .wb_stb_i(uart_stb_o),
    .we_i(uart_we_o),
    .ack_o(uart_ack_i),
    .int_o(uart_int),
    .TxD_o(uart_out),
    .RxD_i(uart_in)
    );
//uart control
uart_top uart_top0(
    //wb
    .wb_clk_i(clk_o),
    .wb_rst_i(rst),
    .wb_adr_i(uart_addr_o[4:0]),
    .wb_dat_i(uart_data_o),
    .wb_dat_o(uart_data_i),
    .wb_we_i(uart_we_o),
    .wb_stb_i(uart_stb_o), 
    .wb_cyc_i(uart_cyc_o), 
    .wb_ack_o(uart_ack_i), 
    .wb_sel_i(uart_sel_o),

    //uart interupt
    .int_o(uart_int),

    //uart interface
    .stx_pad_o(uart_out), 
    .srx_pad_i(uart_in),

    // modem signals
    .rts_pad_o(), 
    .cts_pad_i(1'b0), 
    .dtr_pad_o(), 
    .dsr_pad_i(1'b0), 
    .ri_pad_i(1'b0), 
    .dcd_pad_i(1'b0)
);

// transToDigit transToDigit0(
//     .bits(seg),
//     .digit0(digit0),
//     .digit1(digit1)
// );

//wb_conmax
wb_conmax_top wb_conmax_top0(
.clk_i(clk_o), .rst_i(rst),

// Master 0 Interface
.m0_data_i(data_data_i), 
.m0_data_o(data_data_o), 
.m0_addr_i(data_addr_i), 
.m0_sel_i(data_sel_i), 
.m0_we_i(data_we_i), 
.m0_cyc_i(data_cyc_i),

.m0_stb_i(data_stb_i), 
.m0_ack_o(data_ack_o), 
.m0_err_o(), 
.m0_rty_o(),

// Master 1 Interface:data


.m1_data_i(inst_data_i), 
.m1_data_o(inst_data_o), 
.m1_addr_i(inst_addr_i), 
.m1_sel_i(inst_sel_i), 
.m1_we_i(inst_we_i), 
.m1_cyc_i(inst_cyc_i),

.m1_stb_i(inst_stb_i), 
.m1_ack_o(inst_ack_o), 
.m1_err_o(), 
.m1_rty_o(),

// Master 2 Interface

.m2_data_i(`ZeroWord), 
.m2_data_o(), 
.m2_addr_i(`ZeroWord), 
.m2_sel_i(4'b0000), 
.m2_we_i(1'b0), 
.m2_cyc_i(1'b0),

.m2_stb_i(1'b0), 
.m2_ack_o(), 
.m2_err_o(), 
.m2_rty_o(),

// Master 3 Interface

.m3_data_i(`ZeroWord), 
.m3_data_o(), 
.m3_addr_i(`ZeroWord), 
.m3_sel_i(4'b0000), 
.m3_we_i(1'b0), 
.m3_cyc_i(1'b0),

.m3_stb_i(1'b0), 
.m3_ack_o(), 
.m3_err_o(), 
.m3_rty_o(),

// Master 4 Interface

.m4_data_i(`ZeroWord), 
.m4_data_o(), 
.m4_addr_i(`ZeroWord), 
.m4_sel_i(4'b0000), 
.m4_we_i(1'b0), 
.m4_cyc_i(1'b0),

.m4_stb_i(1'b0), 
.m4_ack_o(), 
.m4_err_o(), 
.m4_rty_o(),

// Master 5 Interface

.m5_data_i(`ZeroWord), 
.m5_data_o(), 
.m5_addr_i(`ZeroWord), 
.m5_sel_i(4'b0000), 
.m5_we_i(1'b0), 
.m5_cyc_i(1'b0),

.m5_stb_i(1'b0), 
.m5_ack_o(), 
.m5_err_o(), 
.m5_rty_o(),

// Master 6 Interface

.m6_data_i(`ZeroWord), 
.m6_data_o(), 
.m6_addr_i(`ZeroWord), 
.m6_sel_i(4'b0000), 
.m6_we_i(1'b0), 
.m6_cyc_i(1'b0),

.m6_stb_i(1'b0), 
.m6_ack_o(), 
.m6_err_o(), 
.m6_rty_o(),

// Master 7 Interface

.m7_data_i(`ZeroWord), 
.m7_data_o(), 
.m7_addr_i(`ZeroWord), 
.m7_sel_i(4'b0000), 
.m7_we_i(1'b0), 
.m7_cyc_i(1'b0),

.m7_stb_i(1'b0), 
.m7_ack_o(), 
.m7_err_o(), 
.m7_rty_o(),

// Slave 0 Interface: ram

.s0_data_i(sram_data_i), 
.s0_data_o(sram_data_o), 
.s0_addr_o(sram_addr_o), 
.s0_sel_o(sram_sel_o), 
.s0_we_o(sram_we_o), 
.s0_cyc_o(sram_cyc_o),

.s0_stb_o(sram_stb_o), 
.s0_ack_i(sram_ack_i), 
.s0_err_i(1'b0), 
.s0_rty_i(1'b0),



// Slave 1 Interface: flash

.s1_data_i(flash_data_i), 
.s1_data_o(flash_data_o), 
.s1_addr_o(flash_addr_o), 
.s1_sel_o(flash_sel_o), 
.s1_we_o(flash_we_o), 
.s1_cyc_o(flash_cyc_o),

.s1_stb_o(flash_stb_o), 
.s1_ack_i(flash_ack_i), 
.s1_err_i(1'b0), 
.s1_rty_i(1'b0),

// Slave 2 Interface: rom

.s2_data_i(rom_data_i), 
.s2_data_o(rom_data_o), 
.s2_addr_o(rom_addr_o), 
.s2_sel_o(rom_sel_o), 
.s2_we_o(rom_we_o), 
.s2_cyc_o(rom_cyc_o),

.s2_stb_o(rom_stb_o), 
.s2_ack_i(rom_ack_i), 
.s2_err_i(1'b0), 
.s2_rty_i(1'b0),



// Slave 3 Interface: uart

.s3_data_i(uart_data_i), 
.s3_data_o(uart_data_o), 
.s3_addr_o(uart_addr_o), 
.s3_sel_o(uart_sel_o), 
.s3_we_o(uart_we_o), 
.s3_cyc_o(uart_cyc_o),

.s3_stb_o(uart_stb_o), 
.s3_ack_i(uart_ack_i), 
.s3_err_i(1'b0), 
.s3_rty_i(1'b0),

// Slave 4 Interface

.s4_data_i(), 
.s4_data_o(), 
.s4_addr_o(), 
.s4_sel_o(), 
.s4_we_o(), 
.s4_cyc_o(),

.s4_stb_o(), 
.s4_ack_i(1'b0), 
.s4_err_i(1'b0), 
.s4_rty_i(1'b0),

// Slave 5 Interface

.s5_data_i(), 
.s5_data_o(), 
.s5_addr_o(), 
.s5_sel_o(), 
.s5_we_o(), 
.s5_cyc_o(),

.s5_stb_o(), 
.s5_ack_i(1'b0), 
.s5_err_i(1'b0), 
.s5_rty_i(1'b0),

// Slave 6 Interface

.s6_data_i(), 
.s6_data_o(), 
.s6_addr_o(), 
.s6_sel_o(), 
.s6_we_o(), 
.s6_cyc_o(),

.s6_stb_o(), 
.s6_ack_i(1'b0), 
.s6_err_i(1'b0), 
.s6_rty_i(1'b0),

// Slave 7 Interface

.s7_data_i(), 
.s7_data_o(), 
.s7_addr_o(), 
.s7_sel_o(), 
.s7_we_o(), 
.s7_cyc_o(),

.s7_stb_o(), 
.s7_ack_i(1'b0), 
.s7_err_i(1'b0), 
.s7_rty_i(1'b0),

// Slave 8 Interface

.s8_data_i(), 
.s8_data_o(), 
.s8_addr_o(), 
.s8_sel_o(), 
.s8_we_o(), 
.s8_cyc_o(),

.s8_stb_o(), 
.s8_ack_i(1'b0), 
.s8_err_i(1'b0), 
.s8_rty_i(1'b0),

// Slave 9 Interface

.s9_data_i(), 
.s9_data_o(), 
.s9_addr_o(), 
.s9_sel_o(), 
.s9_we_o(), 
.s9_cyc_o(),

.s9_stb_o(), 
.s9_ack_i(1'b0), 
.s9_err_i(1'b0), 
.s9_rty_i(1'b0),

// Slave 10 Interface

.s10_data_i(), 
.s10_data_o(), 
.s10_addr_o(), 
.s10_sel_o(), 
.s10_we_o(), 
.s10_cyc_o(),

.s10_stb_o(), 
.s10_ack_i(1'b0), 
.s10_err_i(1'b0), 
.s10_rty_i(1'b0),

// Slave 11 Interface

.s11_data_i(), 
.s11_data_o(), 
.s11_addr_o(), 
.s11_sel_o(), 
.s11_we_o(), 
.s11_cyc_o(),

.s11_stb_o(), 
.s11_ack_i(1'b0), 
.s11_err_i(1'b0), 
.s11_rty_i(1'b0),

// Slave 12 Interface

.s12_data_i(), 
.s12_data_o(), 
.s12_addr_o(), 
.s12_sel_o(), 
.s12_we_o(), 
.s12_cyc_o(),

.s12_stb_o(), 
.s12_ack_i(1'b0), 
.s12_err_i(1'b0), 
.s12_rty_i(1'b0),

// Slave 13 Interface

.s13_data_i(), 
.s13_data_o(), 
.s13_addr_o(), 
.s13_sel_o(), 
.s13_we_o(), 
.s13_cyc_o(),

.s13_stb_o(), 
.s13_ack_i(1'b0), 
.s13_err_i(1'b0), 
.s13_rty_i(1'b0),

// Slave 14 Interface

.s14_data_i(), 
.s14_data_o(), 
.s14_addr_o(), 
.s14_sel_o(), 
.s14_we_o(), 
.s14_cyc_o(),

.s14_stb_o(), 
.s14_ack_i(1'b0), 
.s14_err_i(1'b0), 
.s14_rty_i(1'b0),

// Slave 15 Interface

.s15_data_i(), 
.s15_data_o(), 
.s15_addr_o(), 
.s15_sel_o(), 
.s15_we_o(), 
.s15_cyc_o(),

.s15_stb_o(), 
.s15_ack_i(1'b0), 
.s15_err_i(1'b0), 
.s15_rty_i(1'b0)
);

// BELOW ARE ywn route

//     // rom ram
// wire[`InstAddrBus]  inst_addr;
// wire[`InstBus]      inst;
// wire                rom_ce;

// wire mem_we_i;
// wire[`RegBus] mem_addr_i;
// wire[`RegBus] mem_data_i;
// wire[`RegBus] mem_data_o;
// wire[3:0]     mem_sel_i;  
// wire          mem_ce_i; 

//     abandonmips abandonmips0(
//     .clk(clk),
//     .rst(rst),

//     .rom_ce_o(rom_ce),
//        .iwishbone_data_i(inst),
//        .iwishbone_ack_i(1'b1),
//        .iwishbone_addr_o(inst_addr),
//        .iwishbone_data_o(),
//        .iwishbone_we_o(),
//        .iwishbone_sel_o(),
//        .iwishbone_stb_o(),
//        .iwishbone_cyc_o(), 

//        .int_i(intrpt),
//        .regfile_reg_sel(regfile_reg_sel),
//        .regfile_reg_out(regfile_reg_out),

//        .dwishbone_data_i(mem_data_o),
//        .dwishbone_ack_i(1'b1),
//        .dwishbone_addr_o(mem_addr_i),
//        .dwishbone_data_o(mem_data_i),
//        .dwishbone_we_o(mem_we_i),
//        .dwishbone_sel_o(mem_sel_i),
//        .dwishbone_stb_o(),
//        .dwishbone_cyc_o(),

//     .ram_ce_o(mem_ce_i),

//     .timer_int_o(timer_int)    
// );

//     fake_sram fake_sram0(

//        .clk(clk),

//        // original data_ram
//        .data_ce(mem_ce_i),
//        .we(mem_we_i), // write enable
//        .data_addr(mem_addr_i),
//        .sel(mem_sel_i),
//        .data_i(mem_data_i),
//        .data_o(mem_data_o),

//        // original inst_rom
//        .inst_ce(rom_ce),
//        .inst_addr(inst_addr),
//        .inst(inst),

//        .serial_port_o(ram_serial_port_o)

//    );

endmodule