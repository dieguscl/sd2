`timescale 1ns / 1ps

// Testbench do sincronizador / anti-ressalto (ESTAVEL = 20 ciclos para a simulação).
// Simula carregar e largar a tecla com ressaltos em instantes que não coincidem com o
// relógio e verifica que a saída muda uma só vez em cada caso, ESTAVEL + 2 ciclos depois
// do último ressalto, e que impulsos curtos (ruído) são ignorados.
module sincronizador_teste1();

//   Declaração das entradas
     reg Clock = 0;
     reg Entrada = 0;

//   Declaração da saída
     wire Saida;

     localparam ESTAVEL = 20;

//   Instanciação da UUT e ligação das entradas e saídas
     Sincronizador #(.ESTAVEL(ESTAVEL)) UUT (
         .Clock(Clock),
         .Entrada(Entrada),
         .Saida(Saida)
     );

//   Relógio de 100 MHz (período de 10ns), como o da Basys3
     always #5 Clock = ~Clock;

//   Conta as mudanças da saída e guarda o instante da última
//   (em t = 0 a passagem de x para o valor inicial não conta)
     integer subidas = 0, descidas = 0;
     time t_mudanca = 0;
     always @(posedge Saida) if ($time > 0) begin subidas = subidas + 1; t_mudanca = $time; end
     always @(negedge Saida) if ($time > 0) begin descidas = descidas + 1; t_mudanca = $time; end

     integer erros = 0, verificacoes = 0;
     task verifica(input integer s, input integer d, input [8*48:1] caso);
         begin
             verificacoes = verificacoes + 1;
             if (subidas != s || descidas != d) begin
                 $display("ERRO t=%0t (%0s): %0d subidas e %0d descidas (esperado %0d e %0d)",
                          $time, caso, subidas, descidas, s, d);
                 erros = erros + 1;
             end
         end
     endtask

//   Tecla com ressaltos: muda de valor várias vezes (intervalos < ESTAVEL ciclos) e fica em v
     integer k;
     time t_fim;
     task ressalta(input v);
         begin
             for (k = 0; k < 6; k = k + 1) begin
                 Entrada = v;  #(13 + 17 * k);
                 Entrada = ~v; #(7 + 11 * k);
             end
             Entrada = v;
             t_fim = $time;
         end
     endtask

     initial begin
         #33;
         // Ruído curto (5 ciclos): ignorado
         Entrada = 1; #53 Entrada = 0;
         #400 verifica(0, 0, "impulso curto ignorado");

         // Carregar a tecla com ressaltos
         ressalta(1'b1);
         #400 verifica(1, 0, "carregar: uma so subida");
         verificacoes = verificacoes + 1;
         if (t_mudanca - t_fim < ESTAVEL * 10 || t_mudanca - t_fim > (ESTAVEL + 3) * 10) begin
             $display("ERRO: a saida subiu %0d ns depois do ultimo ressalto (esperado ~%0d ns)",
                      t_mudanca - t_fim, (ESTAVEL + 2) * 10);
             erros = erros + 1;
         end

         // Largar a tecla com ressaltos
         ressalta(1'b0);
         #400 verifica(1, 1, "largar: uma so descida");

         // Impulso a 0 curto com a tecla carregada: ignorado
         Entrada = 1; #400;
         verifica(2, 1, "tecla carregada outra vez");
         Entrada = 0; #77 Entrada = 1;
         #400 verifica(2, 1, "falha curta com a tecla carregada ignorada");
         Entrada = 0; #400 verifica(2, 2, "tecla largada");

         if (erros == 0) $display("Simulacao OK (%0d verificacoes)", verificacoes);
         else            $display("Simulacao FALHOU (%0d erros em %0d verificacoes)", erros, verificacoes);
         $finish;
     end

endmodule
