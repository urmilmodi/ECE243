onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider Mux
add wave -noupdate -label A -radix hexadecimal /testbench/A
add wave -noupdate -label B -radix hexadecimal /testbench/B
add wave -noupdate -label C -radix hexadecimal /testbench/C
add wave -noupdate -label D -radix hexadecimal /testbench/D
add wave -noupdate -label S -radix hexadecimal /testbench/S
add wave -noupdate -label M -radix hexadecimal /testbench/M
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {20000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 73
configure wave -valuecolwidth 64
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {150 ns}
