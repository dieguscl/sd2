`timescale 1ns / 1ps

// Testbench do circuito de teste na placa (TesteDisplays, Fig. 32).
// Reproduz o que se faz na Basys3: escolher um valor nos interruptores Data e ligar e
// desligar o interruptor LDx do display pretendido.
// METADE = 1: cada display fica aceso durante 2 ciclos de relógio (20ns); na placa são 0,5 ms.
// Os comentários indicam o que deve ver-se nos displays, da esquerda (3) para a direita (0).
module testedisplays_teste1();

//   Declaração das entradas
     reg [3:0] Data = 0;
     reg LD3 = 0, LD2 = 0, LD1 = 0, LD0 = 0, LDDP = 0;
     reg EN = 0, Clear = 0;
     reg CLKBasys = 0;

//   Declaração das saídas
     wire [6:0] Seg;
     wire DP;
     wire [3:0] An;

//   Instanciação da UUT e ligação das entradas e saídas
     TesteDisplays #(.METADE(1)) UUT (
         .Data(Data),
         .LD3(LD3), .LD2(LD2), .LD1(LD1), .LD0(LD0), .LDDP(LDDP),
         .EN(EN),
         .Clear(Clear),
         .CLKBasys(CLKBasys),
         .Seg(Seg),
         .DP(DP),
         .An(An)
     );

//   Relógio de 100 MHz da Basys3
     always #5 CLKBasys = ~CLKBasys;

//   Definição do valor das entradas ao longo do tempo
//   (as entradas mudam 2ns depois de um flanco descendente)
     initial begin
         #102;                                  // displays desligados
         EN = 1;                        #100;   // "0000"
         Data = 4'd10; LD3 = 1; #20 LD3 = 0;    // r no display da esquerda
         Data = 4'd11; LD2 = 1; #20 LD2 = 0;    // d
         Data = 4'd12; LD1 = 1; #20 LD1 = 0;    // L
         Data = 4'd13; LD0 = 1; #20 LD0 = 0;    // E
                                        #100;   // "rdLE"
         Data = 4'b0101; LDDP = 1; #20 LDDP = 0;
                                        #100;   // pontos nos displays 2 e 0: "rd.LE."
         LD0 = 1;                               // LD0 ligado: o display 0 segue Data
         Data = 4'd14; #20 Data = 4'd15; #20;
         LD0 = 0; Data = 4'd8;          #100;   // LD0 desligado: fica o 15 e Data já não conta: "rd.L-."
         EN = 0;                        #100;   // displays desligados
         EN = 1;                        #100;   // voltam a mostrar o mesmo: "rd.L-."
         Clear = 1;       #20 Clear = 0; #80;   // tudo a 0 e pontos apagados: "0000"
         $finish;
     end

endmodule
