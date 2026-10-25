`timescale 1ns / 1ps

// Testbench do circuito de teste na placa (TesteDisplays, Fig. 32).
// Reproduz o que se faz na Basys3: escolher um valor nos interruptores Data,
// ligar e desligar o interruptor LDx do display pretendido, etc.
// Vê o circuito só pelos pinos (caixa preta): descobre o display ativo pelos
// ânodos e confirma que os segmentos e o ponto são os que foram carregados nele.
// METADE = 5: cada display fica ativo 100ns (na placa são 0,5 ms).
module testedisplays_teste1();

//   Declaração das entradas
     reg [3:0] Data = 0;
     reg LD3 = 0, LD2 = 0, LD1 = 0, LD0 = 0, LDDP = 0;
     reg EN = 0, Clear = 0;
     reg CLKBasys = 0;

//   Declaração das saídas
     wire [6:0] Seg;
     wire DP;
     wire [3:0] An;

//   Instanciação da UUT e ligação das entradas e saídas
     TesteDisplays #(.METADE(5)) UUT (
         .Data(Data),
         .LD3(LD3), .LD2(LD2), .LD1(LD1), .LD0(LD0), .LDDP(LDDP),
         .EN(EN),
         .Clear(Clear),
         .CLKBasys(CLKBasys),
         .Seg(Seg),
         .DP(DP),
         .An(An)
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
     always @(An or Seg or DP or EN) begin
         case (An)
             4'b1110: DisplayAtivo = "0";   4'b1101: DisplayAtivo = "1";
             4'b1011: DisplayAtivo = "2";   4'b0111: DisplayAtivo = "3";
             default: DisplayAtivo = "-";
         endcase
         Mostra = (DisplayAtivo == "-") ? "  " : {simbolo(Seg), DP ? " " : "."};
         case (DisplayAtivo)
             "0": v0 = Mostra;  "1": v1 = Mostra;  "2": v2 = Mostra;  "3": v3 = Mostra;
         endcase
         if (!EN) {v3, v2, v1, v0} = {4{"  "}};   // displays desligados: apagados
         Placa = 0;                                  // sem espaços à esquerda
         for (j = 3; j >= 0; j = j - 1) begin
             t = (j == 3) ? v3 : (j == 2) ? v2 : (j == 1) ? v1 : v0;
             Placa = {Placa[55:0], t[15:8]};
             if (t[7:0] == ".") Placa = {Placa[55:0], "."};
         end
     end

//   Relógio de 100 MHz da Basys3
     always #5 CLKBasys = ~CLKBasys;

//   Segmentos acesos (ativo a High) de cada símbolo
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

//   O que deve estar guardado em cada display (atualizado como os registos)
     reg [3:0] mostra [0:3];
     reg [3:0] pontos = 0;
     integer i;
     initial for (i = 0; i < 4; i = i + 1) mostra[i] = 0;
     always @(posedge CLKBasys or posedge Clear)
         if (Clear) begin
             for (i = 0; i < 4; i = i + 1) mostra[i] <= 0;
             pontos <= 0;
         end
         else begin
             if (LD0)  mostra[0] <= Data;
             if (LD1)  mostra[1] <= Data;
             if (LD2)  mostra[2] <= Data;
             if (LD3)  mostra[3] <= Data;
             if (LDDP) pontos    <= Data;
         end

//   Verificação pelos pinos, a meio de cada ciclo de relógio
     integer erros = 0, verificacoes = 0, k;
     integer ativo, anterior = -1, visitas = 0;
     always @(negedge CLKBasys) if ($time > 0) begin   // em t=0 a inicialização do relógio conta como flanco
         verificacoes = verificacoes + 1;
         if (!EN) begin
             if (An !== 4'b1111) begin
                 $display("ERRO t=%0t: EN=0 mas An=%b", $time, An);
                 erros = erros + 1;
             end
         end
         else begin
             ativo = -1;
             for (k = 0; k < 4; k = k + 1)
                 if (An === ~(4'b0001 << k)) ativo = k;
             if (ativo < 0) begin
                 $display("ERRO t=%0t: An=%b (tem de haver exatamente um display ativo)", $time, An);
                 erros = erros + 1;
             end
             else begin
                 if (Seg !== ~acesos[mostra[ativo]] || DP !== ~pontos[ativo]) begin
                     $display("ERRO t=%0t: display %0d mostra Seg=%b DP=%b (esperado Seg=%b DP=%b)",
                              $time, ativo, Seg, DP, ~acesos[mostra[ativo]], ~pontos[ativo]);
                     erros = erros + 1;
                 end
                 // o display ativo tem de seguir a ordem 0, 1, 2, 3, 0, ...
                 if (anterior >= 0 && ativo != anterior && ativo != (anterior + 1) % 4) begin
                     $display("ERRO t=%0t: o varrimento saltou do display %0d para o %0d", $time, anterior, ativo);
                     erros = erros + 1;
                 end
                 if (ativo != anterior) visitas = visitas + 1;
                 anterior = ativo;
             end
         end
     end

//   Carregar um valor num display: escolher Data e ligar/desligar o interruptor LDx
     task escreve(input integer display, input [3:0] valor);
         begin
             Data = valor; #20;
             case (display)
                 0: LD0 = 1;  1: LD1 = 1;  2: LD2 = 1;  3: LD3 = 1;  default: LDDP = 1;
             endcase
             #30;
             {LD3, LD2, LD1, LD0, LDDP} = 5'b00000;
             #20;
         end
     endtask

//   Definição do valor das entradas ao longo do tempo
     initial begin
         #202;                         // configurações iniciais da FPGA
                                       // (as entradas mudam 2ns depois de um flanco descendente)
         EN = 1;          #400;        // displays ligados: "0000"
         escreve(3, 4'd10);            // r no display da esquerda
         escreve(2, 4'd11);            // d
         escreve(1, 4'd12);            // L
         escreve(0, 4'd13);            // E
                          #400;        // "rdLE"
         escreve(4, 4'b0101);          // pontos nos displays 2 e 0: "rd.LE."
                          #400;
         escreve(1, 4'd14);            // C
         escreve(0, 4'd15);            // -
                          #400;        // "rd.C-."
         Data = 4'd8;     #400;        // mudar Data sem carregar não altera nada
         EN = 0;          #400;        // displays desligados
         EN = 1;          #400;        // voltam a mostrar o mesmo
         #3 Clear = 1;    #20 Clear = 0;
                          #400;        // tudo a 0 e pontos apagados: "0000"

         if (visitas < 30) begin
             $display("ERRO: o varrimento so passou por %0d displays", visitas);
             erros = erros + 1;
         end
         if (erros == 0) $display("Simulacao OK: TesteDisplays sem erros (%0d verificacoes)", verificacoes);
         else            $display("Simulacao FALHOU: TesteDisplays com %0d erros", erros);
         $finish;
     end
endmodule
