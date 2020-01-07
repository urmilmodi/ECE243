onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -label KEY -radix hexadecimal -expand /testbench/KEY
add wave -noupdate -label SW -radix hexadecimal /testbench/SW
add wave -noupdate -label LEDR -radix hexadecimal /testbench/LEDR
add wave -noupdate -divider FSM
add wave -noupdate -label Clock /testbench/U1/Clock
add wave -noupdate -label Resetn /testbench/U1/Resetn
add wave -noupdate -label Run /testbench/U1/Run
add wave -noupdate -label R /testbench/U1/R
add wave -noupdate -label New /testbench/U1/New
add wave -noupdate -label Wrap /testbench/U1/Wrap
add wave -noupdate -label Done /testbench/U1/Done
add wave -noupdate -label Sensor /testbench/U1/Sensor
add wave -noupdate -label Sum /testbench/U1/Sum
add wave -noupdate -label y_Q /testbench/U1/y_Q
add wave -noupdate -label Y_D /testbench/U1/Y_D
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {10000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 80
configure wave -valuecolwidth 38
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
WaveRestoreZoom {0 ps} {270 ns}
