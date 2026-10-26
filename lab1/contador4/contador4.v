`timescale 1ns / 1ps

// Contador de módulo 4 (0, 1, 2, 3, 0, ...) que avança no flanco ascendente de Clock.
// Q1 Q0 vão atuar nas seleções dos multiplexers e nas entradas do descodificador.
// Baseado no "Contador simples" dos exemplos Verilog do Moodle,
// reduzido a 2 bits com atribuição não bloqueante (relatório, secção 9.4).
module Contador4(
    input Clock,
    output Q1,
    output Q0
    );

     reg [1:0] estado = 2'b00;

     always @(posedge Clock)
         estado <= estado + 1;     // 3 + 1 = 0 em 2 bits: módulo 4

     assign Q1 = estado[1];
     assign Q0 = estado[0];

endmodule
