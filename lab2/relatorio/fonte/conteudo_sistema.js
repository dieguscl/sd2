// Seccoes 10 a 12 e anexo A: integracao do sistema, ensaio na placa, analise critica, conclusao e testbenches.
const { P, Bullet, Num, H1, H2, Figura, FiguraPorTirar, Tabela, Listagem } = require('./lib');
const { AlignmentType } = require('docx');

// Texto a completar depois do ensaio na placa (a vermelho, para nao passar despercebido)
const PorFazer = texto => P('[A COMPLETAR NO LABORATÓRIO: ' + texto + ']', { run: { color: 'C00000', bold: true } });

module.exports = function sistema(N, R) {
  const r = id => N.ref(id);
  const esq = n => Object.fromEntries([...Array(n).keys()].map(i => [i, AlignmentType.LEFT]));
  return [
    // =====================================================================================
    H1('10 Integração do sistema'),
    H2('10.1 Circuito de topo'),
    P('O `GuitarHero` (' + r('lst_gh') + ') liga o controlador à arquitetura a controlar, conforme a ' + r('fig_arq') + ': as ligações são feitas pelo nome do sinal (ClrMem, ShiftMem, Tempo, …). Os tempos longos são parâmetros (`METADE` do varrimento, `ESTAVEL` do anti-ressalto e `INICIAL`, `PASSO` e `MINIMO` do temporizador), com os valores reais por omissão e valores curtos no *testbench*.'),
    ...Listagem(N, 'lst_gh', 'guitarhero/guitarhero.v', 'Circuito de topo: controlador e arquitetura a controlar'),

    H2('10.2 Restrições e implementação'),
    P('A ' + r('tab_pinos') + ' mostra a ligação dos sinais à Basys3 (' + r('lst_xdc') + '). A tecla Start é a tecla central (BTNC) e o Reset a tecla de cima (BTNU).'),
    ...Tabela(N, 'tab_pinos', 'Ligação dos sinais do circuito de topo à Basys3.',
      ['Sinal', 'Pino(s)', 'Elemento da Basys3'],
      [['CLKBasys', 'W5', 'Oscilador de 100 MHz'],
       ['BtnReset', 'T18', 'Tecla BTNU'],
       ['BtnStart', 'U18', 'Tecla BTNC'],
       ['LedReady / LedBeat / LedWaiting', 'U16 / E19 / U19', 'LEDs LD0 / LD1 / LD2'],
       ['LedEstado[0] a LedEstado[5]', 'W3 U3 P3 N3 P1 L1', 'LEDs LD10 a LD15 (S0 a S5)'],
       ['Seg[6:0]', 'W7 W6 U8 V8 U5 V5 U7', 'Segmentos CA a CG (ativos a *Low*)'],
       ['DP', 'V7', 'Ponto decimal (ativo a *Low*)'],
       ['An[3:0]', 'W4 V4 U4 U2', 'Ânodos AN3 a AN0 (ativos a *Low*)']],
      [2.8, 2.4, 3], { largura: 9000 }),
    P('Como no 1.º trabalho, as restrições definem o relógio de 100 MHz e o relógio do varrimento gerado pelo `DivisorClock` (divisão por 50 000), e o caminho de realimentação do divisor entre os dois relógios é declarado como falso, para evitar o aviso crítico TIMING-8. As teclas (que passam pelos sincronizadores), os LEDs e os *displays* não têm requisitos temporais. A implementação cumpre todas as restrições, com uma folga (WNS) de ' + R.wns + ' ns, e ocupa ' + R.util.lut + ' LUT e ' + R.util.ff + ' *flip-flops*. O relatório de travessias entre domínios de relógio (`report_cdc`) não tem avisos críticos: os únicos sinais assíncronos, as teclas, chegam aos sincronizadores com `ASYNC_REG`.'),
    ...Listagem(N, 'lst_xdc', 'guitarhero/guitarhero.xdc', 'Ficheiro de restrições do circuito de topo'),

    H2('10.3 Simulação do sistema completo'),
    P('O *testbench* do sistema (' + r('lst_gh_tb') + ', no Anexo A) usa `METADE = 2`, `ESTAVEL = 4` e um temporizador com `INICIAL = 40`, `PASSO = 4` e `MINIMO = 20` ciclos. É independente da implementação: tem o seu próprio modelo do LFSR e uma fila de referência para a memória, comandados apenas pelos LEDs dos estados (S0 limpa a fila e carrega a semente, S3 desloca). Em cada ciclo verifica que:'),
    Bullet('há um e um só estado ativo e os LEDs Ready e Waiting correspondem ao estado;'),
    Bullet('a memória é igual à fila de referência e o *display* ativo mostra a corda da posição certa;'),
    Bullet('o LED Beat troca de estado uma vez por passo;'),
    Bullet('o intervalo entre passos é o período do temporizador mais 3 ciclos (40, 36, 32, … até 20).'),
    P('O percurso inclui o Reset (ativação imediata e libertação síncrona), a espera em S1, a tecla Start com ressaltos, 12 passos do jogo, um Reset a meio do jogo e um novo jogo, que tem de recomeçar com o período inicial. Resultado: `Simulacao OK (' + R.ver.guitarhero_teste1 + ' verificacoes)`.'),
    P('Na ' + r('fig_viv_gh') + ' vê-se o jogo completo: depois do Reset, Ready acende (S1); `Start` (já sem ressaltos) leva a máquina a S2 e, quando é largada, o jogo começa. As cordas entram em `Pos0` e avançam até `Pos3`, `Periodo` diminui de 40 para 20 ciclos e o LED Beat troca a cada passo. O Reset a meio do jogo limpa a memória e o LED Beat e repõe o período de 40 ciclos.'),
    ...Figura(N, 'fig_viv_gh', 'viv_guitarhero_sim.png', 16.9, 'Simulação do sistema completo: Reset, Start, 12 passos do jogo, Reset a meio do jogo e novo jogo.'),
    P('A ' + r('fig_viv_gh_det') + ' mostra o primeiro passo em pormenor. Quando `Start` volta a 0, a máquina passa de S2 a S3: nesse ciclo ShiftMem carrega a corda do LFSR (11) em `Pos0` e StartTemp inicia o temporizador, que mantém `Tempo` a 1 durante 40 ciclos (S4). Quando `Tempo` volta a 0, a máquina passa por S5 (Faster: o período passa a 36) e regressa a S3, onde a corda seguinte (01) entra em `Pos0` e o 11 passa para `Pos1`. Entre os dois passos decorrem 43 ciclos (40 + 3).'),
    ...Figura(N, 'fig_viv_gh_det', 'viv_guitarhero_detalhe_sim.png', 16.9, 'Pormenor da simulação do sistema: dois passos do jogo (S3, S4, S5 e S3).'),

    H2('10.4 Integração faseada e ensaio na placa'),
    P('A integração foi feita módulo a módulo, como pede o enunciado: cada módulo foi simulado isoladamente (secções 3 a 8), depois o controlador sozinho (secção 9.9) e, por fim, o sistema completo (secção 10.3). Na placa, o ensaio segue a ordem da ' + r('tab_ensaio') + '; os LEDs LD10 a LD15 mostram em cada instante o *flip-flop* ativo, o que permite seguir o fluxograma na própria placa.'),
    ...Tabela(N, 'tab_ensaio', 'Procedimento de ensaio na Basys3 e resultado esperado.',
      ['Passo', 'Ação', 'Resultado esperado'],
      [['1', 'Programar a FPGA com `guitarhero.bit`', 'Displays apagados; LD11 (S1) e LD0 (Ready) acesos'],
       ['2', 'Carregar BTNC (Start) e mantê-la carregada', 'LD12 (S2) aceso; Ready continua aceso; displays apagados'],
       ['3', 'Largar BTNC', 'Ready apaga; LD14 (S4) e LD2 (Waiting) acesos; as cordas entram pelo *display* da esquerda e avançam para a direita a cada 0,5 s; LD1 (Beat) troca a cada passo'],
       ['4', 'Esperar cerca de 20 s', 'A sequência acelera até 0,2 s por passo e mantém essa velocidade'],
       ['5', 'Carregar BTNU (Reset) a meio do jogo', 'Displays e LD1 apagam de imediato; LD10 (S0) aceso enquanto a tecla está carregada'],
       ['6', 'Largar BTNU e repetir os passos 2 e 3', 'Novo jogo, outra vez a 0,5 s por passo e com outra sequência de cordas']],
      [0.8, 3.2, 5.2], { juntar: true, alinhar: { 1: AlignmentType.LEFT, 2: AlignmentType.LEFT } }),
    PorFazer('confirmar o resultado de cada passo da ' + r('tab_ensaio') + ' e substituir as fotografias abaixo'),
    ...FiguraPorTirar(N, 'fig_placa_reset', 'Ensaio na placa Basys3 depois do Reset: LED Ready e LD11 (S1) acesos, *displays* apagados.', 'fotografia da placa depois do Reset (passo 1)'),
    ...FiguraPorTirar(N, 'fig_placa_jogo', 'Ensaio na placa Basys3 durante o jogo: cordas nos quatro *displays*, LEDs Waiting e LD14 (S4) acesos.', 'fotografia da placa durante o jogo (passo 3)'),

    // =====================================================================================
    H1('11 Análise crítica do código de fontes externas'),
    H2('11.1 LFSR do enunciado'),
    P('O `LFSR32` do enunciado funciona e as derivações estão certas (32, 22, 2 e 1 na XAPP052 para 32 *bits*), mas tem alguns pormenores a notar:'),
    Bullet('o comentário pede uma semente "<> 0", o que é válido para um LFSR com XOR; com XNOR o estado proibido é tudo a 1 e o 0 é um estado válido (é, aliás, o valor do registo depois de configurar a FPGA). A semente `32\'h03E3180A` serve nos dois casos;'),
    Bullet('`Init` só atua com `Enable` a 1, porque está dentro do `if (Enable)`: o estado inicial da máquina tem de ativar InitLFSR e EnLFSR ao mesmo tempo;'),
    Bullet('o valor inicial de `regXNOR` (`reg regXNOR = 1`) não tem efeito, porque é um sinal combinatório atribuído num `always @(*)`;'),
    Bullet('`OutLFSR` usa os *bits* 31 e 0, que em ciclos consecutivos estão correlacionados (o LFSR desloca um *bit* por ciclo); como a memória só lê um par de *bits* a cada `Periodo` + 3 ciclos, os pares lidos são praticamente independentes, o que a simulação confirmou (cerca de 25 % para cada corda).'),
    P('O código foi usado sem alterações, só com comentários.'),
    H2('11.2 Módulos do 1.º trabalho'),
    P('O `Registo4`, o `DivisorClock`, o `Contador4`, o `multiplexer16x4` e o `descodificador2x4` foram reutilizados sem alterações: os projetos e os *scripts* do 2.º trabalho referem os ficheiros da pasta do 1.º trabalho, sem os copiar, pelo que uma correção feita num módulo passa a valer nos dois trabalhos. O transcodificador foi substituído por uma versão nova (`TranscodCordas`), porque a função é diferente (um segmento horizontal por corda).'),
    H2('11.3 Primitivas FDPE e FDCE'),
    P('As primitivas seguem os modelos do Vivado: `PRE` e `CLR` são assíncronos e ativos a *High*, `CE` é ativo a *High* e `INIT` define o valor depois de configurar a FPGA. FF_S0 tem `INIT = 1` e os outros `INIT = 0`, pelo que a máquina arranca em S0 mesmo sem carregar Reset; o sincronizador do Reset também tem `INIT = 1`, mantendo o Reset ativo durante os dois primeiros ciclos depois da configuração.'),
    H2('11.4 IA generativa'),
    P('Foi usada IA generativa como apoio na escrita dos *testbenches* e dos modelos de referência, na revisão do código Verilog e dos comentários, na preparação dos diagramas no draw.io e na correção da redação deste relatório, bem como para confirmar que o relatório inclui os elementos pedidos no enunciado. Todo o código e todos os diagramas foram revistos pelo grupo e as simulações foram corridas e analisadas pelo grupo.'),

    // =====================================================================================
    H1('12 Conclusão'),
    P('Desenvolveu-se o sistema de gestão dos *displays* do jogo Guitar Hero: um LFSR de 32 *bits* gera a sequência de cordas e pausas, uma memória 4x2 guarda o que cada *display* mostra e um temporizador variável define e acelera o ritmo do jogo. A gestão dos *displays* reutilizou o sistema do 1.º trabalho, com um novo transcodificador.'),
    P('O controlador, o cerne do trabalho, foi desenhado a partir do fluxograma pelos 11 passos da metodologia e realizado de forma direta, com um *flip-flop* por estado, no modelo estrutural: cada *flip-flop* corresponde a um estado do fluxograma e cada porta a um termo das equações, o que o esquema RTL do Vivado confirmou. O trabalho mostrou também a importância da sincronização das entradas assíncronas: a tecla Start precisa de sincronizador e anti-ressalto, e a libertação do Reset tem de ser síncrona para evitar uma corrida crítica que deixaria a máquina sem estado ativo.'),
    P('Os ' + R.numTestbenches + ' *testbenches* (um por módulo, o do controlador e o do sistema completo) comparam as saídas com modelos de referência e terminam todos com `Simulacao OK`; a implementação cumpre as restrições temporais.'),
    PorFazer('acrescentar o resultado do ensaio na placa Basys3 (secção 10.4)'),

    // =====================================================================================
    H1('Anexo A Testbenches'),
    P('Listagens dos *testbenches* das secções 3 a 10. Todos verificam as saídas automaticamente e terminam com `Simulacao OK` ou `Simulacao FALHOU`; as vistas das formas de onda usadas nas figuras estão nos ficheiros `.wcfg` ao lado de cada *testbench*.'),
    ...Listagem(N, 'lst_sinc_tb', 'sincronizador/sincronizador_teste1.v', '*Testbench* do sincronizador da tecla Start'),
    ...Listagem(N, 'lst_sincr_tb', 'sincronizador/sincronizadorreset_teste1.v', '*Testbench* do sincronizador do Reset'),
    ...Listagem(N, 'lst_lfsr_tb', 'lfsr32/lfsr32_teste1.v', '*Testbench* do LFSR de 32 *bits*'),
    ...Listagem(N, 'lst_mem_tb', 'memoria4x2/memoria4x2_teste1.v', '*Testbench* da memória 4x2'),
    ...Listagem(N, 'lst_temp_tb', 'temporizador/temporizador_teste1.v', '*Testbench* do temporizador'),
    ...Listagem(N, 'lst_tv_tb', 'temporizador/temporizadorvariavel_teste1.v', '*Testbench* do temporizador variável'),
    ...Listagem(N, 'lst_beat_tb', 'beat/beat_teste1.v', '*Testbench* do *flip-flop* T do LED Beat'),
    ...Listagem(N, 'lst_ges_tb', 'gestaodisplays/gestaodisplays_teste1.v', '*Testbench* da gestão dos *displays*'),
    ...Listagem(N, 'lst_ctl_tb', 'controlador/controlador_teste1.v', '*Testbench* do controlador'),
    ...Listagem(N, 'lst_gh_tb', 'guitarhero/guitarhero_teste1.v', '*Testbench* do sistema completo'),
  ];
};
