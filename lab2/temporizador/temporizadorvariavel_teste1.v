`timescale 1ns / 1ps

// Testbench do temporizador variável (registo da velocidade + temporizador).
// Com tempos curtos (INICIAL = 5, PASSO = 1, MINIMO = 3 ciclos) confere o período guardado
// no registo da velocidade e a saída Tempo:
//   - RstTemp põe o período em 5 ciclos;
//   - cada Faster encurta-o 1 ciclo, até ao mínimo de 3;
//   - StartTemp põe Tempo a 1 durante o período atual.
module temporizadorvariavel_teste1();

//   Declaração das entradas
     reg Clock = 0;
     reg RstTemp = 0, StartTemp = 0, Faster = 0;

//   Declaração da saída
     wire Tempo;

//   Instanciação da UUT e ligação das entradas e saídas
     TemporizadorVariavel #(.N(8), .INICIAL(5), .PASSO(1), .MINIMO(3)) UUT (
         .Clock(Clock),
         .RstTemp(RstTemp),
         .StartTemp(StartTemp),
         .Faster(Faster),
         .Tempo(Tempo)
     );

//   Relógio de 100 MHz (período de 10ns): flancos ascendentes em 5, 15, 25, ... ns
     always #5 Clock = ~Clock;

//   Confere o período (registo da velocidade) e a saída Tempo
     integer erros = 0, verificacoes = 0;
     task confere(input [7:0] periodo, input tempo);
         begin
             verificacoes = verificacoes + 1;
             if (UUT.Periodo !== periodo || Tempo !== tempo) begin
                 $display("ERRO t=%0t: Periodo=%0d Tempo=%b (esperado %0d %b)",
                          $time, UUT.Periodo, Tempo, periodo, tempo);
                 erros = erros + 1;
             end
         end
     endtask

     initial begin
         #10;                                                 // as entradas mudam a meio do ciclo
         RstTemp = 1;                  #10 confere(5, 0);     // período inicial: 5 ciclos
         RstTemp = 0; StartTemp = 1;   #10 confere(5, 1);     // Tempo a 1 durante 5 ciclos
                      StartTemp = 0;   #40 confere(5, 1);     // 5.º ciclo
                                       #10 confere(5, 0);     // acabou
         Faster = 1;                   #10 confere(4, 0);     // Faster: 5 - 1 = 4
         Faster = 0;                   #10 confere(4, 0);     // só muda com Faster
         Faster = 1;                   #10 confere(3, 0);     // 4 - 1 = 3 (o mínimo)
                                       #10 confere(3, 0);     // não desce abaixo de 3
         Faster = 0; StartTemp = 1;    #10 confere(3, 1);     // Tempo a 1 durante 3 ciclos
                     StartTemp = 0;    #20 confere(3, 1);     // 3.º ciclo
                                       #10 confere(3, 0);     // acabou
         StartTemp = 1;                #10 confere(3, 1);     // nova contagem
         StartTemp = 0; RstTemp = 1;   #10 confere(5, 0);     // RstTemp: para e repõe os 5 ciclos
         RstTemp = 0;                  #10 confere(5, 0);

         if (erros == 0) $display("Simulacao OK (%0d verificacoes)", verificacoes);
         else            $display("Simulacao FALHOU (%0d erros em %0d verificacoes)", erros, verificacoes);
         $finish;
     end

endmodule
