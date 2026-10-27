`timescale 1ns / 1ps

// Testbench do LFSR de 32 bits.
// Parte 1: casos dirigidos (estado inicial, carga da semente, Enable = 0 mantém o estado).
// Parte 2: 100000 ciclos comparados com um modelo de referência; verifica-se também que o
//          LFSR nunca fica parado e que as 4 cordas aparecem com frequências parecidas.
module lfsr32_teste1();

//   Declaração das entradas
     reg Clock = 0;
     reg Enable = 0, Init = 0;

//   Declaração da saída
     wire [1:0] OutLFSR;

     localparam [31:0] SEMENTE = 32'h03E3180A;

//   Instanciação da UUT e ligação das entradas e saídas
     LFSR32 #(.SEED(SEMENTE)) UUT (
         .Clock(Clock),
         .Enable(Enable),
         .Init(Init),
         .OutLFSR(OutLFSR)
     );

//   Relógio de 100 MHz (período de 10ns), como o da Basys3
     always #5 Clock = ~Clock;

//   Modelo de referência: realimentação = XNOR dos bits 31, 21, 1 e 0
     reg [31:0] referencia = 0;
     always @(posedge Clock)
         if (Enable)
             referencia <= Init ? SEMENTE
                                : {referencia[30:0], ~(referencia[31] ^ referencia[21] ^ referencia[1] ^ referencia[0])};

     integer erros = 0, verificacoes = 0;
     task verifica(input [31:0] esperado, input [8*40:1] caso);
         begin
             verificacoes = verificacoes + 1;
             if (UUT.regLFSR !== esperado || OutLFSR !== {esperado[31], esperado[0]}) begin
                 if (erros < 10) $display("ERRO t=%0t (%0s): regLFSR=%h OutLFSR=%b (esperado %h)",
                                          $time, caso, UUT.regLFSR, OutLFSR, esperado);
                 erros = erros + 1;
             end
         end
     endtask

     integer n;
     integer conta [0:3];           // quantas vezes saiu cada corda
     reg [31:0] guardado;
     initial begin
         conta[0] = 0; conta[1] = 0; conta[2] = 0; conta[3] = 0;
         // --- Parte 1: casos dirigidos -------------------------------------------
         #1   verifica(32'h0, "estado inicial = 0");
         // As entradas mudam a meio do período (relógio sobe em 5, 15, 25, ...)
         Init = 1;          #20 verifica(32'h0, "Enable=0 ignora Init");
         Enable = 1;        #10 verifica(SEMENTE, "Enable=1, Init=1 carrega semente");
                            #10 verifica(SEMENTE, "Init mantido: continua na semente");
         Init = 0;          #10 verifica({SEMENTE[30:0], ~(SEMENTE[31]^SEMENTE[21]^SEMENTE[1]^SEMENTE[0])}, "primeiro passo");
         Enable = 0;        guardado = UUT.regLFSR;
                            #50 verifica(guardado, "Enable=0 mantem durante 5 ciclos");
         Enable = 1;        #10 verifica(referencia, "volta a avancar");

         // --- Parte 2: 100000 ciclos contra o modelo ------------------------------
         for (n = 0; n < 100000; n = n + 1) begin
             #10 verifica(referencia, "comparacao com o modelo");
             conta[OutLFSR] = conta[OutLFSR] + 1;
             if (UUT.regLFSR == 32'hFFFFFFFF) begin
                 $display("ERRO t=%0t: LFSR no estado proibido (tudo a 1)", $time);
                 erros = erros + 1;
             end
             if (UUT.regLFSR == SEMENTE) begin
                 $display("ERRO t=%0t: a sequencia repetiu-se ao fim de %0d passos", $time, n);
                 erros = erros + 1;
             end
         end
         $display("Cordas em 100000 passos: pausa %0d, cima %0d, meio %0d, baixo %0d",
                  conta[0], conta[1], conta[2], conta[3]);
         for (n = 0; n < 4; n = n + 1)
             if (conta[n] < 23000 || conta[n] > 27000) begin
                 $display("ERRO: frequencia da combinacao %0d fora de 25%% +- 2%%", n);
                 erros = erros + 1;
             end

         if (erros == 0) $display("Simulacao OK (%0d verificacoes)", verificacoes);
         else            $display("Simulacao FALHOU (%0d erros em %0d verificacoes)", erros, verificacoes);
         $finish;
     end

endmodule
