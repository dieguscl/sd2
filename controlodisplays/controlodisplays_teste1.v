`timescale 1ns / 1ps

// Testbench do controlador dos displays (ControloDisplays).
// METADE = 1: cada display fica aceso durante 2 ciclos de relógio (20ns), para que o
// varrimento se veja numa simulação curta (na placa, com METADE = 25000, são 0,5 ms).
// Os comentários indicam o que deve ver-se nos displays, da esquerda (3) para a direita (0).
module controlodisplays_teste1();

//   Declaração das entradas
     reg [3:0] D3 = 0, D2 = 0, D1 = 0, D0 = 0, DotPoints = 0;
     reg [3:0] Load = 0, Clr = 0, En = 0;      // índice i = display i
     reg LoadDP = 0, ClrDP = 0;
     reg Clk = 0;

//   Declaração das saídas
     wire [6:0] Segmentos;
     wire DotPoint;
     wire [3:0] Anodos;

//   Instanciação da UUT e ligação das entradas e saídas
     ControloDisplays #(.METADE(1)) UUT (
         .Data3(D3), .Load3(Load[3]), .Clr3(Clr[3]), .Enable3(En[3]),
         .Data2(D2), .Load2(Load[2]), .Clr2(Clr[2]), .Enable2(En[2]),
         .Data1(D1), .Load1(Load[1]), .Clr1(Clr[1]), .Enable1(En[1]),
         .Data0(D0), .Load0(Load[0]), .Clr0(Clr[0]), .Enable0(En[0]),
         .DotPoints(DotPoints), .LoadDP(LoadDP), .ClrDP(ClrDP),
         .Clock(Clk),
         .Segmentos(Segmentos),
         .DotPoint(DotPoint),
         .Anodos(Anodos)
     );

//   Relógio de 100 MHz (período de 10ns), como o da Basys3
     always #5 Clk = ~Clk;

//   Definição do valor das entradas ao longo do tempo
//   (as entradas mudam 2ns depois de um flanco descendente; os registos carregam no ascendente)
     initial begin
         #102;                                         // displays desligados
         En = 4'b1111;                         #100;   // "0000"
         {D3, D2, D1, D0} = {4'd2, 4'd0, 4'd2, 4'd6};
         Load = 4'b1111;          #10 Load = 0; #90;   // carrega os 4 registos: "2026"
         DotPoints = 4'b0100;
         LoadDP = 1;            #10 LoadDP = 0; #90;   // ponto no display 2: "20.26"
         Load = 4'b0001;                               // Load0 mantido a 1: o registo 0 segue D0
         D0 = 4'd5; #20 D0 = 4'd6; #20 D0 = 4'd7; #20;
         Load = 4'b0000; D0 = 4'd1;            #100;   // Load0 a 0: fica o 7: "20.27"
         {D3, D2, D1, D0} = {4'd10, 4'd11, 4'd12, 4'd13};
         Load = 4'b1010;          #10 Load = 0; #90;   // só os registos 3 e 1: "r0.L7"
         En = 4'b1011;                         #100;   // display 2 desligado: "r L7"
         #6 Clr[3] = 1; #2 Clr[3] = 0;         #92;   // clear assíncrono (entre flancos) do registo 3: "0 L7"
         En = 4'b1111; ClrDP = 1; #10 ClrDP = 0; #90;  // display 2 ligado, sem pontos: "00L7"
         Clr = 4'b1111;            #10 Clr = 0; #90;   // todos os registos a 0: "0000"
         En = 4'b0000;                         #100;   // displays desligados
         $finish;
     end

endmodule
