`timescale 1ns / 1ps

// Testbench do sincronizador do Reset.
// Verifica que a saída sobe de imediato (assíncrona) ao carregar a tecla, em qualquer
// instante do ciclo, e que só desce num flanco ascendente do relógio, 2 flancos depois de
// a tecla ser largada (também depois das configurações iniciais da FPGA).
module sincronizadorreset_teste1();

//   Declaração das entradas
     reg Clock = 0;
     reg Entrada = 0;

//   Declaração da saída
     wire Saida;

//   Instanciação da UUT e ligação das entradas e saídas
     SincronizadorReset UUT (
         .Clock(Clock),
         .Entrada(Entrada),
         .Saida(Saida)
     );

//   Relógio de 100 MHz (período de 10ns), como o da Basys3
     always #5 Clock = ~Clock;

     integer erros = 0, verificacoes = 0;
     task verifica(input esperado, input [8*48:1] caso);
         begin
             verificacoes = verificacoes + 1;
             if (Saida !== esperado) begin
                 $display("ERRO t=%0t (%0s): Saida=%b (esperado %b)", $time, caso, Saida, esperado);
                 erros = erros + 1;
             end
         end
     endtask

//   A saída só pode descer num flanco ascendente do relógio
     always @(negedge Saida)
         if ($time > 0 && ($time % 10) != 5) begin
             $display("ERRO t=%0t: Saida desceu fora do flanco do relogio", $time);
             erros = erros + 1;
         end

//   Conta os flancos do relógio desde que a tecla foi largada até a saída descer
     integer flancos;
     task larga_e_conta;
         begin
             Entrada = 0;
             flancos = 0;
             while (Saida === 1'b1 && flancos < 10) @(posedge Clock) begin
                 #1 flancos = flancos + 1;
             end
             verificacoes = verificacoes + 1;
             if (flancos != 2) begin
                 $display("ERRO t=%0t: a saida desceu ao fim de %0d flancos (esperado 2)", $time, flancos);
                 erros = erros + 1;
             end
         end
     endtask

     integer k;
     initial begin
         #1   verifica(1'b1, "ativo depois de configurar a FPGA");
         #99;                                             // fim das configurações iniciais (GSR)
         flancos = 0;
         while (Saida === 1'b1 && flancos < 10) @(posedge Clock) begin
             #1 flancos = flancos + 1;
         end
         verificacoes = verificacoes + 1;
         if (flancos != 2) begin
             $display("ERRO: depois do GSR a saida desceu ao fim de %0d flancos (esperado 2)", flancos);
             erros = erros + 1;
         end

         // Carregar e largar a tecla em vários instantes do ciclo (incluindo junto ao flanco)
         for (k = 0; k < 10; k = k + 1) begin
             #(23 + k);
             Entrada = 1;
             #0.1 verifica(1'b1, "sobe de imediato, sem flanco");
             #(31 + 3 * k);
             verifica(1'b1, "ativo enquanto a tecla esta carregada");
             larga_e_conta;
         end

         // Impulso muito curto entre dois flancos: também é aceite
         @(negedge Clock) Entrada = 1;
         #1 Entrada = 0;
         verifica(1'b1, "impulso curto ativa o Reset");
         larga_e_conta;

         if (erros == 0) $display("Simulacao OK (%0d verificacoes)", verificacoes);
         else            $display("Simulacao FALHOU (%0d erros em %0d verificacoes)", erros, verificacoes);
         $finish;
     end

endmodule
