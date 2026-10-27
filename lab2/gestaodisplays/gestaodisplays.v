`timescale 1ns / 1ps

// Gestão dos 4 displays do jogo, feita com o sistema do 1.º trabalho (secção 2.5):
//   - DivisorClock + Contador4: varrimento dos displays (2 kHz);
//   - multiplexer16x4: corda do display ativo para o transcodificador;
//   - TranscodCordas: transcodificador alterado (um segmento horizontal por corda);
//   - descodificador2x4: ativa um display de cada vez (enables sempre a 1).
// Os registos dos símbolos do 1.º trabalho passam a ser a memória da sequência (Memoria4x2),
// por isso as cordas entram diretamente em Pos0 a Pos3.
// A corda nova (Pos0) aparece no display da esquerda (Anodos[3]) e avança para a direita
// até Pos3, no display da direita (Anodos[0]).
// Segmentos, ponto decimal e ânodos são ativos a Low na Basys3.
module GestaoDisplays #(
    parameter METADE = 25000        // varrimento a 100 MHz / (2 x 25000) = 2 kHz
    )(
    input [1:0] Pos0,
    input [1:0] Pos1,
    input [1:0] Pos2,
    input [1:0] Pos3,
    input Clock,
    output [6:0] Segmentos,
    output DotPoint,
    output [3:0] Anodos
    );

//   Sinais internos
     wire [3:0] ValorAtivo;                       // corda do display ativo (2 bits de menor peso)
     wire [3:0] DisplayAtivo;                     // saídas do descodificador (ativas a High)
     wire ClockVarrimento;                        // relógio dividido
     wire Control1, Control0;                     // variáveis de varrimento

//   Varrimento: divisor de clock e contador de módulo 4
     DivisorClock #(.METADE(METADE)) divisor (
         .ClockIn(Clock),
         .ClockOut(ClockVarrimento)
     );

     Contador4 contador (
         .Clock(ClockVarrimento),
         .Q1(Control1),
         .Q0(Control0)
     );

//   Multiplexer 16x4: o display i mostra a entrada i (display 3 = esquerda = Pos0)
     multiplexer16x4 mux16x4 (
         .DataIn0({2'b00, Pos3}),
         .DataIn1({2'b00, Pos2}),
         .DataIn2({2'b00, Pos1}),
         .DataIn3({2'b00, Pos0}),
         .DataOut(ValorAtivo),
         .Sel({Control1, Control0})
     );

//   Transcodificador das cordas: segmentos partilhados por todos os displays (ativos a Low)
     TranscodCordas transcod (
         .Corda(ValorAtivo[1:0]),
         .Segmentos(Segmentos)
     );

     assign DotPoint = 1'b1;            // ponto decimal sempre apagado

//   Descodificador 2x4: ativa um display de cada vez
     descodificador2x4 descod (
         .Bit1(Control1),
         .Bit0(Control0),
         .En0(1'b1),
         .En1(1'b1),
         .En2(1'b1),
         .En3(1'b1),
         .Out0(DisplayAtivo[0]),
         .Out1(DisplayAtivo[1]),
         .Out2(DisplayAtivo[2]),
         .Out3(DisplayAtivo[3])
     );

     assign Anodos = ~DisplayAtivo;     // ânodos comuns ligados por transistores PNP: ativos a Low

endmodule
