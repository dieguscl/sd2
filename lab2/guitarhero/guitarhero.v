`timescale 1ns / 1ps

// Gestão dos displays para o jogo Guitar Hero (2.º trabalho): circuito de topo.
// Liga o controlador (máquina de estados) à arquitetura a controlar:
//   - SincronizadorReset: Reset ativado de imediato e libertado em sincronismo com o relógio;
//   - Sincronizador: tecla Start sincronizada e sem ressaltos;
//   - LFSR32: sequência pseudo-aleatória das cordas;
//   - Memoria4x2: cordas dos 4 displays (fila);
//   - GestaoDisplays: varrimento dos displays com o transcodificador das cordas;
//   - TemporizadorVariavel: velocidade do jogo;
//   - Beat: flip-flop T do LED Beat.
// As ligações entre o controlador e a arquitetura são feitas pelo nome do sinal.
// Os parâmetros permitem usar tempos curtos na simulação.
module GuitarHero #(
    parameter METADE  = 25000,      // varrimento dos displays a 2 kHz
    parameter ESTAVEL = 1000000,    // anti-ressalto da tecla Start: 10 ms
    parameter INICIAL = 50000000,   // período inicial do temporizador: 0,5 s
    parameter PASSO   = 500000,     // aceleração por passo: 5 ms
    parameter MINIMO  = 20000000    // período mínimo: 0,2 s
    )(
    input CLKBasys,
    input BtnReset,
    input BtnStart,
    output [6:0] Seg,
    output DP,
    output [3:0] An,
    output LedReady,
    output LedBeat,
    output LedWaiting,
    output [5:0] LedEstado
    );

//   Sinais entre o controlador e a arquitetura a controlar
     wire Reset, Start, Tempo;                                  // entradas do controlador
     wire ClrMem, InitLFSR, EnLFSR, ShiftMem;                   // saídas do controlador
     wire RstTemp, StartTemp, Faster, TglBeat;

//   Sinais internos da arquitetura
     wire [1:0] OutLFSR;
     wire [1:0] Pos0, Pos1, Pos2, Pos3;

//   ---------------------------------------------------------------- controlador
     SincronizadorReset sincronizadorReset (
         .Clock(CLKBasys),
         .Entrada(BtnReset),
         .Saida(Reset)
     );

     Controlador controlador (
         .Clock(CLKBasys),
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
         .Ready(LedReady),
         .Waiting(LedWaiting),
         .Estado(LedEstado)
     );

//   ---------------------------------------------------------------- arquitetura a controlar
     Sincronizador #(.ESTAVEL(ESTAVEL)) sincronizador (
         .Clock(CLKBasys),
         .Entrada(BtnStart),
         .Saida(Start)
     );

     LFSR32 lfsr (
         .Clock(CLKBasys),
         .Enable(EnLFSR),
         .Init(InitLFSR),
         .OutLFSR(OutLFSR)
     );

     Memoria4x2 memoria (
         .Data(OutLFSR),
         .Shift(ShiftMem),
         .Clk(CLKBasys),
         .CLR(ClrMem),
         .Pos0(Pos0),
         .Pos1(Pos1),
         .Pos2(Pos2),
         .Pos3(Pos3)
     );

     GestaoDisplays #(.METADE(METADE)) displays (
         .Pos0(Pos0),
         .Pos1(Pos1),
         .Pos2(Pos2),
         .Pos3(Pos3),
         .Clock(CLKBasys),
         .Segmentos(Seg),
         .DotPoint(DP),
         .Anodos(An)
     );

     TemporizadorVariavel #(.INICIAL(INICIAL), .PASSO(PASSO), .MINIMO(MINIMO)) temporizador (
         .Clock(CLKBasys),
         .RstTemp(RstTemp),
         .StartTemp(StartTemp),
         .Faster(Faster),
         .Tempo(Tempo)
     );

     Beat beat (
         .Clk(CLKBasys),
         .Tgl(TglBeat),
         .CLR(ClrMem),
         .Q(LedBeat)
     );

endmodule
