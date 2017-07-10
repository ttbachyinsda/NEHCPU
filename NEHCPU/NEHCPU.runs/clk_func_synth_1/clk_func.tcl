# 
# Synthesis run script generated by Vivado
# 

set_param project.vivado.isBlockSynthRun true
set_msg_config -msgmgr_mode ooc_run
create_project -in_memory -part xc7a100tfgg676-2L

set_param project.singleFileAddWarning.threshold 0
set_param project.compositeFile.enableAutoGeneration 0
set_param synth.vivado.isSynthRun true
set_msg_config -source 4 -id {IP_Flow 19-2162} -severity warning -new_severity info
set_property webtalk.parent_dir G:/prj5_apollo-master-3bd193289902d4aded5121b45787793f054fa79c/mips/NEHCPU/NEHCPU.cache/wt [current_project]
set_property parent.project_path G:/prj5_apollo-master-3bd193289902d4aded5121b45787793f054fa79c/mips/NEHCPU/NEHCPU.xpr [current_project]
set_property XPM_LIBRARIES XPM_MEMORY [current_project]
set_property default_lib xil_defaultlib [current_project]
set_property target_language Verilog [current_project]
set_property ip_output_repo g:/prj5_apollo-master-3bd193289902d4aded5121b45787793f054fa79c/mips/NEHCPU/NEHCPU.cache/ip [current_project]
set_property ip_cache_permissions {read write} [current_project]
read_ip -quiet G:/prj5_apollo-master-3bd193289902d4aded5121b45787793f054fa79c/mips/NEHCPU/NEHCPU.srcs/sources_1/ip/clk_func/clk_func.xci
set_property used_in_implementation false [get_files -all g:/prj5_apollo-master-3bd193289902d4aded5121b45787793f054fa79c/mips/NEHCPU/NEHCPU.srcs/sources_1/ip/clk_func/clk_func_board.xdc]
set_property used_in_implementation false [get_files -all g:/prj5_apollo-master-3bd193289902d4aded5121b45787793f054fa79c/mips/NEHCPU/NEHCPU.srcs/sources_1/ip/clk_func/clk_func.xdc]
set_property used_in_implementation false [get_files -all g:/prj5_apollo-master-3bd193289902d4aded5121b45787793f054fa79c/mips/NEHCPU/NEHCPU.srcs/sources_1/ip/clk_func/clk_func_late.xdc]
set_property used_in_implementation false [get_files -all g:/prj5_apollo-master-3bd193289902d4aded5121b45787793f054fa79c/mips/NEHCPU/NEHCPU.srcs/sources_1/ip/clk_func/clk_func_ooc.xdc]
set_property is_locked true [get_files G:/prj5_apollo-master-3bd193289902d4aded5121b45787793f054fa79c/mips/NEHCPU/NEHCPU.srcs/sources_1/ip/clk_func/clk_func.xci]

# Mark all dcp files as not used in implementation to prevent them from being
# stitched into the results of this synthesis run. Any black boxes in the
# design are intentionally left as such for best results. Dcp files will be
# stitched into the design at a later time, either when this synthesis run is
# opened, or when it is stitched into a dependent implementation run.
foreach dcp [get_files -quiet -all -filter file_type=="Design\ Checkpoint"] {
  set_property used_in_implementation false $dcp
}
read_xdc dont_touch.xdc
set_property used_in_implementation false [get_files dont_touch.xdc]

set cached_ip [config_ip_cache -export -no_bom -use_project_ipc -dir G:/prj5_apollo-master-3bd193289902d4aded5121b45787793f054fa79c/mips/NEHCPU/NEHCPU.runs/clk_func_synth_1 -new_name clk_func -ip [get_ips clk_func]]

