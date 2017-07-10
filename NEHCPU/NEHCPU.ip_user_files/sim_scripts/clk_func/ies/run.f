-makelib ies/xil_defaultlib -sv \
  "F:/Xilinx/Vivado/2017.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \
-endlib
-makelib ies/xpm \
  "F:/Xilinx/Vivado/2017.2/data/ip/xpm/xpm_VCOMP.vhd" \
-endlib
-makelib ies/xil_defaultlib \
  "../../../ip/clk_func/clk_func_clk_wiz.v" \
  "../../../ip/clk_func/clk_func.v" \
-endlib
-makelib ies/xil_defaultlib \
  glbl.v
-endlib

