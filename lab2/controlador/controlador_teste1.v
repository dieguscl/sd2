`timescale 1ns / 1ps

// Testbench do controlador (máquina de estados por realização direta).
// Um modelo de referência do fluxograma (descrição comportamental com case) corre em paralelo
// e, a meio de cada ciclo e logo depois de cada Reset, compara-se o estado (os 6 flip-flops) e
// todas as saídas. Verifica-se também que há sempre um e um só flip-flop ativo.
// Parte 1: percurso dirigido por todos os estados e transições do fluxograma.
// Parte 2: 5000 ciclos com Start e Tempo aleatórios e Resets assíncronos fora do flanco.
module controlador_teste1();

//   Declaração das entradas
     reg Clock = 0;
     reg Reset = 0, Start = 0, Tempo = 0;

//   Declaração das saídas
     wire ClrMem, InitLFSR, EnLFSR, ShiftMem, RstTemp, StartTemp, Faster, TglBeat, Ready, Waiting;
     wire [5:0] Estado;

//   Instanciação da UUT e ligação das entradas e saídas
     Controlador UUT (
         .Clock(Clock),
         .Reset(Reset),
         .Start(Start),
         .Tempo(Tempo),
         .ClrMem(ClrMem),
         .InitLFSR(InitLFSR),
         .EnLFSR(EnLFSR),
         .ShiftMem(ShiftMem),
         .RstTemp(RstTemp),
         .StartTemp(StartTemp),
         .Faster(Faster),
         .TglBeat(TglBeat),
         .Ready(Ready),
         .Waiting(Waiting),
         .Estado(Estado)
     );

//   Relógio de 100 MHz (período de 10ns), como o da Basys3
     always #5 Clock = ~Clock;

//   Modelo de referência: o fluxograma descrito de forma comportamental
     integer ref_estado = 0;               // número do estado (0 a 5)
     always @(posedge Clock or posedge Reset)
         if (Reset) ref_estado <= 0;
         else
             case (ref_estado)
                 0: ref_estado <= 1;
                 1: ref_estado <= Start ? 2 : 1;
                 2: ref_estado <= Start ? 2 : 3;
                 3: ref_estado <= 4;
                 4: ref_estado <= Tempo ? 4 : 5;
                 5: ref_estado <= 3;
             endcase

//   Saídas esperadas em cada estado:  ClrMem InitLFSR EnLFSR ShiftMem RstTemp StartTemp Faster TglBeat Ready Waiting
     function [9:0] saidas_de(input integer e);
         case (e)
             0: saidas_de = 10'b1_1_1_0_1_0_0_0_0_0;
             1: saidas_de = 10'b0_0_1_0_0_0_0_0_1_0;
             2: saidas_de = 10'b0_0_1_0_0_0_0_0_1_0;
             3: saidas_de = 10'b0_0_1_1_0_1_0_1_0_0;
             4: saidas_de = 10'b0_0_1_0_0_0_0_0_0_1;
             5: saidas_de = 10'b0_0_1_0_0_0_1_0_0_0;
             default: saidas_de = 10'bx;
         endcase
     endfunction

     wire [9:0] saidas = {ClrMem, InitLFSR, EnLFSR, ShiftMem, RstTemp, StartTemp, Faster, TglBeat, Ready, Waiting};

     integer erros = 0, verificacoes = 0;
     integer visitas [0:5];         // quantas vezes se verificou cada estado
     task verifica(input [8*40:1] caso);
         begin
             verificacoes = verificacoes + 1;
             visitas[ref_estado] = visitas[ref_estado] + 1;
             if (Estado !== (6'b000001 << ref_estado) || saidas !== saidas_de(ref_estado)) begin
                 if (erros < 10) $display("ERRO t=%0t (%0s): Estado=%b saidas=%b (esperado S%0d: %b %b) Start=%b Tempo=%b",
                                          $time, caso, Estado, saidas, ref_estado, 6'b000001 << ref_estado, saidas_de(ref_estado), Start, Tempo);
                 erros = erros + 1;
             end
         end
     endtask

//   Verificação a meio de cada ciclo (flanco descendente), depois das configurações iniciais
     always @(negedge Clock)
         if ($time > 100) verifica("a meio do ciclo");

//   Um ciclo de relógio; as entradas mudam 2 ns depois do flanco ascendente
     task ciclo(input s, input t);
         begin
             Start = s; Tempo = t;
             #10;
         end
     endtask

     integer n;
     integer semente = 2026;        // semente fixa: resultado repetível
     initial begin
         visitas[0] = 0; visitas[1] = 0; visitas[2] = 0; visitas[3] = 0; visitas[4] = 0; visitas[5] = 0;
         #1   verifica("estado inicial: S0 (INIT)");
         #106;                                            // configurações iniciais (t = 107)

         // --- Parte 1: percurso dirigido -----------------------------------------
         Reset = 1;   #1 verifica("Reset assincrono: S0");
         #20 Reset = 0;                                   // t = 128
         #9;                                              // t = 137: S1
         ciclo(0, 0); ciclo(0, 0); ciclo(0, 1);           // S1 espera Start (Tempo nao interessa)
         ciclo(1, 0);                                     // Start = 1: S2
         ciclo(1, 0); ciclo(1, 1);                        // S2 enquanto Start = 1
         ciclo(0, 0);                                     // Start = 0: S3
         ciclo(0, 1);                                     // S3 -> S4 incondicional
         ciclo(0, 1); ciclo(1, 1); ciclo(0, 1);           // S4 enquanto Tempo = 1 (Start nao interessa)
         ciclo(0, 0);                                     // Tempo = 0: S5
         ciclo(1, 1);                                     // S5 -> S3 incondicional
         ciclo(0, 1); ciclo(0, 1); ciclo(0, 0);           // S3 -> S4 -> S5 ...
         ciclo(0, 0); ciclo(0, 0);
         #4 Reset = 1;  #1 verifica("Reset a meio do jogo");
         #12 Reset = 0;
         #3;

         // --- Parte 2: entradas aleatórias e Resets fora do flanco ---------------
         for (n = 0; n < 5000; n = n + 1) begin
             // Start muda poucas vezes (tecla), Tempo fica a 1 durante vários ciclos
             if (($random(semente) & 7) == 0)  Start = ~Start;
             if (($random(semente) & 3) == 0)  Tempo = ~Tempo;
             if (($random(semente) & 255) == 0) begin
                 #4 Reset = 1;
                 #1 verifica("Reset aleatorio");
                 #(10 * (1 + ($random(semente) & 3))) Reset = 0;
                 #5;
             end
             else
                 #10;
         end

         for (n = 0; n < 6; n = n + 1)
             if (visitas[n] == 0) begin
                 $display("ERRO: o estado S%0d nunca foi visitado", n);
                 erros = erros + 1;
             end
         $display("Ciclos verificados por estado: S0 %0d, S1 %0d, S2 %0d, S3 %0d, S4 %0d, S5 %0d",
                  visitas[0], visitas[1], visitas[2], visitas[3], visitas[4], visitas[5]);
         if (erros == 0) $display("Simulacao OK (%0d verificacoes)", verificacoes);
         else            $display("Simulacao FALHOU (%0d erros em %0d verificacoes)", erros, verificacoes);
         $finish;
     end

endmodule
