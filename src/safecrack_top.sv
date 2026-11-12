// =====================================================================
// safecrack_top.sv
// Modulo TOPO do SafeCrack Pro (placa DE2-115).
//
// Por que existe:
//  * E o unico modulo que "conversa" com os pinos da placa. Os nomes
//    das portas (CLOCK_50, KEY, LEDG, LEDR, HEX0..HEX4) sao exatamente
//    os usados no pin assignment (quartus/criar_projeto.tcl).
//  * Ele nao tem logica propria importante: so liga os modulos entre si.
//
// Ligacoes:
//   KEY --> detector_borda --> pulsos inc/dec/confirma + reset
//   pulsos --> cofre_fsm <--> temporizador
//   digitos --> 4x decodificador_7seg --> HEX3..HEX0
//   digito ativo --> decodificador_7seg --> HEX4
//   aberto/erro --> LEDG / LEDR
// =====================================================================
module safecrack_top #(
    parameter logic [15:0] SENHA          = 16'h1234,    // senha 1-2-3-4
    parameter int          CICLOS_POR_SEG = 50_000_000,  // 50 MHz
    parameter int          TEMPO_ABERTO_S = 5,           // LEDG acesos (s)
    parameter int          TEMPO_ERRO_S   = 3            // LEDR acesos (s)
) (
    input  logic        CLOCK_50,
    input  logic [3:0]  KEY,    // ativos em 0: [0]=reset [1]=confirma [2]=+ [3]=-
    output logic [8:0]  LEDG,
    output logic [17:0] LEDR,
    output logic [6:0]  HEX0,   // 4o digito
    output logic [6:0]  HEX1,   // 3o digito
    output logic [6:0]  HEX2,   // 2o digito
    output logic [6:0]  HEX3,   // 1o digito
    output logic [6:0]  HEX4    // numero do digito ativo (1 a 4)
);

    // ---------------- Botoes ----------------
    logic [3:0] botao_nivel;  // 1 = botao apertado (sincronizado)
    logic [3:0] botao_pulso;  // 1 ciclo por aperto

    detector_borda #(.N(4)) u_botoes (
        .clk     (CLOCK_50),
        .botao_n (KEY),
        .nivel   (botao_nivel),
        .pulso   (botao_pulso)
    );

    // KEY[0] e reset: vale enquanto estiver apertado (nivel, nao pulso),
    // e e sincrono porque ja passou pelo sincronizador.
    logic rst;
    assign rst = botao_nivel[0];

    // ---------------- FSM + digitos ----------------
    logic [3:0] dig1, dig2, dig3, dig4;
    logic       editando;
    logic [1:0] posicao;
    logic       aberto, erro;
    logic       temporizar, fim_tempo;
    logic [3:0] duracao_seg;

    cofre_fsm #(
        .SENHA          (SENHA),
        .TEMPO_ABERTO_S (TEMPO_ABERTO_S),
        .TEMPO_ERRO_S   (TEMPO_ERRO_S)
    ) u_fsm (
        .clk         (CLOCK_50),
        .rst         (rst),
        .inc         (botao_pulso[2]),
        .dec         (botao_pulso[3]),
        .confirma    (botao_pulso[1]),
        .fim_tempo   (fim_tempo),
        .dig1        (dig1),
        .dig2        (dig2),
        .dig3        (dig3),
        .dig4        (dig4),
        .editando    (editando),
        .posicao     (posicao),
        .aberto      (aberto),
        .erro        (erro),
        .temporizar  (temporizar),
        .duracao_seg (duracao_seg)
    );

    // ---------------- Temporizador ----------------
    temporizador #(.CICLOS_POR_SEG(CICLOS_POR_SEG)) u_tempo (
        .clk         (CLOCK_50),
        .rst         (rst),
        .habilita    (temporizar),
        .duracao_seg (duracao_seg),
        .fim         (fim_tempo)
    );

    // ---------------- LEDs ----------------
    // Todos os verdes juntos quando aberto; todos os vermelhos no erro.
    assign LEDG = {9{aberto}};
    assign LEDR = {18{erro}};

    // ---------------- Displays ----------------
    // HEX4 mostra 1..4 (posicao + 1) enquanto se edita um digito.
    // Fora da edicao (verificando/aberto/erro) nao ha digito ativo,
    // entao mandamos 4'hF, que o decodificador mostra como apagado.
    logic [3:0] valor_hex4;
    assign valor_hex4 = editando ? {2'b00, posicao} + 4'd1 : 4'hF;

    decodificador_7seg u_hex3 (.valor(dig1),       .seg(HEX3));
    decodificador_7seg u_hex2 (.valor(dig2),       .seg(HEX2));
    decodificador_7seg u_hex1 (.valor(dig3),       .seg(HEX1));
    decodificador_7seg u_hex0 (.valor(dig4),       .seg(HEX0));
    decodificador_7seg u_hex4 (.valor(valor_hex4), .seg(HEX4));

endmodule
