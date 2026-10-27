`timescale 1ns / 1ps

// Temporizador (secção 2.3 do enunciado).
// Periodo é o tempo total a temporizar, em ciclos do relógio de 100 MHz (10 ns).
// Com Start a 1, no flanco ascendente do relógio, carrega Periodo e começa a contar;
// Tempo fica a 1 durante Periodo ciclos e volta a 0 sozinho no fim da contagem.
// Reset (síncrono) interrompe a contagem e inicializa o temporizador (Tempo = 0).
module Temporizador #(
    parameter N = 28                // bits do contador: até 2^28 ciclos = 2,68 s
    )(
    input Clock,
    input Reset,
    input Start,
    input [N-1:0] Periodo,
    output Tempo
    );

     reg [N-1:0] contagem = 0;      // ciclos que faltam

     always @(posedge Clock)
         if (Reset)
             contagem <= 0;
         else if (Start)
             contagem <= Periodo;
         else if (contagem != 0)
             contagem <= contagem - 1;

     assign Tempo = (contagem != 0);

endmodule
