`timescale 1ns / 1ps

// Máquina de estados assíncrona (modelo de Huffman, modo fundamental) que elimina o ressalto
// de uma tecla com a ajuda de um temporizador monoestável redisparável.
//   Entradas: K  - tecla (assíncrona, com ressaltos)
//             To - saída do temporizador (1 enquanto conta)
//             Clear - reset da máquina, atua diretamente nas realimentações (Fig. 3 do enunciado)
//   Saídas:   Kd - tecla sem ressaltos
//             F  - comuta o flanco que dispara o temporizador (Ti = K xor F, fora da máquina)
// Seis estados em três variáveis de estado, sem flip-flops nem outros elementos de memória:
//   S0 = 000 repouso                         S3 = 111 tecla premida estável
//   S1 = 001 tecla premida, espera por To    S4 = 110 tecla largada, espera por To
//   S2 = 011 temporização ao premir          S5 = 100 temporização ao largar
// Y2, Y1 e Y0 são as variáveis secundárias de excitação e YY2, YY1 e YY0 as variáveis de estado
// (realimentações). Cada equação de excitação é uma soma de produtos sem acidentes estáticos:
// em Y2 e Y1 o 3.º termo é o termo de consenso dos outros dois; em Y0 (função maioria de K,
// /YY2 e YY0) os três termos são essenciais. As saídas são as próprias variáveis de
// estado (Kd = YY0, F = YY2), pelo que não têm picos.
module MaquinaTecla(
    input K,
    input To,
    input Clear,                    // ativo a High: com Clear = 1 a máquina vai para S0 (000)
    output Kd,
    output F,
    output [2:0] Estado             // {YY2, YY1, YY0}, para depuração
    );

//   DONT_TOUCH: o Vivado mantém as seis ligações e não funde nem elimina as realimentações
     (* DONT_TOUCH = "TRUE" *) wire Y2, Y1, Y0;         // variáveis secundárias de excitação
     (* DONT_TOUCH = "TRUE" *) wire YY2, YY1, YY0;      // variáveis de estado

//   Equações de excitação (o #1 é o atraso do circuito de excitação e só conta na simulação)
     assign #1 Y2 = (To & YY2) | (~To & YY1) | (YY2 & YY1);
     assign #1 Y1 = (To & YY0) | (~To & YY1) | (YY1 & YY0);
     assign #1 Y0 = (K & ~YY2) | (K & YY0) | (~YY2 & YY0);

//   Realimentações com o clear da Fig. 3 do enunciado (porta AND2B1: YYi = Yi . /Clear)
     assign YY2 = Y2 & ~Clear;
     assign YY1 = Y1 & ~Clear;
     assign YY0 = Y0 & ~Clear;

//   Equações de saída
     assign Kd = YY0;
     assign F  = YY2;
     assign Estado = {YY2, YY1, YY0};

endmodule
