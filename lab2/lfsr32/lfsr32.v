`timescale 1ns / 1ps

// LFSR de 32 bits que gera a sequência pseudo-aleatória das cordas a tocar.
// Código do enunciado (secção 2.2), com realimentação XNOR nas saídas 32, 22, 2 e 1
// (tabela da nota de aplicação Xilinx XAPP052), o que dá um período de 2^32 - 1 ciclos.
// Com XNOR o estado proibido é 32'hFFFFFFFF (o LFSR ficaria parado), por isso a semente
// tem de ser diferente de tudo a 1; o estado 0 é válido.
// Init e Enable são comandados pela máquina de estados (InitLFSR e EnLFSR):
//   Enable = 1 e Init = 1: carrega a semente;
//   Enable = 1 e Init = 0: avança um passo em cada ciclo de relógio;
//   Enable = 0:            mantém o estado.
// OutLFSR (2 bits) escolhe a corda: 00 pausa, 01 cima, 10 meio, 11 baixo.
module LFSR32 #(
    parameter SEED = 32'h03E3180A   // semente aleatória, diferente de 32'hFFFFFFFF
    )(
    input Clock,
    input Enable,
    input Init,
    output [1:0] OutLFSR
    );

     reg [31:0] regLFSR = 0;
     reg regXNOR = 1;

//   Registo de deslocamento: carrega a semente ou desloca para a esquerda
     always @(posedge Clock)
         if (Enable) begin
             if (Init)
                 regLFSR <= SEED;
             else
                 regLFSR[31:0] <= {regLFSR[30:0], regXNOR};
         end

//   Realimentação: XNOR das saídas 32, 22, 2 e 1 (bits 31, 21, 1 e 0)
     always @(*)
         regXNOR = regLFSR[31] ~^ regLFSR[21] ~^ regLFSR[1] ~^ regLFSR[0];

     assign OutLFSR = {regLFSR[31], regLFSR[0]};

endmodule
