`timescale 1ns / 1ps

// Memória 4x2 com as cordas dos 4 displays, organizada como uma fila (registo de deslocamento).
// Feita com 4 Registo4 do 1.º trabalho, dos quais só se usam os 2 bits de menor peso
// (os 2 de maior peso carregam sempre 0 e a síntese elimina-os).
// Com Shift a 1, no flanco ascendente do relógio:
//   Pos0 <- Data (2 bits do LFSR), Pos1 <- Pos0, Pos2 <- Pos1, Pos3 <- Pos2
//   (perde-se o valor que estava em Pos3).
// CLR limpa as 4 posições de forma assíncrona (todas as cordas em pausa).
module Memoria4x2(
    input [1:0] Data,
    input Shift,
    input Clk,
    input CLR,
    output [1:0] Pos0,
    output [1:0] Pos1,
    output [1:0] Pos2,
    output [1:0] Pos3
    );

//   Conteúdo dos 4 registos (4 bits cada)
     wire [3:0] Q0, Q1, Q2, Q3;

//   Fila: cada registo carrega o anterior e o primeiro carrega a corda nova
     Registo4 reg0 (.Data({2'b00, Data}), .CE(Shift), .Clk(Clk), .CLR(CLR), .DataOut(Q0));
     Registo4 reg1 (.Data(Q0),            .CE(Shift), .Clk(Clk), .CLR(CLR), .DataOut(Q1));
     Registo4 reg2 (.Data(Q1),            .CE(Shift), .Clk(Clk), .CLR(CLR), .DataOut(Q2));
     Registo4 reg3 (.Data(Q2),            .CE(Shift), .Clk(Clk), .CLR(CLR), .DataOut(Q3));

     assign Pos0 = Q0[1:0];
     assign Pos1 = Q1[1:0];
     assign Pos2 = Q2[1:0];
     assign Pos3 = Q3[1:0];

endmodule
