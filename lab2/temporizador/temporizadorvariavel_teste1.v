`timescale 1ns / 1ps

// Testbench do temporizador variável (registo da velocidade + temporizador).
// Com tempos curtos (INICIAL = 40, PASSO = 6, MINIMO = 20 ciclos) verifica:
//   - depois de RstTemp, cada StartTemp dá Tempo = 1 durante INICIAL ciclos;
//   - cada Faster encurta o período em PASSO ciclos, sem descer abaixo de MINIMO
//     (40, 34, 28, 22 e depois 22 sempre, porque 22 - 6 < 20);
//   - RstTemp repõe o período inicial e interrompe a contagem.
module temporizadorvariavel_teste1();

//   Declaração das entradas
     reg Clock = 0;
     reg RstTemp = 0, StartTemp = 0, Faster = 0;

//   Declaração da saída
     wire Tempo;

     localparam INICIAL = 40, PASSO = 6, MINIMO = 20;

//   Instanciação da UUT e ligação das entradas e saídas
     TemporizadorVariavel #(.N(8), .INICIAL(INICIAL), .PASSO(PASSO), .MINIMO(MINIMO)) UUT (
         .Clock(Clock),
         .RstTemp(RstTemp),
         .StartTemp(StartTemp),
         .Faster(Faster),
         .Tempo(Tempo)
     );

//   Relógio de 100 MHz (período de 10ns), como o da Basys3
     always #5 Clock = ~Clock;

     integer erros = 0, verificacoes = 0;

//   Impulso de StartTemp com 1 ciclo; conta os ciclos com Tempo a 1 e compara
     integer ciclos;
     task temporiza(input integer esperado);
         begin
             StartTemp = 1;
             #10 StartTemp = 0;
             ciclos = 0;
             while (Tempo === 1'b1 && ciclos < 300) begin
                 #10 ciclos = ciclos + 1;
             end
             verificacoes = verificacoes + 1;
             if (ciclos != esperado) begin
                 $display("ERRO t=%0t: Tempo esteve a 1 durante %0d ciclos (esperado %0d)", $time, ciclos, esperado);
                 erros = erros + 1;
             end
         end
     endtask

//   Impulso de Faster com 1 ciclo (como no estado S5 da máquina de estados)
     task acelera;
         begin
             Faster = 1;
             #10 Faster = 0;
         end
     endtask

     initial begin
         // As entradas mudam a meio do período (relógio sobe em 5, 15, 25, ...)
         #10 RstTemp = 1;
         #10 RstTemp = 0;
         temporiza(40);
         temporiza(40);                 // sem Faster o período não muda
         acelera; temporiza(34);
         acelera; temporiza(28);
         acelera; temporiza(22);
         acelera; temporiza(22);        // 22 - 6 = 16 < MINIMO: fica em 22
         acelera; temporiza(22);

         // RstTemp a meio da contagem: para e repõe o período inicial
         StartTemp = 1; #10 StartTemp = 0;
         #50 RstTemp = 1;
         #10 RstTemp = 0;
         verificacoes = verificacoes + 1;
         if (Tempo !== 1'b0) begin
             $display("ERRO t=%0t: RstTemp nao parou a contagem", $time);
             erros = erros + 1;
         end
         temporiza(40);

         if (erros == 0) $display("Simulacao OK (%0d verificacoes)", verificacoes);
         else            $display("Simulacao FALHOU (%0d erros em %0d verificacoes)", erros, verificacoes);
         $finish;
     end

endmodule
