`timescale 1ns / 1ps

// Controlador dos 4 displays de 7 segmentos da Basys3 (Fig. 31 do enunciado).
// Reutiliza os modulos ja desenvolvidos:
//   - 5 x Registo4: 4 registos com o simbolo de cada display e 1 com os pontos decimais;
//   - multiplexer16x4: liga ao transcodificador o registo do display ativo;
//   - multiplexer4x1: escolhe o ponto decimal do display ativo;
//   - Transcod7Seg: converte o simbolo nos segmentos a acender;
//   - descodificador2x4: escolhe o display ativo (com um enable por display);
//   - DivisorClock + Contador4: geram as variaveis de varrimento Control1 e Control0.
// O display i (Anodos[i]) mostra o registo i; Anodos[0] e o display da direita.
// Segmentos, ponto decimal e anodos sao ativos a Low na Basys3.
module ControloDisplays #(
    parameter METADE = 25000        // varrimento a 100 MHz / (2 x 25000) = 2 kHz
    )(
    input [3:0] Data3,
    input Load3,
    input Clr3,
    input Enable3,
    input [3:0] Data2,
    input Load2,
    input Clr2,
    input Enable2,
    input [3:0] Data1,
    input Load1,
    input Clr1,
    input Enable1,
    input [3:0] Data0,
    input Load0,
    input Clr0,
    input Enable0,
    input [3:0] DotPoints,
    input LoadDP,
    input ClrDP,
    input Clock,
    output [6:0] Segmentos,
    output DotPoint,
    output [3:0] Anodos
    );

//   Sinais internos
     wire [3:0] Valor3, Valor2, Valor1, Valor0;   // conteudo dos registos dos simbolos
     wire [3:0] Pontos;                           // conteudo do registo dos pontos decimais
     wire [3:0] ValorAtivo;                       // simbolo do display ativo
     wire PontoAtivo;                             // ponto decimal do display ativo (1 = aceso)
     wire [3:0] DisplayAtivo;                     // saidas do descodificador (ativas a High)
     wire ClockVarrimento;                        // relogio dividido
     wire Control1, Control0;                     // variaveis de varrimento

//   Registos dos simbolos e dos pontos decimais (relogio de 100 MHz, carga com Load)
     Registo4 reg3  (.Data(Data3),     .CE(Load3),  .Clk(Clock), .CLR(Clr3),  .DataOut(Valor3));
     Registo4 reg2  (.Data(Data2),     .CE(Load2),  .Clk(Clock), .CLR(Clr2),  .DataOut(Valor2));
     Registo4 reg1  (.Data(Data1),     .CE(Load1),  .Clk(Clock), .CLR(Clr1),  .DataOut(Valor1));
     Registo4 reg0  (.Data(Data0),     .CE(Load0),  .Clk(Clock), .CLR(Clr0),  .DataOut(Valor0));
     Registo4 regDP (.Data(DotPoints), .CE(LoadDP), .Clk(Clock), .CLR(ClrDP), .DataOut(Pontos));

//   Varrimento: divisor de clock e contador de modulo 4
     DivisorClock #(.METADE(METADE)) divisor (
         .ClockIn(Clock),
         .ClockOut(ClockVarrimento)
     );

     Contador4 contador (
         .Clock(ClockVarrimento),
         .Q1(Control1),
         .Q0(Control0)
     );

//   Multiplexer 16x4: registo do display ativo para o transcodificador
     multiplexer16x4 mux16x4 (
         .DataIn0(Valor0),
         .DataIn1(Valor1),
         .DataIn2(Valor2),
         .DataIn3(Valor3),
         .DataOut(ValorAtivo),
         .Sel({Control1, Control0})
     );

//   Transcodificador: segmentos partilhados por todos os displays (ativos a Low)
     Transcod7Seg transcod (
         .Numero(ValorAtivo),
         .Segmentos(Segmentos)
     );

//   Multiplexer 4x1: ponto decimal do display ativo
     multiplexer4x1 mux4x1 (
         .Sel1(Control1),
         .Sel0(Control0),
         .DataIn0(Pontos[0]),
         .DataIn1(Pontos[1]),
         .DataIn2(Pontos[2]),
         .DataIn3(Pontos[3]),
         .DataOut(PontoAtivo)
     );

     assign DotPoint = ~PontoAtivo;     // o segmento DP acende com nivel Low

//   Descodificador 2x4: ativa um display de cada vez, se o respetivo enable estiver a 1
     descodificador2x4 descod (
         .Bit1(Control1),
         .Bit0(Control0),
         .En0(Enable0),
         .En1(Enable1),
         .En2(Enable2),
         .En3(Enable3),
         .Out0(DisplayAtivo[0]),
         .Out1(DisplayAtivo[1]),
         .Out2(DisplayAtivo[2]),
         .Out3(DisplayAtivo[3])
     );

     assign Anodos = ~DisplayAtivo;     // anodos comuns ligados por transistores PNP: ativos a Low

endmodule
