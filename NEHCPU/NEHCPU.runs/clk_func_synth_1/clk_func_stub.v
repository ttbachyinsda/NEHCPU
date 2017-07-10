// Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2017.2 (win64) Build 1909853 Thu Jun 15 18:39:09 MDT 2017
// Date        : Sat Jul  8 16:20:32 2017
// Host        : DESKTOP-9I7G7R0 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               G:/prj5_apollo-master-3bd193289902d4aded5121b45787793f054fa79c/mips/NEHCPU/NEHCPU.runs/clk_func_synth_1/clk_func_stub.v
// Design      : clk_func
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100tfgg676-2L
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module clk_func(clk_out1, clk_out2, CLK_IN1)
/* synthesis syn_black_box black_box_pad_pin="clk_out1,clk_out2,CLK_IN1" */;
  output clk_out1;
  output clk_out2;
  input CLK_IN1;
endmodule
