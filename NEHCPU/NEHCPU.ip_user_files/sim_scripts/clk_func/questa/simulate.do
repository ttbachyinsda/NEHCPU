onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib clk_func_opt

do {wave.do}

view wave
view structure
view signals

do {clk_func.udo}

run -all

quit -force
