// Seccoes 7 a 9 e Anexo A: integracao, restricoes, ensaio, analise critica, conclusao e testbenches.
const { P, Bullet, H1, H2, Figura, FiguraPorTirar, Tabela, Listagem } = require('./lib');
const { AlignmentType } = require('docx');

const VERMELHO = { color: 'C00000', bold: true };

module.exports = function integracao(N, R) {
  const r = id => N.ref(id);
  const esq = (...c) => Object.fromEntries(c.map(i => [i, AlignmentType.LEFT]));
  return [
    // =====================================================================================
    H1('7 Integração do sistema'),
    H2('7.1 Circuito de topo'),
    P('O `GestaoTeclas` (' + r('lst_topo') + ') instancia três vezes a gestão de tecla, uma por tecla do jogo, liga as três saídas Kd à validação e aos LEDs, e o Clear às três máquinas. Para além do pedido no enunciado, tem dois elementos:'),
    Bullet('**reset de arranque:** um registo de deslocamento de 4 *bits*, com valor inicial 1111, mantém o Clear ativo nos 4 primeiros ciclos depois de configurar a FPGA. Numa máquina sem *flip-flops* não há valor inicial de configuração (INIT): sem isto, as realimentações podiam arrancar num código qualquer. Assim as máquinas começam sempre em S0 sem ser preciso carregar Reset. O registo é síncrono e a sua saída não tem picos;'),
    Bullet('**circuito auxiliar de ensaio:** dois `ContaImpulsos` contam os flancos ascendentes do OR das teclas com ressaltos e do OR das teclas sem ressaltos (Kd), e o `ControloDisplays` do 1.º trabalho mostra as duas contagens em hexadecimal (à esquerda as teclas com ressaltos, à direita sem ressaltos, separadas pelo ponto). A tecla Reset também põe as contagens a 0 (através de dois *flip-flops* de sincronização). Este circuito só serve para ver na placa os ressaltos que foram filtrados e não interfere com as máquinas de estados.'),
    ...Listagem(N, 'lst_topo', 'gestaoteclas/gestaoteclas.v', 'Circuito de topo'),
    ...Listagem(N, 'lst_conta', 'ensaio/contaimpulsos.v', 'Contador de impulsos do circuito de ensaio'),

    H2('7.2 Restrições e implementação'),
    P('A ' + r('tab_pinos') + ' mostra a ligação dos sinais à Basys3 (' + r('lst_xdc') + '). As três teclas do jogo são as teclas da fila central (esquerda, centro e direita), que se carregam com três dedos como os trastes de uma guitarra, e o Reset é a tecla de cima, como no 2.º trabalho.'),
    ...Tabela(N, 'tab_pinos', 'Ligação dos sinais do circuito de topo à Basys3.',
      ['Sinal', 'Pino(s)', 'Elemento da Basys3'],
      [['CLKBasys', 'W5', 'Oscilador de 100 MHz'],
       ['BtnReset', 'T18', 'Tecla BTNU'],
       ['BtnK1 / BtnK2 / BtnK3', 'W19 / U18 / T17', 'Teclas BTNL / BTNC / BTNR'],
       ['LedKd[0] a LedKd[2]', 'U16 E19 U19', 'LEDs LD0 a LD2 (Kd1 a Kd3)'],
       ['LedEstado[0] a LedEstado[8]', 'W18 U15 U14 V14 V13 V3 W3 U3 P3', 'LEDs LD4 a LD12 (YY0 YY1 YY2 das teclas 1, 2, 3)'],
       ['LedM / LedU', 'P1 / L1', 'LEDs LD14 / LD15'],
       ['Seg[6:0], DP', 'W7 W6 U8 V8 U5 V5 U7, V7', 'Segmentos CA a CG e ponto (ativos a Low)'],
       ['An[3:0]', 'W4 V4 U4 U2', 'Ânodos AN3 a AN0 (ativos a Low)']],
      [2.4, 3, 3.6], { alinhar: esq(0, 2) }),
    P('As realimentações das máquinas de estados são laços combinatórios intencionais. Por omissão, o Vivado recusa gerar o *bitstream* de um circuito com laços combinatórios (erro DRC LUTLP-1); a propriedade `ALLOW_COMBINATORIAL_LOOPS` nas ligações YY2, YY1 e YY0 das três máquinas indica que são propositados, e o erro passa a aviso (LUTLP-2). As teclas, que atuam sem relógio nas máquinas e passam por sincronizadores nos temporizadores e no circuito de ensaio, e as saídas para LEDs e *displays* não têm requisitos de tempo. O relógio do varrimento dos *displays* é declarado como no 1.º trabalho.'),
    ...Listagem(N, 'lst_xdc', 'gestaoteclas/gestaoteclas.xdc', 'Ficheiro de restrições do circuito de topo'),
    P(`A implementação ocupa ${R.util.lut} LUT e ${R.util.ff} *flip-flops* e cumpre todas as restrições temporais, com uma folga (WNS) de ${R.wns} ns. Cada máquina de estados ocupa 6 LUT e nenhum *flip-flop*. Os avisos que ficam são todos esperados: LUTLP-2 (laço combinatório permitido, um por máquina), TIMING-23 (o Vivado corta cada laço num ponto para a análise temporal, porque um laço não tem caminho com início e fim) e TIMING-9 (a mesma situação do relógio do varrimento já explicada no 1.º e no 2.º trabalhos). Os laços não são caminhos temporizados: a análise dos atrasos que interessam à máquina assíncrona está na secção 3.8.`),

    H2('7.3 Simulação do sistema completo'),
    P(`O testbench do circuito de topo (${r('lst_tb_topo')}, no Anexo A) usa T = 20 ciclos e o varrimento dos *displays* acelerado, começa com a tecla Reset carregada e testa as teclas uma a uma e em conjunto, sempre com ressaltos (impulsos de 15 ns, que a sincronização dos contadores de ensaio consegue ver). Confere Kd, U e M depois de cada pressão, as contagens do circuito de ensaio (8 flancos com ressaltos e 2 sem ressaltos no OR das teclas) e, no fim, o Reset com uma tecla premida. Resultado: \`Simulacao OK (${R.ver.gestaoteclas_teste1} verificacoes)\`.`),
    P('Na ' + r('fig_sim_topo') + ', K1 é premida (U = 1), K2 é premida sem largar K1 (M = 1 e U = 0), K1 é largada (U volta a 1 com K2), K2 é largada e K3 é premida. As variáveis de estado de cada máquina seguem o ciclo 000 → 001 → 011 → 111 → 110 → 100 → 000. A contagem com ressaltos (`ImpulsosK`) sobe 3 vezes em cada pressão com dois ressaltos e a contagem sem ressaltos (`ImpulsosKd`) sobe uma vez; o Reset (2601 ns) põe as máquinas em S0 de imediato e as contagens a 0. A ' + r('fig_sim_topo_det') + ' mostra a primeira pressão em pormenor.'),
    ...Figura(N, 'fig_sim_topo', 'viv_gestaoteclas_sim.png', 16.9, 'Simulação do sistema completo: teclas sozinhas e em conjunto, contagens do circuito de ensaio e Reset.'),
    ...Figura(N, 'fig_sim_topo_det', 'viv_gestaoteclas_detalhe_sim.png', 16.9, 'Pormenor da simulação do sistema: K1 com ressaltos (3 flancos contados, 1 em Kd) e K2 premida com K1.'),

    H2('7.4 Integração faseada e ensaio na placa'),
    P('A integração foi feita por fases: primeiro a máquina de estados sozinha (secção 3.10), depois o temporizador (secção 4), a gestão de uma tecla (secção 5), a validação (secção 6) e, por fim, o sistema completo (secção 7.3). Na placa, o ensaio segue a ordem da ' + r('tab_ensaio') + '; os LEDs LD4 a LD12 mostram as variáveis de estado e os *displays* as contagens dos flancos.'),
    ...Tabela(N, 'tab_ensaio', 'Procedimento de ensaio na Basys3 e resultado esperado.',
      ['Passo', 'Ação', 'Resultado esperado'],
      [['1', 'Programar a FPGA com `gestaoteclas.bit`', 'LEDs apagados; *displays* com 00.00'],
       ['2', 'Carregar e manter BTNL (K1)', 'LD0 (Kd1) e LD15 (U) acendem de imediato; LD4 a LD6 = 111 (S3) ao fim de 10 ms'],
       ['3', 'Largar BTNL', 'LD0 e LD15 apagam de imediato; LD4 a LD6 = 000'],
       ['4', 'Carregar e largar BTNL, BTNC e BTNR 20 vezes, uma de cada vez', 'Contagem da direita = 14 (20 em hexadecimal); a da esquerda é igual ou maior (a diferença são os ressaltos filtrados)'],
       ['5', 'Carregar BTNL e BTNC ao mesmo tempo, depois as três', 'LD0 e LD1 (e LD2) acesos; LD14 (M) aceso e LD15 (U) apagado'],
       ['6', 'Carregar e largar BTNU (Reset), sem teclas do jogo', 'Contagens a 00.00; LEDs apagados'],
       ['7', 'Carregar e largar uma tecla muito depressa (toque curto)', 'O LED Kd da tecla acende pelo menos 10 ms (impercetível) e a contagem da direita sobe 1'],
       ['8', 'Manter BTNL, carregar BTNU cerca de 1 s, largar BTNU e só depois BTNL', 'LD0 apaga com o Reset, volta a acender ao largar BTNU e apaga ao largar BTNL; LD4 a LD6 acabam em 000']],
      [0.7, 4, 5], { alinhar: esq(1, 2), tamanho: 17, juntar: true }),
    P('[A COMPLETAR NO LABORATÓRIO: confirmar o resultado de cada passo da ' + r('tab_ensaio') + ', registar as contagens do passo 4 e substituir as fotografias abaixo]', { run: VERMELHO }),
    ...FiguraPorTirar(N, 'fig_placa1', 'Ensaio na placa Basys3: tecla K1 premida (LD0 e LD15 acesos, LD4 a LD6 com o estado S3).', 'fotografia da placa com BTNL carregada (passo 2)'),
    ...FiguraPorTirar(N, 'fig_placa2', 'Ensaio na placa Basys3: contagens dos flancos com e sem ressaltos depois de 20 pressões.', 'fotografia dos displays depois do passo 4'),

    // =====================================================================================
    H1('8 Análise crítica do código de fontes externas'),
    H2('8.1 Tabela de estados primitiva'),
    P('A tabela de estados primitiva foi construída pelo grupo numa folha de cálculo partilhada, antes do resto do projeto. Foi usada sem alterações, depois de conferida pelo `scripts/projeto.py`: cada linha tem um só estado estável, as saídas estão definidas em todos os estados e as células indiferentes são exatamente as que exigem mudar K e To ao mesmo tempo ou subir To sem um flanco em Ti (secção 3.1).'),
    H2('8.2 Módulos do 1.º trabalho'),
    P('O sistema dos *displays* do 1.º trabalho (`ControloDisplays`, `Registo4`, `DivisorClock`, `Contador4`, `multiplexer16x4`, `multiplexer4x1`, `descodificador2x4` e `Transcod7Seg`) foi usado sem alterações e só no circuito auxiliar de ensaio. Ao contrário do 2.º trabalho, em que os projetos referiam os ficheiros da pasta do 1.º trabalho, desta vez foram copiados para `modulos_lab1/`, como recomenda a secção 4 do enunciado, para o 3.º trabalho poder ser demonstrado de forma independente.'),
    H2('8.3 Enunciado'),
    P('O texto da secção 2.1 diz que as variáveis de estado vão a 0 com o nível Low no sinal CLEAR, mas a porta AND2B1 da Fig. 3 tem a entrada CLEAR negada, ou seja, ativa a High. Seguiu-se a figura (YYi = Yi · /Clear), que coincide com o nível da tecla premida na Basys3 e dispensa um inversor.'),
    H2('8.4 IA generativa'),
    P('Foi usada IA generativa como apoio na escrita do *script* que confere os passos do projeto da máquina de estados, na escrita dos testbenches, na revisão do código Verilog e dos comentários, na preparação dos diagramas no draw.io e na correção da redação deste relatório. Todo o código, os diagramas e os resultados foram revistos pelo grupo, e as simulações foram corridas e analisadas pelo grupo.'),

    // =====================================================================================
    H1('9 Conclusão'),
    P('Desenvolveu-se a gestão das teclas do jogo Guitar Hero: para cada uma das três teclas, uma máquina de estados assíncrona, com a ajuda de um temporizador monoestável redisparável, elimina os ressaltos e reage de imediato ao premir e ao largar; a validação indica se está premida uma só tecla ou mais do que uma.'),
    P('A máquina de estados, o cerne do trabalho, foi projetada pela metodologia lecionada: dos 10 estados da tabela primitiva, a fusão deixou 6; os dois triângulos do grafo de transições obrigaram a três transições indiretas, depois das quais a codificação de um contador de Johnson (000, 001, 011, 111, 110, 100) fica livre de corridas e as saídas passam a ser as próprias variáveis de estado (Kd = YY0, F = YY2), sem picos. As equações de excitação são somas de produtos sem acidentes estáticos (com termos de consenso em Y2 e Y1), e os acidentes essenciais, que são próprios da tabela de estados, foram verificados com os atrasos reais do *place & route*. O código Verilog não tem *flip-flops*: cada equação é um `assign` e cada variável de estado a sua realimentação, com o Clear da Fig. 3 do enunciado.'),
    P(`Os ${R.numTestbenches} testbenches conferem as saídas com os valores esperados e terminam todos com \`Simulacao OK\`, e detetaram todas as alterações propositadas de função; a implementação cumpre as restrições temporais.`),
    P('**Limitações conhecidas.**'),
    Bullet('A máquina assume o modo fundamental, mas K é assíncrono em relação ao relógio do temporizador: se K mudar a menos de um nanossegundo de To (ou da libertação do Clear), as duas mudanças contam como simultâneas e a máquina pode acabar num estado errado (por exemplo, em S1 à espera de To). A probabilidade é muito pequena, porque To só muda T depois de um flanco de K e os ressaltos já acabaram nessa altura.'),
    Bullet('Um impulso em Ti mais curto do que um ciclo do relógio pode não ser visto pela sincronização do temporizador. Se for o único flanco (ruído com a tecla em repouso), a máquina fica em S1 com Kd = 1 até à pressão seguinte. Os ressaltos mecânicos são muito mais longos do que 10 ns; uma melhoria seria capturar o flanco de Ti de forma assíncrona antes da sincronização.'),
    Bullet('A margem dos acidentes essenciais (secção 3.8) foi confirmada para esta implementação; se o projeto mudar, convém repetir a verificação com `scripts/atrasos.tcl`.'),
    P('[A COMPLETAR NO LABORATÓRIO: acrescentar o resultado do ensaio na placa Basys3 (secção 7.4)]', { run: VERMELHO }),

    // =====================================================================================
    H1('Anexo A Testbenches'),
    P('Listagens dos testbenches das secções 3 a 7. Todos verificam as saídas automaticamente e terminam com `Simulacao OK` ou `Simulacao FALHOU`; as vistas das formas de onda usadas nas figuras estão nos ficheiros `.wcfg` ao lado de cada testbench.'),
    ...Listagem(N, 'lst_tb_maq', 'maquinatecla/maquinatecla_teste1.v', 'Testbench da máquina de estados'),
    ...Listagem(N, 'lst_tb_mono', 'monoestavel/monoestavel_teste1.v', 'Testbench do temporizador'),
    ...Listagem(N, 'lst_tb_tecla', 'tecla/tecla_teste1.v', 'Testbench da gestão de uma tecla'),
    ...Listagem(N, 'lst_tb_val', 'validacao/validacao_teste1.v', 'Testbench da validação'),
    ...Listagem(N, 'lst_tb_topo', 'gestaoteclas/gestaoteclas_teste1.v', 'Testbench do circuito de topo'),
  ];
};
