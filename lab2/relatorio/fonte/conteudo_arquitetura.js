// Seccoes 1 a 8 do relatorio: introducao, arquitetura do sistema e modulos da arquitetura a controlar.
const { P, Bullet, Num, H1, H2, Figura, Tabela, Listagem } = require('./lib');
const { AlignmentType } = require('docx');

module.exports = function arquitetura(N, R) {
  const r = id => N.ref(id);
  const esq = n => Object.fromEntries([...Array(n).keys()].map(i => [i, AlignmentType.LEFT]));
  return [
    // =====================================================================================
    H1('1 Introdução', false),
    P('Este relatório descreve o 2.º Trabalho de Laboratório de Sistemas Digitais II: um sistema para a gestão dos *displays* de 7 segmentos do jogo Guitar Hero na placa Basys3. Um LFSR de 32 *bits* gera uma sequência pseudo-aleatória de cordas e pausas, uma memória de 4x2 *bits* guarda as cordas mostradas nos quatro *displays* e um temporizador variável define o ritmo a que a sequência avança (e acelera) ao longo do "braço da guitarra".'),
    P('O sistema está dividido em **arquitetura a controlar** e **controlador**. O controlador é uma máquina de estados síncrona por **realização direta** (um *flip-flop* por estado), desenhada a partir do fluxograma do algoritmo segundo a metodologia lecionada e descrita em Verilog no **modelo estrutural**, de forma que cada *flip-flop* corresponde a um estado do fluxograma.'),
    P('A secção 2 apresenta a especificação, a arquitetura e os sinais de interface; as secções 3 a 8 descrevem os módulos da arquitetura a controlar (código, *testbench* e simulação); a secção 9 descreve o projeto do controlador, pelos 11 passos da metodologia; a secção 10 trata da integração, das restrições, da implementação e do ensaio na placa; a secção 11 analisa o código de fontes externas e a secção 12 conclui. As listagens dos *testbenches* estão no Anexo A.'),
    P('Ferramentas: Vivado ' + R.versaoVivado + ' (licença WebPACK) para a FPGA `xc7a35ticpg236-1L` da Basys3 e draw.io para os diagramas. Todos os *testbenches* comparam as saídas com um modelo de referência e terminam com `Simulacao OK` ou `Simulacao FALHOU`; os tempos longos (varrimento, anti-ressalto e temporizador) são parâmetros dos módulos e são reduzidos nas simulações.'),

    // =====================================================================================
    H1('2 Especificação e arquitetura do sistema'),
    H2('2.1 Especificação funcional'),
    P('O sistema tem duas teclas, **Reset** (BTNU) e **Start** (BTNC), os quatro *displays* do jogo e os LEDs de sinalização **Ready** (LD0), **Beat** (LD1) e **Waiting** (LD2). Depois de Reset (secção 2.1 do enunciado):'),
    Bullet('inicializa a zeros a memória da sequência (os quatro *displays* ficam apagados) e habilita o LFSR, que passa a avançar livremente;'),
    Bullet('acende o LED Ready e espera que se carregue e largue a tecla Start;'),
    Bullet('quando se larga Start, apaga o LED Ready e, em ciclo: desloca a memória uma posição, carregando 2 *bits* do LFSR na primeira posição e perdendo a última; troca o estado do LED Beat; inicializa o temporizador variável e espera pelo fim do tempo; acelera ligeiramente o temporizador (parte opcional) e repete.'),
    P('A tecla Reset tem uma única função: pôr a máquina de estados no estado inicial, de forma **assíncrona** (secção 2.7 do enunciado). Os restantes elementos são inicializados pelas saídas da própria máquina de estados no estado inicial. As únicas exceções são o sincronizador da tecla Start e o varrimento dos *displays* (divisor de *clock* e contador): o primeiro só condiciona uma entrada e o varrimento funciona sempre, arrancando com os valores iniciais da configuração da FPGA; nenhum deles guarda informação do jogo.'),
    P('O enunciado não define a função do LED Waiting. Como o LED Ready já indica a espera pela tecla Start, o Waiting indica a espera pelo fim do tempo de cada passo (estado S4): fica aceso quase sempre durante o jogo e apaga-se por instantes em cada passo. Para depuração, os LEDs LD10 a LD15 mostram os seis *flip-flops* da máquina de estados (um aceso de cada vez).'),

    H2('2.2 Arquitetura a controlar e controlador'),
    P('A ' + r('fig_arq') + ' mostra o diagrama de blocos do sistema e a ' + r('tab_modulos') + ' a função de cada bloco. As saídas do controlador são os comandos sobre a arquitetura (ClrMem, InitLFSR, EnLFSR, ShiftMem, RstTemp, StartTemp, Faster e TglBeat); as saídas da arquitetura Start e Tempo são as entradas do controlador, fechando a malha de controlo (Fig. 2 do enunciado).'),
    ...Figura(N, 'fig_arq', 'arquitetura.png', 16.9, 'Diagrama de blocos do sistema: arquitetura a controlar, controlador e interface com o utilizador.'),
    ...Tabela(N, 'tab_modulos', 'Blocos do sistema, módulos Verilog e origem.',
      ['Bloco', 'Módulo (ficheiro)', 'Função', 'Origem'],
      [['LFSR de 32 *bits*', '`LFSR32` (lfsr32/lfsr32.v)', 'Sequência pseudo-aleatória das cordas (2 *bits* por passo)', 'Enunciado (secção 2.2)'],
       ['Memória 4x2', '`Memoria4x2` (memoria4x2/)', 'Cordas dos 4 *displays*, organizadas em fila', '4 × `Registo4` do 1.º trabalho'],
       ['Gestão dos *displays*', '`GestaoDisplays`, `TranscodCordas` (gestaodisplays/)', 'Varrimento dos 4 *displays* e transcodificação das cordas', 'Sistema do 1.º trabalho, transcodificador alterado'],
       ['Temporizador variável', '`Velocidade`, `Temporizador`, `TemporizadorVariavel` (temporizador/)', 'Tempo de cada passo e aceleração do jogo', 'Novo'],
       ['LED Beat', '`Beat` (beat/beat.v)', '*Flip-flop* T: o LED troca de estado em cada passo', 'Novo (primitiva FDCE)'],
       ['Sincronizador e anti-ressalto', '`Sincronizador` (sincronizador/)', 'Tecla Start sincronizada com o relógio e sem ressaltos', 'Novo'],
       ['Sincronizador do Reset', '`SincronizadorReset` (sincronizador/)', 'Reset ativado de imediato e libertado em sincronismo com o relógio', 'Novo (primitivas FDPE)'],
       ['Controlador', '`Controlador` (controlador/controlador.v)', 'Máquina de estados por realização direta (6 *flip-flops*)', 'Novo (FDPE, FDCE e portas lógicas)'],
       ['Circuito de topo', '`GuitarHero` (guitarhero/)', 'Liga o controlador à arquitetura e aos pinos da placa', 'Novo']],
      [2.2, 3.2, 3.6, 2.4], { alinhar: esq(4), tamanho: 17 }),
    P('Para além dos blocos sugeridos no enunciado (LFSR, memória e temporizador), a arquitetura inclui os seguintes:'),
    Bullet('**dois sincronizadores**, porque as teclas mudam em qualquer instante: a tecla Start é testada nas decisões da máquina de estados e tem de chegar síncrona e sem ressaltos (secção 3.1); a libertação do Reset tem de ser síncrona para os seis *flip-flops* saírem de S0 no mesmo flanco (secção 3.2);'),
    Bullet('um **registo da velocidade**, que guarda o período do temporizador e o encurta em cada passo (parte opcional);'),
    Bullet('um ***flip-flop* T** para o LED Beat, que troca de estado com um único comando (TglBeat) por passo.'),
    P('Os LEDs Ready e Waiting dispensam o *latch* SR sugerido na secção 2.4 do enunciado: as saídas que os comandam estão ativas em todos os estados entre o momento em que o LED acende e aquele em que apaga (Ready em S1 e S2, Waiting em S4). Todos os blocos usam o relógio de 100 MHz da placa.'),

    H2('2.3 Sinais de interface e a sua natureza'),
    P('A ' + r('tab_sinais') + ' identifica os sinais entre o controlador, a arquitetura e a placa. Todas as saídas do controlador são de Moore (só dependem do estado) e ativas a *High*.'),
    ...Tabela(N, 'tab_sinais', 'Sinais de interface do controlador e da arquitetura a controlar.',
      ['Sinal', 'Bits', 'Origem → destino', 'Natureza', 'Função'],
      [['CLKBasys', '1', 'Oscilador (W5) → todos os blocos', 'Relógio, flanco ascendente', 'Relógio único de 100 MHz'],
       ['BtnReset', '1', 'Tecla BTNU → Sincronizador do Reset', 'Assíncrono, ativo a *High*', 'Inicialização da máquina de estados'],
       ['BtnStart', '1', 'Tecla BTNC → Sincronizador', 'Assíncrono, ativo a *High*', 'Começa o jogo (carregar e largar)'],
       ['Reset', '1', 'Sincronizador do Reset → Controlador (PRE do FF_S0, CLR dos outros)', 'Ativação assíncrona, libertação síncrona', 'Põe a máquina em S0 de imediato'],
       ['Start', '1', 'Sincronizador → Controlador', 'Síncrono, ativo a *High*', 'Tecla Start sem ressaltos (10 ms)'],
       ['Tempo', '1', 'Temporizador variável → Controlador', 'Síncrono, ativo a *High*', '1 enquanto o temporizador conta'],
       ['ClrMem', '1', 'Controlador → Memória e Beat (CLR)', 'Comando assíncrono (CLR)', 'Limpa a memória e apaga o LED Beat'],
       ['InitLFSR', '1', 'Controlador → LFSR (Init)', 'Comando síncrono', 'Carrega a semente'],
       ['EnLFSR', '1', 'Controlador → LFSR (Enable)', 'Comando síncrono', 'O LFSR avança um passo por ciclo'],
       ['ShiftMem', '1', 'Controlador → Memória (CE)', 'Comando síncrono', 'Desloca a memória e carrega a corda nova'],
       ['RstTemp', '1', 'Controlador → Temporizador variável', 'Comando síncrono', 'Para a contagem e repõe o período inicial'],
       ['StartTemp', '1', 'Controlador → Temporizador', 'Comando síncrono', 'Começa uma contagem com o período atual'],
       ['Faster', '1', 'Controlador → Registo da velocidade', 'Comando síncrono', 'Encurta o período (opcional)'],
       ['TglBeat', '1', 'Controlador → Beat (CE)', 'Comando síncrono', 'Troca o estado do LED Beat'],
       ['Ready, Waiting', '1 + 1', 'Controlador → LD0, LD2', 'Sinalização', 'Espera por Start; espera pelo fim do tempo'],
       ['Estado[5:0]', '6', 'Controlador → LD10 a LD15', 'Depuração', 'Saídas Q dos 6 *flip-flops*'],
       ['OutLFSR[1:0]', '2', 'LFSR → Memória', 'Dados, síncrono', 'Corda nova: 00 pausa, 01 cima, 10 meio, 11 baixo'],
       ['Pos0 a Pos3', '4 × 2', 'Memória → Gestão dos *displays*', 'Dados, síncrono', 'Corda de cada *display* (Pos0 à esquerda)'],
       ['Periodo[27:0]', '28', 'Registo da velocidade → Temporizador', 'Dados, síncrono', 'Tempo de um passo, em ciclos de 10 ns'],
       ['Seg[6:0], DP', '7 + 1', 'Gestão dos *displays* → cátodos', 'Ativos a *Low*', 'Segmentos do *display* ativo; ponto apagado'],
       ['An[3:0]', '4', 'Gestão dos *displays* → ânodos', 'Ativos a *Low*', 'Um *display* de cada vez (2 kHz)'],
       ['LedBeat', '1', 'Beat → LD1', 'Sinalização', 'Pisca ao ritmo do temporizador']],
      [1.7, 0.7, 3.4, 2.4, 3.4], { alinhar: { 0: AlignmentType.LEFT, 2: AlignmentType.LEFT, 3: AlignmentType.LEFT, 4: AlignmentType.LEFT }, tamanho: 16 }),

    // =====================================================================================
    H1('3 Sincronização das teclas'),
    H2('3.1 Sincronizador e anti-ressalto da tecla Start'),
    P('A tecla Start é assíncrona em relação ao relógio e tem ressaltos de alguns milissegundos. Ligada diretamente às portas das decisões de S1 e S2, poderia violar os tempos de preparação de FF_S1 e FF_S2 no mesmo flanco (um podia ver 0 e o outro 1, deixando a máquina com zero ou dois estados ativos), e um ressalto ao carregar faria passar de S2 a S3 antes de a tecla ser largada, começando o jogo cedo de mais.'),
    P('O `Sincronizador` (' + r('lst_sinc') + ') resolve os dois problemas: dois *flip-flops* em série (`meta` e `sinc`, com o atributo `ASYNC_REG` para o Vivado os colocar lado a lado) sincronizam a tecla, e a saída só muda depois de a entrada sincronizada se manter diferente dela durante `ESTAVEL` ciclos seguidos (10 ms). Qualquer ressalto reinicia a contagem.'),
    ...Listagem(N, 'lst_sinc', 'sincronizador/sincronizador.v', 'Sincronizador e anti-ressalto da tecla Start'),
    P('O *testbench* (' + r('lst_sinc_tb') + ', no Anexo A) usa `ESTAVEL = 20` e simula ruído curto, carregar e largar a tecla com seis ressaltos e uma falha curta com a tecla carregada, em instantes que não coincidem com o relógio. Verifica que a saída muda uma única vez em cada caso, entre `ESTAVEL` e `ESTAVEL + 3` ciclos depois do último ressalto, e que o ruído é ignorado. Na ' + r('fig_viv_sinc') + ' `contagem` volta a 0 em cada ressalto e `Saida` só muda quando a entrada estabiliza. Resultado: `Simulacao OK (' + R.ver.sincronizador_teste1 + ' verificacoes)`.'),
    ...Figura(N, 'fig_viv_sinc', 'viv_sincronizador_sim.png', 16.9, 'Simulação do sincronizador da tecla Start (ESTAVEL = 20 ciclos).'),

    H2('3.2 Sincronizador do Reset'),
    P('O Reset tem de pôr a máquina em S0 de imediato, sem esperar pelo relógio (secção 2.7 do enunciado), mas a sua **libertação** não pode ser assíncrona: se a tecla fosse largada junto a um flanco, FF_S0 podia sair do PRE a tempo de carregar D = 0 nesse flanco enquanto FF_S1 ainda estava no CLR. A máquina ficava sem nenhum estado ativo e, como nenhuma equação de excitação tem termos fora dos estados, nunca mais sairia daí. É uma **corrida crítica** entre os sinais assíncronos (passo 5 da metodologia, secção 9.4).'),
    P('O `SincronizadorReset` (' + r('lst_sincr') + ') usa duas primitivas FDPE em série com `PRE` ligado à tecla: ao carregar, a saída vai a 1 de imediato (assíncrono); ao largar, só volta a 0 no 2.º flanco ascendente do relógio, pelo que os seis *flip-flops* saem do *reset* com um ciclo inteiro de folga. Com `INIT = 1`, o Reset também é libertado de forma síncrona depois de configurar a FPGA.'),
    ...Listagem(N, 'lst_sincr', 'sincronizador/sincronizadorreset.v', 'Sincronizador do Reset (ativação assíncrona, libertação síncrona)'),
    P('O *testbench* (' + r('lst_sincr_tb') + ', no Anexo A) carrega e larga a tecla em dez instantes diferentes do ciclo, incluindo junto ao flanco, e verifica que a saída sobe sem flanco do relógio e desce sempre num flanco ascendente, 2 flancos depois de largar a tecla. Na ' + r('fig_viv_sincr') + ', depois das configurações iniciais (100 ns), `q1` e `Saida` descem em flancos consecutivos; em cada impulso da tecla `Saida` sobe com a entrada. Resultado: `Simulacao OK (' + R.ver.sincronizadorreset_teste1 + ' verificacoes)`.'),
    ...Figura(N, 'fig_viv_sincr', 'viv_sincronizadorreset_sim.png', 16.9, 'Simulação do sincronizador do Reset: subida imediata e descida síncrona.'),

    // =====================================================================================
    H1('4 LFSR de 32 bits'),
    P('O `LFSR32` (' + r('lst_lfsr') + ') é o código do enunciado, com comentários. A realimentação é a XNOR das saídas 32, 22, 2 e 1 (*bits* 31, 21, 1 e 0), a combinação da nota de aplicação XAPP052 da Xilinx para 32 *bits*, o que dá o período máximo de 2³² − 1 estados. Com XNOR o estado proibido é tudo a 1 (o LFSR ficaria parado); a semente `32\'h03E3180A` é diferente desse valor.'),
    P('O LFSR é comandado pela máquina de estados: com `Enable` a 1 carrega a semente se `Init` estiver a 1 e avança um passo se `Init` estiver a 0; com `Enable` a 0 mantém o estado. Como `Init` só atua com `Enable` a 1, o estado S0 ativa as duas saídas (InitLFSR e EnLFSR). A saída `OutLFSR = {regLFSR[31], regLFSR[0]}` escolhe a corda (' + r('tab_cordas') + ').'),
    ...Tabela(N, 'tab_cordas', 'Correspondência entre os 2 *bits* do LFSR e as cordas.',
      ['OutLFSR', 'Corda', 'Segmento aceso', 'Seg[6:0] (a…g)'],
      [['00', 'Pausa', 'Nenhum', '1111111'], ['01', 'Corda de cima', 'a', '0111111'],
       ['10', 'Corda do meio', 'g', '1111110'], ['11', 'Corda de baixo', 'd', '1110111']],
      [1, 1.6, 1.4, 1.6], { largura: 6500, mono: [true, false, false, true] }),
    P('O LFSR avança em todos os ciclos do relógio (EnLFSR está ativa em todos os estados), mas a memória só lê um par de *bits* em cada passo do jogo. O número de ciclos que a máquina passa em S1 e S2 depende do tempo que o jogador demora a carregar e largar Start, por isso a sequência de cordas é diferente em cada jogo, apesar de a semente ser fixa.'),
    ...Listagem(N, 'lst_lfsr', 'lfsr32/lfsr32.v', 'LFSR de 32 *bits* (código do enunciado)'),
    P('O *testbench* (' + r('lst_lfsr_tb') + ', no Anexo A) verifica os casos dirigidos (estado inicial 0, `Init` ignorado com `Enable` a 0, carga da semente, primeiro passo e `Enable` a 0 a manter o estado) e depois compara 100 000 ciclos com um modelo de referência, verificando que o LFSR não passa pelo estado proibido nem repete a semente. Em 100 000 passos saíram ' + R.cordas[0] + ' pausas e ' + R.cordas[1] + ', ' + R.cordas[2] + ' e ' + R.cordas[3] + ' notas nas cordas de cima, do meio e de baixo, ou seja, cerca de 25 % cada. Na ' + r('fig_viv_lfsr') + ' a semente é carregada aos 25 ns, o primeiro passo dá `07c63015` e o registo fica parado entre 51 e 101 ns, com `Enable` a 0. Resultado: `Simulacao OK (' + R.ver.lfsr32_teste1 + ' verificacoes)`.'),
    ...Figura(N, 'fig_viv_lfsr', 'viv_lfsr32_sim.png', 16.9, 'Simulação do LFSR: carga da semente, primeiro passo, Enable = 0 e avanço livre.'),

    // =====================================================================================
    H1('5 Memória 4x2'),
    P('A memória guarda a corda de cada *display* e funciona como uma fila (registo de deslocamento): com `Shift` a 1, no flanco ascendente do relógio, `Pos0` recebe os 2 *bits* do LFSR e cada posição recebe a anterior, perdendo-se a de `Pos3`. `CLR` limpa as quatro posições de forma assíncrona (todas em pausa).'),
    P('A `Memoria4x2` (' + r('lst_mem') + ') reutiliza quatro `Registo4` do 1.º trabalho (quatro primitivas FDCE cada), em cadeia, dos quais só se usam os 2 *bits* de menor peso: os de maior peso carregam sempre 0 e a síntese elimina-os.'),
    ...Listagem(N, 'lst_mem', 'memoria4x2/memoria4x2.v', 'Memória 4x2 com quatro registos do 1.º trabalho'),
    P('O *testbench* (' + r('lst_mem_tb') + ', no Anexo A) compara a fila `{Pos3, Pos2, Pos1, Pos0}` com um modelo de referência sempre que alguma delas muda: primeiro com casos dirigidos (quatro cordas a entrar, `Shift` a 0, *clear* fora do flanco e com prioridade sobre `Shift`) e depois com 2000 ciclos de entradas aleatórias, com *clears* ocasionais. Na ' + r('fig_viv_mem') + ' as cordas 01, 10, 11, 00 e 10 entram em `Pos0` e avançam uma posição em cada flanco; aos 203 ns o `CLR` apaga tudo sem esperar pelo relógio. Resultado: `Simulacao OK (' + R.ver.memoria4x2_teste1 + ' verificacoes)`.'),
    ...Figura(N, 'fig_viv_mem', 'viv_memoria4x2_sim.png', 16.9, 'Simulação da memória 4x2: deslocamento das cordas e *clear* assíncrono.'),

    // =====================================================================================
    H1('6 Temporizador variável'),
    P('O temporizador variável define a duração de cada passo do jogo. Foi dividido em dois módulos, ligados pelo `TemporizadorVariavel` (' + r('lst_tv') + '):'),
    Bullet('o `Temporizador` (' + r('lst_temp') + '), pedido na secção 2.3 do enunciado: com `Start` a 1 carrega `Periodo` (o tempo total, em ciclos de 10 ns) e `Tempo` fica a 1 durante `Periodo` ciclos, voltando a 0 sozinho; `Reset` interrompe a contagem;'),
    Bullet('o registo da velocidade, `Velocidade` (' + r('lst_vel') + '), que guarda `Periodo`: `Reset` repõe o valor inicial (0,5 s) e cada impulso de `Faster` encurta-o em 5 ms, sem descer abaixo de 0,2 s (parte opcional do enunciado).'),
    P('Com estes valores o jogo chega à velocidade máxima ao fim de 60 passos (cerca de 21 s). Cada passo dura `Periodo` + 3 ciclos do relógio (estados S3 e S5 e o ciclo de S4 em que Tempo já está a 0), ou seja, mais 30 ns do que o período, o que é desprezável. O contador tem 28 *bits* (até 2,68 s).'),
    ...Listagem(N, 'lst_temp', 'temporizador/temporizador.v', 'Temporizador'),
    ...Listagem(N, 'lst_vel', 'temporizador/velocidade.v', 'Registo da velocidade do jogo'),
    ...Listagem(N, 'lst_tv', 'temporizador/temporizadorvariavel.v', 'Temporizador variável'),
    P('O *testbench* do temporizador (' + r('lst_temp_tb') + ', no Anexo A) usa um contador de 8 *bits* e conta os ciclos em que `Tempo` está a 1 para períodos de 1, 5, 17, 255 e outros; verifica também que `Periodo = 0` não ativa `Tempo`, que `Reset` interrompe a contagem e tem prioridade sobre `Start` e que um `Start` durante a contagem recomeça com o novo período. Na ' + r('fig_viv_temp') + ' `contagem` desce de `Periodo` até 0 e `Tempo` fica a 1 durante 1, 5 e 17 ciclos. Resultado: `Simulacao OK (' + R.ver.temporizador_teste1 + ' verificacoes)`.'),
    ...Figura(N, 'fig_viv_temp', 'viv_temporizador_sim.png', 16.9, 'Simulação do temporizador: períodos de 1, 5 e 17 ciclos.'),
    P('O *testbench* do temporizador variável (' + r('lst_tv_tb') + ', no Anexo A) usa `INICIAL = 40`, `PASSO = 6` e `MINIMO = 20` ciclos e verifica a sequência de períodos 40, 40, 34, 28, 22, 22 e 22 (22 − 6 = 16 seria menor do que o mínimo) e que `RstTemp` a meio da contagem para o temporizador e repõe os 40 ciclos (' + r('fig_viv_tv') + '). Resultado: `Simulacao OK (' + R.ver.temporizadorvariavel_teste1 + ' verificacoes)`.'),
    ...Figura(N, 'fig_viv_tv', 'viv_temporizadorvariavel_sim.png', 16.9, 'Simulação do temporizador variável: aceleração até ao período mínimo e reposição com RstTemp.'),

    // =====================================================================================
    H1('7 LED Beat'),
    P('O LED Beat pisca ao ritmo do temporizador: o `Beat` (' + r('lst_beat') + ') é um *flip-flop* T feito com uma primitiva FDCE com `D` = /`Q` e `CE` = `Tgl`. Em cada passo do jogo o controlador ativa TglBeat durante um ciclo e o LED troca de estado (aceso num passo, apagado no seguinte). `CLR` está ligado a ClrMem, pelo que o LED apaga com a inicialização. Assim basta um único comando, sem *latch* SR.'),
    ...Listagem(N, 'lst_beat', 'beat/beat.v', '*Flip-flop* T do LED Beat'),
    P('O *testbench* (' + r('lst_beat_tb') + ', no Anexo A) verifica que `Q` mantém o valor com `Tgl` a 0, troca em cada flanco com `Tgl` a 1 e vai a 0 com `CLR` fora do flanco, mesmo com `Tgl` a 1 (' + r('fig_viv_beat') + '). Resultado: `Simulacao OK (' + R.ver.beat_teste1 + ' verificacoes)`.'),
    ...Figura(N, 'fig_viv_beat', 'viv_beat_sim.png', 16.9, 'Simulação do *flip-flop* T do LED Beat.'),

    // =====================================================================================
    H1('8 Gestão dos displays'),
    P('A gestão dos *displays* (' + r('lst_ges') + ') reutiliza o sistema do 1.º trabalho (secção 2.5 do enunciado): o `DivisorClock` e o `Contador4` fazem o varrimento a 2 kHz (cada *display* aceso 0,5 ms, os quatro atualizados a cada 2 ms), o `multiplexer16x4` escolhe a corda do *display* ativo e o `descodificador2x4`, com os *enables* a 1, ativa um *display* de cada vez. Os registos dos símbolos foram substituídos pela memória 4x2, cujas saídas entram diretamente no *multiplexer*.'),
    P('O transcodificador foi alterado para as cordas (`TranscodCordas`, ' + r('lst_transc') + ' e ' + r('tab_cordas') + '): cada corda acende um só segmento horizontal (a, g ou d) e a pausa apaga o *display*. A corda nova (`Pos0`) aparece no *display* da esquerda (AN3) e avança para a direita até `Pos3` (AN0). Segmentos e ânodos são ativos a *Low* e o ponto decimal fica apagado.'),
    ...Listagem(N, 'lst_transc', 'gestaodisplays/transcodcordas.v', 'Transcodificador das cordas'),
    ...Listagem(N, 'lst_ges', 'gestaodisplays/gestaodisplays.v', 'Gestão dos quatro *displays*'),
    P('O *testbench* (' + r('lst_ges_tb') + ', no Anexo A) usa `METADE = 2` e percorre as 256 combinações das quatro posições; em cada passo do varrimento verifica que há um só ânodo ativo, que os segmentos são os da corda que esse *display* deve mostrar e que os quatro *displays* são varridos. Na ' + r('fig_viv_ges') + ', com `Pos0` a `Pos3` = 00, 01, 10 e 11, `Anodos` percorre 1011, 0111, 1110 e 1101 e `Segmentos` mostra, respetivamente, a corda de cima (0111111), a pausa (1111111), a corda de baixo (1110111) e a do meio (1111110). Resultado: `Simulacao OK (' + R.ver.gestaodisplays_teste1 + ' verificacoes)`.'),
    ...Figura(N, 'fig_viv_ges', 'viv_gestaodisplays_sim.png', 16.9, 'Simulação da gestão dos *displays* (METADE = 2): varrimento com uma corda diferente em cada posição.'),
  ];
};
