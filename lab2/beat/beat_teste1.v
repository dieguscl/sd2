`timescale 1ns / 1ps

// Testbench do flip-flop T do LED Beat.
// Verifica que o LED troca de estado em cada flanco com Tgl a 1, mantém com Tgl a 0
// e que CLR o apaga de forma assíncrona.
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

//   Relógio de 100 MHz (período de 10ns), como o da Basys3
     always #5 Clk = ~Clk;

     integer erros = 0, verificacoes = 0;
     task verifica(input esperado, input [8*40:1] caso);
         begin
             verificacoes = verificacoes + 1;
             if (Q !== esperado) begin
                 $display("ERRO t=%0t (%0s): Q=%b (esperado %b)", $time, caso, Q, esperado);
                 erros = erros + 1;
             end
         end
     endtask

     initial begin
         #1   verifica(1'b0, "valor inicial (INIT=0)");
         #100;                                            // configurações iniciais da FPGA
         // As entradas mudam a meio do período (relógio sobe em 5, 15, 25, ...)
         #9;
         #30  verifica(1'b0, "Tgl=0 mantem");
         Tgl = 1;  #10 verifica(1'b1, "1.o Tgl acende");
         Tgl = 0;  #50 verifica(1'b1, "mantem aceso");
         Tgl = 1;  #10 verifica(1'b0, "2.o Tgl apaga");
                   #10 verifica(1'b1, "Tgl continuo: 3.o");
                   #10 verifica(1'b0, "Tgl continuo: 4.o");
                   #10 verifica(1'b1, "Tgl continuo: 5.o");
         Tgl = 0;  #2 CLR = 1;
                   #1 verifica(1'b0, "CLR assincrono apaga");
         Tgl = 1;  #20 verifica(1'b0, "CLR tem prioridade sobre Tgl");
         CLR = 0;  #4 verifica(1'b1, "volta a piscar depois do CLR");

         if (erros == 0) $display("Simulacao OK (%0d verificacoes)", verificacoes);
         else            $display("Simulacao FALHOU (%0d erros em %0d verificacoes)", erros, verificacoes);
         $finish;
     end

endmodule
