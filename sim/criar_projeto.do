# =====================================================================
# SafeCrack Pro - criacao do projeto ModelSim (Intel FPGA Starter Edition)
#
# Uso (a partir da raiz do projeto):
#   vsim -do sim/criar_projeto.do                          (modo GUI)
#   vsim -c -do "do sim/criar_projeto.do; quit -f"         (linha de comando)
# Ou, de dentro do ModelSim ja aberto:
#   do <caminho>/sim/criar_projeto.do
#
# Pode ser executado de novo sempre que novos .sv forem criados em src/:
# o projeto existente e reaberto e apenas os arquivos novos sao adicionados.
# =====================================================================

set PROJ_NAME safecrack_pro

# --- Localiza a pasta sim/ (onde este script esta) -------------------
# Obs.: no ModelSim, [info script] nem sempre devolve o caminho real
# do .do, por isso procuramos primeiro a partir da pasta atual.
if {[file exists [file join [pwd] sim criar_projeto.do]]} {
    set SIM_DIR [file normalize [file join [pwd] sim]]
} elseif {[file exists [file join [pwd] criar_projeto.do]]} {
    set SIM_DIR [file normalize [pwd]]
} else {
    set SIM_DIR [file dirname [file normalize [info script]]]
}
set SRC_DIR [file normalize [file join $SIM_DIR .. src]]

cd $SIM_DIR
echo "Pasta sim: $SIM_DIR"
echo "Pasta src: $SRC_DIR"

# --- Fecha qualquer projeto aberto ----------------------------------
catch {project close}

# --- Cria ou reabre o projeto ----------------------------------------
set MPF [file join $SIM_DIR $PROJ_NAME.mpf]
if {[file exists $MPF]} {
    echo "Projeto ja existe, reabrindo: $MPF"
    project open $MPF
} else {
    echo "Criando projeto: $MPF"
    project new $SIM_DIR $PROJ_NAME work
}

# --- Biblioteca de trabalho ------------------------------------------
if {![file exists [file join $SIM_DIR work _info]]} {
    vlib work
}
vmap work work

# --- Adiciona os arquivos .sv de src/ --------------------------------
set ja_no_projeto {}
catch {
    foreach f [project filenames] {
        lappend ja_no_projeto [file normalize $f]
    }
}

set arquivos [lsort [glob -nocomplain -directory $SRC_DIR *.sv]]
# testbench(s) que ficam na propria pasta sim/
set testbenches [lsort [glob -nocomplain -directory $SIM_DIR tb_*.sv]]
if {[llength $arquivos] == 0} {
    echo "AVISO: nenhum arquivo .sv encontrado em $SRC_DIR."
    echo "       Crie os modulos em src/ e rode este script de novo."
} else {
    foreach f $arquivos {
        set fn [file normalize $f]
        if {[lsearch -exact $ja_no_projeto $fn] >= 0} {
            echo "Ja no projeto: [file tail $f]"
        } else {
            # caminho relativo a sim/ (projeto portavel)
            project addfile ../src/[file tail $f] SystemVerilog
            echo "Adicionado:    [file tail $f]"
        }
    }
}

foreach f $testbenches {
    if {[lsearch -exact $ja_no_projeto [file normalize $f]] >= 0} {
        echo "Ja no projeto: [file tail $f]"
    } else {
        project addfile [file tail $f] SystemVerilog
        echo "Adicionado:    [file tail $f] (testbench)"
    }
}

echo "Projeto $PROJ_NAME pronto. Para compilar: project compileall"
