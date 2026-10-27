`timescale 1ns / 1ps

// Temporizador variável: o registo da velocidade fornece ao temporizador o tempo total a
// temporizar (Periodo). É o bloco "Temporizador variável" da arquitetura a controlar.
//   RstTemp:   inicializa os dois (período inicial e contagem parada);
//   StartTemp: começa uma contagem com o período atual;
//   Faster:    encurta o período para as próximas contagens;
//   Tempo:     1 enquanto a contagem decorre.
module TemporizadorVariavel #(
    parameter N       = 28,
    parameter INICIAL = 50000000,
    parameter PASSO   = 500000,
    parameter MINIMO  = 20000000
    )(
    input Clock,
    input RstTemp,
    input StartTemp,
    input Faster,
    output Tempo
    );

     wire [N-1:0] Periodo;

     Velocidade #(.N(N), .INICIAL(INICIAL), .PASSO(PASSO), .MINIMO(MINIMO)) velocidade (
         .Clock(Clock),
         .Reset(RstTemp),
         .Faster(Faster),
         .Periodo(Periodo)
     );

     Temporizador #(.N(N)) temporizador (
         .Clock(Clock),
         .Reset(RstTemp),
         .Start(StartTemp),
         .Periodo(Periodo),
         .Tempo(Tempo)
     );

endmodule
