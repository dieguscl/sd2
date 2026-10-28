`timescale 1ns / 1ps

// Testbench do controlador (máquina de estados por realização direta).
// Percorre todas as transições do fluxograma. Em cada linha muda Start/Tempo, espera um ciclo
// e confere o estado (os 6 flip-flops) e as 10 saídas de Moore desse estado.
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

//   Relógio de 100 MHz (período de 10ns): flancos ascendentes em 5, 15, 25, ... ns
     always #5 Clock = ~Clock;

//   Estados one-hot: Estado = {S5, S4, S3, S2, S1, S0}
     localparam S0 = 6'b000001, S1 = 6'b000010, S2 = 6'b000100,
                S3 = 6'b001000, S4 = 6'b010000, S5 = 6'b100000;

//   Saídas de cada estado, pela ordem
//   ClrMem InitLFSR EnLFSR ShiftMem RstTemp StartTemp Faster TglBeat Ready Waiting
     function [9:0] saidas_de(input [5:0] estado);
         case (estado)
             S0: saidas_de = 10'b1_1_1_0_1_0_0_0_0_0;
             S1: saidas_de = 10'b0_0_1_0_0_0_0_0_1_0;
             S2: saidas_de = 10'b0_0_1_0_0_0_0_0_1_0;
             S3: saidas_de = 10'b0_0_1_1_0_1_0_1_0_0;
             S4: saidas_de = 10'b0_0_1_0_0_0_0_0_0_1;
             S5: saidas_de = 10'b0_0_1_0_0_0_1_0_0_0;
         endcase
     endfunction
     wire [9:0] saidas = {ClrMem, InitLFSR, EnLFSR, ShiftMem, RstTemp,
                          StartTemp, Faster, TglBeat, Ready, Waiting};

//   Confere o estado e as saídas
     integer erros = 0, verificacoes = 0;
     task confere(input [5:0] estado);
         begin
             verificacoes = verificacoes + 1;
             if (Estado !== estado || saidas !== saidas_de(estado)) begin
                 $display("ERRO t=%0t: Estado=%b saidas=%b (esperado %b %b)",
                          $time, Estado, saidas, estado, saidas_de(estado));
                 erros = erros + 1;
             end
         end
     endtask

     initial begin
         #50  confere(S0);                       // configuração da FPGA: S0 (INIT = 1 só em FF_S0)
         #60  confere(S1);                       // t = 110: no 1.º flanco (105) passa a S1
         // As entradas mudam a meio do ciclo; cada confere é feito depois de um flanco
         Tempo = 1;            #10 confere(S1);  // S1 espera Start (Tempo não interessa)
         Start = 1;            #10 confere(S2);  // Start = 1: S2
                               #10 confere(S2);  // fica em S2 enquanto Start = 1
         Start = 0; Tempo = 0; #10 confere(S3);  // Start largada: S3 (1.º passo do jogo)
         Tempo = 1;            #10 confere(S4);  // S3 -> S4 sempre
                               #10 confere(S4);  // fica em S4 enquanto Tempo = 1
         Start = 1;            #10 confere(S4);  // Start não interessa em S4
         Start = 0; Tempo = 0; #10 confere(S5);  // fim do tempo: S5
         Tempo = 1;            #10 confere(S3);  // S5 -> S3 sempre (passo seguinte)
                               #10 confere(S4);
         // Reset a meio do ciclo
         Reset = 1;            #1  confere(S0);  // S0 logo, sem esperar pelo flanco
                               #9  confere(S0);  // fica em S0 enquanto Reset = 1
         Reset = 0;            #10 confere(S1);  // Reset largado: S1 no flanco seguinte

         if (erros == 0) $display("Simulacao OK (%0d verificacoes)", verificacoes);
         else            $display("Simulacao FALHOU (%0d erros em %0d verificacoes)", erros, verificacoes);
         $finish;
     end

endmodule
