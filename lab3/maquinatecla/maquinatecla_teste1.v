`timescale 1ns / 1ps

// Testbench da máquina de estados assíncrona (sem temporizador: To é imposto pelo testbench).
// Começa com Clear ativo, como pede o enunciado. Cada linha muda uma só entrada (modo
// fundamental), espera 10 ns para a máquina estabilizar e confere o estado e as saídas.
// O percurso passa pelas 22 transições especificadas da tabela de estados reduzida, pelas
// situações de arranque (To = 1 em S0) e pelo Clear em vários estados.
module maquinatecla_teste1();

//   Declaração das entradas
     reg K = 0, To = 0, Clear = 1;

//   Declaração das saídas
     wire Kd, F;
     wire [2:0] Estado;

//   Instanciação da UUT e ligação das entradas e saídas
     MaquinaTecla UUT (
         .K(K),
         .To(To),
         .Clear(Clear),
         .Kd(Kd),
         .F(F),
         .Estado(Estado)
     );

//   Codificação dos estados (YY2 YY1 YY0)
     localparam S0 = 3'b000, S1 = 3'b001, S2 = 3'b011, S3 = 3'b111, S4 = 3'b110, S5 = 3'b100;

//   Confere o estado e as saídas: Kd = 1 em S1, S2, S3; F = 1 em S3, S4, S5
     integer erros = 0, verificacoes = 0;
     task confere(input [2:0] estado);
         reg kd, f;
         begin
             kd = (estado == S1 || estado == S2 || estado == S3);
             f  = (estado == S3 || estado == S4 || estado == S5);
             verificacoes = verificacoes + 1;
             if (Estado !== estado || Kd !== kd || F !== f) begin
                 $display("ERRO t=%0t: K=%b To=%b Clr=%b Estado=%b Kd=%b F=%b (esperado %b %b %b)",
                          $time, K, To, Clear, Estado, Kd, F, estado, kd, f);
                 erros = erros + 1;
             end
         end
     endtask

     initial begin
         // Arranque com Clear ativo: a máquina fica em S0 (000)
         #10  confere(S0);
         Clear = 0;  #10 confere(S0);    // S0 estável com K To = 00
         // Premir com ressaltos antes de To subir (b, i) e durante a temporização (c, d)
         K = 1;      #10 confere(S1);    // S0 -> S1: Kd = 1 de imediato
         K = 0;      #10 confere(S1);    // ressalto antes de To subir (i): Kd mantém-se
         K = 1;      #10 confere(S1);    // de volta a b
         K = 0;      #10 confere(S1);    // i
         To = 1;     #10 confere(S2);    // temporizador arrancou com a tecla em baixo (d)
         K = 1;      #10 confere(S2);    // ressalto durante a temporização (c)
         K = 0;      #10 confere(S2);    // d
         K = 1;      #10 confere(S2);    // c
         To = 0;     #10 confere(S3);    // fim da temporização com a tecla premida: S3, F = 1
         // Largar com ressaltos
         K = 0;      #10 confere(S4);    // S3 -> S4: Kd = 0 de imediato
         K = 1;      #10 confere(S4);    // ressalto antes de To subir (j)
         K = 0;      #10 confere(S4);    // f
         To = 1;     #10 confere(S5);    // temporização ao largar (g)
         K = 1;      #10 confere(S5);    // ressalto durante a temporização (h)
         K = 0;      #10 confere(S5);    // g
         To = 0;     #10 confere(S0);    // fim da temporização: repouso
         // Percurso normal: b -> c; tecla largada antes do fim da temporização
         K = 1;      #10 confere(S1);
         To = 1;     #10 confere(S2);    // b -> c
         K = 0;      #10 confere(S2);    // c -> d
         To = 0;     #10 confere(S4);    // d -> f: transição indireta S2 -> S3 -> S4
         To = 1;     #10 confere(S5);    // f -> g
         K = 1;      #10 confere(S5);    // g -> h
         To = 0;     #10 confere(S1);    // h -> b: tecla premida outra vez, S5 -> S0 -> S1
         To = 1;     #10 confere(S2);
         To = 0;     #10 confere(S3);
         K = 0;      #10 confere(S4);
         K = 1;      #10 confere(S4);    // j
         To = 1;     #10 confere(S5);    // j -> h
         K = 0;      #10 confere(S5);    // h -> g
         To = 0;     #10 confere(S0);
         // Arranque com o temporizador a contar (transitório inicial): espera em S0
         To = 1;     #10 confere(S0);    // S0 fica estável com To = 1
         To = 0;     #10 confere(S0);
         To = 1;     #10 confere(S0);
         K = 1;      #10 confere(S2);    // premida com To = 1: S0 -> S1 -> S2
         To = 0;     #10 confere(S3);
         // Clear em vários estados
         Clear = 1;  #10 confere(S0);    // S3 -> S0 de imediato
         Clear = 0;  #10 confere(S1);    // libertado com K To = 10: S1
         To = 1;     #10 confere(S2);
         Clear = 1;  #10 confere(S0);    // S2 -> S0
         Clear = 0;  #10 confere(S2);    // libertado com K To = 11: S0 -> S1 -> S2
         K = 0;      #10 confere(S2);
         Clear = 1;  #10 confere(S0);
         Clear = 0;  #10 confere(S0);    // libertado com K To = 01: fica em S0 até To = 0
         To = 0;     #10 confere(S0);
         if (erros == 0) $display("Simulacao OK (%0d verificacoes)", verificacoes);
         else $display("Simulacao FALHOU (%0d erros em %0d verificacoes)", erros, verificacoes);
         $finish;
     end

endmodule
