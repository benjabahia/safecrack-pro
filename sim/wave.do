# =====================================================================
# wave.do - sinais principais do SafeCrack Pro na janela Wave
# Usado por sim/simular.do (ou: do wave.do, com a simulacao carregada)
# =====================================================================
onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -noupdate -divider {Placa (entradas)}
add wave -noupdate /tb_safecrack/CLOCK_50
add wave -noupdate -label {KEY (ativo em 0)} -radix binary /tb_safecrack/KEY

add wave -noupdate -divider {Botoes tratados}
add wave -noupdate -label {nivel (1=apertado)} -radix binary /tb_safecrack/dut/botao_nivel
add wave -noupdate -label {pulso (1 ciclo)}    -radix binary /tb_safecrack/dut/botao_pulso
add wave -noupdate -label reset /tb_safecrack/dut/rst

add wave -noupdate -divider {FSM}
add wave -noupdate -label estado      /tb_safecrack/dut/u_fsm/estado
add wave -noupdate -label prox_estado /tb_safecrack/dut/u_fsm/prox_estado
add wave -noupdate -label {posicao (0=1o)} -radix unsigned /tb_safecrack/dut/u_fsm/posicao
add wave -noupdate -label dig1 -radix unsigned /tb_safecrack/dut/dig1
add wave -noupdate -label dig2 -radix unsigned /tb_safecrack/dut/dig2
add wave -noupdate -label dig3 -radix unsigned /tb_safecrack/dut/dig3
add wave -noupdate -label dig4 -radix unsigned /tb_safecrack/dut/dig4
add wave -noupdate -label senha_ok /tb_safecrack/dut/u_fsm/senha_ok

add wave -noupdate -divider {Temporizador}
add wave -noupdate -label habilita    /tb_safecrack/dut/u_tempo/habilita
add wave -noupdate -label cont_ciclos -radix unsigned /tb_safecrack/dut/u_tempo/cont_ciclos
add wave -noupdate -label cont_seg    -radix unsigned /tb_safecrack/dut/u_tempo/cont_seg
add wave -noupdate -label fim         /tb_safecrack/dut/u_tempo/fim

add wave -noupdate -divider {Placa (saidas)}
add wave -noupdate -radix binary /tb_safecrack/LEDG
add wave -noupdate -radix binary /tb_safecrack/LEDR
add wave -noupdate -label {HEX4 (ativo)} -radix binary /tb_safecrack/HEX4
add wave -noupdate -label {HEX3 (1o)}    -radix binary /tb_safecrack/HEX3
add wave -noupdate -label {HEX2 (2o)}    -radix binary /tb_safecrack/HEX2
add wave -noupdate -label {HEX1 (3o)}    -radix binary /tb_safecrack/HEX1
add wave -noupdate -label {HEX0 (4o)}    -radix binary /tb_safecrack/HEX0

add wave -noupdate -divider {Resultado do testbench}
add wave -noupdate -label PASS -radix unsigned /tb_safecrack/n_pass
add wave -noupdate -label FAIL -radix unsigned /tb_safecrack/n_fail

TreeUpdate [SetDefaultTree]
configure wave -namecolwidth 180
configure wave -valuecolwidth 90
configure wave -timelineunits us
update
WaveRestoreZoom {0 us} {24 us}
