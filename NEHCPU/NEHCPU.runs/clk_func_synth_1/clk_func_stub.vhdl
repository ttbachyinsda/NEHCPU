-- Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2017.2 (win64) Build 1909853 Thu Jun 15 18:39:09 MDT 2017
-- Date        : Sat Jul  8 16:20:32 2017
-- Host        : DESKTOP-9I7G7R0 running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub
--               G:/prj5_apollo-master-3bd193289902d4aded5121b45787793f054fa79c/mips/NEHCPU/NEHCPU.runs/clk_func_synth_1/clk_func_stub.vhdl
-- Design      : clk_func
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7a100tfgg676-2L
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity clk_func is
  Port ( 
    clk_out1 : out STD_LOGIC;
    clk_out2 : out STD_LOGIC;
    CLK_IN1 : in STD_LOGIC
  );

end clk_func;

architecture stub of clk_func is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clk_out1,clk_out2,CLK_IN1";
begin
end;
