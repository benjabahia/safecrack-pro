# =====================================================================
# safecrack_pro.sdc - restricoes de timing do SafeCrack Pro (DE2-115)
#
# Sem este arquivo, o Timing Analyzer supoe um clock de 1 ns (1 GHz) e
# acusa "Timing requirements not met". Aqui informamos o clock real.
# =====================================================================

# Clock da placa: oscilador de 50 MHz no pino CLOCK_50 (periodo 20 ns)
create_clock -name CLOCK_50 -period 20.000 [get_ports {CLOCK_50}]

# Incertezas do clock (jitter etc.) calculadas automaticamente pelo Quartus
derive_clock_uncertainty

# Botoes: sao assincronos (apertados por uma pessoa) e passam pelo
# sincronizador de 2 flip-flops em detector_borda.sv, entao nao ha
# requisito de timing entre o pino e o primeiro flip-flop.
set_false_path -from [get_ports {KEY[*]}]

# LEDs e displays: sao vistos por uma pessoa, entao alguns ns de atraso
# nao importam. Sem requisito de timing ate os pinos de saida.
set_false_path -to [get_ports {LEDG[*] LEDR[*] HEX0[*] HEX1[*] HEX2[*] HEX3[*] HEX4[*]}]
