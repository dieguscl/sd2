`timescale 1ns / 1ps

// Contador de impulsos (circuito auxiliar de ensaio na placa, fora do sistema pedido).
// Conta os flancos ascendentes de uma entrada assíncrona (8 bits, volta a 0 depois de 255):
// dois flip-flops sincronizam a entrada e o flanco é detetado comparando com o valor anterior.
// Clr (síncrono) põe a contagem a 0.
module ContaImpulsos(
    input Clock,
    input Clr,
    input Entrada,
    output reg [7:0] Contagem = 8'd0
    );

     (* ASYNC_REG = "TRUE" *) reg meta = 1'b0, sinc = 1'b0;
     reg anterior = 1'b0;

     always @(posedge Clock) begin
         meta <= Entrada;
         sinc <= meta;
         anterior <= sinc;
         if (Clr)
             Contagem <= 8'd0;
         else if (sinc & ~anterior)
             Contagem <= Contagem + 1;
     end

endmodule
