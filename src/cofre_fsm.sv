// =====================================================================
// cofre_fsm.sv
// Maquina de estados (FSM) do cofre + registradores dos 4 digitos.
//
// Por que existe:
//  * E o "cerebro" do cofre: decide em que etapa estamos (editando qual
//    digito, verificando, aberto ou erro) e guarda os digitos digitados.
//  * Segue o estilo da FSM base do professor:
//      - estados declarados com typedef enum;
//      - um bloco always_ff (SEQUENCIAL) que so guarda o estado atual;
//      - um bloco always_comb (COMBINACIONAL) que calcula o proximo estado.
//    Separar os dois deixa claro o que e "memoria" e o que e "decisao".
//
// Estados:
//   EDITA_D1..EDITA_D4 : usuario ajusta o 1o..4o digito (KEY[2]/KEY[3])
//                        e confirma com KEY[1]
//   VERIFICA           : 1 ciclo comparando os digitos com a SENHA
//   ABERTO             : senha certa, LEDG acesos por TEMPO_ABERTO_S
//   ERRO               : senha errada, LEDR acesos por TEMPO_ERRO_S
//
// Diagrama:
//   EDITA_D1 -conf-> EDITA_D2 -conf-> EDITA_D3 -conf-> EDITA_D4 -conf-> VERIFICA
//   VERIFICA --(certa)--> ABERTO --(fim do tempo)--> EDITA_D1
//   VERIFICA --(errada)-> ERRO   --(fim do tempo)--> EDITA_D1
//   qualquer estado --(reset KEY[0])--> EDITA_D1
// =====================================================================
module cofre_fsm #(
    // Senha escrita em BCD: 16'h1234 = digitos 1, 2, 3, 4
    // (cada digito hexadecimal = um digito decimal da senha).
    parameter logic [15:0] SENHA          = 16'h1234,
    parameter int          TEMPO_ABERTO_S = 5,
    parameter int          TEMPO_ERRO_S   = 3
) (
    input  logic       clk,
    input  logic       rst,         // reset sincrono (KEY[0] apertado)
    input  logic       inc,         // pulso: incrementa digito ativo (KEY[2])
    input  logic       dec,         // pulso: decrementa digito ativo (KEY[3])
    input  logic       confirma,    // pulso: confirma digito ativo   (KEY[1])
    input  logic       fim_tempo,   // pulso do temporizador

    output logic [3:0] dig1,        // 1o digito (vai para HEX3)
    output logic [3:0] dig2,        // 2o digito (HEX2)
    output logic [3:0] dig3,        // 3o digito (HEX1)
    output logic [3:0] dig4,        // 4o digito (HEX0)
    output logic       editando,    // 1 = algum digito esta sendo editado
    output logic [1:0] posicao,     // digito ativo: 0=1o ... 3=4o
    output logic       aberto,      // 1 = acende LEDG
    output logic       erro,        // 1 = acende LEDR
    output logic       temporizar,  // 1 = temporizador deve contar
    output logic [3:0] duracao_seg  // tempo que o temporizador deve contar
);

    // ---------------------------------------------------------------
    // Estados. EDITA_D1 e o primeiro, entao vale 0: ao ligar a FPGA
    // (registradores em 0) o cofre ja comeca no estado inicial.
    // ---------------------------------------------------------------
    typedef enum logic [2:0] {
        EDITA_D1,
        EDITA_D2,
        EDITA_D3,
        EDITA_D4,
        VERIFICA,
        ABERTO,
        ERRO
    } estado_t;

    estado_t estado;       // estado atual (registrador)
    estado_t prox_estado;  // proximo estado (calculado)

    // Os 4 digitos digitados. digitos[0] = 1o digito ... digitos[3] = 4o.
    logic [3:0] digitos [0:3];

    logic senha_ok;  // 1 quando os digitos digitados == SENHA
    logic limpar;    // 1 quando devemos zerar os digitos (fim do tempo)

    // ---------------------------------------------------------------
    // 1) SEQUENCIAL da FSM: so guarda o estado na borda do clock.
    // ---------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (rst)
            estado <= EDITA_D1;
        else
            estado <= prox_estado;
    end

    // ---------------------------------------------------------------
    // 2) COMBINACIONAL da FSM: decide o proximo estado a partir do
    //    estado atual e das entradas. Comeca com "fica onde esta" para
    //    nao criar latch e para so mudar quando algo acontece.
    // ---------------------------------------------------------------
    always_comb begin
        prox_estado = estado;
        case (estado)
            EDITA_D1: if (confirma) prox_estado = EDITA_D2;
            EDITA_D2: if (confirma) prox_estado = EDITA_D3;
            EDITA_D3: if (confirma) prox_estado = EDITA_D4;
            EDITA_D4: if (confirma) prox_estado = VERIFICA;
            VERIFICA: prox_estado = senha_ok ? ABERTO : ERRO;
            ABERTO:   if (fim_tempo) prox_estado = EDITA_D1;
            ERRO:     if (fim_tempo) prox_estado = EDITA_D1;
            default:  prox_estado = EDITA_D1;  // seguranca: estado invalido
        endcase
    end

    // ---------------------------------------------------------------
    // 3) COMBINACIONAL das saidas: dependem so do estado atual
    //    (maquina de Moore), por isso nao ha "glitch" com os botoes.
    // ---------------------------------------------------------------
    always_comb begin
        // valores padrao (evitam latch)
        editando    = 1'b0;
        posicao     = 2'd0;
        aberto      = 1'b0;
        erro        = 1'b0;
        temporizar  = 1'b0;
        duracao_seg = 4'd0;

        case (estado)
            EDITA_D1: begin editando = 1'b1; posicao = 2'd0; end
            EDITA_D2: begin editando = 1'b1; posicao = 2'd1; end
            EDITA_D3: begin editando = 1'b1; posicao = 2'd2; end
            EDITA_D4: begin editando = 1'b1; posicao = 2'd3; end
            ABERTO: begin
                aberto      = 1'b1;
                temporizar  = 1'b1;
                duracao_seg = 4'(TEMPO_ABERTO_S);
            end
            ERRO: begin
                erro        = 1'b1;
                temporizar  = 1'b1;
                duracao_seg = 4'(TEMPO_ERRO_S);
            end
            default: ;  // VERIFICA: tudo no padrao
        endcase
    end

    // Comparacao com a senha: junta os 4 digitos em 16 bits e compara.
    assign senha_ok = ({digitos[0], digitos[1], digitos[2], digitos[3]} == SENHA);

    // Ao terminar o tempo dos LEDs voltamos ao estado inicial com os
    // displays em 0, entao os digitos precisam ser zerados.
    assign limpar = fim_tempo && (estado == ABERTO || estado == ERRO);

    // ---------------------------------------------------------------
    // 4) SEQUENCIAL dos digitos: altera so o digito ativo.
    //    Prioridade quando dois botoes chegam no mesmo ciclo:
    //    confirma > incrementa > decrementa (uma acao por vez).
    // ---------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (rst || limpar) begin
            for (int i = 0; i < 4; i++)
                digitos[i] <= 4'd0;
        end else if (editando && !confirma) begin
            if (inc)
                // wrap-around: depois do 9 volta para 0
                digitos[posicao] <= (digitos[posicao] == 4'd9) ? 4'd0
                                                               : digitos[posicao] + 4'd1;
            else if (dec)
                // wrap-around: antes do 0 vem o 9
                digitos[posicao] <= (digitos[posicao] == 4'd0) ? 4'd9
                                                               : digitos[posicao] - 4'd1;
        end
    end

    // Saidas dos digitos para os displays
    assign dig1 = digitos[0];
    assign dig2 = digitos[1];
    assign dig3 = digitos[2];
    assign dig4 = digitos[3];

endmodule
