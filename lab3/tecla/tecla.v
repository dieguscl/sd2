`timescale 1ns / 1ps

// Gestão de uma tecla: máquina de estados assíncrona + porta XOR + temporizador (Fig. 1 e 2).
// O XOR de F com K escolhe o flanco da tecla que dispara o temporizador: com F = 0 dispara
// ao premir (flanco ascendente de K) e com F = 1 ao largar (flanco descendente de K).
// Enquanto Clear = 1, Ti fica a 0: se a tecla estiver premida quando o Clear é libertado, Ti sobe
// nesse momento e dispara o temporizador, como num flanco normal da tecla (a máquina sai do Clear
// para S1 e espera que To suba). O temporizador nunca é inicializado (secção 2.1 do enunciado).
module Tecla #(
    parameter T = 1000000           // duração do impulso do temporizador (10 ms a 100 MHz)
    )(
    input Clock,
    input Clear,                    // reset da máquina de estados (não atua no temporizador)
    input K,                        // tecla, com ressaltos
    output Kd,                      // tecla sem ressaltos
    output F,
    output Ti,
    output To,
    output [2:0] Estado             // variáveis de estado {YY2, YY1, YY0}
    );

     MaquinaTecla maquina (
         .K(K),
         .To(To),
         .Clear(Clear),
         .Kd(Kd),
         .F(F),
         .Estado(Estado)
     );

     assign Ti = (K ^ F) & ~Clear;  // entrada do temporizador

     Monoestavel #(.T(T)) temporizador (
         .Clock(Clock),
         .Ti(Ti),
         .To(To)
     );

endmodule
