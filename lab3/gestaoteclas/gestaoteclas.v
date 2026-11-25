`timescale 1ns / 1ps

// Circuito de topo do 3.º trabalho: gestão das teclas do jogo Guitar Hero na Basys3.
//   - três instâncias de Tecla (máquina de estados assíncrona + XOR + temporizador), uma por
//     tecla do jogo K1, K2 e K3;
//   - Validacao: U = uma só tecla premida, M = mais do que uma tecla premida;
//   - Reset (tecla BTNU) ligado ao Clear das três máquinas, nas realimentações; os
//     temporizadores não são inicializados (secção 2.1 do enunciado);
//   - circuito auxiliar de ensaio: conta os flancos das teclas antes e depois da eliminação dos
//     ressaltos e mostra as duas contagens nos displays (sistema do 1.º trabalho).
module GestaoTeclas #(
    parameter T = 100000000,        // impulso do temporizador: 1 s a 100 MHz (versão de demonstração; o relatório usa 10 ms = 1000000)
    parameter METADE = 25000        // varrimento dos displays: 100 MHz / (2 x 25000) = 2 kHz
    )(
    input CLKBasys,
    input BtnReset,                 // BTNU
    input BtnK1,                    // BTNL
    input BtnK2,                    // BTNC
    input BtnK3,                    // BTNR
    output [2:0] LedKd,             // LD0 a LD2: teclas sem ressaltos Kd1, Kd2, Kd3
    output [8:0] LedEstado,         // LD4 a LD12: variáveis de estado das três máquinas
    output LedM,                    // LD14: mais do que uma tecla premida
    output LedU,                    // LD15: uma só tecla premida
    output [6:0] Seg,
    output DP,
    output [3:0] An
    );

//   Reset de arranque: Clear também fica ativo nos 4 primeiros ciclos depois de configurar a
//   FPGA, para as máquinas começarem em S0 sem ser preciso carregar Reset
     reg [3:0] arranque = 4'b1111;
     always @(posedge CLKBasys)
         arranque <= {arranque[2:0], 1'b0};
     wire Clear = BtnReset | arranque[3];

//   Uma instância da gestão de tecla por cada tecla do jogo
     wire Kd1, Kd2, Kd3;
     wire [2:0] Estado1, Estado2, Estado3;

     Tecla #(.T(T)) tecla1 (.Clock(CLKBasys), .Clear(Clear), .K(BtnK1), .Kd(Kd1),
                            .F(), .Ti(), .To(), .Estado(Estado1));
     Tecla #(.T(T)) tecla2 (.Clock(CLKBasys), .Clear(Clear), .K(BtnK2), .Kd(Kd2),
                            .F(), .Ti(), .To(), .Estado(Estado2));
     Tecla #(.T(T)) tecla3 (.Clock(CLKBasys), .Clear(Clear), .K(BtnK3), .Kd(Kd3),
                            .F(), .Ti(), .To(), .Estado(Estado3));

//   Validação: uma só tecla (U) ou mais do que uma (M)
     Validacao validacao (.K1(Kd1), .K2(Kd2), .K3(Kd3), .U(LedU), .M(LedM));

     assign LedKd = {Kd3, Kd2, Kd1};
     assign LedEstado = {Estado3, Estado2, Estado1};

//   Circuito auxiliar de ensaio: flancos das teclas com ressaltos (displays da esquerda) e sem
//   ressaltos (displays da direita), em hexadecimal; a tecla Reset também põe as contagens a 0
     (* ASYNC_REG = "TRUE" *) reg rst_meta = 1'b0, rst_sinc = 1'b0;
     always @(posedge CLKBasys) begin
         rst_meta <= BtnReset;
         rst_sinc <= rst_meta;
     end
     wire [7:0] ImpulsosK, ImpulsosKd;
     ContaImpulsos contaK  (.Clock(CLKBasys), .Clr(rst_sinc),
                            .Entrada(BtnK1 | BtnK2 | BtnK3), .Contagem(ImpulsosK));
     ContaImpulsos contaKd (.Clock(CLKBasys), .Clr(rst_sinc),
                            .Entrada(Kd1 | Kd2 | Kd3), .Contagem(ImpulsosKd));

     ControloDisplays #(.METADE(METADE)) displays (
         .Data3(ImpulsosK[7:4]),  .Load3(1'b1), .Clr3(1'b0), .Enable3(1'b1),
         .Data2(ImpulsosK[3:0]),  .Load2(1'b1), .Clr2(1'b0), .Enable2(1'b1),
         .Data1(ImpulsosKd[7:4]), .Load1(1'b1), .Clr1(1'b0), .Enable1(1'b1),
         .Data0(ImpulsosKd[3:0]), .Load0(1'b1), .Clr0(1'b0), .Enable0(1'b1),
         .DotPoints(4'b0100), .LoadDP(1'b1), .ClrDP(1'b0),       // ponto a separar as contagens
         .Clock(CLKBasys),
         .Segmentos(Seg), .DotPoint(DP), .Anodos(An)
     );

endmodule
