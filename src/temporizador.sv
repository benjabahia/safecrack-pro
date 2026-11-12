// =====================================================================
// temporizador.sv
// Conta um tempo em segundos e avisa (pulso "fim") quando ele acaba.
//
// Por que existe:
//  * A FSM precisa manter os LEDs acesos por 5 s (senha certa) ou
//    3 s (senha errada). A FPGA so conhece ciclos de clock, entao
//    contamos ciclos: com 50 MHz, 1 segundo = 50.000.000 ciclos.
//  * CICLOS_POR_SEG e PARAMETRO: na placa vale 50_000_000; no testbench
//    usamos um valor pequeno (ex.: 10) para a simulacao ser rapida.
//  * Funciona em dois niveis, como um relogio:
//      - cont_ciclos conta de 0 ate CICLOS_POR_SEG-1  -> gera tick_1s
//      - cont_seg conta quantos segundos (ticks) ja passaram
//  * Enquanto "habilita" = 0 os contadores ficam zerados. Assim a FSM
//    so precisa manter habilita = 1 durante o estado ABERTO ou ERRO,
//    e a contagem sempre recomeca do zero na proxima vez.
// =====================================================================
module temporizador #(
    parameter int CICLOS_POR_SEG = 50_000_000
) (
    input  logic       clk,
    input  logic       rst,          // reset sincrono (1 = reseta)
    input  logic       habilita,     // 1 = contando
    input  logic [3:0] duracao_seg,  // quantos segundos contar (1 a 15)
    output logic       fim           // 1 durante 1 ciclo quando o tempo acaba
);

    logic [31:0] cont_ciclos;  // ciclos dentro do segundo atual
    logic [3:0]  cont_seg;     // segundos completos ja contados
    logic        tick_1s;      // 1 no ultimo ciclo de cada segundo

    // Combinacional: chegamos ao ultimo ciclo do segundo atual?
    assign tick_1s = (cont_ciclos == CICLOS_POR_SEG - 1);

    // Sequencial: atualiza os contadores a cada borda do clock.
    always_ff @(posedge clk) begin
        if (rst || !habilita) begin
            // parado: deixa tudo pronto para comecar do zero
            cont_ciclos <= '0;
            cont_seg    <= '0;
        end else if (tick_1s) begin
            // completou 1 segundo: zera os ciclos e soma 1 segundo
            cont_ciclos <= '0;
            cont_seg    <= cont_seg + 4'd1;
        end else begin
            cont_ciclos <= cont_ciclos + 32'd1;
        end
    end

    // O tempo acaba no ultimo ciclo do ultimo segundo pedido.
    // Ex.: duracao 5 -> fim quando cont_seg = 4 e tick_1s = 1,
    // ou seja, depois de exatamente 5 * CICLOS_POR_SEG ciclos.
    assign fim = habilita && tick_1s && (cont_seg == duracao_seg - 4'd1);

endmodule
