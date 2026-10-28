`timescale 1ns / 1ps

// Testbench do sincronizador do Reset.
// A saída sobe logo que a tecla é carregada (sem esperar pelo relógio) e só desce no
// 2.º flanco ascendente depois de a tecla ser largada.
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
         // Depois de configurar a FPGA (INIT = 1) o Reset está ativo
         #50  confere(1);
         #60  confere(1);           // t = 110: fim das configurações (100 ns), 1.º flanco em 105
         #10  confere(0);           // t = 120: 2.º flanco em 115, Reset libertado

         // Carregar a tecla entre dois flancos: sobe logo
         #12  Entrada = 1;          // t = 132
         #1   confere(1);           // t = 133, antes do flanco de 135
         #20  Entrada = 0;          // t = 153: largar
         #5   confere(1);           // t = 158: 1.º flanco (155), ainda ativo
         #10  confere(0);           // t = 168: 2.º flanco (165), libertado

         // Impulso de 2 ns entre dois flancos: também ativa o Reset
         #14  Entrada = 1;          // t = 182
         #1   confere(1);
         #1   Entrada = 0;          // t = 184
         #4   confere(1);           // t = 188: 1.º flanco (185)
         #10  confere(0);           // t = 198: 2.º flanco (195)

         if (erros == 0) $display("Simulacao OK (%0d verificacoes)", verificacoes);
         else            $display("Simulacao FALHOU (%0d erros em %0d verificacoes)", erros, verificacoes);
         $finish;
     end

endmodule
