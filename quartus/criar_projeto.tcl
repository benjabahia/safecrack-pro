# =====================================================================
# SafeCrack Pro - criacao do projeto Quartus Prime Lite
# Placa DE2-115 - Cyclone IV E EP4CE115F29C7
#
# Uso (a partir da raiz do projeto):
#   quartus_sh -t quartus/criar_projeto.tcl
#
# Pinos conforme docs/PINOS_DE2-115.md.
# Pode ser executado de novo: o projeto e reaberto e as atribuicoes
# sao regravadas; arquivos .sv novos em src/ sao incluidos.
# =====================================================================

load_package flow

set PROJ_NAME safecrack_pro
set TOP_LEVEL safecrack_top

# --- Trabalha sempre dentro da pasta quartus/ ------------------------
set QUARTUS_DIR [file dirname [file normalize [info script]]]
set SRC_DIR     [file normalize [file join $QUARTUS_DIR .. src]]
cd $QUARTUS_DIR

# --- Cria ou abre o projeto ------------------------------------------
if {[project_exists $PROJ_NAME]} {
    puts "Projeto ja existe, abrindo: $PROJ_NAME"
    project_open -revision $PROJ_NAME $PROJ_NAME
} else {
    puts "Criando projeto: $PROJ_NAME"
    project_new -revision $PROJ_NAME $PROJ_NAME
}

# --- Dispositivo e top-level -----------------------------------------
set_global_assignment -name FAMILY "Cyclone IV E"
set_global_assignment -name DEVICE EP4CE115F29C7
set_global_assignment -name TOP_LEVEL_ENTITY $TOP_LEVEL
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files

# --- Restricoes de timing (clock de 50 MHz) --------------------------
set_global_assignment -name SDC_FILE safecrack_pro.sdc

# --- Arquivos fonte (src/*.sv) ---------------------------------------
foreach f [lsort [glob -nocomplain -directory $SRC_DIR *.sv]] {
    set_global_assignment -name SYSTEMVERILOG_FILE ../src/[file tail $f]
    puts "Fonte: [file tail $f]"
}

# --- Funcao auxiliar: atribui um vetor de pinos ----------------------
# nome  : nome da porta (ex.: LEDR)
# pinos : lista de pinos na ordem [0], [1], ...
# iostd : I/O standard ("" = nao altera)
proc atribuir_vetor {nome pinos {iostd ""}} {
    set i 0
    foreach p $pinos {
        set_location_assignment PIN_$p -to "${nome}\[$i\]"
        if {$iostd ne ""} {
            set_instance_assignment -name IO_STANDARD $iostd -to "${nome}\[$i\]"
        }
        incr i
    }
}

# --- Clock -----------------------------------------------------------
set_location_assignment PIN_Y2 -to CLOCK_50

# --- Botoes (ativos em nivel baixo) ----------------------------------
# KEY[0]=reset, KEY[1]=confirma, KEY[2]=incrementa, KEY[3]=decrementa
atribuir_vetor KEY {M23 M21 N21 R24}

# --- LEDs verdes LEDG[8:0] (2.5 V) -----------------------------------
atribuir_vetor LEDG {E21 E22 E25 E24 H21 G20 G22 G21 F17} "2.5 V"

# --- LEDs vermelhos LEDR[17:0] (2.5 V) -------------------------------
atribuir_vetor LEDR {G19 F19 E19 F21 F18 E18 J19 H19 J17 G17 J15 H16 J16 H17 F15 G15 G16 H15} "2.5 V"

# --- Displays de 7 segmentos, [0]..[6] = a..g, ativos em baixo (2.5 V)
atribuir_vetor HEX0 {G18 F22 E17 L26 L25 J22 H22}       "2.5 V"
atribuir_vetor HEX1 {M24 Y22 W21 W22 W25 U23 U24}       "2.5 V"
atribuir_vetor HEX2 {AA25 AA26 Y25 W26 Y26 W27 W28}     "2.5 V"
atribuir_vetor HEX3 {V21 U21 AB20 AA21 AD24 AF23 Y19}   "2.5 V"
atribuir_vetor HEX4 {AB19 AA19 AG21 AH21 AE19 AF19 AE18} "2.5 V"

# --- Grava e fecha ---------------------------------------------------
export_assignments
project_close
puts "Projeto $PROJ_NAME criado em $QUARTUS_DIR (top-level: $TOP_LEVEL)"
