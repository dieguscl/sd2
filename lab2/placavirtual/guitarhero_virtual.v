`timescale 1ns / 1ps

// Versão do circuito de topo para a placa virtual de fpga.dieguscl.com.
// O simulador do browser corre muito abaixo dos 100 MHz da Basys3, por isso os tempos são
// reduzidos (o GuitarHero é o mesmo do relatório, só mudam os parâmetros):
//   METADE, ESTAVEL, INICIAL, PASSO e MINIMO escolhidos para a velocidade do simulador.
// O simulador também ignora os valores INIT dos flip-flops (começam todos a 0), por isso há
// um reset de arranque: os primeiros 15 ciclos funcionam como se a tecla Reset estivesse carregada.
// Usar com a aceleração (Speed-up) desligada.
module GuitarHeroVirtual #(
    parameter METADE  = 250,
    parameter ESTAVEL = 2000,
    parameter INICIAL = 100000,
    parameter PASSO   = 1000,
    parameter MINIMO  = 40000
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

     reg [3:0] arranque = 4'd0;
     always @(posedge CLKBasys)
         if (arranque != 4'hF)
             arranque <= arranque + 1;

     GuitarHero #(.METADE(METADE), .ESTAVEL(ESTAVEL), .INICIAL(INICIAL), .PASSO(PASSO), .MINIMO(MINIMO)) jogo (
         .CLKBasys(CLKBasys),
         .BtnReset(BtnReset | (arranque != 4'hF)),
         .BtnStart(BtnStart),
         .Seg(Seg),
         .DP(DP),
         .An(An),
         .LedReady(LedReady),
         .LedBeat(LedBeat),
         .LedWaiting(LedWaiting),
         .LedEstado(LedEstado)
     );

endmodule
