`timescale 1ns / 1ps

// Controlador: máquina de estados síncrona por realização direta (um flip-flop por estado),
// descrita no modelo estrutural a partir do fluxograma (aula 1):
//
//   S0 INICIA       ClrMem, InitLFSR, EnLFSR, RstTemp                    -> S1
//   S1 ESPERA_START Ready, EnLFSR             Start = 1 -> S2,  senão fica em S1
//   S2 LIBERTA      Ready, EnLFSR             Start = 0 -> S3,  senão fica em S2
//   S3 DESLOCA      ShiftMem, TglBeat, StartTemp, EnLFSR                 -> S4
//   S4 ESPERA_TEMPO Waiting, EnLFSR           Tempo = 0 -> S5,  senão fica em S4
//   S5 ACELERA      Faster, EnLFSR            (opcional)                 -> S3
//
// Flip-flop FF_Sk = estado Sk: só um está a 1 em cada instante (codificação one-hot).
// Reset (tecla) põe a máquina em S0 de forma assíncrona: PRE do FF_S0 e CLR dos restantes.
// Os outros elementos da arquitetura são inicializados pelas saídas do estado S0.
// As decisões são produtos lógicos (AND) do estado com a condição testada (desmultiplexer)
// e a reunião de percursos que entram no mesmo estado é uma soma lógica (OR).
// Todas as saídas são de Moore: soma lógica dos estados em que estão ativas.
module Controlador(
    input Clock,
    input Reset,                    // assíncrono, ativo a High
    input Start,                    // tecla Start já sincronizada (1 = premida)
    input Tempo,                    // 1 enquanto o temporizador variável conta
    output ClrMem,                  // limpa a memória e o LED Beat
    output InitLFSR,                // carrega a semente no LFSR
    output EnLFSR,                  // habilita o LFSR (avança livremente)
    output ShiftMem,                // desloca a memória e carrega a corda nova
    output RstTemp,                 // inicializa o temporizador variável
    output StartTemp,               // começa nova contagem do temporizador
    output Faster,                  // encurta o período do temporizador
    output TglBeat,                 // troca o estado do LED Beat
    output Ready,                   // LED Ready
    output Waiting,                 // LED Waiting
    output [5:0] Estado             // Q dos 6 flip-flops (LEDs de depuração)
    );

//   Estados (saídas Q dos flip-flops) e respetivas entradas D (estado seguinte)
     wire S0, S1, S2, S3, S4, S5;
     wire D0, D1, D2, D3, D4, D5;

//   Condições negadas e percursos de saída das decisões
     wire nStart, nTempo;
     wire S1_nStart, S1_Start;      // decisão de S1 (Start = 1 ?)
     wire S2_Start, S2_nStart;      // decisão de S2 (Start = 0 ?)
     wire S4_Tempo, S4_nTempo;      // decisão de S4 (Tempo = 1 ?)

//   ---------------------------------------------------------------- flip-flops (um por estado)
     FDPE #(.INIT(1'b1)) FF_S0 (.Q(S0), .C(Clock), .CE(1'b1), .PRE(Reset), .D(D0));
     FDCE #(.INIT(1'b0)) FF_S1 (.Q(S1), .C(Clock), .CE(1'b1), .CLR(Reset), .D(D1));
     FDCE #(.INIT(1'b0)) FF_S2 (.Q(S2), .C(Clock), .CE(1'b1), .CLR(Reset), .D(D2));
     FDCE #(.INIT(1'b0)) FF_S3 (.Q(S3), .C(Clock), .CE(1'b1), .CLR(Reset), .D(D3));
     FDCE #(.INIT(1'b0)) FF_S4 (.Q(S4), .C(Clock), .CE(1'b1), .CLR(Reset), .D(D4));
     FDCE #(.INIT(1'b0)) FF_S5 (.Q(S5), .C(Clock), .CE(1'b1), .CLR(Reset), .D(D5));

//   ---------------------------------------------------------------- decisões
     not inv_start (nStart, Start);
     not inv_tempo (nTempo, Tempo);

     and dec_s1_0 (S1_nStart, S1, nStart);  // S1 com Start = 0: fica em S1
     and dec_s1_1 (S1_Start,  S1, Start);   // S1 com Start = 1: vai para S2
     and dec_s2_1 (S2_Start,  S2, Start);   // S2 com Start = 1: fica em S2
     and dec_s2_0 (S2_nStart, S2, nStart);  // S2 com Start = 0: vai para S3
     and dec_s4_1 (S4_Tempo,  S4, Tempo);   // S4 com Tempo = 1: fica em S4
     and dec_s4_0 (S4_nTempo, S4, nTempo);  // S4 com Tempo = 0: vai para S5

//   ---------------------------------------------------------------- estado seguinte
     buf  ns0 (D0, 1'b0);                   // nenhum percurso entra em S0 (só a tecla Reset)
     or   ns1 (D1, S0, S1_nStart);          // D1 = S0 + S1./Start
     or   ns2 (D2, S1_Start, S2_Start);     // D2 = S1.Start + S2.Start
     or   ns3 (D3, S2_nStart, S5);          // D3 = S2./Start + S5
     or   ns4 (D4, S3, S4_Tempo);           // D4 = S3 + S4.Tempo
     buf  ns5 (D5, S4_nTempo);              // D5 = S4./Tempo

//   ---------------------------------------------------------------- saídas (Moore)
     buf  o_clrmem   (ClrMem,    S0);
     buf  o_initlfsr (InitLFSR,  S0);
     buf  o_rsttemp  (RstTemp,   S0);
     or   o_enlfsr   (EnLFSR,    S0, S1, S2, S3, S4, S5);
     or   o_ready    (Ready,     S1, S2);
     buf  o_shiftmem (ShiftMem,  S3);
     buf  o_tglbeat  (TglBeat,   S3);
     buf  o_starttemp(StartTemp, S3);
     buf  o_waiting  (Waiting,   S4);
     buf  o_faster   (Faster,    S5);

     assign Estado = {S5, S4, S3, S2, S1, S0};

endmodule
