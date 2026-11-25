`timescale 1ns / 1ps

// Testbench do temporizador monoestável redisparável (T = 5 ciclos).
// Confere a duração do impulso, que o flanco descendente de Ti não dispara o temporizador e
// que um novo flanco a meio da contagem a reinicia (Fig. 1 do enunciado).
module monoestavel_teste1();

//   Declaração das entradas
     reg Clock = 0;
     reg Ti = 0;

//   Declaração das saídas
     wire To;

//   Instanciação da UUT e ligação das entradas e saídas
     Monoestavel #(.T(5), .N(3)) UUT (
         .Clock(Clock),
         .Ti(Ti),
         .To(To)
     );

//   Relógio de 100 MHz (período de 10 ns): flancos ascendentes em 5, 15, 25, ... ns
     always #5 Clock = ~Clock;

     integer erros = 0, verificacoes = 0;
     task confere(input esperado);
         begin
             verificacoes = verificacoes + 1;
             if (To !== esperado) begin
                 $display("ERRO t=%0t: To=%b (esperado %b)", $time, To, esperado);
                 erros = erros + 1;
             end
         end
     endtask

     initial begin
         #20 confere(0);         // t = 20: parado depois de configurar a FPGA
         Ti = 1;                 // t = 20: flanco ascendente (meta em 25, sinc em 35)
         #20 confere(0);         // t = 40: ainda na sincronização
         #10 confere(1);         // t = 50: To = 1 desde o flanco de 45 ns
         #40 confere(1);         // t = 90: ainda a contar
         #10 confere(0);         // t = 100: 5 ciclos (45 a 95 ns)
         Ti = 0;                 // t = 100: flanco descendente, não dispara
         #40 confere(0);         // t = 140
         #10 Ti = 1;             // t = 150: novo disparo (To = 1 a partir de 175 ns)
         #30 confere(1);         // t = 180
         #10 Ti = 0;             // t = 190
         #10 Ti = 1;             // t = 200: redisparo a meio da contagem
         #30 confere(1);         // t = 230: sem o redisparo já teria acabado (225 ns)
         #40 confere(1);         // t = 270
         #10 confere(0);         // t = 280: acabou 5 ciclos depois do redisparo (275 ns)
         if (erros == 0) $display("Simulacao OK (%0d verificacoes)", verificacoes);
         else $display("Simulacao FALHOU (%0d erros em %0d verificacoes)", erros, verificacoes);
         $finish;
     end

endmodule
