`timescale 1ns / 1ps

// Testbench do circuito completo (controlador + arquitetura a controlar).
// Tempos curtos: varrimento METADE = 2, anti-ressalto de 4 ciclos e temporizador com
// INICIAL = 40, PASSO = 4, MINIMO = 20 ciclos.
// Em cada ciclo verifica-se:
//   - há um e um só estado ativo e os LEDs Ready e Waiting correspondem ao estado;
//   - a memória é igual a uma fila de referência alimentada pelo LFSR em cada deslocamento;
//   - o display ativo mostra a corda da posição certa da memória;
//   - o LED Beat troca de estado uma vez por passo;
//   - o intervalo entre passos é o período do temporizador (40, 36, 32, ... até 20) + 3 ciclos
//     (estados S4 com Tempo = 0, S5 e S3).
// O percurso: Reset, espera em S1, Start com ressaltos, 12 passos do jogo, Reset a meio do
// jogo (inicialização assíncrona) e novo jogo.
module guitarhero_teste1();

//   Declaração das entradas
     reg CLKBasys = 0;
     reg BtnReset = 0, BtnStart = 0;

//   Declaração das saídas
     wire [6:0] Seg;
     wire DP;
     wire [3:0] An;
     wire LedReady, LedBeat, LedWaiting;
     wire [5:0] LedEstado;

     localparam INICIAL = 40, PASSO = 4, MINIMO = 20;

//   Instanciação da UUT com tempos curtos para a simulação
     GuitarHero #(.METADE(2), .ESTAVEL(4), .INICIAL(INICIAL), .PASSO(PASSO), .MINIMO(MINIMO)) UUT (
         .CLKBasys(CLKBasys),
         .BtnReset(BtnReset),
         .BtnStart(BtnStart),
         .Seg(Seg),
         .DP(DP),
         .An(An),
         .LedReady(LedReady),
         .LedBeat(LedBeat),
         .LedWaiting(LedWaiting),
         .LedEstado(LedEstado)
     );

//   Relógio de 100 MHz (período de 10ns), como o da Basys3
     always #5 CLKBasys = ~CLKBasys;

     integer erros = 0, verificacoes = 0;
     task erro(input [8*60:1] texto);
         begin
             if (erros < 15) $display("ERRO t=%0t: %0s (Estado=%b)", $time, texto, LedEstado);
             erros = erros + 1;
         end
     endtask

//   Segmentos esperados para cada corda (abcdefg, ativos a Low)
     function [6:0] segmentos_de(input [1:0] corda);
         case (corda)
             2'b00: segmentos_de = 7'b1111111;
             2'b01: segmentos_de = 7'b0111111;
             2'b10: segmentos_de = 7'b1111110;
             2'b11: segmentos_de = 7'b1110111;
         endcase
     endfunction

//   Fila de referência {Pos3, Pos2, Pos1, Pos0}: recebe a saída do LFSR em cada ShiftMem
     reg [7:0] fila_ref = 8'h00;
     reg [3:0] cordas_vistas = 4'b0000;
     always @(posedge CLKBasys or posedge UUT.ClrMem)
         if (UUT.ClrMem) fila_ref <= 8'h00;
         else if (UUT.ShiftMem) begin
             fila_ref <= {fila_ref[5:0], UUT.OutLFSR};
             cordas_vistas[UUT.OutLFSR] <= 1'b1;
         end

     wire [7:0] fila = {UUT.Pos3, UUT.Pos2, UUT.Pos1, UUT.Pos0};

//   Verificações a meio de cada ciclo
     integer ciclo = 0, ultimo_passo = -1, passos = 0, periodo = INICIAL;
     reg [1:0] corda;
     always @(negedge CLKBasys)
         if ($time > 100) begin
             ciclo = ciclo + 1;
             verificacoes = verificacoes + 1;
             if (LedEstado[0]) begin                      // S0: tudo volta ao início
                 ultimo_passo = -1; passos = 0; periodo = INICIAL;
             end
             // um e um só estado ativo
             case (LedEstado)
                 6'b000001, 6'b000010, 6'b000100, 6'b001000, 6'b010000, 6'b100000: ;
                 default: erro("estado nao one-hot");
             endcase
             // LEDs de sinalização
             if (LedReady !== (LedEstado[1] | LedEstado[2])) erro("LED Ready errado");
             if (LedWaiting !== LedEstado[4])                erro("LED Waiting errado");
             if (LedBeat !== passos[0])                      erro("LED Beat errado");
             // memória e displays
             if (fila !== fila_ref) erro("memoria diferente da fila de referencia");
             case (An)
                 4'b0111: corda = UUT.Pos0;
                 4'b1011: corda = UUT.Pos1;
                 4'b1101: corda = UUT.Pos2;
                 4'b1110: corda = UUT.Pos3;
                 default: erro("mais do que um display ativo");
             endcase
             if (Seg !== segmentos_de(corda) || DP !== 1'b1) erro("segmentos errados no display ativo");
             // passo do jogo (estado S3): intervalo desde o passo anterior
             if (LedEstado[3]) begin
                 if (ultimo_passo >= 0) begin
                     if (ciclo - ultimo_passo != periodo + 3) begin
                         $display("ERRO t=%0t: passo %0d ao fim de %0d ciclos (esperado %0d)",
                                  $time, passos, ciclo - ultimo_passo, periodo + 3);
                         erros = erros + 1;
                     end
                     if (periodo >= MINIMO + PASSO) periodo = periodo - PASSO;
                 end
                 ultimo_passo = ciclo;
                 passos = passos + 1;
             end
         end

//   Verificação do estado num instante
     task verifica_estado(input [5:0] esperado, input [8*40:1] caso);
         begin
             verificacoes = verificacoes + 1;
             if (LedEstado !== esperado) begin
                 $display("ERRO t=%0t (%0s): Estado=%b (esperado %b)", $time, caso, LedEstado, esperado);
                 erros = erros + 1;
             end
         end
     endtask

//   Inicialização assíncrona: logo depois de carregar Reset (sem esperar pelo relógio)
     task verifica_reset;
         begin
             #1 verifica_estado(6'b000001, "Reset: S0 imediatamente");
             verificacoes = verificacoes + 1;
             if (fila !== 8'h00 || LedBeat !== 1'b0 || LedReady !== 1'b0 || LedWaiting !== 1'b0) begin
                 $display("ERRO t=%0t: Reset nao limpou memoria/LEDs (fila=%b Beat=%b Ready=%b Waiting=%b)",
                          $time, fila, LedBeat, LedReady, LedWaiting);
                 erros = erros + 1;
             end
         end
     endtask

//   Tecla Start com ressaltos (mais curtos do que o anti-ressalto)
     task carrega_start;
         begin
             BtnStart = 1; #13 BtnStart = 0; #7 BtnStart = 1; #300;
         end
     endtask
     task larga_start;
         begin
             BtnStart = 0; #9 BtnStart = 1; #5 BtnStart = 0;
         end
     endtask

     initial begin
         #100;                                            // configurações iniciais da FPGA
         #33 BtnReset = 1;                                // t = 133
         verifica_reset;
         #98 BtnReset = 0;                                // t = 232
         @(negedge CLKBasys);
         verifica_estado(6'b000010, "S1 depois do Reset");
         verificacoes = verificacoes + 1;
         if (UUT.lfsr.regLFSR !== 32'h03E3180A) begin
             $display("ERRO t=%0t: LFSR sem a semente depois de S0 (%h)", $time, UUT.lfsr.regLFSR);
             erros = erros + 1;
         end
         #500 verifica_estado(6'b000010, "espera em S1 sem Start");

         carrega_start;
         verifica_estado(6'b000100, "Start carregada: S2 (sem sair com os ressaltos)");
         #200 verifica_estado(6'b000100, "S2 enquanto Start carregada");
         larga_start;
         #100;
         if (LedReady !== 1'b0 || LedWaiting !== 1'b1) erro("depois de largar Start: Ready apagado e Waiting aceso");

         wait (passos == 12);
         verificacoes = verificacoes + 1;
         if (cordas_vistas != 4'b1111) begin
             $display("ERRO: em 12 passos so sairam as cordas %b", cordas_vistas);
             erros = erros + 1;
         end

         // Reset a meio do jogo, fora do flanco do relógio
         #37 BtnReset = 1;
         verifica_reset;
         #48 BtnReset = 0;
         #300 verifica_estado(6'b000010, "S1 depois do Reset a meio do jogo");
         if (UUT.Tempo !== 1'b0) erro("temporizador nao foi inicializado");

         // Novo jogo: o período volta ao inicial (verificado a cada passo)
         carrega_start;
         larga_start;
         wait (passos == 4);
         #50;

         if (erros == 0) $display("Simulacao OK (%0d verificacoes)", verificacoes);
         else            $display("Simulacao FALHOU (%0d erros em %0d verificacoes)", erros, verificacoes);
         $finish;
     end

     initial begin
         #100000 $display("Simulacao FALHOU (tempo limite: o jogo nao avancou)");
         $finish;
     end

endmodule
