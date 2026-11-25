`timescale 1ns / 1ps

// Testbench do circuito completo (controlador + arquitetura a controlar).
// Tempos curtos: varrimento METADE = 2, anti-ressalto de 4 ciclos e temporizador com
// INICIAL = 40, PASSO = 4, MINIMO = 20 ciclos.
// Percurso: espera em S1, Start com um ressalto, 7 passos do jogo e Reset a meio do jogo.
// Em cada passo confere os LEDs, as cordas da memória (que avançam uma posição) e o período.
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

//   Instanciação da UUT com tempos curtos para a simulação
     GuitarHero #(.METADE(2), .ESTAVEL(4), .INICIAL(40), .PASSO(4), .MINIMO(20)) UUT (
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

//   Relógio de 100 MHz (período de 10ns): flancos ascendentes em 5, 15, 25, ... ns
     always #5 CLKBasys = ~CLKBasys;

//   Estados one-hot: LedEstado = {S5, S4, S3, S2, S1, S0}
     localparam S0 = 6'b000001, S1 = 6'b000010, S2 = 6'b000100, S4 = 6'b010000;

     integer erros = 0, verificacoes = 0;
     task erro;
         begin
             $display("ERRO t=%0t: Estado=%b LEDs=%b%b%b Pos=%b %b %b %b Periodo=%0d Seg=%b",
                      $time, LedEstado, LedReady, LedWaiting, LedBeat,
                      UUT.Pos0, UUT.Pos1, UUT.Pos2, UUT.Pos3, UUT.temporizador.Periodo, Seg);
             erros = erros + 1;
         end
     endtask

//   Confere o estado e os LEDs Ready, Waiting e Beat
     task confere_leds(input [5:0] estado, input ready, input waiting, input beat);
         begin
             verificacoes = verificacoes + 1;
             if ({LedEstado, LedReady, LedWaiting, LedBeat} !== {estado, ready, waiting, beat}) erro;
         end
     endtask

//   Confere as cordas da memória (Pos0 no display da esquerda ... Pos3 no da direita)
     task confere_cordas(input [1:0] p0, input [1:0] p1, input [1:0] p2, input [1:0] p3);
         begin
             verificacoes = verificacoes + 1;
             if ({UUT.Pos0, UUT.Pos1, UUT.Pos2, UUT.Pos3} !== {p0, p1, p2, p3}) erro;
         end
     endtask

//   Confere o período do temporizador (em ciclos)
     task confere_periodo(input integer periodo);
         begin
             verificacoes = verificacoes + 1;
             if (UUT.temporizador.Periodo !== periodo) erro;
         end
     endtask

//   Confere os segmentos acesos no display ativo
     task confere_segmentos(input [6:0] segmentos);
         begin
             verificacoes = verificacoes + 1;
             if (Seg !== segmentos) erro;
         end
     endtask

//   Espera pelo passo seguinte do jogo: entrada em S4, quando a memória já deslocou
     task passo;
         begin
             @(posedge LedEstado[4]);
             #2;
         end
     endtask

     initial begin
         // Depois de configurar a FPGA o Reset é libertado (2 flancos) e a máquina passa de S0 a S1
         #200 confere_leds(S1, 1, 0, 0);                  // à espera de Start, Ready aceso
              confere_cordas(2'b00, 2'b00, 2'b00, 2'b00); // displays apagados
              confere_periodo(40);

         // Carregar Start com um ressalto (mais curto do que o anti-ressalto)
         BtnStart = 1; #10 BtnStart = 0; #10 BtnStart = 1;
         #200 confere_leds(S2, 1, 0, 0);                  // S2 enquanto Start está carregada
         BtnStart = 0;                                    // largar Start: o jogo começa

         // Passos do jogo: entra uma corda nova em Pos0, as outras avançam, o Beat troca
         // e o período diminui 4 ciclos (o S5 do passo anterior) até ao mínimo de 20
         passo; confere_leds(S4, 0, 1, 1); confere_cordas(2'b10, 2'b00, 2'b00, 2'b00); confere_periodo(40);
         @(negedge An[3]) #20;                            // display da esquerda ativo
         confere_segmentos(7'b1111110);                   // Pos0 = 10: corda do meio (segmento g)
         passo; confere_leds(S4, 0, 1, 0); confere_cordas(2'b00, 2'b10, 2'b00, 2'b00); confere_periodo(36);
         passo; confere_leds(S4, 0, 1, 1); confere_cordas(2'b11, 2'b00, 2'b10, 2'b00); confere_periodo(32);
         passo; confere_leds(S4, 0, 1, 0); confere_cordas(2'b00, 2'b11, 2'b00, 2'b10); confere_periodo(28);
         passo; confere_leds(S4, 0, 1, 1); confere_cordas(2'b01, 2'b00, 2'b11, 2'b00); confere_periodo(24);
         passo; confere_leds(S4, 0, 1, 0); confere_cordas(2'b11, 2'b01, 2'b00, 2'b11); confere_periodo(20);
         passo; confere_leds(S4, 0, 1, 1); confere_cordas(2'b10, 2'b11, 2'b01, 2'b00); confere_periodo(20);

         // Reset a meio do jogo
         #200 BtnReset = 1;
         #1   confere_leds(S0, 0, 0, 0);                  // S0 de imediato (sem flanco); Beat apagado
              confere_cordas(2'b00, 2'b00, 2'b00, 2'b00); // memória limpa (CLR assíncrono)
         #50  BtnReset = 0;
         #100 confere_leds(S1, 1, 0, 0);                  // de volta a S1, à espera de Start
              confere_periodo(40);                        // período inicial reposto

         if (erros == 0) $display("Simulacao OK (%0d verificacoes)", verificacoes);
         else            $display("Simulacao FALHOU (%0d erros em %0d verificacoes)", erros, verificacoes);
         $finish;
     end

//   Se o jogo não avançar, a simulação acaba aqui
     initial begin
         #10000 $display("Simulacao FALHOU (tempo limite: o jogo nao avancou)");
         $finish;
     end

endmodule
