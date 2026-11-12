# Pinos da DE2-115 usados no SafeCrack Pro
Fonte: manual da DE2-115 (cap. 4). FPGA: Cyclone IV E EP4CE115F29C7.

| Sinal | Pino | Uso |
|---|---|---|
| CLOCK_50 | PIN_Y2 | clock de 50 MHz |
| KEY[0] | PIN_M23 | reset |
| KEY[1] | PIN_M21 | confirma dígito |
| KEY[2] | PIN_N21 | incrementa |
| KEY[3] | PIN_R24 | decrementa |
| LEDG[0..7] | E21 E22 E25 E24 H21 G20 G22 G21 | verdes (acerto) |
| LEDG[8] | PIN_F17 | verde (acerto) |
| LEDR[0..17] | G19 F19 E19 F21 F18 E18 J19 H19 J17 G17 J15 H16 J16 H17 F15 G15 G16 H15 | vermelhos (erro) |

Botões e segmentos são ATIVOS EM NÍVEL BAIXO (botão apertado = 0; segmento aceso = 0).

## Displays (segmentos [0]..[6] = a,b,c,d,e,f,g)
| Display | Função | Pinos [0]..[6] |
|---|---|---|
| HEX0 | 4º dígito | G18 F22 E17 L26 L25 J22 H22 |
| HEX1 | 3º dígito | M24 Y22 W21 W22 W25 U23 U24 |
| HEX2 | 2º dígito | AA25 AA26 Y25 W26 Y26 W27 W28 |
| HEX3 | 1º dígito | V21 U21 AB20 AA21 AD24 AF23 Y19 |
| HEX4 | índice do dígito ativo | AB19 AA19 AG21 AH21 AE19 AF19 AE18 |
