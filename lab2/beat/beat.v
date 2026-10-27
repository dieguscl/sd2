`timescale 1ns / 1ps

// Flip-flop T do LED Beat, feito com uma primitiva FDCE com D = /Q.
// Em cada flanco ascendente do relógio com Tgl a 1 o LED troca de estado,
// por isso pisca ao ritmo do temporizador variável (Tgl = TglBeat, uma vez por passo).
// CLR apaga o LED de forma assíncrona.
module Beat(
    input Clk,
    input Tgl,
    input CLR,
    output Q
    );

     wire nQ;

     not inv (nQ, Q);
     FDCE #(.INIT(1'b0)) ff (.Q(Q), .C(Clk), .CE(Tgl), .CLR(CLR), .D(nQ));

endmodule
