`timescale 1ns / 1ps

// Registo da velocidade do jogo: guarda o período do temporizador (em ciclos de 10 ns).
// Reset (síncrono) repõe o período inicial.
// Com Faster a 1 o período diminui PASSO ciclos no flanco ascendente do relógio,
// sem descer abaixo de MINIMO (parte opcional do enunciado: acelerar ligeiramente).
module Velocidade #(
    parameter N       = 28,
    parameter INICIAL = 50000000,   // 0,5 s por passo da sequência
    parameter PASSO   = 500000,     // acelera 5 ms em cada passo
    parameter MINIMO  = 20000000    // velocidade máxima: 0,2 s por passo
    )(
    input Clock,
    input Reset,
    input Faster,
    output reg [N-1:0] Periodo = INICIAL
    );

     always @(posedge Clock)
         if (Reset)
             Periodo <= INICIAL;
         else if (Faster && Periodo >= MINIMO + PASSO)
             Periodo <= Periodo - PASSO;

endmodule
