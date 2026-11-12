# =====================================================================
# simular.do - compila tudo, roda o testbench e abre as waveforms
#
# Uso (a partir da raiz do projeto):
#   vsim -do sim/simular.do                       (GUI, com waveform)
#   vsim -c -do "do sim/simular.do; quit -f"      (so texto, PASS/FAIL)
# =====================================================================

# --- Localiza a pasta sim/ -------------------------------------------
# Obs.: no ModelSim, [info script] nem sempre devolve o caminho real
# do .do, por isso procuramos primeiro a partir da pasta atual.
if {[file exists [file join [pwd] sim simular.do]]} {
    set SIM_DIR [file normalize [file join [pwd] sim]]
} elseif {[file exists [file join [pwd] simular.do]]} {
    set SIM_DIR [file normalize [pwd]]
} else {
    set SIM_DIR [file dirname [file normalize [info script]]]
}
cd $SIM_DIR

# Encerra uma simulacao anterior, se houver
catch {quit -sim}

# --- Compilacao ------------------------------------------------------
if {![file exists work/_info]} { vlib work }
vmap work work
vlog -sv -work work ../src/detector_borda.sv \
                    ../src/decodificador_7seg.sv \
                    ../src/temporizador.sv \
                    ../src/cofre_fsm.sv \
                    ../src/safecrack_top.sv \
                    tb_safecrack.sv

# --- Simulacao -------------------------------------------------------
# +acc mantem os sinais internos visiveis para a janela Wave
vsim -voptargs=+acc work.tb_safecrack

# So abre as waveforms no modo grafico
if {![batch_mode]} {
    do wave.do
}

# O testbench chama $finish; -onfinish stop evita fechar a janela
onfinish stop
run -all
if {![batch_mode]} { wave zoom full }
