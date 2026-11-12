// =====================================================================
// tb_safecrack.sv
// Testbench do SafeCrack Pro com verificacoes automaticas.
//
// Ideia:
//  * Simula a placa: gera o clock, "aperta" os botoes KEY e observa
//    LEDs e displays, exatamente como uma pessoa faria.
//  * Usa CICLOS_POR_SEG = 10 para que 5 s = 50 ciclos (simulacao rapida).
//  * Cada verificacao imprime PASS ou FAIL no Transcript; no final sai
//    um resumo com o total.
//  * Os padroes esperados dos displays estao numa tabela PROPRIA do
//    testbench (funcao seg_esperado), independente do decodificador,
//    para que um erro no decodificador seja detectado.
// =====================================================================
`timescale 1ns/1ps

module tb_safecrack;

    // ---------------- Parametros da simulacao ----------------
    localparam int CPS        = 10;   // "ciclos por segundo" reduzido
    localparam int T_ABERTO   = 5;    // segundos
    localparam int T_ERRO     = 3;    // segundos
    localparam int CICLOS_ABERTO = T_ABERTO * CPS;
    localparam int CICLOS_ERRO   = T_ERRO   * CPS;

    // ---------------- Sinais da "placa" ----------------
    logic        CLOCK_50;
    logic [3:0]  KEY;
    logic [8:0]  LEDG;
    logic [17:0] LEDR;
    logic [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4;

    // ---------------- Contadores do resultado ----------------
    int n_pass = 0;
    int n_fail = 0;

    // ---------------- DUT (circuito sob teste) ----------------
    safecrack_top #(
        .SENHA          (16'h1234),
        .CICLOS_POR_SEG (CPS),
        .TEMPO_ABERTO_S (T_ABERTO),
        .TEMPO_ERRO_S   (T_ERRO)
    ) dut (.*);

    // ---------------- Clock de 50 MHz (periodo 20 ns) ----------------
    initial CLOCK_50 = 1'b0;
    always #10 CLOCK_50 = ~CLOCK_50;

    // ---------------- Tabela esperada do display ----------------
    // Ordem {g,f,e,d,c,b,a}, ativo em 0. -1 = display apagado.
    function automatic logic [6:0] seg_esperado(int d);
        case (d)
            0: return 7'b1000000;
            1: return 7'b1111001;
            2: return 7'b0100100;
            3: return 7'b0110000;
            4: return 7'b0011001;
            5: return 7'b0010010;
            6: return 7'b0000010;
            7: return 7'b1111000;
            8: return 7'b0000000;
            9: return 7'b0010000;
            default: return 7'b1111111;
        endcase
    endfunction

    // ---------------- Tarefas auxiliares ----------------

    // Espera n bordas de descida (amostramos/estimulamos na descida
    // para nao disputar com a borda de subida, onde os registradores mudam).
    task automatic ciclos(int n);
        repeat (n) @(negedge CLOCK_50);
    endtask

    // Registra o resultado de uma verificacao.
    task automatic checar(string nome, bit ok, string detalhe = "");
        if (ok) begin
            n_pass++;
            $display("[%0t] PASS: %s", $time, nome);
        end else begin
            n_fail++;
            $display("[%0t] FAIL: %s %s", $time, nome, detalhe);
        end
    endtask

    // Aperta o botao b por 'dur' ciclos e solta (botao ativo em 0).
    task automatic apertar(int b, int dur = 5);
        @(negedge CLOCK_50) KEY[b] = 1'b0;
        ciclos(dur);
        KEY[b] = 1'b1;
        ciclos(5);  // tempo para o sinal atravessar o sincronizador
    endtask

    task automatic incrementar(int vezes = 1);
        repeat (vezes) apertar(2);
    endtask

    task automatic decrementar(int vezes = 1);
        repeat (vezes) apertar(3);
    endtask

    task automatic confirmar();
        apertar(1);
    endtask

    task automatic resetar();
        apertar(0);
    endtask

    // Confere os 4 digitos (HEX3..HEX0) e o indicador HEX4.
    // ativo = 1..4, ou 0 para "apagado".
    task automatic checar_displays(string nome, int d1, int d2, int d3, int d4, int ativo);
        bit ok;
        ok = (HEX3 == seg_esperado(d1)) && (HEX2 == seg_esperado(d2)) &&
             (HEX1 == seg_esperado(d3)) && (HEX0 == seg_esperado(d4)) &&
             (HEX4 == seg_esperado(ativo == 0 ? -1 : ativo));
        checar(nome, ok,
               $sformatf("(esperado %0d%0d%0d%0d ativo=%0d; HEX3..0=%b %b %b %b HEX4=%b)",
                         d1, d2, d3, d4, ativo, HEX3, HEX2, HEX1, HEX0, HEX4));
    endtask

    // Estado inicial: tudo em 0, digito ativo 1, LEDs apagados.
    task automatic checar_inicial(string nome);
        checar_displays({nome, " - displays 0000, HEX4=1"}, 0, 0, 0, 0, 1);
        checar({nome, " - LEDs apagados"}, (LEDG == '0) && (LEDR == '0),
               $sformatf("(LEDG=%b LEDR=%b)", LEDG, LEDR));
    endtask

    // Digita um valor no digito ativo (partindo de 0) e confirma.
    task automatic digitar(int valor);
        incrementar(valor);
        confirmar();
    endtask

    // Conta por quantos ciclos o grupo de LEDs (verde ou vermelho)
    // fica totalmente aceso. Deve ser chamada logo apos o ultimo
    // aperto de confirmar ter comecado (ver uso com fork abaixo).
    task automatic medir_leds(bit verde, output int duracao);
        int espera;
        espera  = 0;
        duracao = 0;
        // aguarda acender (com limite para nao travar o teste)
        while (!(verde ? (&LEDG) : (&LEDR)) && espera < 100) begin
            ciclos(1); espera++;
        end
        // conta enquanto estiver aceso
        while ((verde ? (&LEDG) : (&LEDR)) && duracao < 1000) begin
            // enquanto aceso, o outro grupo tem que estar apagado
            if (verde ? (LEDR != '0) : (LEDG != '0))
                checar("LEDs da outra cor apagados durante o resultado", 1'b0);
            ciclos(1); duracao++;
        end
    endtask

    // ---------------- Sequencia de testes ----------------
    initial begin
        int dur;

        $display("==================================================");
        $display(" SafeCrack Pro - testbench (CPS=%0d)", CPS);
        $display("==================================================");

        // Botoes soltos (1) e reset inicial com KEY[0]
        KEY = 4'b1111;
        ciclos(3);
        resetar();

        // --- T1: estado inicial ---
        $display("--- T1: estado inicial ---");
        checar_inicial("T1 inicial");

        // --- T2: wrap-around 0 -> 9 (decrementar no 0) ---
        $display("--- T2: wrap-around 0 -> 9 ---");
        decrementar();
        checar_displays("T2 0 -1 = 9", 9, 0, 0, 0, 1);

        // --- T3: wrap-around 9 -> 0 (incrementar no 9) ---
        $display("--- T3: wrap-around 9 -> 0 ---");
        incrementar();
        checar_displays("T3 9 +1 = 0", 0, 0, 0, 0, 1);
        // contando para cima de 0 ate 9 e passando do 9
        incrementar(9);
        checar_displays("T3 0 +9 = 9", 9, 0, 0, 0, 1);
        incrementar();
        checar_displays("T3 9 +1 = 0 (subindo)", 0, 0, 0, 0, 1);

        // --- T4: botao segurado conta so 1 acao ---
        $display("--- T4: botao segurado ---");
        apertar(2, 60);  // segura KEY[2] por 60 ciclos
        checar_displays("T4 segurar KEY[2] incrementa so 1 vez", 1, 0, 0, 0, 1);
        apertar(3, 60);  // segura KEY[3] por 60 ciclos
        checar_displays("T4 segurar KEY[3] decrementa so 1 vez", 0, 0, 0, 0, 1);
        incrementar();
        apertar(1, 60);  // segura confirmar: deve avancar so 1 digito
        checar_displays("T4 segurar KEY[1] avanca so 1 digito", 1, 0, 0, 0, 2);

        // --- T5: reset no meio da digitacao ---
        $display("--- T5: reset no meio da digitacao ---");
        incrementar(2);
        confirmar();
        incrementar(3);
        checar_displays("T5 antes do reset (1 2 3 _, ativo 3)", 1, 2, 3, 0, 3);
        resetar();
        checar_inicial("T5 apos reset");

        // --- T6: senha correta 1-2-3-4 ---
        $display("--- T6: senha correta ---");
        digitar(1);
        checar_displays("T6 apos 1o digito (ativo 2)", 1, 0, 0, 0, 2);
        digitar(2);
        checar_displays("T6 apos 2o digito (ativo 3)", 1, 2, 0, 0, 3);
        digitar(3);
        checar_displays("T6 apos 3o digito (ativo 4)", 1, 2, 3, 0, 4);
        incrementar(4);
        checar_displays("T6 4o digito ajustado", 1, 2, 3, 4, 4);
        // confirma o ultimo digito e mede, em paralelo, o tempo dos LEDG
        fork
            confirmar();
            medir_leds(1'b1, dur);
        join
        checar("T6 LEDG acesos por 5 s", dur == CICLOS_ABERTO,
               $sformatf("(medido %0d ciclos, esperado %0d)", dur, CICLOS_ABERTO));
        checar("T6 LEDR apagados", LEDR == '0);
        ciclos(2);
        checar_inicial("T6 volta ao inicial apos 5 s");

        // --- T7: senha incorreta 1-2-3-5 ---
        $display("--- T7: senha incorreta ---");
        digitar(1);
        digitar(2);
        digitar(3);
        incrementar(5);
        fork
            confirmar();
            medir_leds(1'b0, dur);
        join
        checar("T7 LEDR acesos por 3 s", dur == CICLOS_ERRO,
               $sformatf("(medido %0d ciclos, esperado %0d)", dur, CICLOS_ERRO));
        checar("T7 LEDG apagados", LEDG == '0);
        ciclos(2);
        checar_inicial("T7 volta ao inicial apos 3 s");

        // --- T8: senha incorreta so no 1o digito (0-2-3-4) ---
        $display("--- T8: senha incorreta no 1o digito ---");
        confirmar();     // 1o digito = 0
        digitar(2);
        digitar(3);
        incrementar(4);
        fork
            confirmar();
            medir_leds(1'b0, dur);
        join
        checar("T8 0234 da erro (LEDR por 3 s)", dur == CICLOS_ERRO,
               $sformatf("(medido %0d ciclos)", dur));
        ciclos(2);
        checar_inicial("T8 volta ao inicial");

        // --- T9: botoes ignorados com o cofre aberto + reset no aberto ---
        $display("--- T9: botoes durante o resultado / reset ---");
        digitar(1); digitar(2); digitar(3); incrementar(4); confirmar();
        checar("T9 cofre aberto", &LEDG);
        incrementar();   // nao deve mudar nada
        checar_displays("T9 KEY[2] ignorado com cofre aberto (HEX4 apagado)", 1, 2, 3, 4, 0);
        resetar();
        checar_inicial("T9 reset com cofre aberto volta ao inicial");

        // ---------------- Resumo ----------------
        $display("==================================================");
        $display(" RESUMO: %0d PASS, %0d FAIL", n_pass, n_fail);
        if (n_fail == 0) $display(" RESULTADO: TODOS OS TESTES PASSARAM");
        else             $display(" RESULTADO: HA TESTES FALHANDO");
        $display("==================================================");
        $finish;
    end

    // Seguranca: se algo travar, encerra a simulacao.
    initial begin
        #2ms;
        $display("FAIL: timeout da simulacao");
        $finish;
    end

endmodule
