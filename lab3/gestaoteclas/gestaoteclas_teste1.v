`timescale 1ns / 1ps

// Testbench do circuito de topo, com tempos curtos (T = 20 ciclos, varrimento com METADE = 2).
// Começa com a tecla Reset carregada. Prime K1, depois K2 sem largar K1, larga as duas e prime
// K3, sempre com ressaltos (impulsos de 15 ns, que os contadores de ensaio conseguem ver).
// Confere os LEDs Kd, U e M e as duas contagens de flancos (com e sem ressaltos) do circuito
// de ensaio; no fim carrega Reset com K3 premida e confere que as máquinas vão para S0.
module gestaoteclas_teste1();

//   Declaração das entradas
     reg CLKBasys = 0;
     reg BtnReset = 1, BtnK1 = 0, BtnK2 = 0, BtnK3 = 0;

//   Declaração das saídas
     wire [2:0] LedKd;
     wire [8:0] LedEstado;
     wire LedU, LedM;
     wire [6:0] Seg;
     wire DP;
     wire [3:0] An;

//   Instanciação da UUT e ligação das entradas e saídas
     GestaoTeclas #(.T(20), .METADE(2)) UUT (
         .CLKBasys(CLKBasys),
         .BtnReset(BtnReset),
         .BtnK1(BtnK1),
         .BtnK2(BtnK2),
         .BtnK3(BtnK3),
         .LedKd(LedKd),
         .LedEstado(LedEstado),
         .LedM(LedM),
         .LedU(LedU),
         .Seg(Seg),
         .DP(DP),
         .An(An)
     );

//   Relógio de 100 MHz (período de 10 ns)
     always #5 CLKBasys = ~CLKBasys;

     integer erros = 0, verificacoes = 0;
     task confere(input [2:0] kd, input u, input m);
         begin
             verificacoes = verificacoes + 1;
             if (LedKd !== kd || LedU !== u || LedM !== m) begin
                 $display("ERRO t=%0t: LedKd=%b U=%b M=%b (esperado %b %b %b)",
                          $time, LedKd, LedU, LedM, kd, u, m);
                 erros = erros + 1;
             end
         end
     endtask
     task confere_contagens(input [7:0] k, input [7:0] kd);
         begin
             verificacoes = verificacoes + 1;
             if (UUT.ImpulsosK !== k || UUT.ImpulsosKd !== kd) begin
                 $display("ERRO t=%0t: contagens %0d e %0d (esperado %0d e %0d)",
                          $time, UUT.ImpulsosK, UUT.ImpulsosKd, k, kd);
                 erros = erros + 1;
             end
         end
     endtask
     task ate(input integer t);
         #(t - $time);
     endtask

     initial begin
         ate(50);   confere(3'b000, 0, 0);   BtnReset = 0;           // reset ativo no arranque
         // K1 premida com dois ressaltos (3 flancos ascendentes)
         ate(101);  BtnK1 = 1;  ate(116); BtnK1 = 0;  ate(131); BtnK1 = 1;
         ate(146);  BtnK1 = 0;  ate(161); BtnK1 = 1;
         ate(170);  confere(3'b001, 1, 0);                           // só K1: U
         // K2 premida sem largar K1 (o OR das teclas não muda: 0 flancos)
         ate(601);  BtnK2 = 1;  ate(616); BtnK2 = 0;  ate(631); BtnK2 = 1;
         ate(640);  confere(3'b011, 0, 1);                           // K1 e K2: M
         // K1 largada (com ressaltos), K2 continua premida
         ate(1101); BtnK1 = 0;  ate(1116); BtnK1 = 1; ate(1131); BtnK1 = 0;
         ate(1140); confere(3'b010, 1, 0);                           // só K2: U
         // K2 largada com dois ressaltos (o OR das teclas tem 2 flancos ascendentes)
         ate(1601); BtnK2 = 0;  ate(1616); BtnK2 = 1; ate(1631); BtnK2 = 0;
         ate(1646); BtnK2 = 1;  ate(1661); BtnK2 = 0;
         ate(1670); confere(3'b000, 0, 0);
         // K3 premida com dois ressaltos (3 flancos ascendentes)
         ate(2101); BtnK3 = 1;  ate(2116); BtnK3 = 0; ate(2131); BtnK3 = 1;
         ate(2146); BtnK3 = 0;  ate(2161); BtnK3 = 1;
         ate(2170); confere(3'b100, 1, 0);
         // contagens: 8 flancos das teclas com ressaltos, 2 sem ressaltos (OR de Kd: K1..K2 e K3)
         ate(2500); confere_contagens(8, 2);
         // Reset com K3 premida: as máquinas vão para S0 de imediato; K3 é largada com o Reset
         // carregado e o Reset é libertado depois
         ate(2601); BtnReset = 1;
         ate(2605); confere(3'b000, 0, 0);
         ate(2651); BtnK3 = 0;
         ate(2701); BtnReset = 0;
         ate(2720); confere_contagens(0, 0);                         // contagens a 0
         ate(3200); confere(3'b000, 0, 0);
         verificacoes = verificacoes + 1;
         if (LedEstado !== 9'b000_000_000) begin
             $display("ERRO: LedEstado=%b (esperado as três máquinas em S0)", LedEstado);
             erros = erros + 1;
         end
         if (erros == 0) $display("Simulacao OK (%0d verificacoes)", verificacoes);
         else $display("Simulacao FALHOU (%0d erros em %0d verificacoes)", erros, verificacoes);
         $finish;
     end

endmodule
