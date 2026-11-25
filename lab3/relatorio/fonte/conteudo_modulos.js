// Seccoes 4 a 6 do relatorio: temporizador, gestao de uma tecla e validacao das teclas.
const { P, Bullet, H1, H2, Figura, Tabela, Listagem } = require('./lib');
const { AlignmentType } = require('docx');

module.exports = function modulos(N, R) {
  const r = id => N.ref(id);
  const esq = (...c) => Object.fromEntries(c.map(i => [i, AlignmentType.LEFT]));
  return [
    // =====================================================================================
    H1('4 Temporizador monoestável redisparável'),
    P('O temporizador (' + r('lst_mono') + ') tem o comportamento da Fig. 1 do enunciado: cada flanco ascendente de Ti (re)inicia a contagem, e To fica a 1 durante T ciclos do relógio contados a partir do último flanco. Foi feito de forma síncrona, com o relógio de 100 MHz, porque T = 10 ms corresponde a 10⁶ ciclos e um contador é a forma natural de o medir:'),
    Bullet('Ti é assíncrono (vem da tecla e da máquina de estados), por isso passa por dois *flip-flops* de sincronização (`meta` e `sinc`, com `ASYNC_REG`) antes de ser usado, como no sincronizador do 2.º trabalho;'),
    Bullet('o flanco ascendente é detetado comparando `sinc` com o valor do ciclo anterior (`anterior`);'),
    Bullet('com um flanco, o contador carrega T − 1 e To passa a 1; a contagem desce até 0 e To volta a 0 no ciclo seguinte, pelo que To fica a 1 exatamente T ciclos; um novo flanco a meio volta a carregar o contador (redisparo);'),
    Bullet('To sai diretamente de um *flip-flop*, pelo que nunca tem picos, o que é importante porque é uma entrada da máquina de estados assíncrona;'),
    Bullet('não tem Reset: arranca parado (valores iniciais da configuração da FPGA) e o Reset da máquina de estados não o interrompe, como recomenda o enunciado.'),
    P('Entre o flanco de Ti e a subida de To passam 2 a 3 ciclos (20 a 30 ns) de sincronização. É por isso que a tabela primitiva tem os estados i e j (um ressalto antes de To subir). Um impulso em Ti mais curto do que um ciclo do relógio pode não ser visto pela sincronização; na prática os ressaltos de uma tecla mecânica duram microssegundos, e a tecla acaba sempre por ficar estável, dando um flanco longo (ver a secção 9).'),
    ...Listagem(N, 'lst_mono', 'monoestavel/monoestavel.v', 'Temporizador monoestável redisparável'),
    P(`O testbench (${r('lst_tb_mono')}, no Anexo A) usa T = 5 ciclos. Na ${r('fig_sim_mono')}, o flanco de Ti aos 20 ns é sincronizado (\`meta\` aos 25 ns, \`sinc\` aos 35 ns) e To fica a 1 de 45 a 95 ns, 5 ciclos; o flanco descendente aos 100 ns não dispara o temporizador; o disparo aos 150 ns é seguido de um novo flanco aos 200 ns, que recarrega o contador a meio (4, 3, 2, 1, 0, 4, ...), e To só desce aos 275 ns, 5 ciclos depois do redisparo. Resultado: \`Simulacao OK (${R.ver.monoestavel_teste1} verificacoes)\`.`),
    ...Figura(N, 'fig_sim_mono', 'viv_monoestavel_sim.png', 16.9, 'Simulação do temporizador (T = 5 ciclos): disparo, flanco descendente sem efeito e redisparo.'),

    // =====================================================================================
    H1('5 Gestão de uma tecla'),
    P('O módulo `Tecla` (' + r('lst_tecla') + ') liga a máquina de estados, a porta XOR e o temporizador, como na Fig. 2 do enunciado. É a unidade instanciada três vezes no circuito de topo.'),
    P('Em relação à Fig. 2, Ti tem uma porta AND com /Clear: **Ti = (K ⊕ F)·/Clear**. Sem ela havia uma situação em que a máquina ficava bloqueada: com a tecla premida, o Clear força F = 0 e Ti = K ⊕ 0 = 1; se o Reset durar mais do que T (uma pressão humana dura muito mais do que 10 ms), o temporizador acaba durante o Reset e, quando este é libertado com a tecla ainda premida, a máquina vai para S1 (K To = 10) à espera que To suba, mas Ti já estava a 1 e não há flanco que dispare o temporizador. Ao largar a tecla, a máquina ficava em S1 com Kd = 1 até à pressão seguinte. Com Ti a 0 durante o Clear, a libertação do Clear com a tecla premida é um flanco ascendente de Ti, o temporizador arranca e a máquina segue S1 → S2 → S3, como numa pressão normal. O temporizador continua a nunca ser inicializado.'),
    ...Listagem(N, 'lst_tecla', 'tecla/tecla.v', 'Gestão de uma tecla: máquina de estados, XOR e temporizador'),
    P(`O testbench (${r('lst_tb_tecla')}, no Anexo A) usa T = 20 ciclos (200 ns) e uma tecla com ressaltos de 6 a 11 ns, começa com o Clear ativo e testa cinco situações: premir e largar com ressaltos, uma pressão mais curta do que a temporização, uma nova pressão durante a temporização ao largar e um Clear mais longo do que T com a tecla premida. Além de conferir Kd e o estado em vários instantes, conta os flancos de Kd: no total têm de ser exatamente seis subidas e seis descidas (uma por pressão, mais a descida no Clear e a subida quando é libertado), ou seja, nenhum ressalto passa para Kd. Resultado: \`Simulacao OK (${R.ver.tecla_teste1} verificacoes)\`.`),
    P('A ' + r('fig_sim_tecla') + ' mostra o teste completo e a ' + r('fig_sim_tecla_det') + ' a primeira pressão em pormenor, que reproduz a Fig. 2 do enunciado:'),
    Bullet('ao premir (101 ns), Kd sobe de imediato e a máquina vai para S1; os ressaltos (108 a 131 ns) passam por i e d (S1 e S2) sem mudar Kd, e cada regresso de K a 1 redispara o temporizador (Ti = K);'),
    Bullet('To desce 200 ns depois do último flanco de Ti e a máquina vai para S3: F sobe e Ti, que é K ⊕ F, desce;'),
    Bullet('ao largar (601 ns), Kd desce de imediato e Ti sobe; os ressaltos passam por j, f, g e h (S4 e S5) sem mudar Kd e, quando To desce, a máquina volta a S0 (F desce com K = 0: Ti desce, sem disparo).'),
    ...Figura(N, 'fig_sim_tecla', 'viv_tecla_sim.png', 16.9, 'Simulação da gestão de uma tecla (T = 200 ns): as cinco situações do testbench.'),
    ...Figura(N, 'fig_sim_tecla_det', 'viv_tecla_detalhe_sim.png', 16.9, 'Pormenor da primeira pressão: ressaltos ao premir e ao largar, como na Fig. 2 do enunciado.'),
    P('A ' + r('fig_sim_tecla_curta') + ' mostra as outras duas situações. Na pressão curta (K a 1 só de 1101 a 1151 ns), Kd mantém-se a 1 até ao fim da temporização: quando To desce com K = 0, a máquina faz S2 → S3 → S4 (transição indireta), Kd desce e F sobe, o que faz Ti subir e dispara a temporização ao largar. Assim, um impulso na tecla, por curto que seja, dá um impulso em Kd de pelo menos T, e uma tecla largada durante a temporização nunca é perdida. Na nova pressão durante a temporização ao largar (2351 ns), a máquina fica em S5 (h) com Kd = 0 até To descer e faz depois S5 → S0 → S1: Kd sobe e começa a temporização ao premir.'),
    ...Figura(N, 'fig_sim_tecla_curta', 'viv_tecla_curta_sim.png', 16.9, 'Pressão mais curta do que a temporização e nova pressão durante a temporização ao largar.'),
    P('A ' + r('fig_sim_tecla_clear') + ' mostra a quinta situação: com a tecla premida (S3), o Clear aos 3901 ns põe a máquina em S0 (Kd desce) e Ti a 0, e dura 400 ns, mais do que T. Quando é libertado (4301 ns) com a tecla premida, a máquina vai para S1 (Kd sobe) e Ti sobe ao mesmo tempo, pelo que To sobe e a máquina segue para S2 e, no fim da temporização, para S3. Ao largar a tecla (4801 ns), a máquina volta normalmente a S0. Sem a porta AND com /Clear, este teste falha (' + r('tab_mut') + ').'),
    ...Figura(N, 'fig_sim_tecla_clear', 'viv_tecla_clear_sim.png', 16.9, 'Clear mais longo do que a temporização com a tecla premida: a libertação do Clear dispara o temporizador.'),

    // =====================================================================================
    H1('6 Validação das teclas'),
    P('A validação (' + r('lst_val') + ') é uma função combinatória das três teclas já sem ressaltos. U é a soma dos três mintermos com uma só variável a 1; M é a função maioria (pelo menos duas teclas), que já está na forma mínima (' + r('tab_val') + ').'),
    ...Tabela(N, 'tab_val', 'Tabela de verdade da validação.',
      ['Kd1 Kd2 Kd3', 'Teclas premidas', 'U', 'M'],
      [['000', '0', '0', '0'], ['001', '1', '1', '0'], ['010', '1', '1', '0'], ['011', '2', '0', '1'],
       ['100', '1', '1', '0'], ['101', '2', '0', '1'], ['110', '2', '0', '1'], ['111', '3', '0', '1']],
      [1.5, 1.5, 1, 1], { largura: 5000, juntar: true, mono: { 0: true } }),
    ...Listagem(N, 'lst_val', 'validacao/validacao.v', 'Validação das teclas'),
    P('Como as entradas Kd mudam de forma assíncrona e independente, U e M podem ter picos de nanossegundos quando duas teclas mudam quase ao mesmo tempo (por exemplo, uma é largada e outra premida). Os LEDs não os mostram; no projeto final, estes sinais deverão ser lidos de forma síncrona (como a tecla Start no 2.º trabalho), e um pico de nanossegundos entre dois flancos do relógio não tem efeito.'),
    P(`O testbench (${r('lst_tb_val')}, no Anexo A) percorre as 8 combinações em código de Gray (uma tecla de cada vez), com U e M esperados escritos à mão. Resultado: \`Simulacao OK (${R.ver.validacao_teste1} verificacoes)\` (${r('fig_sim_val')}).`),
    ...Figura(N, 'fig_sim_val', 'viv_validacao_sim.png', 16.9, 'Simulação da validação: U com uma só tecla e M com duas ou três.'),
  ];
};
