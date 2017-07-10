set_property SRC_FILE_INFO {cfile:g:/prj5_apollo-master-3bd193289902d4aded5121b45787793f054fa79c/mips/NEHCPU/NEHCPU.srcs/sources_1/ip/clk_func/clk_func.xdc rfile:../../../NEHCPU.srcs/sources_1/ip/clk_func/clk_func.xdc id:1 order:EARLY scoped_inst:inst} [current_design]
set_property src_info {type:SCOPED_XDC file:1 line:57 export:INPUT save:INPUT read:READ} [current_design]
set_input_jitter [get_clocks -of_objects [get_ports CLK_IN1]] 0.2
