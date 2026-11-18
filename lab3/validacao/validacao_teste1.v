`timescale 1ns / 1ps

// Testbench da validação das teclas: percorre as 8 combinações de K1, K2 e K3 (código de Gray,
// uma tecla de cada vez) e confere U e M, escritos à mão para cada combinação.
module validacao_teste1();

//   Declaração das entradas
     reg K1 = 0, K2 = 0, K3 = 0;

//   Declaração das saídas
     wire U, M;

//   Instanciação da UUT e ligação das entradas e saídas
     Validacao UUT (
         .K1(K1),
         .K2(K2),
         .K3(K3),
         .U(U),
         .M(M)
     );

     integer erros = 0, verificacoes = 0;
     task confere(input u, input m);
         begin
             verificacoes = verificacoes + 1;
             if (U !== u || M !== m) begin
                 $display("ERRO t=%0t: K1K2K3=%b%b%b U=%b M=%b (esperado %b %b)",
                          $time, K1, K2, K3, U, M, u, m);
                 erros = erros + 1;
             end
         end
     endtask

     initial begin
         #10 confere(0, 0);              // 000: nenhuma tecla
         K3 = 1; #10 confere(1, 0);      // 001: uma tecla
         K2 = 1; #10 confere(0, 1);      // 011: duas teclas
         K3 = 0; #10 confere(1, 0);      // 010: uma tecla
         K1 = 1; #10 confere(0, 1);      // 110: duas teclas
         K3 = 1; #10 confere(0, 1);      // 111: três teclas
         K2 = 0; #10 confere(0, 1);      // 101: duas teclas
         K3 = 0; #10 confere(1, 0);      // 100: uma tecla
         if (erros == 0) $display("Simulacao OK (%0d verificacoes)", verificacoes);
         else $display("Simulacao FALHOU (%0d erros em %0d verificacoes)", erros, verificacoes);
         $finish;
     end

endmodule
