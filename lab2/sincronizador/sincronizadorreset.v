`timescale 1ns / 1ps

// Sincronizador da tecla Reset: ativação assíncrona, libertação síncrona.
// Dois flip-flops FDPE em série com PRE = Entrada:
//   - ao carregar Reset, Saida vai a 1 de imediato, sem esperar pelo relógio
//     (a máquina de estados é posta em S0 de forma assíncrona, secção 2.7);
//   - ao largar Reset, Saida só volta a 0 no 2.º flanco ascendente do relógio.
// Sem isto, se a tecla fosse largada mesmo junto a um flanco, FF_S0 podia sair do PRE
// (e carregar D = 0) antes de FF_S1 sair do CLR, e a máquina ficava sem nenhum estado ativo.
// INIT = 1: depois de configurar a FPGA o Reset também é libertado de forma síncrona.
module SincronizadorReset(
    input Clock,
    input Entrada,
    output Saida
    );

     wire q1;

     (* ASYNC_REG = "TRUE" *) FDPE #(.INIT(1'b1)) ff1 (.Q(q1),    .C(Clock), .CE(1'b1), .PRE(Entrada), .D(1'b0));
     (* ASYNC_REG = "TRUE" *) FDPE #(.INIT(1'b1)) ff2 (.Q(Saida), .C(Clock), .CE(1'b1), .PRE(Entrada), .D(q1));

endmodule
