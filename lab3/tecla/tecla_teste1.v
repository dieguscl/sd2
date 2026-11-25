`timescale 1ns / 1ps

// Testbench da gestão de uma tecla (máquina de estados + XOR + temporizador), com T = 20
// ciclos (200 ns) e uma tecla com ressaltos de alguns nanossegundos. Começa com Clear ativo.
// Situações: premir e largar com ressaltos (Fig. 2 do enunciado), uma pressão mais curta do que
// a temporização, uma nova pressão durante a temporização ao largar e um Clear mais longo do que
// a temporização com a tecla premida.
// Confere Kd e o estado em vários instantes e conta os flancos de Kd (um por pressão, sem picos).
module tecla_teste1();

//   Declaração das entradas
     reg Clock = 0;
     reg Clear = 1;
     reg K = 0;

//   Declaração das saídas
     wire Kd, F, Ti, To;
     wire [2:0] Estado;

//   Instanciação da UUT e ligação das entradas e saídas
     Tecla #(.T(20)) UUT (
         .Clock(Clock),
         .Clear(Clear),
         .K(K),
         .Kd(Kd),
         .F(F),
         .Ti(Ti),
         .To(To),
         .Estado(Estado)
     );

//   Relógio de 100 MHz (período de 10 ns)
     always #5 Clock = ~Clock;

     localparam S0 = 3'b000, S1 = 3'b001, S2 = 3'b011, S3 = 3'b111, S4 = 3'b110, S5 = 3'b100;

//   Flancos de Kd (cada pressão da tecla deve dar exatamente uma subida e uma descida)
     integer subidas = 0, descidas = 0;
     always @(posedge Kd) subidas = subidas + 1;
     always @(negedge Kd) descidas = descidas + 1;

     integer erros = 0, verificacoes = 0;
     task confere(input kd, input [2:0] estado);
         begin
             verificacoes = verificacoes + 1;
             if (Kd !== kd || Estado !== estado) begin
                 $display("ERRO t=%0t: Kd=%b Estado=%b (esperado %b %b)",
                          $time, Kd, Estado, kd, estado);
                 erros = erros + 1;
             end
         end
     endtask
     task ate(input integer t);          // espera até ao instante t (ns)
         #(t - $time);
     endtask

     initial begin
         ate(20);  confere(0, S0);  Clear = 0;          // reset ativo no arranque
         subidas = 0; descidas = 0;                     // (a passagem de X a 0 em t = 0 não conta)
         // 1) Premir com ressaltos (100 a 131 ns): Kd sobe logo no 1.º flanco e não volta a 0
         ate(101); K = 1;
         ate(103); confere(1, S1);
         ate(108); K = 0;
         ate(110); confere(1, S1);                      // ressalto antes de To subir (i)
         ate(114); K = 1;
         ate(122); K = 0;
         ate(127); confere(1, S2);                      // To subiu com a tecla em baixo (d)
         ate(131); K = 1;                               // tecla premida, já sem ressaltos
         ate(200); confere(1, S2);                      // temporização (reiniciada pelos ressaltos)
         ate(500); confere(1, S3);                      // fim da temporização: premida estável
         // 2) Largar com ressaltos (601 a 633 ns): Kd desce logo e não volta a 1
         ate(601); K = 0;
         ate(603); confere(0, S4);
         ate(607); K = 1;
         ate(609); confere(0, S4);                      // ressalto antes de To subir (j)
         ate(614); K = 0;
         ate(622); K = 1;
         ate(633); K = 0;                               // tecla largada, já sem ressaltos
         ate(700); confere(0, S5);                      // temporização ao largar
         ate(1000); confere(0, S0);                     // repouso
         // 3) Pressão mais curta do que a temporização: Kd fica a 1 até ao fim da temporização
         ate(1101); K = 1;
         ate(1103); confere(1, S1);
         ate(1151); K = 0;                              // largada aos 50 ns, To ainda a 1
         ate(1200); confere(1, S2);
         ate(1400); confere(0, S5);                     // fim da temporização: S2 -> S3 -> S4 -> S5
         ate(1700); confere(0, S0);
         // 4) Nova pressão durante a temporização ao largar: só conta no fim da temporização
         ate(1801); K = 1;
         ate(2300); confere(1, S3);
         ate(2301); K = 0;
         ate(2303); confere(0, S4);
         ate(2351); K = 1;                              // premida outra vez, To ainda a 1
         ate(2400); confere(0, S5);                     // h: Kd continua a 0
         ate(2600); confere(1, S2);                     // fim da temporização: S5 -> S0 -> S1 -> S2
         ate(2900); confere(1, S3);
         ate(3001); K = 0;
         ate(3400); confere(0, S0);
         // 5) Clear mais longo do que T com a tecla premida, libertado com a tecla ainda premida:
         //    a máquina sai do Clear para S1 e Ti sobe nesse momento, disparando o temporizador
         ate(3501); K = 1;
         ate(3900); confere(1, S3);
         ate(3901); Clear = 1;
         ate(3903); confere(0, S0);                     // S0 de imediato, Kd = 0
         ate(4301); Clear = 0;                          // 400 ns depois: temporizador parado
         ate(4303); confere(1, S1);                     // tecla premida: S1, Kd = 1
         ate(4400); confere(1, S2);                     // To subiu: a libertação do Clear disparou-o
         ate(4700); confere(1, S3);
         ate(4801); K = 0;
         ate(5200); confere(0, S0);                     // largada normalmente
         // contagem dos flancos de Kd: 6 subidas e 6 descidas (4 pressões, o Clear e a nova subida)
         verificacoes = verificacoes + 1;
         if (subidas !== 6 || descidas !== 6) begin
             $display("ERRO: Kd teve %0d subidas e %0d descidas (esperado 6 e 6)",
                      subidas, descidas);
             erros = erros + 1;
         end
         if (erros == 0) $display("Simulacao OK (%0d verificacoes)", verificacoes);
         else $display("Simulacao FALHOU (%0d erros em %0d verificacoes)", erros, verificacoes);
         $finish;
     end

endmodule
