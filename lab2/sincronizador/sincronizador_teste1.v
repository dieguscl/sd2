`timescale 1ns / 1ps

// Testbench do sincronizador / anti-ressalto da tecla Start.
// Com ESTAVEL = 4 ciclos (na placa são 1 000 000 = 10 ms): a saída só muda depois de a
// entrada ficar 4 ciclos estável, mais 2 ciclos dos flip-flops de sincronização.
module sincronizador_teste1();

//   Declaração das entradas
     reg Clock = 0;
     reg Entrada = 0;

//   Declaração da saída
     wire Saida;

//   Instanciação da UUT e ligação das entradas e saídas
     Sincronizador #(.ESTAVEL(4)) UUT (
         .Clock(Clock),
         .Entrada(Entrada),
         .Saida(Saida)
     );

//   Relógio de 100 MHz (período de 10ns): flancos ascendentes em 5, 15, 25, ... ns
     always #5 Clock = ~Clock;

//   Confere a saída com o valor esperado
     integer erros = 0, verificacoes = 0;
     task confere(input esperado);
         begin
             verificacoes = verificacoes + 1;
             if (Saida !== esperado) begin
                 $display("ERRO t=%0t: Saida=%b (esperado %b)", $time, Saida, esperado);
                 erros = erros + 1;
             end
         end
     endtask

     initial begin
         #10;                                       // as entradas mudam a meio do ciclo
         // Ruído: impulso de 2 ciclos, mais curto do que ESTAVEL
         Entrada = 1; #20 Entrada = 0;
         #100 confere(0);                           // ignorado

         // Carregar a tecla com ressaltos
         Entrada = 1; #20 Entrada = 0; #10 Entrada = 1; #20 Entrada = 0; #10 Entrada = 1;
         #50 confere(0);                            // 5 ciclos depois do último ressalto: ainda não
         #20 confere(1);                            // 7 ciclos depois: Saida = 1 (uma só subida)
         #100 confere(1);

         // Largar a tecla com ressaltos
         Entrada = 0; #20 Entrada = 1; #10 Entrada = 0;
         #50 confere(1);                            // ainda não
         #20 confere(0);                            // Saida = 0 (uma só descida)
         #100 confere(0);

         if (erros == 0) $display("Simulacao OK (%0d verificacoes)", verificacoes);
         else            $display("Simulacao FALHOU (%0d erros em %0d verificacoes)", erros, verificacoes);
         $finish;
     end

endmodule
