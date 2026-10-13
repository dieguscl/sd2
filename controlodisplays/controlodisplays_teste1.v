`timescale 1ns / 1ps

// Testbench do controlador dos displays (ControloDisplays).
// Usa METADE = 5 para o varrimento ser visivel em poucas centenas de ns:
// cada display fica ativo durante 2 x 5 ciclos de 10ns = 100ns.
// Verifica continuamente (a meio de cada ciclo de relogio) que:
//   - so o anodo do display selecionado esta ativo (a Low), e so se o enable estiver a 1;
//   - os segmentos sao os do simbolo guardado no registo desse display;
//   - o ponto decimal e o bit desse display no registo dos pontos;
//   - o varrimento avanca 0, 1, 2, 3, 0, ... de 100 em 100ns.
module controlodisplays_teste1();

//   Declaracao das entradas
     reg [3:0] D3 = 0, D2 = 0, D1 = 0, D0 = 0, DP = 0;
     reg [3:0] Load = 0, Clr = 0, En = 0;      // indice i = display i
     reg LoadDP = 0, ClrDP = 0;
     reg Clk = 0;

//   Declaracao das saidas
     wire [6:0] Segmentos;
     wire DotPoint;
     wire [3:0] Anodos;

//   Instanciacao da UUT e ligacao das entradas e saidas
     ControloDisplays #(.METADE(5)) UUT (
         .Data3(D3), .Load3(Load[3]), .Clr3(Clr[3]), .Enable3(En[3]),
         .Data2(D2), .Load2(Load[2]), .Clr2(Clr[2]), .Enable2(En[2]),
         .Data1(D1), .Load1(Load[1]), .Clr1(Clr[1]), .Enable1(En[1]),
         .Data0(D0), .Load0(Load[0]), .Clr0(Clr[0]), .Enable0(En[0]),
         .DotPoints(DP), .LoadDP(LoadDP), .ClrDP(ClrDP),
         .Clock(Clk),
         .Segmentos(Segmentos),
         .DotPoint(DotPoint),
         .Anodos(Anodos)
     );

//   Relogio de 100 MHz (periodo de 10ns), como o da Basys3
     always #5 Clk = ~Clk;

//   Selecao atual do varrimento (variaveis Control1 e Control0 do controlador)
     wire [1:0] Sel = {UUT.Control1, UUT.Control0};

//   Segmentos acesos (ativo a High) de cada simbolo, a partir da Fig. 30 e de "dIEGo-"
     reg [6:0] acesos [0:15];
     initial begin           //  abcdefg
         acesos[0]  = 7'b1111110;  acesos[1]  = 7'b0110000;
         acesos[2]  = 7'b1101101;  acesos[3]  = 7'b1111001;
         acesos[4]  = 7'b0110011;  acesos[5]  = 7'b1011011;
         acesos[6]  = 7'b1011111;  acesos[7]  = 7'b1110000;
         acesos[8]  = 7'b1111111;  acesos[9]  = 7'b1111011;
         acesos[10] = 7'b0111101;  acesos[11] = 7'b0000110;
         acesos[12] = 7'b1001111;  acesos[13] = 7'b1011110;
         acesos[14] = 7'b0011101;  acesos[15] = 7'b0000001;
     end

//   Modelo de referencia dos 5 registos (clear assincrono, carga no flanco ascendente)
     reg [3:0] ref3 = 0, ref2 = 0, ref1 = 0, ref0 = 0, refDP = 0;
     always @(posedge Clk or posedge Clr[3]) if (Clr[3]) ref3 <= 0; else if (Load[3]) ref3 <= D3;
     always @(posedge Clk or posedge Clr[2]) if (Clr[2]) ref2 <= 0; else if (Load[2]) ref2 <= D2;
     always @(posedge Clk or posedge Clr[1]) if (Clr[1]) ref1 <= 0; else if (Load[1]) ref1 <= D1;
     always @(posedge Clk or posedge Clr[0]) if (Clr[0]) ref0 <= 0; else if (Load[0]) ref0 <= D0;
     always @(posedge Clk or posedge ClrDP)  if (ClrDP)  refDP <= 0; else if (LoadDP) refDP <= DP;

//   Verificacao continua, a meio de cada ciclo de relogio:
//   compara as saidas com as esperadas para a selecao atual
     reg [3:0] valor;
     reg [6:0] seg_esperado;
     reg       dp_esperado;
     reg [3:0] an_esperado;
     integer erros = 0, verificacoes = 0;
     always @(negedge Clk) if ($time > 0) begin   // em t=0 a inicializacao de Clk conta como flanco
         case (Sel)
             2'd0: valor = ref0;
             2'd1: valor = ref1;
             2'd2: valor = ref2;
             2'd3: valor = ref3;
         endcase
         seg_esperado = ~acesos[valor];
         dp_esperado  = ~refDP[Sel];
         an_esperado  = ~((4'b0001 << Sel) & En);
         verificacoes = verificacoes + 1;
         if (Segmentos !== seg_esperado || DotPoint !== dp_esperado || Anodos !== an_esperado) begin
             if (erros < 10)
                 $display("ERRO t=%0t: Sel=%0d Seg=%b DP=%b An=%b (esperado Seg=%b DP=%b An=%b)",
                          $time, Sel, Segmentos, DotPoint, Anodos, seg_esperado, dp_esperado, an_esperado);
             erros = erros + 1;
         end
     end

//   Verificacao do varrimento: a selecao avanca 1 (modulo 4) a cada 2 x METADE ciclos
     integer ciclos = 0, trocas = 0;
     reg [1:0] sel_ant = 0;
     always @(posedge Clk) begin
         #1;
         ciclos = ciclos + 1;
         if (Sel !== sel_ant) begin
             if (Sel !== sel_ant + 2'd1) begin
                 $display("ERRO t=%0t: varrimento passou de %0d para %0d", $time, sel_ant, Sel);
                 erros = erros + 1;
             end
             if (trocas > 0 && ciclos != 10) begin
                 $display("ERRO t=%0t: display ativo durante %0d ciclos (esperado 10)", $time, ciclos);
                 erros = erros + 1;
             end
             trocas = trocas + 1;
             ciclos = 0;
             sel_ant = Sel;
         end
     end

//   Impulso de carga com a duracao de um ciclo de relogio (como uma tecla sincronizada)
     task carrega(input [3:0] quais, input [3:0] v3, v2, v1, v0);
         begin
             D3 = v3; D2 = v2; D1 = v1; D0 = v0;
             Load = quais;
             #10 Load = 4'b0000;
         end
     endtask

//   Definicao do valor das entradas ao longo do tempo
//   (as entradas mudam sempre 2ns depois de um flanco descendente)
     initial begin
         #202;                                  // configuracoes iniciais da FPGA
                                                // registos a 0 e displays desligados
         En = 4'b1111;              #400;       // 4 displays ligados: "0000"
         carrega(4'b1111, 4'd2, 4'd0, 4'd2, 4'd6);
                                    #400;       // "2026"
         DP = 4'b0100; LoadDP = 1;  #10 LoadDP = 0;
                                    #400;       // "20.26" (ponto no display 2)
         carrega(4'b0001, 4'd0, 4'd0, 4'd0, 4'd7);
                                    #400;       // "20.27": so o display 0 muda
         D1 = 4'd9;                 #400;       // sem Load o registo nao muda
         // cada registo carregado sozinho, com valores diferentes nas outras entradas
         carrega(4'b1000, 4'd10, 4'd11, 4'd12, 4'd13);   // so o display 3: "d0.27"
         carrega(4'b0100, 4'd10, 4'd11, 4'd12, 4'd13);   // so o display 2: "dI.27"
         carrega(4'b0010, 4'd10, 4'd11, 4'd12, 4'd13);   // so o display 1: "dI.E7"
         carrega(4'b0001, 4'd10, 4'd11, 4'd12, 4'd13);   // so o display 0: "dI.EG"
                                    #400;       // "dI.EG" (simbolos originais)
         En = 4'b1011;              #400;       // display 2 desligado: "d EG"
         #3 Clr[3] = 1; #4 Clr[3] = 0;          // clear assincrono, entre flancos
                                    #400;       // "0 EG"
         En = 4'b1111; ClrDP = 1;   #10 ClrDP = 0;
                                    #400;       // pontos apagados: "0IEG"
         Clr = 4'b1111;             #10 Clr = 4'b0000;
                                    #400;       // "0000"
         En = 4'b0000;              #400;       // todos os displays desligados

         if (trocas < 40) begin
             $display("ERRO: so houve %0d mudancas de display", trocas);
             erros = erros + 1;
         end
         if (erros == 0) $display("Simulacao OK: ControloDisplays sem erros (%0d verificacoes)", verificacoes);
         else            $display("Simulacao FALHOU: ControloDisplays com %0d erros", erros);
         $finish;
     end
endmodule
