`timescale 1ns / 1ps

// Testbench do temporizador.
// Com Start a 1 o temporizador carrega Periodo; Tempo fica a 1 durante Periodo ciclos.
// Cada linha muda as entradas, espera e confere Tempo.
module temporizador_teste1();

//   Declaração das entradas
     reg Clock = 0;
     reg Reset = 0, Start = 0;
     reg [7:0] Periodo = 8'd0;

//   Declaração da saída
     wire Tempo;

//   Instanciação da UUT (contador de 8 bits para a simulação)
     Temporizador #(.N(8)) UUT (
         .Clock(Clock),
         .Reset(Reset),
         .Start(Start),
         .Periodo(Periodo),
         .Tempo(Tempo)
     );

//   Relógio de 100 MHz (período de 10ns): flancos ascendentes em 5, 15, 25, ... ns
     always #5 Clock = ~Clock;

//   Confere Tempo com o valor esperado
     integer erros = 0, verificacoes = 0;
     task confere(input esperado);
         begin
             verificacoes = verificacoes + 1;
             if (Tempo !== esperado) begin
                 $display("ERRO t=%0t: Tempo=%b (esperado %b)", $time, Tempo, esperado);
                 erros = erros + 1;
             end
         end
     endtask

     initial begin
         #10;                                            // as entradas mudam a meio do ciclo
                                         confere(0);     // valor inicial: parado
         // Periodo = 3: Tempo a 1 durante 3 ciclos
         Periodo = 3; Start = 1;     #10 confere(1);     // 1.º ciclo
                      Start = 0;     #10 confere(1);     // 2.º ciclo
                                     #10 confere(1);     // 3.º ciclo
                                     #10 confere(0);     // acabou sozinho
                                     #30 confere(0);
         // Periodo = 0: Tempo não chega a subir
         Periodo = 0; Start = 1;     #10 confere(0);
                      Start = 0;     #10 confere(0);
         // Reset a meio da contagem: para
         Periodo = 5; Start = 1;     #10 confere(1);
                      Start = 0;     #10 confere(1);
         Reset = 1;                  #10 confere(0);     // Reset interrompe a contagem
         Reset = 0;                  #30 confere(0);     // e não volta a contar
         // Reset tem prioridade sobre Start
         Reset = 1; Start = 1;       #10 confere(0);
         // Start a meio da contagem: recomeça com o novo período
         Reset = 0; Periodo = 3;     #10 confere(1);     // Start continua a 1: carrega 3 ciclos
                      Start = 0;     #10 confere(1);
         Periodo = 4; Start = 1;     #10 confere(1);     // Start outra vez: recomeça com 4 ciclos
                      Start = 0;     #20 confere(1);     // t = 220: sem recomeçar já teria acabado
                                     #10 confere(1);     // t = 230: se recomeçasse com 3 ciclos já teria acabado
                                     #10 confere(0);     // t = 240: acaba 4 ciclos depois do 2.º Start

         if (erros == 0) $display("Simulacao OK (%0d verificacoes)", verificacoes);
         else            $display("Simulacao FALHOU (%0d erros em %0d verificacoes)", erros, verificacoes);
         $finish;
     end

endmodule
