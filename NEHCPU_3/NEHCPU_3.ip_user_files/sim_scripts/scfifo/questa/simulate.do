onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib scfifo_opt

do {wave.do}

view wave
view structure
view signals

do {scfifo.udo}

run -all

quit -force