if { $cached_ip eq {} } {

synth_design -top clk_func -part xc7a100tfgg676-2L -mode out_of_context

#---------------------------------------------------------
# Generate Checkpoint/Stub/Simulation Files For IP Cache
#---------------------------------------------------------
catch {
 write_checkpoint -force -noxdef -rename_prefix clk_func_ clk_func.dcp

 set ipCachedFiles {}
 write_verilog -force -mode synth_stub -rename_top decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix -prefix decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_ clk_func_stub.v
 lappend ipCachedFiles clk_func_stub.v

 write_vhdl -force -mode synth_stub -rename_top decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix -prefix decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_ clk_func_stub.vhdl
 lappend ipCachedFiles clk_func_stub.vhdl

 write_verilog -force -mode funcsim -rename_top decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix -prefix decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_ clk_func_sim_netlist.v
 lappend ipCachedFiles clk_func_sim_netlist.v

 write_vhdl -force -mode funcsim -rename_top decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix -prefix decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_ clk_func_sim_netlist.vhdl
 lappend ipCachedFiles clk_func_sim_netlist.vhdl

 config_ip_cache -add -dcp clk_func.dcp -move_files $ipCachedFiles -use_project_ipc -ip [get_ips clk_func]
}

rename_ref -prefix_all clk_func_

write_checkpoint -force -noxdef clk_func.dcp

catch { report_utilization -file clk_func_utilization_synth.rpt -pb clk_func_utilization_synth.pb }

if { [catch {
  write_verilog -force -mode synth_stub G:/prj5_apollo-master-3bd193289902d4aded5121b45787793f054fa79c/mips/NEHCPU/NEHCPU.runs/clk_func_synth_1/clk_func_stub.v
} _RESULT ] } { 
  puts "CRITICAL WARNING: Unable to successfully create a Verilog synthesis stub for the sub-design. This may lead to errors in top level synthesis of the design. Error reported: $_RESULT"
}

if { [catch {
  write_vhdl -force -mode synth_stub G:/prj5_apollo-master-3bd193289902d4aded5121b45787793f054fa79c/mips/NEHCPU/NEHCPU.runs/clk_func_synth_1/clk_func_stub.vhdl
} _RESULT ] } { 
  puts "CRITICAL WARNING: Unable to successfully create a VHDL synthesis stub for the sub-design. This may lead to errors in top level synthesis of the design. Error reported: $_RESULT"
}

if { [catch {
  write_verilog -force -mode funcsim G:/prj5_apollo-master-3bd193289902d4aded5121b45787793f054fa79c/mips/NEHCPU/NEHCPU.runs/clk_func_synth_1/clk_func_sim_netlist.v
} _RESULT ] } { 
  puts "CRITICAL WARNING: Unable to successfully create the Verilog functional simulation sub-design file. Post-Synthesis Functional Simulation with this file may not be possible or may give incorrect results. Error reported: $_RESULT"
}

if { [catch {
  write_vhdl -force -mode funcsim G:/prj5_apollo-master-3bd193289902d4aded5121b45787793f054fa79c/mips/NEHCPU/NEHCPU.runs/clk_func_synth_1/clk_func_sim_netlist.vhdl
} _RESULT ] } { 
  puts "CRITICAL WARNING: Unable to successfully create the VHDL functional simulation sub-design file. Post-Synthesis Functional Simulation with this file may not be possible or may give incorrect results. Error reported: $_RESULT"
}


} else {


}; # end if cached_ip 

add_files G:/prj5_apollo-master-3bd193289902d4aded5121b45787793f054fa79c/mips/NEHCPU/NEHCPU.runs/clk_func_synth_1/clk_func_stub.v -of_objects [get_files G:/prj5_apollo-master-3bd193289902d4aded5121b45787793f054fa79c/mips/NEHCPU/NEHCPU.srcs/sources_1/ip/clk_func/clk_func.xci]

add_files G:/prj5_apollo-master-3bd193289902d4aded5121b45787793f054fa79c/mips/NEHCPU/NEHCPU.runs/clk_func_synth_1/clk_func_stub.vhdl -of_objects [get_files G:/prj5_apollo-master-3bd193289902d4aded5121b45787793f054fa79c/mips/NEHCPU/NEHCPU.srcs/sources_1/ip/clk_func/clk_func.xci]

