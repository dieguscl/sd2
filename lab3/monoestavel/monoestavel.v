`timescale 1ns / 1ps

// Temporizador monoestável redisparável (Fig. 1 do enunciado).
// Cada flanco ascendente de Ti (re)inicia a contagem: To fica a 1 durante T ciclos do relógio
// de 100 MHz contados a partir do último flanco de Ti, e volta a 0 sozinho no fim.
// Ti é assíncrono (vem da tecla e da máquina de estados), por isso passa primeiro por dois
// flip-flops de sincronização (ASYNC_REG); o flanco é detetado comparando com o valor anterior.
// To sai diretamente de um flip-flop: nunca tem picos.
// Não tem reset: depois de configurar a FPGA arranca parado (To = 0) e o reset da máquina de
// estados não o interrompe (secção 2.1 do enunciado).
module Monoestavel #(
    parameter T = 1000000,          // duração do impulso em ciclos: 10 ms a 100 MHz
    parameter N = 20                // bits do contador (2^20 > 1000000)
    )(
    input Clock,
    input Ti,
    output reg To = 1'b0
    );

     (* ASYNC_REG = "TRUE" *) reg meta = 1'b0, sinc = 1'b0;    // sincronização de Ti
     reg anterior = 1'b0;                                       // Ti sincronizado no ciclo anterior
     reg [N-1:0] contagem = 0;                                  // ciclos que faltam depois deste

     wire flanco = sinc & ~anterior;                            // flanco ascendente de Ti

     always @(posedge Clock) begin
         meta <= Ti;
         sinc <= meta;
         anterior <= sinc;
         if (flanco) begin                  // (re)disparo: To = 1 durante T ciclos
             contagem <= T - 1;
             To <= 1'b1;
         end
         else if (contagem != 0)
             contagem <= contagem - 1;
         else
             To <= 1'b0;
     end

endmodule
