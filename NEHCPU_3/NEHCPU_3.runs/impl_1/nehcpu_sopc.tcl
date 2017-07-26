proc start_step { step } {
  set stopFile ".stop.rst"
  if {[file isfile .stop.rst]} {
    puts ""
    puts "*** Halting run - EA reset detected ***"
    puts ""
    puts ""
    return -code error
  }
  set beginFile ".$step.begin.rst"
  set platform "$::tcl_platform(platform)"
  set user "$::tcl_platform(user)"
  set pid [pid]
  set host ""
  if { [string equal $platform unix] } {
    if { [info exist ::env(HOSTNAME)] } {
      set host $::env(HOSTNAME)
    }
  } else {
    if { [info exist ::env(COMPUTERNAME)] } {
      set host $::env(COMPUTERNAME)
    }
  }
  set ch [open $beginFile w]
  puts $ch "<?xml version=\"1.0\"?>"
  puts $ch "<ProcessHandle Version=\"1\" Minor=\"0\">"
  puts $ch "    <Process Command=\".planAhead.\" Owner=\"$user\" Host=\"$host\" Pid=\"$pid\">"
  puts $ch "    </Process>"
  puts $ch "</ProcessHandle>"
  close $ch
}

proc end_step { step } {
  set endFile ".$step.end.rst"
  set ch [open $endFile w]
  close $ch
}

proc step_failed { step } {
  set endFile ".$step.error.rst"
  set ch [open $endFile w]
  close $ch
}


start_step init_design
set ACTIVE_STEP init_design
set rc [catch {
  create_msg_db init_design.pb
  create_project -in_memory -part xc7a100tfgg676-2L
  set_property design_mode GateLvl [current_fileset]
  set_param project.singleFileAddWarning.threshold 0
  set_property webtalk.parent_dir G:/AbandonMIPS/AbandonMIPS/v1.0/Abandon_MIPS/src/NEHCPU_3/NEHCPU_3.cache/wt [current_project]
  set_property parent.project_path G:/AbandonMIPS/AbandonMIPS/v1.0/Abandon_MIPS/src/NEHCPU_3/NEHCPU_3.xpr [current_project]
  set_property ip_output_repo G:/AbandonMIPS/AbandonMIPS/v1.0/Abandon_MIPS/src/NEHCPU_3/NEHCPU_3.cache/ip [current_project]
  set_property ip_cache_permissions {read write} [current_project]
  set_property XPM_LIBRARIES {XPM_CDC XPM_MEMORY} [current_project]
  add_files -quiet G:/AbandonMIPS/AbandonMIPS/v1.0/Abandon_MIPS/src/NEHCPU_3/NEHCPU_3.runs/synth_1/nehcpu_sopc.dcp
  read_ip -quiet G:/AbandonMIPS/AbandonMIPS/v1.0/Abandon_MIPS/src/NEHCPU_3/NEHCPU_3.srcs/sources_1/ip/scfifo/scfifo.xci
  set_property is_locked true [get_files G:/AbandonMIPS/AbandonMIPS/v1.0/Abandon_MIPS/src/NEHCPU_3/NEHCPU_3.srcs/sources_1/ip/scfifo/scfifo.xci]
  read_ip -quiet G:/AbandonMIPS/AbandonMIPS/v1.0/Abandon_MIPS/src/NEHCPU_3/NEHCPU_3.srcs/sources_1/ip/vga_ram/vga_ram.xci
  set_property is_locked true [get_files G:/AbandonMIPS/AbandonMIPS/v1.0/Abandon_MIPS/src/NEHCPU_3/NEHCPU_3.srcs/sources_1/ip/vga_ram/vga_ram.xci]
  read_xdc G:/AbandonMIPS/AbandonMIPS/v1.0/Abandon_MIPS/src/NEHCPU_3/NEHCPU_3.srcs/constrs_1/new/NEHCPU.xdc
  link_design -top nehcpu_sopc -part xc7a100tfgg676-2L
  close_msg_db -file init_design.pb
} RESULT]
if {$rc} {
  step_failed init_design
  return -code error $RESULT
} else {
  end_step init_design
  unset ACTIVE_STEP 
}

start_step opt_design
set ACTIVE_STEP opt_design
set rc [catch {
  create_msg_db opt_design.pb
  opt_design 
  write_checkpoint -force nehcpu_sopc_opt.dcp
  catch { report_drc -file nehcpu_sopc_drc_opted.rpt }
  close_msg_db -file opt_design.pb
} RESULT]
if {$rc} {
  step_failed opt_design
  return -code error $RESULT
} else {
  end_step opt_design
  unset ACTIVE_STEP 
}

start_step place_design
set ACTIVE_STEP place_design
set rc [catch {
  create_msg_db place_design.pb
  implement_debug_core 
  place_design 
  write_checkpoint -force nehcpu_sopc_placed.dcp
  catch { report_io -file nehcpu_sopc_io_placed.rpt }
  catch { report_utilization -file nehcpu_sopc_utilization_placed.rpt -pb nehcpu_sopc_utilization_placed.pb }
  catch { report_control_sets -verbose -file nehcpu_sopc_control_sets_placed.rpt }
  close_msg_db -file place_design.pb
} RESULT]
if {$rc} {
  step_failed place_design
  return -code error $RESULT
} else {
  end_step place_design
  unset ACTIVE_STEP 
}

start_step route_design
set ACTIVE_STEP route_design
set rc [catch {
  create_msg_db route_design.pb
  route_design 
  write_checkpoint -force nehcpu_sopc_routed.dcp
  catch { report_drc -file nehcpu_sopc_drc_routed.rpt -pb nehcpu_sopc_drc_routed.pb -rpx nehcpu_sopc_drc_routed.rpx }
  catch { report_methodology -file nehcpu_sopc_methodology_drc_routed.rpt -rpx nehcpu_sopc_methodology_drc_routed.rpx }
  catch { report_power -file nehcpu_sopc_power_routed.rpt -pb nehcpu_sopc_power_summary_routed.pb -rpx nehcpu_sopc_power_routed.rpx }
  catch { report_route_status -file nehcpu_sopc_route_status.rpt -pb nehcpu_sopc_route_status.pb }
  catch { report_clock_utilization -file nehcpu_sopc_clock_utilization_routed.rpt }
  catch { report_timing_summary -warn_on_violation -max_paths 10 -file nehcpu_sopc_timing_summary_routed.rpt -rpx nehcpu_sopc_timing_summary_routed.rpx }
  close_msg_db -file route_design.pb
} RESULT]
if {$rc} {
  write_checkpoint -force nehcpu_sopc_routed_error.dcp
  step_failed route_design
  return -code error $RESULT
} else {
  end_step route_design
  unset ACTIVE_STEP 
}

start_step write_bitstream
set ACTIVE_STEP write_bitstream
set rc [catch {
  create_msg_db write_bitstream.pb
  set_property XPM_LIBRARIES {XPM_CDC XPM_MEMORY} [current_project]
  catch { write_mem_info -force nehcpu_sopc.mmi }
  write_bitstream -force nehcpu_sopc.bit 
  catch {write_debug_probes -no_partial_ltxfile -quiet -force debug_nets}
  catch {file copy -force debug_nets.ltx nehcpu_sopc.ltx}
  close_msg_db -file write_bitstream.pb
} RESULT]
if {$rc} {
  step_failed write_bitstream
  return -code error $RESULT
} else {
  end_step write_bitstream
  unset ACTIVE_STEP 
}

