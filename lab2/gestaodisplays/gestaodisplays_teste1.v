`timescale 1ns / 1ps

// Testbench da gestão dos displays (com o transcodificador das cordas).
// Com o varrimento acelerado (METADE = 2), para cada uma das 256 combinações das 4 posições
// da memória verifica em cada passo do varrimento que só um display está ativo, que os
// segmentos são os da corda que esse display deve mostrar (Pos0 à esquerda, Pos3 à direita)
// e que o ponto decimal está apagado. Verifica também que os 4 displays são todos varridos.
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

//   Relógio de 100 MHz (período de 10ns), como o da Basys3
     always #5 Clock = ~Clock;

//   Segmentos esperados para cada corda (abcdefg, ativos a Low)
     function [6:0] segmentos_de(input [1:0] corda);
         case (corda)
             2'b00: segmentos_de = 7'b1111111;   // pausa
             2'b01: segmentos_de = 7'b0111111;   // cima (a)
             2'b10: segmentos_de = 7'b1111110;   // meio (g)
             2'b11: segmentos_de = 7'b1110111;   // baixo (d)
         endcase
     endfunction

     integer erros = 0, verificacoes = 0;
     reg [3:0] varridos;            // displays que já estiveram ativos
     reg [1:0] corda;

     task verifica_passo;
         begin
             verificacoes = verificacoes + 1;
             case (Anodos)
                 4'b0111: corda = Pos0;     // display da esquerda
                 4'b1011: corda = Pos1;
                 4'b1101: corda = Pos2;
                 4'b1110: corda = Pos3;     // display da direita
                 default: begin
                     $display("ERRO t=%0t: Anodos=%b (deve haver um so display ativo)", $time, Anodos);
                     erros = erros + 1;
                 end
             endcase
             varridos = varridos | ~Anodos;
             if (Segmentos !== segmentos_de(corda) || DotPoint !== 1'b1) begin
                 if (erros < 10) $display("ERRO t=%0t: Anodos=%b Pos=%b %b %b %b Segmentos=%b (esperado %b) DP=%b",
                                          $time, Anodos, Pos0, Pos1, Pos2, Pos3, Segmentos, segmentos_de(corda), DotPoint);
                 erros = erros + 1;
             end
         end
     endtask

     integer n, p;
     initial begin
         #100;                                            // configurações iniciais da FPGA
         for (n = 0; n < 256; n = n + 1) begin
             {Pos0, Pos1, Pos2, Pos3} = n;
             varridos = 4'b0000;
             // o display ativo muda a cada 40 ns (METADE = 2): verifica 8 passos fora dos flancos do relógio
             #22;
             for (p = 0; p < 8; p = p + 1) begin
                 verifica_passo;
                 #40;
             end
             #18;
             verificacoes = verificacoes + 1;
             if (varridos !== 4'b1111) begin
                 $display("ERRO t=%0t: nem todos os displays foram varridos (%b)", $time, varridos);
                 erros = erros + 1;
             end
         end

         if (erros == 0) $display("Simulacao OK (%0d verificacoes)", verificacoes);
         else            $display("Simulacao FALHOU (%0d erros em %0d verificacoes)", erros, verificacoes);
         $finish;
     end

endmodule
