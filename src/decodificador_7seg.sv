// =====================================================================
// decodificador_7seg.sv
// Converte um valor de 4 bits (0 a 9) no padrao de um display de
// 7 segmentos da DE2-115.
//
// Por que existe:
//  * O display nao entende numeros: cada um dos 7 segmentos (a..g) e um
//    LED que precisa ser ligado ou desligado individualmente.
//  * Na DE2-115 os segmentos sao ATIVOS EM NIVEL BAIXO: 0 = aceso.
//  * Ordem dos bits (igual ao docs/PINOS_DE2-115.md):
//        seg[0]=a  seg[1]=b  seg[2]=c  seg[3]=d  seg[4]=e  seg[5]=f  seg[6]=g
//
//         --a--
//        |     |
//        f     b
//        |     |
//         --g--
//        |     |
//        e     c
//        |     |
//         --d--
//
//  * Valores 10 a 15 nao sao digitos: o display fica APAGADO
//    (usado, por exemplo, para apagar o HEX4 quando nao ha digito ativo).
//
// Baseado no modulo bcd_to_7segment_anodo do professor, mas com a ordem
// dos bits invertida (la seg[6]=a; aqui seg[0]=a, para casar com os
// pinos da placa).
// =====================================================================
module decodificador_7seg (
    input  logic [3:0] valor,   // numero a mostrar (0 a 9)
    output logic [6:0] seg      // segmentos {g,f,e,d,c,b,a}, ativo em 0
);

    // Bloco combinacional: a saida depende so da entrada atual
    // (uma "tabela verdade" escrita como case).
    always_comb begin
        case (valor)
            //                  gfedcba
            4'd0:    seg = 7'b1000000;
            4'd1:    seg = 7'b1111001;
            4'd2:    seg = 7'b0100100;
            4'd3:    seg = 7'b0110000;
            4'd4:    seg = 7'b0011001;
            4'd5:    seg = 7'b0010010;
            4'd6:    seg = 7'b0000010;
            4'd7:    seg = 7'b1111000;
            4'd8:    seg = 7'b0000000;
            4'd9:    seg = 7'b0010000;
            default: seg = 7'b1111111;  // apagado
        endcase
    end

endmodule
