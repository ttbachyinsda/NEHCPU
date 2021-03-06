// Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2017.2 (win64) Build 1909853 Thu Jun 15 18:39:09 MDT 2017
// Date        : Sun Jul 23 14:58:44 2017
// Host        : DESKTOP-9I7G7R0 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               G:/AbandonMIPS/AbandonMIPS/v1.0/Abandon_MIPS/src/NEHCPU_3/NEHCPU_3.runs/vga_ram_synth_1/vga_ram_stub.v
// Design      : vga_ram
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100tfgg676-2L
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_3_6,Vivado 2017.2" *)
module vga_ram(clka, wea, addra, dina, clkb, addrb, doutb)
/* synthesis syn_black_box black_box_pad_pin="clka,wea[0:0],addra[17:0],dina[8:0],clkb,addrb[17:0],doutb[8:0]" */;
  input clka;
  input [0:0]wea;
  input [17:0]addra;
  input [8:0]dina;
  input clkb;
  input [17:0]addrb;
  output [8:0]doutb;
endmodule
