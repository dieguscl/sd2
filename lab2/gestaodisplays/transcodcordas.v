`timescale 1ns / 1ps

// Transcodificador das cordas para os segmentos horizontais do display.
// Versão alterada do Transcod7Seg do 1.º trabalho (secção 2.5 do enunciado):
// cada corda acende um só segmento horizontal e a pausa apaga o display.
// Segmentos[6] = a ... Segmentos[0] = g, ativos a Low (0 = segmento aceso).
module TranscodCordas(
    input [1:0] Corda,
    output reg [6:0] Segmentos
    );

     always @(*)
         case (Corda)                //  abcdefg
             2'b00:   Segmentos = 7'b1111111;   // pausa: tudo apagado
             2'b01:   Segmentos = 7'b0111111;   // corda de cima (a)
             2'b10:   Segmentos = 7'b1111110;   // corda do meio (g)
             2'b11:   Segmentos = 7'b1110111;   // corda de baixo (d)
             default: Segmentos = 7'b1111111;   // nunca usado: os 4 casos estão cobertos
         endcase

endmodule
