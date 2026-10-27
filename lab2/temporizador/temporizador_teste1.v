`timescale 1ns / 1ps

// Testbench do temporizador.
// Verifica que Tempo fica a 1 exatamente Periodo ciclos depois de Start, que volta a 0
// sozinho, que Reset interrompe a contagem, que Start durante a contagem recomeça e que
// Periodo = 0 não ativa Tempo.
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

//   Relógio de 100 MHz (período de 10ns), como o da Basys3
     always #5 Clock = ~Clock;

     integer erros = 0, verificacoes = 0;
     task verifica(input esperado, input [8*48:1] caso);
         begin
             verificacoes = verificacoes + 1;
             if (Tempo !== esperado) begin
                 $display("ERRO t=%0t (%0s): Tempo=%b (esperado %b)", $time, caso, Tempo, esperado);
                 erros = erros + 1;
             end
         end
     endtask

//   Dá um impulso de Start com 1 ciclo e conta durante quantos ciclos Tempo fica a 1
     integer ciclos;
     task temporiza(input [7:0] p);
         begin
             Periodo = p; Start = 1;
             #10 Start = 0;
             ciclos = 0;
             while (Tempo === 1'b1 && ciclos < 300) begin
                 #10 ciclos = ciclos + 1;
             end
             verificacoes = verificacoes + 1;
             if (ciclos != p) begin
                 $display("ERRO t=%0t: Periodo=%0d mas Tempo esteve a 1 durante %0d ciclos", $time, p, ciclos);
                 erros = erros + 1;
             end
         end
     endtask

     integer n;
     initial begin
         #1   verifica(1'b0, "valor inicial: parado");
         // As entradas mudam a meio do período (relógio sobe em 5, 15, 25, ...)
         #9;
         temporiza(8'd1);
         temporiza(8'd5);
         temporiza(8'd17);
         temporiza(8'd255);
         #50  verifica(1'b0, "fica a 0 depois do fim");

         // Periodo = 0: Tempo nunca sobe
         Periodo = 0; Start = 1; #10 Start = 0;
         verifica(1'b0, "Periodo = 0");

         // Reset a meio da contagem
         Periodo = 50; Start = 1; #10 Start = 0;
         #100 verifica(1'b1, "a contar antes do Reset");
         Reset = 1; #10 verifica(1'b0, "Reset interrompe a contagem");
         Reset = 0; #100 verifica(1'b0, "continua parado depois do Reset");

         // Reset tem prioridade sobre Start
         Reset = 1; Start = 1; #10 verifica(1'b0, "Reset tem prioridade sobre Start");
         Reset = 0; Start = 0;

         // Start durante a contagem recomeça com o novo período
         Periodo = 30; Start = 1; #10 Start = 0;
         #100;                                   // 10 dos 30 ciclos já passaram
         temporiza(8'd12);                       // recomeça: tem de durar 12, não 20

         // Vários valores seguidos
         for (n = 2; n < 40; n = n + 7)
             temporiza(n);

         if (erros == 0) $display("Simulacao OK (%0d verificacoes)", verificacoes);
         else            $display("Simulacao FALHOU (%0d erros em %0d verificacoes)", erros, verificacoes);
         $finish;
     end

endmodule
