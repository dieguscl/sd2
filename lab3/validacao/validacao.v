`timescale 1ns / 1ps

// Validação das teclas do jogo (função combinatória, secção 2 do enunciado).
//   U = 1 quando exatamente uma das teclas está premida;
//   M = 1 quando há mais do que uma tecla premida;
//   sem teclas premidas, U = M = 0.
// As entradas são as teclas já sem ressaltos (saídas Kd das três máquinas de estados).
module Validacao(
    input K1,
    input K2,
    input K3,
    output U,
    output M
    );

     assign U = (K1 & ~K2 & ~K3) | (~K1 & K2 & ~K3) | (~K1 & ~K2 & K3);
     assign M = (K1 & K2) | (K1 & K3) | (K2 & K3);

endmodule
