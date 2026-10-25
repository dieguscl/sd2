`timescale 1ns / 1ps

// Testbench do controlador dos displays (ControloDisplays).
// Usa METADE = 5 para o varrimento ser visível em poucas centenas de ns:
// cada display fica ativo durante 2 x 5 ciclos de 10ns = 100ns.
// Verifica continuamente (a meio de cada ciclo de relógio) que:
//   - só o ânodo do display selecionado está ativo (a Low), e só se o enable estiver a 1;
//   - os segmentos são os do símbolo guardado no registo desse display;
//   - o ponto decimal é o bit desse display no registo dos pontos;
//   - o varrimento avança 0, 1, 2, 3, 0, ... de 100 em 100ns.
module controlodisplays_teste1();

//   Declaração das entradas
     reg [3:0] D3 = 0, D2 = 0, D1 = 0, D0 = 0, DP = 0;
     reg [3:0] Load = 0, Clr = 0, En = 0;      // índice i = display i
     reg LoadDP = 0, ClrDP = 0;
     reg Clk = 0;

//   Declaração das saídas
     wire [6:0] Segmentos;
     wire DotPoint;
     wire [3:0] Anodos;

//   Instanciação da UUT e ligação das entradas e saídas
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

//   Apenas para ler as formas de onda (base ASCII no Vivado): traduz as saídas no que
//   se vê na placa. Não intervém na verificação.
//     DisplayAtivo: display aceso neste instante ("0" a "3", "-" se nenhum)
//     Mostra:       símbolo desse display, seguido de "." se o ponto decimal estiver aceso
//     Placa:        o que se vê nos quatro displays, da esquerda (3) para a direita (0)
     function [7:0] simbolo(input [6:0] s);          // segmentos (ativos a Low) -> carácter
         case (s)
             7'b0000001: simbolo = "0";  7'b1001111: simbolo = "1";
             7'b0010010: simbolo = "2";  7'b0000110: simbolo = "3";
             7'b1001100: simbolo = "4";  7'b0100100: simbolo = "5";
             7'b0100000: simbolo = "6";  7'b0001111: simbolo = "7";
             7'b0000000: simbolo = "8";  7'b0000100: simbolo = "9";
             7'b1111010: simbolo = "r";  7'b1000010: simbolo = "d";
             7'b1110001: simbolo = "L";  7'b0110000: simbolo = "E";
             7'b0110001: simbolo = "C";  7'b1111110: simbolo = "-";
             default:    simbolo = "?";
         endcase
     endfunction
     reg [7:0]  DisplayAtivo = "-";
     reg [15:0] Mostra = "  ";
     reg [15:0] v3 = "  ", v2 = "  ", v1 = "  ", v0 = "  ";   // último símbolo visto em cada display
     reg [63:0] Placa = 0;
     reg [15:0] t;
     integer j;
     always @(Anodos or Segmentos or DotPoint or En) begin
         case (Anodos)
             4'b1110: DisplayAtivo = "0";   4'b1101: DisplayAtivo = "1";
             4'b1011: DisplayAtivo = "2";   4'b0111: DisplayAtivo = "3";
             default: DisplayAtivo = "-";
         endcase
         Mostra = (DisplayAtivo == "-") ? "  " : {simbolo(Segmentos), DotPoint ? " " : "."};
         case (DisplayAtivo)
             "0": v0 = Mostra;  "1": v1 = Mostra;  "2": v2 = Mostra;  "3": v3 = Mostra;
         endcase
         if (!En[3]) v3 = "  ";      // display desligado: apagado
         if (!En[2]) v2 = "  ";
         if (!En[1]) v1 = "  ";
         if (!En[0]) v0 = "  ";
         Placa = 0;                                  // sem espaços à esquerda
         for (j = 3; j >= 0; j = j - 1) begin
             t = (j == 3) ? v3 : (j == 2) ? v2 : (j == 1) ? v1 : v0;
             Placa = {Placa[55:0], t[15:8]};
             if (t[7:0] == ".") Placa = {Placa[55:0], "."};
         end
     end

//   Relógio de 100 MHz (período de 10ns), como o da Basys3
     always #5 Clk = ~Clk;

//   Seleção atual do varrimento (variáveis Control1 e Control0 do controlador)
     wire [1:0] Sel = {UUT.Control1, UUT.Control0};

//   Segmentos acesos (ativo a High) de cada símbolo, a partir da Fig. 30 e de "rdLEC-"
     reg [6:0] acesos [0:15];
     initial begin           //  abcdefg
         acesos[0]  = 7'b1111110;  acesos[1]  = 7'b0110000;
         acesos[2]  = 7'b1101101;  acesos[3]  = 7'b1111001;
         acesos[4]  = 7'b0110011;  acesos[5]  = 7'b1011011;
         acesos[6]  = 7'b1011111;  acesos[7]  = 7'b1110000;
         acesos[8]  = 7'b1111111;  acesos[9]  = 7'b1111011;
         acesos[10] = 7'b0000101;  acesos[11] = 7'b0111101;
         acesos[12] = 7'b0001110;  acesos[13] = 7'b1001111;
         acesos[14] = 7'b1001110;  acesos[15] = 7'b0000001;
     end

//   Modelo de referência dos 5 registos (clear assíncrono, carga no flanco ascendente)
     reg [3:0] ref3 = 0, ref2 = 0, ref1 = 0, ref0 = 0, refDP = 0;
     always @(posedge Clk or posedge Clr[3]) if (Clr[3]) ref3 <= 0; else if (Load[3]) ref3 <= D3;
     always @(posedge Clk or posedge Clr[2]) if (Clr[2]) ref2 <= 0; else if (Load[2]) ref2 <= D2;
     always @(posedge Clk or posedge Clr[1]) if (Clr[1]) ref1 <= 0; else if (Load[1]) ref1 <= D1;
     always @(posedge Clk or posedge Clr[0]) if (Clr[0]) ref0 <= 0; else if (Load[0]) ref0 <= D0;
     always @(posedge Clk or posedge ClrDP)  if (ClrDP)  refDP <= 0; else if (LoadDP) refDP <= DP;

//   Verificação contínua, a meio de cada ciclo de relógio:
//   compara as saídas com as esperadas para a seleção atual
     reg [3:0] valor;
     reg [6:0] seg_esperado;
     reg       dp_esperado;
     reg [3:0] an_esperado;
     integer erros = 0, verificacoes = 0;
     always @(negedge Clk) if ($time > 0) begin   // em t=0 a inicialização de Clk conta como flanco
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

//   Verificação do varrimento: a seleção avança 1 (módulo 4) a cada 2 x METADE ciclos
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

//   Impulso de carga com a duração de um ciclo de relógio (como uma tecla sincronizada)
     task carrega(input [3:0] quais, input [3:0] v3, v2, v1, v0);
         begin
             D3 = v3; D2 = v2; D1 = v1; D0 = v0;
             Load = quais;
             #10 Load = 4'b0000;
         end
     endtask

//   Definição do valor das entradas ao longo do tempo
//   (as entradas mudam sempre 2ns depois de um flanco descendente)
     initial begin
         #202;                                  // configurações iniciais da FPGA
                                                // registos a 0 e displays desligados
         En = 4'b1111;              #400;       // 4 displays ligados: "0000"
         carrega(4'b1111, 4'd2, 4'd0, 4'd2, 4'd6);
                                    #400;       // "2026"
         DP = 4'b0100; LoadDP = 1;  #10 LoadDP = 0;
                                    #400;       // "20.26" (ponto no display 2)
         carrega(4'b0001, 4'd0, 4'd0, 4'd0, 4'd7);
                                    #400;       // "20.27": só o display 0 muda
         D1 = 4'd9;                 #400;       // sem Load o registo não muda
         // cada registo carregado sozinho, com valores diferentes nas outras entradas
         carrega(4'b1000, 4'd10, 4'd11, 4'd12, 4'd13);   // só o display 3: "r0.27"
         carrega(4'b0100, 4'd10, 4'd11, 4'd12, 4'd13);   // só o display 2: "rd.27"
         carrega(4'b0010, 4'd10, 4'd11, 4'd12, 4'd13);   // só o display 1: "rd.L7"
         carrega(4'b0001, 4'd10, 4'd11, 4'd12, 4'd13);   // só o display 0: "rd.LE"
                                    #400;       // "rd.LE" (símbolos originais)
         En = 4'b1011;              #400;       // display 2 desligado: "r LE"
         #3 Clr[3] = 1; #4 Clr[3] = 0;          // clear assíncrono, entre flancos
                                    #400;       // "0 LE"
         En = 4'b1111; ClrDP = 1;   #10 ClrDP = 0;
                                    #400;       // pontos apagados: "0dLE"
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
