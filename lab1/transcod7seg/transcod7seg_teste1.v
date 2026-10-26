`timescale 1ns / 1ps

// Testbench do transcodificador para 7 segmentos.
// Percorre os 16 valores de Numero e verifica, para cada um:
//   - que a saída é igual à tabela de referência (Fig. 30 e símbolos 10 a 15);
//   - que nenhum bit da saída fica indefinido (X ou Z);
//   - que os 16 símbolos são todos diferentes entre si (nenhum é ambíguo no display).
// Depois repete os 16 valores por ordem aleatória, para garantir que a saída
// só depende do valor atual e não do valor anterior (circuito combinatório).
module transcod7seg_teste1();

//   Declaração das entradas
     reg [3:0] N;

//   Declaração da saída (a..g, ativos a Low)
     wire [6:0] S;

//   Instanciação da UUT e ligação das entradas e saídas
     Transcod7Seg UUT (
         .Numero(N),
         .Segmentos(S)
     );

//   Tabela de referência, escrita com os segmentos ACESOS (ativo a High) para
//   ser fácil de comparar com a Fig. 30; a saída esperada é a sua negação.
     reg [6:0] acesos [0:15];
     initial begin           //  abcdefg
         acesos[0]  = 7'b1111110;  acesos[1]  = 7'b0110000;
         acesos[2]  = 7'b1101101;  acesos[3]  = 7'b1111001;
         acesos[4]  = 7'b0110011;  acesos[5]  = 7'b1011011;
         acesos[6]  = 7'b1011111;  acesos[7]  = 7'b1110000;
         acesos[8]  = 7'b1111111;  acesos[9]  = 7'b1111011;
         acesos[10] = 7'b0000101;  acesos[11] = 7'b0111101;  // r  d
         acesos[12] = 7'b0001110;  acesos[13] = 7'b1001111;  // L  E
         acesos[14] = 7'b1001110;  acesos[15] = 7'b0000001;  // C  -
     end

//   Declaração de vars auxiliares
     integer n, m, k, erros = 0, verificacoes = 0;
     integer semente = 7;
     reg [6:0] obtido [0:15];
     reg [3:0] ordem [0:15];
     reg [3:0] tmp;

     task verifica(input [3:0] valor);
         begin
             verificacoes = verificacoes + 1;
             if (^S === 1'bx) begin
                 $display("ERRO: Numero=%0d tem segmentos indefinidos (%b)", valor, S);
                 erros = erros + 1;
             end
             else if (S !== ~acesos[valor]) begin
                 $display("ERRO: Numero=%0d Segmentos=%b (esperado %b)", valor, S, ~acesos[valor]);
                 erros = erros + 1;
             end
         end
     endtask

//   Definição do valor das entradas ao longo do tempo
     initial begin
         N = 4'h0;
         #200;                    // Aguardar as configurações iniciais da FPGA

         // 1) Os 16 valores por ordem crescente
         for (n=0; n<16; n=n+1)
         begin
             N = n;
             #50;                 // Passam 50ns em cada valor
             verifica(n);
             obtido[n] = S;
         end

         // 2) Os 16 símbolos têm de ser todos diferentes
         for (n=0; n<16; n=n+1)
             for (m=n+1; m<16; m=m+1)
                 if (obtido[n] === obtido[m]) begin
                     $display("ERRO: Numero=%0d e Numero=%0d mostram o mesmo simbolo", n, m);
                     erros = erros + 1;
                 end

         // 3) Os 16 valores por ordem aleatória (baralhados), duas vezes
         for (k=0; k<2; k=k+1) begin
             for (n=0; n<16; n=n+1) ordem[n] = n;
             for (n=15; n>0; n=n-1) begin
                 m = {$random(semente)} % (n+1);
                 tmp = ordem[n]; ordem[n] = ordem[m]; ordem[m] = tmp;
             end
             for (n=0; n<16; n=n+1) begin
                 N = ordem[n];
                 #20 verifica(ordem[n]);
             end
         end

         if (erros == 0) $display("Simulacao OK: Transcod7Seg sem erros (%0d verificacoes)", verificacoes);
         else            $display("Simulacao FALHOU: Transcod7Seg com %0d erros", erros);
         $finish;
     end
endmodule
