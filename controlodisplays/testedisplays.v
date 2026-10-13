`timescale 1ns / 1ps

// Circuito de teste do controlador dos displays na Basys3 (Fig. 32 do enunciado).
// O mesmo barramento Data alimenta os 4 registos dos simbolos e o registo dos pontos
// decimais; cada registo so carrega quando o respetivo sinal LDx esta a 1.
// Clear limpa todos os registos e EN liga ou desliga os 4 displays.
module TesteDisplays #(
    parameter METADE = 25000        // passado ao divisor de clock do controlador
    )(
    input [3:0] Data,
    input LD3,
    input LD2,
    input LD1,
    input LD0,
    input LDDP,
    input EN,
    input Clear,
    input CLKBasys,
    output [6:0] Seg,
    output DP,
    output [3:0] An
    );

     ControloDisplays #(.METADE(METADE)) controlo (
         .Data3(Data),  .Load3(LD3),  .Clr3(Clear),  .Enable3(EN),
         .Data2(Data),  .Load2(LD2),  .Clr2(Clear),  .Enable2(EN),
         .Data1(Data),  .Load1(LD1),  .Clr1(Clear),  .Enable1(EN),
         .Data0(Data),  .Load0(LD0),  .Clr0(Clear),  .Enable0(EN),
         .DotPoints(Data),
         .LoadDP(LDDP),
         .ClrDP(Clear),
         .Clock(CLKBasys),
         .Segmentos(Seg),
         .DotPoint(DP),
         .Anodos(An)
     );

endmodule
