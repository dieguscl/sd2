`timescale 1ns / 1ps

// Testbench da memória 4x2 (fila de 4 posições de 2 bits).
// Parte 1: casos dirigidos (valor inicial, deslocamento de 4 cordas, Shift = 0, clear assíncrono).
// Parte 2: 2000 ciclos com entradas aleatórias comparados com um modelo de referência.
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

//   Relógio de 100 MHz (período de 10ns), como o da Basys3
     always #5 Clk = ~Clk;

//   Modelo de referência: fila {Pos3, Pos2, Pos1, Pos0}
     reg [7:0] referencia = 8'h00;
     always @(posedge Clk or posedge CLR)
         if (CLR)        referencia <= 8'h00;
         else if (Shift) referencia <= {referencia[5:0], Data};

     wire [7:0] fila = {Pos3, Pos2, Pos1, Pos0};

//   Verificação contínua: a fila tem de ser sempre igual à referência
     integer erros = 0, verificacoes = 0;
     always @(fila or referencia) begin
         #1;
         verificacoes = verificacoes + 1;
         if (fila !== referencia) begin
             if (erros < 10) $display("ERRO t=%0t: fila=%b (esperado %b) Data=%b Shift=%b CLR=%b",
                                      $time, fila, referencia, Data, Shift, CLR);
             erros = erros + 1;
         end
     end

//   Verificação direta num instante (para os casos dirigidos)
     task verifica(input [7:0] esperado, input [8*40:1] caso);
         begin
             verificacoes = verificacoes + 1;
             if (fila !== esperado) begin
                 $display("ERRO t=%0t (%0s): fila=%b (esperado %b)", $time, caso, fila, esperado);
                 erros = erros + 1;
             end
         end
     endtask

     integer n;
     integer semente = 2026;        // semente fixa: resultado repetível
     initial begin
         // --- Parte 1: casos dirigidos -------------------------------------------
         #1   verifica(8'h00, "valor inicial (INIT=0)");
         #100;                                            // configurações iniciais da FPGA
         // As entradas mudam a meio do período (relógio sobe em 5, 15, 25, ...)
         Shift = 1;
         Data = 2'b01;      #10 verifica(8'b00_00_00_01, "1.a corda em Pos0");
         Data = 2'b10;      #10 verifica(8'b00_00_01_10, "desloca: Pos1 <- Pos0");
         Data = 2'b11;      #10 verifica(8'b00_01_10_11, "3.a corda");
         Data = 2'b00;      #10 verifica(8'b01_10_11_00, "pausa entra em Pos0");
         Data = 2'b10;      #10 verifica(8'b10_11_00_10, "Pos3 perde a 1.a corda");
         Shift = 0; Data = 2'b01;
                            #50 verifica(8'b10_11_00_10, "Shift=0 mantem 5 ciclos");
         #2 CLR = 1;        #1  verifica(8'h00, "CLR assincrono (sem flanco)");
         Shift = 1;         #20 verifica(8'h00, "CLR tem prioridade sobre Shift");
         CLR = 0; Shift = 0; #7;

         // --- Parte 2: 2000 ciclos com entradas aleatórias -----------------------
         for (n = 0; n < 2000; n = n + 1) begin
             Data  = $random(semente);
             Shift = $random(semente);
             if (($random(semente) & 63) == 0) begin   // às vezes um clear fora do flanco
                 #3 CLR = 1;
                 #4 CLR = 0;
                 #3;
             end
             else
                 #10;
         end

         if (erros == 0) $display("Simulacao OK (%0d verificacoes)", verificacoes);
         else            $display("Simulacao FALHOU (%0d erros em %0d verificacoes)", erros, verificacoes);
         $finish;
     end

endmodule
