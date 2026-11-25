`timescale 1ns / 1ps

// Testbench da gestão dos displays (com o transcodificador das cordas).
// Com o varrimento acelerado (METADE = 2) o display ativo muda a cada 40 ns. Põe uma corda
// diferente em cada posição da memória e confere, display a display, o ânodo ativo e os
// segmentos acesos (Pos0 no display da esquerda, Pos3 no da direita).
module gestaodisplays_teste1();

//   Declaração das entradas
     reg [1:0] Pos0 = 0, Pos1 = 0, Pos2 = 0, Pos3 = 0;
     reg Clock = 0;

//   Declaração das saídas
     wire [6:0] Segmentos;
     wire DotPoint;
     wire [3:0] Anodos;

//   Instanciação da UUT (varrimento a 100 MHz / 4 para a simulação ser curta)
     GestaoDisplays #(.METADE(2)) UUT (
         .Pos0(Pos0),
         .Pos1(Pos1),
         .Pos2(Pos2),
         .Pos3(Pos3),
         .Clock(Clock),
         .Segmentos(Segmentos),
         .DotPoint(DotPoint),
         .Anodos(Anodos)
     );

//   Relógio de 100 MHz (período de 10ns): flancos ascendentes em 5, 15, 25, ... ns
     always #5 Clock = ~Clock;

//   Segmentos (abcdefg, ativos a Low) de cada corda
     localparam PAUSA = 7'b1111111, CIMA = 7'b0111111, MEIO = 7'b1111110, BAIXO = 7'b1110111;

//   Confere o display ativo, os segmentos e o ponto decimal (sempre apagado)
     integer erros = 0, verificacoes = 0;
     task confere(input [3:0] anodos, input [6:0] segmentos);
         begin
             verificacoes = verificacoes + 1;
             if (Anodos !== anodos || Segmentos !== segmentos || DotPoint !== 1'b1) begin
                 $display("ERRO t=%0t: Anodos=%b Segmentos=%b DP=%b (esperado %b %b 1)",
                          $time, Anodos, Segmentos, DotPoint, anodos, segmentos);
                 erros = erros + 1;
             end
         end
     endtask

     initial begin
         // Pos0 a Pos3: cima, pausa, baixo, meio
         Pos0 = 2'b01; Pos1 = 2'b00; Pos2 = 2'b11; Pos3 = 2'b10;
         #100;                                     // deixa o varrimento correr (começa sozinho)
         @(negedge Anodos[0]) #20;                 // a meio do tempo do display da direita
             confere(4'b1110, MEIO);               // AN0 (direita): Pos3
         #40 confere(4'b1101, BAIXO);              // AN1: Pos2
         #40 confere(4'b1011, PAUSA);              // AN2: Pos1 (display apagado)
         #40 confere(4'b0111, CIMA);               // AN3 (esquerda): Pos0
         #40 confere(4'b1110, MEIO);               // volta ao da direita

         // As cordas avançam uma posição (entra a corda de baixo à esquerda)
         Pos0 = 2'b11; Pos1 = 2'b01; Pos2 = 2'b00; Pos3 = 2'b11;
         #40 confere(4'b1101, PAUSA);              // AN1: Pos2
         #40 confere(4'b1011, CIMA);               // AN2: Pos1
         #40 confere(4'b0111, BAIXO);              // AN3: Pos0
         #40 confere(4'b1110, BAIXO);              // AN0: Pos3

         if (erros == 0) $display("Simulacao OK (%0d verificacoes)", verificacoes);
         else            $display("Simulacao FALHOU (%0d erros em %0d verificacoes)", erros, verificacoes);
         $finish;
     end

endmodule