add_files G:/prj5_apollo-master-3bd193289902d4aded5121b45787793f054fa79c/mips/NEHCPU/NEHCPU.runs/clk_func_synth_1/clk_func_sim_netlist.v -of_objects [get_files G:/prj5_apollo-master-3bd193289902d4aded5121b45787793f054fa79c/mips/NEHCPU/NEHCPU.srcs/sources_1/ip/clk_func/clk_func.xci]

add_files G:/prj5_apollo-master-3bd193289902d4aded5121b45787793f054fa79c/mips/NEHCPU/NEHCPU.runs/clk_func_synth_1/clk_func_sim_netlist.vhdl -of_objects [get_files G:/prj5_apollo-master-3bd193289902d4aded5121b45787793f054fa79c/mips/NEHCPU/NEHCPU.srcs/sources_1/ip/clk_func/clk_func.xci]

add_files G:/prj5_apollo-master-3bd193289902d4aded5121b45787793f054fa79c/mips/NEHCPU/NEHCPU.runs/clk_func_synth_1/clk_func.dcp -of_objects [get_files G:/prj5_apollo-master-3bd193289902d4aded5121b45787793f054fa79c/mips/NEHCPU/NEHCPU.srcs/sources_1/ip/clk_func/clk_func.xci]

if {[file isdir G:/prj5_apollo-master-3bd193289902d4aded5121b45787793f054fa79c/mips/NEHCPU/NEHCPU.ip_user_files/ip/clk_func]} {
  catch { 
    file copy -force G:/prj5_apollo-master-3bd193289902d4aded5121b45787793f054fa79c/mips/NEHCPU/NEHCPU.runs/clk_func_synth_1/clk_func_sim_netlist.v G:/prj5_apollo-master-3bd193289902d4aded5121b45787793f054fa79c/mips/NEHCPU/NEHCPU.ip_user_files/ip/clk_func
  }
}

if {[file isdir G:/prj5_apollo-master-3bd193289902d4aded5121b45787793f054fa79c/mips/NEHCPU/NEHCPU.ip_user_files/ip/clk_func]} {
  catch { 
    file copy -force G:/prj5_apollo-master-3bd193289902d4aded5121b45787793f054fa79c/mips/NEHCPU/NEHCPU.runs/clk_func_synth_1/clk_func_sim_netlist.vhdl G:/prj5_apollo-master-3bd193289902d4aded5121b45787793f054fa79c/mips/NEHCPU/NEHCPU.ip_user_files/ip/clk_func
  }
}

if {[file isdir G:/prj5_apollo-master-3bd193289902d4aded5121b45787793f054fa79c/mips/NEHCPU/NEHCPU.ip_user_files/ip/clk_func]} {
  catch { 
    file copy -force G:/prj5_apollo-master-3bd193289902d4aded5121b45787793f054fa79c/mips/NEHCPU/NEHCPU.runs/clk_func_synth_1/clk_func_stub.v G:/prj5_apollo-master-3bd193289902d4aded5121b45787793f054fa79c/mips/NEHCPU/NEHCPU.ip_user_files/ip/clk_func
  }
}

if {[file isdir G:/prj5_apollo-master-3bd193289902d4aded5121b45787793f054fa79c/mips/NEHCPU/NEHCPU.ip_user_files/ip/clk_func]} {
  catch { 
    file copy -force G:/prj5_apollo-master-3bd193289902d4aded5121b45787793f054fa79c/mips/NEHCPU/NEHCPU.runs/clk_func_synth_1/clk_func_stub.vhdl G:/prj5_apollo-master-3bd193289902d4aded5121b45787793f054fa79c/mips/NEHCPU/NEHCPU.ip_user_files/ip/clk_func
  }
}
