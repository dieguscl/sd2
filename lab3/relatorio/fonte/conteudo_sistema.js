// Seccoes 1 e 2 do relatorio: introducao, especificacao, arquitetura e sinais de interface.
const { P, Bullet, H1, H2, Figura, Tabela } = require('./lib');
const { AlignmentType } = require('docx');

module.exports = function sistema(N, R) {
  const r = id => N.ref(id);
  const esq = (...c) => Object.fromEntries(c.map(i => [i, AlignmentType.LEFT]));
  return [
    // =====================================================================================
    H1('1 Introdução'),
    P('Este relatório descreve o 3.º Trabalho de Laboratório de Sistemas Digitais II: a gestão das teclas do jogo Guitar Hero na placa Basys3. Cada uma das três teclas do jogo (K1, K2 e K3) passa por um circuito que elimina o ressalto (*bouncing*) e que reage de imediato tanto ao premir como ao largar a tecla; uma função combinatória indica depois se está premida uma só tecla (U) ou mais do que uma (M).'),
    P('O cerne do trabalho é uma **máquina de estados assíncrona** (modelo de Huffman, em modo fundamental), desenhada a partir da tabela de estados primitiva pela metodologia lecionada e descrita em Verilog sem *flip-flops* nem outros elementos de memória: cada variável de estado é uma realimentação de uma equação de excitação. A máquina trabalha com um temporizador monoestável redisparável: a porta XOR entre a tecla K e a saída F da máquina escolhe o flanco da tecla que dispara o temporizador (ascendente ao premir, descendente ao largar).'),
    P('A secção 2 apresenta a especificação, a arquitetura e os sinais de interface; a secção 3 descreve o projeto da máquina de estados, passo a passo, incluindo a análise de corridas e de acidentes; as secções 4 a 6 descrevem o temporizador, a gestão de uma tecla e a validação das teclas (código, testbench e simulação); a secção 7 trata da integração, das restrições, da implementação e do ensaio na placa; a secção 8 analisa o código de fontes externas e a secção 9 conclui. As listagens dos testbenches estão no Anexo A.'),
    P(`**Ferramentas:** Vivado ${R.versaoVivado} (licença WebPACK) para a FPGA xc7a35ticpg236-1L da Basys3, draw.io para os diagramas e um *script* em Python (\`scripts/projeto.py\`) que repete e confere cada passo do projeto da máquina de estados (redução, codificação, equações, corridas e acidentes). Todos os testbenches aplicam uma sequência curta de entradas e conferem as saídas com os valores esperados, escritos no próprio testbench, terminando com \`Simulacao OK\` ou \`Simulacao FALHOU\`; a duração do temporizador é um parâmetro dos módulos e é reduzida nas simulações.`),

    // =====================================================================================
    H1('2 Especificação e arquitetura do sistema'),
    H2('2.1 Especificação funcional'),
    P('O sistema tem as três teclas do jogo, K1 (BTNL), K2 (BTNC) e K3 (BTNR), e uma tecla Reset (BTNU). Para cada tecla do jogo pretende-se (secção 2 do enunciado):'),
    Bullet('um sinal **Kd** sem ressaltos, que muda **de imediato** no primeiro flanco da tecla, tanto ao premir como ao largar, e que ignora os ressaltos que se seguem;'),
    Bullet('que os ressaltos sejam filtrados por um temporizador monoestável redisparável de duração T: cada flanco ascendente da sua entrada Ti (re)inicia a contagem e a saída To fica a 1 durante T depois do último flanco (Fig. 1 do enunciado);'),
    Bullet('que a máquina de estados comande, com a saída **F**, o flanco da tecla que dispara o temporizador: Ti = K ⊕ F, pelo que com F = 0 dispara o flanco ascendente de K (premir) e com F = 1 o flanco descendente (largar), como na Fig. 2 do enunciado.'),
    P('Com as três teclas sem ressaltos, a validação produz **U** = 1 quando exatamente uma tecla está premida e **M** = 1 quando há mais do que uma; sem teclas premidas U = M = 0.'),
    P('A tecla **Reset** não é uma entrada da máquina de estados: atua diretamente nas realimentações (secção 2.1 e Fig. 3 do enunciado), pondo as três máquinas no estado inicial S0 (código 000). Os temporizadores não são inicializados, como recomenda o enunciado: um temporizador que ainda esteja a contar no momento do Reset é um transitório inicial que a máquina deixa terminar (secção 3.3). Durante o Reset, a entrada Ti do temporizador é mantida a 0, para que a libertação do Reset com uma tecla premida seja vista como um flanco normal da tecla (secção 5).'),
    P('A duração T escolhida foi **10 ms** (1 000 000 ciclos de 100 MHz): os ressaltos das teclas duram tipicamente menos de 5 ms e 10 ms continua a ser curto face ao ritmo do jogo (no mínimo 0,2 s por passo no 2.º trabalho). Como Kd muda logo no primeiro flanco, T não atrasa a resposta à tecla; só define o tempo durante o qual os ressaltos são ignorados. T é o parâmetro `T` dos módulos `Monoestavel`, `Tecla` e `GestaoTeclas`, pelo que pode ser aumentado se o ensaio o justificar.'),
    P('Para o ensaio na placa, os LEDs LD0 a LD2 mostram Kd1 a Kd3, LD15 e LD14 mostram U e M e LD4 a LD12 as variáveis de estado das três máquinas. Um circuito auxiliar de ensaio, fora do sistema pedido, conta os flancos ascendentes das teclas antes e depois da eliminação dos ressaltos e mostra as duas contagens nos *displays*: assim vê-se na placa quantos ressaltos foram filtrados em cada pressão.'),

    H2('2.2 Arquitetura'),
    P('A ' + r('fig_arq') + ' mostra o diagrama de blocos e a ' + r('tab_blocos') + ' a função de cada bloco. A gestão de uma tecla (módulo `Tecla`) junta a máquina de estados, a porta XOR e o temporizador, e é instanciada três vezes. As máquinas de estados são assíncronas: reagem a K e a To sem relógio. O temporizador é síncrono (relógio de 100 MHz) e sincroniza a sua entrada Ti antes de detetar o flanco.'),
    ...Figura(N, 'fig_arq', 'arquitetura.png', 16.9, 'Diagrama de blocos do sistema (a gestão da tecla 1 em pormenor; as das teclas 2 e 3 são iguais).'),
    ...Tabela(N, 'tab_blocos', 'Blocos do sistema, módulos Verilog e origem.',
      ['Bloco', 'Módulo (ficheiro)', 'Função', 'Origem'],
      [['Máquina de estados assíncrona', '`MaquinaTecla` (`maquinatecla/`)', 'Tecla sem ressaltos (Kd) e comando do flanco do temporizador (F)', 'Novo (sem *flip-flops*)'],
       ['Temporizador monoestável redisparável', '`Monoestavel` (`monoestavel/`)', 'To = 1 durante T depois do último flanco ascendente de Ti', 'Novo'],
       ['Gestão de uma tecla', '`Tecla` (`tecla/`)', 'Máquina de estados + XOR + temporizador', 'Novo'],
       ['Validação', '`Validacao` (`validacao/`)', 'U (uma só tecla) e M (mais do que uma)', 'Novo'],
       ['Circuito de topo', '`GestaoTeclas` (`gestaoteclas/`)', 'Três teclas, validação, Reset e ligação aos pinos da placa', 'Novo'],
       ['Contador de impulsos (ensaio)', '`ContaImpulsos` (`ensaio/`)', 'Conta os flancos de um sinal assíncrono', 'Novo'],
       ['Gestão dos *displays* (ensaio)', '`ControloDisplays` e módulos (`modulos_lab1/`)', 'Mostra as duas contagens em hexadecimal', 'Cópia do 1.º trabalho']],
      [2.2, 2.6, 3.4, 1.6], { alinhar: esq(0, 1, 2) }),

    H2('2.3 Sinais de interface e a sua natureza'),
    P('A ' + r('tab_sinais') + ' identifica os sinais de uma tecla e do circuito de topo. Os únicos sinais síncronos são os do temporizador e do circuito de ensaio; a máquina de estados, a XOR e a validação são lógica assíncrona.'),
    ...Tabela(N, 'tab_sinais', 'Sinais de interface (por tecla e do circuito de topo).',
      ['Sinal', 'Bits', 'Origem → destino', 'Natureza', 'Função'],
      [['CLKBasys', '1', 'Oscilador (W5) → temporizadores e ensaio', 'Relógio, flanco ascendente', 'Relógio de 100 MHz'],
       ['BtnK1..3 (K)', '1+1+1', 'Teclas BTNL, BTNC, BTNR → máquinas', 'Assíncronas, com ressaltos', 'Teclas do jogo'],
       ['BtnReset', '1', 'Tecla BTNU → Clear das máquinas', 'Assíncrono, ativo a High', 'Põe as máquinas em S0'],
       ['Clear', '1', 'BtnReset + reset de arranque → realimentações', 'Assíncrono, ativo a High', 'Força YY2 = YY1 = YY0 = 0'],
       ['To', '1', 'Temporizador → máquina', 'Síncrono (saída de um *flip-flop*)', '1 enquanto o temporizador conta'],
       ['F', '1', 'Máquina → XOR', 'Assíncrono, sem picos', 'Escolhe o flanco de K que dispara o temporizador'],
       ['Ti = (K ⊕ F)·/Clear', '1', 'XOR → temporizador', 'Assíncrono', 'Entrada do temporizador (flanco ascendente); a 0 durante o Clear'],
       ['Kd1..3', '1+1+1', 'Máquinas → validação e LD0..LD2', 'Assíncronos, sem picos', 'Teclas sem ressaltos'],
       ['Estado1..3', '3+3+3', 'Máquinas → LD4..LD12', 'Depuração', 'Variáveis de estado YY2 YY1 YY0'],
       ['U, M', '1+1', 'Validação → LD15, LD14', 'Combinatórios', 'Uma só tecla / mais do que uma'],
       ['Seg, DP, An', '7+1+4', 'Ensaio → *displays*', 'Ativos a Low', 'Contagens de flancos (ensaio)']],
      [1.5, 0.8, 2.8, 2.2, 2.8], { alinhar: esq(0, 2, 3, 4), tamanho: 17 }),
  ];
};
