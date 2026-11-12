// =====================================================================
// detector_borda.sv
// Sincronizador de 2 flip-flops + detector de borda para os botoes KEY.
//
// Por que existe:
//  * Os botoes sao ASSINCRONOS em relacao ao clock de 50 MHz. Se um sinal
//    externo muda perto da borda do clock, o flip-flop pode ficar
//    "metaestavel". Passar o sinal por 2 flip-flops em serie da tempo
//    para essa instabilidade sumir antes de o sinal ser usado.
//  * Os botoes da DE2-115 sao ATIVOS EM NIVEL BAIXO (apertado = 0).
//    Aqui o sinal e invertido logo na entrada, para que no resto do
//    projeto "1" signifique "apertado" (mais facil de ler).
//  * Um aperto dura milhoes de ciclos de clock. Para que cada aperto
//    gere UMA unica acao, detectamos so a BORDA de subida (o instante
//    em que o botao passou de solto para apertado). Segurar o botao
//    nao gera novos pulsos.
//  * Obs.: os botoes da DE2-115 ja tem debounce em hardware na placa
//    (circuito Schmitt trigger), por isso nao ha debounce aqui.
// =====================================================================
module detector_borda #(
    parameter int N = 4                 // quantidade de botoes
) (
    input  logic         clk,
    input  logic [N-1:0] botao_n,       // botoes crus da placa (ativo em 0)
    output logic [N-1:0] nivel,         // botao sincronizado (1 = apertado)
    output logic [N-1:0] pulso          // 1 durante 1 ciclo a cada aperto
);

    // Os tres registradores abaixo guardam o botao ja invertido
    // (1 = apertado). Ao ligar a FPGA eles valem 0 = "solto".
    logic [N-1:0] sinc1;   // 1o flip-flop do sincronizador
    logic [N-1:0] sinc2;   // 2o flip-flop do sincronizador (sinal seguro)
    logic [N-1:0] anterior;// valor de sinc2 no ciclo anterior

    // Bloco sequencial: a cada borda do clock o sinal anda uma posicao
    // na "fila" botao -> sinc1 -> sinc2 -> anterior.
    always_ff @(posedge clk) begin
        sinc1    <= ~botao_n;  // inverte: apertado (0 na placa) vira 1
        sinc2    <= sinc1;
        anterior <= sinc2;
    end

    // Nivel sincronizado: usado, por exemplo, como reset (KEY[0]).
    assign nivel = sinc2;

    // Borda de subida: agora apertado E no ciclo anterior solto.
    // Esse "1" dura exatamente um ciclo de clock.
    assign pulso = sinc2 & ~anterior;

endmodule
