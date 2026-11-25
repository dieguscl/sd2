`timescale 1ns / 1ps

// Testbench do flip-flop T do LED Beat.
// Cada linha do bloco initial muda uma entrada, espera e confere a saída Q.
module beat_teste1();

//   Declaração das entradas
     reg Clk = 0;
     reg Tgl = 0, CLR = 0;

//   Declaração da saída
     wire Q;

//   Instanciação da UUT e ligação das entradas e saídas
     Beat UUT (
         .Clk(Clk),
         .Tgl(Tgl),
         .CLR(CLR),
         .Q(Q)
     );

//   Relógio de 100 MHz (período de 10ns): flancos ascendentes em 5, 15, 25, ... ns
     always #5 Clk = ~Clk;

//   Confere Q com o valor esperado
     integer erros = 0, verificacoes = 0;
     task confere(input esperado);
         begin
             verificacoes = verificacoes + 1;
             if (Q !== esperado) begin
                 $display("ERRO t=%0t: Q=%b (esperado %b)", $time, Q, esperado);
                 erros = erros + 1;
             end
         end
     endtask

     initial begin
         #110;                      // configuração da FPGA (100 ns); entradas a meio do ciclo
                      confere(0);   // valor inicial (INIT = 0)
         Tgl = 1; #10 confere(1);   // Tgl = 1: troca em cada flanco
                  #10 confere(0);
                  #10 confere(1);
         Tgl = 0; #30 confere(1);   // Tgl = 0: mantém durante 3 flancos
         CLR = 1; #2  confere(0);   // CLR apaga logo, sem esperar pelo flanco
         Tgl = 1; #18 confere(0);   // com CLR a 1 o Tgl não tem efeito
         CLR = 0; #10 confere(1);   // CLR a 0: volta a trocar

         if (erros == 0) $display("Simulacao OK (%0d verificacoes)", verificacoes);
         else            $display("Simulacao FALHOU (%0d erros em %0d verificacoes)", erros, verificacoes);
         $finish;
     end

endmodule
