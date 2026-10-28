`timescale 1ns / 1ps

// Testbench da memória 4x2 (fila de 4 posições de 2 bits).
// Cada linha muda as entradas, espera e confere as 4 posições (Pos0, Pos1, Pos2, Pos3).
module memoria4x2_teste1();

//   Declaração das entradas
     reg [1:0] Data = 2'b00;
     reg Shift = 0, CLR = 0;
     reg Clk = 0;

//   Declaração das saídas
     wire [1:0] Pos0, Pos1, Pos2, Pos3;

//   Instanciação da UUT e ligação das entradas e saídas
     Memoria4x2 UUT (
         .Data(Data),
         .Shift(Shift),
         .Clk(Clk),
         .CLR(CLR),
         .Pos0(Pos0),
         .Pos1(Pos1),
         .Pos2(Pos2),
         .Pos3(Pos3)
     );

//   Relógio de 100 MHz (período de 10ns): flancos ascendentes em 5, 15, 25, ... ns
     always #5 Clk = ~Clk;

//   Confere as 4 posições com os valores esperados
     integer erros = 0, verificacoes = 0;
     task confere(input [1:0] p0, input [1:0] p1, input [1:0] p2, input [1:0] p3);
         begin
             verificacoes = verificacoes + 1;
             if ({Pos0, Pos1, Pos2, Pos3} !== {p0, p1, p2, p3}) begin
                 $display("ERRO t=%0t: Pos0..Pos3 = %b %b %b %b (esperado %b %b %b %b)",
                          $time, Pos0, Pos1, Pos2, Pos3, p0, p1, p2, p3);
                 erros = erros + 1;
             end
         end
     endtask

     initial begin
         #110;                                                               // configurações iniciais da FPGA (100 ns)
                                      confere(2'b00, 2'b00, 2'b00, 2'b00);   // valor inicial: tudo em pausa
         Shift = 1; Data = 2'b01; #10 confere(2'b01, 2'b00, 2'b00, 2'b00);   // 01 entra em Pos0
                    Data = 2'b10; #10 confere(2'b10, 2'b01, 2'b00, 2'b00);   // e o 01 passa a Pos1
                    Data = 2'b11; #10 confere(2'b11, 2'b10, 2'b01, 2'b00);
                    Data = 2'b00; #10 confere(2'b00, 2'b11, 2'b10, 2'b01);
                    Data = 2'b10; #10 confere(2'b10, 2'b00, 2'b11, 2'b10);   // o 01 sai de Pos3
         Shift = 0; Data = 2'b01; #30 confere(2'b10, 2'b00, 2'b11, 2'b10);   // Shift = 0: mantém
         CLR = 1;                 #2  confere(2'b00, 2'b00, 2'b00, 2'b00);   // CLR limpa logo, sem flanco
         Shift = 1;               #18 confere(2'b00, 2'b00, 2'b00, 2'b00);   // CLR tem prioridade
         CLR = 0;                 #10 confere(2'b01, 2'b00, 2'b00, 2'b00);   // volta a deslocar

         if (erros == 0) $display("Simulacao OK (%0d verificacoes)", verificacoes);
         else            $display("Simulacao FALHOU (%0d erros em %0d verificacoes)", erros, verificacoes);
         $finish;
     end

endmodule
