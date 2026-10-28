`timescale 1ns / 1ps

// Testbench do LFSR de 32 bits.
// Confere o registo interno (regLFSR) e a saída OutLFSR = {regLFSR[31], regLFSR[0]}
// com os valores calculados à mão: em cada passo o registo desloca para a esquerda e entra
// à direita a XNOR dos bits 31, 21, 1 e 0.
module lfsr32_teste1();

//   Declaração das entradas
     reg Clock = 0;
     reg Enable = 0, Init = 0;

//   Declaração da saída
     wire [1:0] OutLFSR;

//   Instanciação da UUT e ligação das entradas e saídas
     LFSR32 #(.SEED(32'h03E3180A)) UUT (
         .Clock(Clock),
         .Enable(Enable),
         .Init(Init),
         .OutLFSR(OutLFSR)
     );

//   Relógio de 100 MHz (período de 10ns): flancos ascendentes em 5, 15, 25, ... ns
     always #5 Clock = ~Clock;

//   Confere o registo e a saída com os valores esperados
     integer erros = 0, verificacoes = 0;
     task confere(input [31:0] registo, input [1:0] saida);
         begin
             verificacoes = verificacoes + 1;
             if (UUT.regLFSR !== registo || OutLFSR !== saida) begin
                 $display("ERRO t=%0t: regLFSR=%h OutLFSR=%b (esperado %h %b)",
                          $time, UUT.regLFSR, OutLFSR, registo, saida);
                 erros = erros + 1;
             end
         end
     endtask

     initial begin
         #10;                                               // as entradas mudam a meio do ciclo
                            confere(32'h00000000, 2'b00);   // valor inicial
         Init = 1;      #10 confere(32'h00000000, 2'b00);   // Enable = 0: Init não tem efeito
         Enable = 1;    #10 confere(32'h03E3180A, 2'b00);   // Enable = 1 e Init = 1: carrega a semente
         Init = 0;      #10 confere(32'h07C63015, 2'b01);   // 1.º passo: entra 1 à direita
                        #10 confere(32'h0F8C602A, 2'b00);   // 2.º passo: entra 0
                        #10 confere(32'h1F18C054, 2'b00);   // 3.º passo: entra 0
         Enable = 0;    #30 confere(32'h1F18C054, 2'b00);   // Enable = 0: mantém durante 3 flancos
         Enable = 1;    #10 confere(32'h3E3180A9, 2'b01);   // volta a avançar
                        #10 confere(32'h7C630153, 2'b01);

         if (erros == 0) $display("Simulacao OK (%0d verificacoes)", verificacoes);
         else            $display("Simulacao FALHOU (%0d erros em %0d verificacoes)", erros, verificacoes);
         $finish;
     end

endmodule
