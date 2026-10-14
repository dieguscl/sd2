`timescale 1ns / 1ps

// Transcodificador de BCD (e símbolos 10 a 15) para display de 7 segmentos.
// Segmentos[6] = a ... Segmentos[0] = g, ativos a Low (0 = segmento aceso).
// O ponto decimal não é tratado neste módulo.
// Adaptado do módulo Transcod7Seg dos exemplos Verilog do Moodle,
// com os erros corrigidos e símbolos 10 a 15 originais (ver relatório, secção 9.2).
module Transcod7Seg(
    input [3:0] Numero,
    output reg [6:0] Segmentos
    );

     always @(*)
         case (Numero)               //  abcdefg
             4'd0:  Segmentos = 7'b0000001;   // 0
             4'd1:  Segmentos = 7'b1001111;   // 1
             4'd2:  Segmentos = 7'b0010010;   // 2
             4'd3:  Segmentos = 7'b0000110;   // 3
             4'd4:  Segmentos = 7'b1001100;   // 4
             4'd5:  Segmentos = 7'b0100100;   // 5
             4'd6:  Segmentos = 7'b0100000;   // 6
             4'd7:  Segmentos = 7'b0001111;   // 7
             4'd8:  Segmentos = 7'b0000000;   // 8
             4'd9:  Segmentos = 7'b0000100;   // 9
             // Símbolos originais nas combinações não BCD: iniciais do grupo (r, d),
             // LEC (de LEEC) e um traço: "rdLEC-"
             4'd10: Segmentos = 7'b1111010;   // r (e g)
             4'd11: Segmentos = 7'b1000010;   // d (b c d e g)
             4'd12: Segmentos = 7'b1110001;   // L (d e f)
             4'd13: Segmentos = 7'b0110000;   // E (a d e f g)
             4'd14: Segmentos = 7'b0110001;   // C (a d e f)
             4'd15: Segmentos = 7'b1111110;   // - (g)
             default: Segmentos = 7'b1111111; // tudo apagado (nunca usado: os 16 casos estão cobertos)
         endcase

endmodule
