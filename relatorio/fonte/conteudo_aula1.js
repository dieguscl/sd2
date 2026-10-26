// Seccoes 1 a 4 do relatorio: introducao e modulos da aula 1.
const { P, Bullet, H1, H2, Figura, FiguraPorTirar, Tabela, Listagem } = require('./lib');
const { AlignmentType } = require('docx');

module.exports = function aula1(N, R) {
  const r = id => N.ref(id);
  return [
    // =====================================================================================
    H1('1 Introdução', false),
    P('Este relatório descreve o 1.º Trabalho de Laboratório de Sistemas Digitais II: o controlo do *display* de 7 segmentos e 4 dígitos da placa Basys3, percorrendo o fluxo completo de projeto no Vivado (versão ' + R.versaoVivado + ', licença WebPACK) e no Digital (versão ' + R.versaoDigital + ').'),
    P('Os módulos mais simples foram desenhados e simulados no Digital e exportados para Verilog; os restantes foram escritos diretamente no Vivado. Para cada módulo apresentam-se o código, as restrições, o *testbench* e a simulação comentada; as listagens dos *testbenches*, exceto a primeira (secção 2.5), estão no Anexo A.'),

    // =====================================================================================
    H1('2 Multiplexer 4x1'),
    H2('2.1 Desenho do circuito no Digital'),
    P('O *multiplexer* 4x1 foi desenhado no Digital com quatro portas AND de 3 entradas e uma OR de 4 entradas (' + r('fig_mux_esq') + '): para cada combinação da seleção, só uma das AND deixa passar a respetiva entrada:'),
    P('DataOut = Sel1′·Sel0′·DataIn0 + Sel1′·Sel0·DataIn1 + Sel1·Sel0′·DataIn2 + Sel1·Sel0·DataIn3', { align: AlignmentType.CENTER, run: { italics: true } }),
    ...Figura(N, 'fig_mux_esq', 'dig_mux_esquema.png', 11.5, 'Circuito final do *multiplexer* 4x1 desenhado no Digital.'),

    H2('2.2 Simulação no Digital'),
    P('A ' + r('fig_mux_sim') + ' mostra um dos ensaios no simulador do Digital: com Sel1 Sel0 = 10 a saída segue DataIn2 (= 1), apesar de DataIn0 também estar a 1. O ensaio foi repetido para as quatro seleções.'),
    ...Figura(N, 'fig_mux_sim', 'dig_mux_sim.png', 11.5, 'Simulação do *multiplexer* 4x1 no Digital (Sel1 = 1, Sel0 = 0, DataIn0 = DataIn2 = 1, DataOut = 1).'),

    H2('2.3 Exportação para Verilog'),
    P('O circuito foi exportado com File > Export > Export to Verilog (' + r('lst_mux_v') + ').'),
    ...Listagem(N, 'lst_mux_v', 'multiplexer4x1/multiplexer4x1.v', 'Código Verilog do *multiplexer* 4x1 gerado pelo Digital'),

    H2('2.4 Projeto no Vivado e ficheiro de restrições'),
    P('No Vivado criou-se o projeto `multiplexer4x1` para a FPGA da Basys3 (`xc7a35ticpg236-1L`). Nas restrições (' + r('lst_mux_xdc') + ') as entradas de dados ficaram nos interruptores SW0 a SW3, em vez das teclas do enunciado, para o estado de todas as entradas ficar visível; a seleção ficou em SW5 e SW4 e a saída no LED LD0.'),
    ...Listagem(N, 'lst_mux_xdc', 'multiplexer4x1/multiplexer4x1.xdc', 'Ficheiro de restrições do *multiplexer* 4x1'),

    H2('2.5 Testbench e simulação'),
    P('O *testbench* (' + r('lst_mux_tb') + ') segue a estrutura do enunciado (entradas `reg`, saída `wire`, instância UUT e ciclo `for` com `case`, de 50 em 50 ns). Para cada seleção coloca a 1 primeiro **só** a entrada selecionada (Z = 1) e depois **todas as outras** (Z = 0), o que mostra que só a entrada selecionada influencia a saída (' + r('tab_mux_tb') + '). Um bloco `always` compara `Z` com `D[S]` e escreve o resultado na consola.'),
    ...Tabela(N, 'tab_mux_tb', 'Sequência aplicada no *testbench* do *multiplexer* 4x1 e valores esperados de Z.',
      ['Instante (ns)', 'S', 'D (DataIn3..0)', 'Z esperado', 'Observação'],
      [['0', '00', '0000', '0', 'Estado inicial'],
       ['250', '00', '0001', '1', 'Só a entrada 0 a 1'],
       ['300', '00', '1110', '0', 'Todas a 1 menos a 0'],
       ['350', '01', '1110', '1', 'Seleciona a entrada 1'],
       ['400', '01', '0010', '1', 'Só a entrada 1 a 1'],
       ['450', '01', '1101', '0', 'Todas a 1 menos a 1'],
       ['500', '10', '1101', '1', 'Seleciona a entrada 2'],
       ['550', '10', '0100', '1', 'Só a entrada 2 a 1'],
       ['600', '10', '1011', '0', 'Todas a 1 menos a 2'],
       ['650', '11', '1011', '1', 'Seleciona a entrada 3'],
       ['700', '11', '1000', '1', 'Só a entrada 3 a 1'],
       ['750', '11', '0111', '0', 'Todas a 1 menos a 3'],
       ['800', '11', '1111', '1', 'Todas a 1'],
       ['850 / 900 / 950', '10 / 01 / 00', '1111', '1', 'Seleção percorre 2, 1 e 0'],
       ['1000', '00', '0000', '0', 'Todas a 0']],
      [2, 2, 2, 1.5, 3.5], { mono: [false, true, true, true, false], alinhar: { 4: AlignmentType.LEFT } }),
    ...Listagem(N, 'lst_mux_tb', 'multiplexer4x1/multiplexer4x1_teste1.v', '*Testbench* do *multiplexer* 4x1'),
    P('Na simulação (' + r('fig_viv_mux') + ') `Z` coincide em todos os intervalos com a ' + r('tab_mux_tb') + '; a consola indicou `Simulacao OK: multiplexer4x1 sem erros`.'),
    ...Figura(N, 'fig_viv_mux', 'viv_mux4x1_sim.png', 16.5, 'Simulação comportamental do *multiplexer* 4x1 no Vivado.'),

    H2('2.6 Geração do bitstream e ensaio na Basys3'),
    P('A síntese, a implementação e a geração do *bitstream* decorreram sem erros (' + R.util.multiplexer4x1.lut + ' LUT: a função de 6 variáveis cabe numa LUT da Artix-7) e o ficheiro foi carregado com o Adept. Na placa (' + r('fig_placa_mux') + '), SW5 SW4 = 01 seleciona SW1, que está a 1, e o LED LD0 acende.'),
    ...Figura(N, 'fig_placa_mux', 'placa_mux4x1.jpg', 13, 'Ensaio do *multiplexer* 4x1 na placa Basys3: seleção 01 e SW1 = 1, LD0 aceso.'),

    // =====================================================================================
    H1('3 Descodificador 2x4 com enables individuais'),
    P('Desenhou-se um descodificador de 2 *bits* com um *enable* por saída (Fig. 26 do enunciado): a saída selecionada por Bit1 Bit0 só fica a 1 se o seu *enable* estiver a 1, e os outros *enables* não têm efeito. No controlador (secção 8) escolhe o *display* ativo e os *enables* ligam ou desligam cada *display*.'),
    P('Out0 = Bit1′·Bit0′·En0     Out1 = Bit1′·Bit0·En1     Out2 = Bit1·Bit0′·En2     Out3 = Bit1·Bit0·En3', { align: AlignmentType.CENTER, run: { italics: true } }),
    ...Figura(N, 'fig_dec_esq', 'dig_dec_esquema.png', 10.5, 'Esquema do descodificador 2x4 com *enables* individuais desenhado no Digital.'),
    P('Na simulação no Digital (' + r('fig_dec_sim') + '), com Bit1 Bit0 = 10 e En1 = En2 = 1, só Out2 fica a 1 (' + r('tab_dec') + ').'),
    ...Figura(N, 'fig_dec_sim', 'dig_dec_sim.png', 10.5, 'Simulação do descodificador 2x4 no Digital (Bit1 = 1, Bit0 = 0, En1 = En2 = 1): só Out2 fica a 1.'),
    ...Tabela(N, 'tab_dec', 'Funcionamento do descodificador 2x4 com *enables* individuais (X = indiferente).',
      ['Bit1', 'Bit0', 'En3 En2 En1 En0', 'Out3 Out2 Out1 Out0'],
      [['0', '0', 'X X X 1', '0 0 0 1'], ['0', '1', 'X X 1 X', '0 0 1 0'], ['1', '0', 'X 1 X X', '0 1 0 0'], ['1', '1', '1 X X X', '1 0 0 0'],
       ['X', 'X', 'En*i* = 0 (*i* = código selecionado)', '0 0 0 0']],
      [1, 1, 2, 2], { largura: 7000, mono: [false, false, true, true] }),
    P('O código exportado (' + r('lst_dec_v') + ') tem uma atribuição contínua por saída. Nas restrições (' + r('lst_dec_xdc') + ') a seleção ficou em SW15 e SW14, os *enables* em SW0 a SW3 e as saídas em LD0 a LD3, cada *enable* por baixo do LED que controla.'),
    ...Listagem(N, 'lst_dec_v', 'descodificador2x4/descodificador2x4.v', 'Código Verilog do descodificador 2x4 gerado pelo Digital'),
    ...Listagem(N, 'lst_dec_xdc', 'descodificador2x4/descodificador2x4.xdc', 'Ficheiro de restrições do descodificador 2x4'),
    P('O *testbench* (' + r('lst_dec_tb') + ', no Anexo A) percorre os quatro códigos com todos os *enables* a 1, desliga depois os *enables* um a um e confirma que o *enable* de uma saída não selecionada não acende nada; a saída é comparada com `(4\'b0001 << B) & E`. Na ' + r('fig_viv_dec') + ' a saída ativa percorre O0 a O3 entre 250 e 400 ns e passa a 0000 sempre que se desliga o *enable* da saída selecionada. Resultado: `Simulacao OK: descodificador2x4 sem erros`; *bitstream* sem erros (' + R.util.descodificador2x4.lut + ' LUT).'),
    ...Figura(N, 'fig_viv_dec', 'viv_dec_sim.png', 16.5, 'Simulação comportamental do descodificador 2x4 no Vivado.'),
    P('Na placa (' + r('fig_placa_dec') + '): em (a), SW15 SW14 = 01 com SW1 ligado acende só LD1; em (b), 10 com SW2 ligado acende só LD2. Os *enables* das saídas não selecionadas não acendem nada.'),
    ...Figura(N, 'fig_placa_dec', 'placa_dec.jpg', 16.5, 'Ensaio do descodificador 2x4 na placa Basys3: (a) saída 1 selecionada, LD1 aceso; (b) saída 2 selecionada, LD2 aceso.'),

    // =====================================================================================
    H1('4 Multiplexer 16x4'),
    P('O *multiplexer* 16x4 (Fig. 27 do enunciado) foi criado no Vivado por **hierarquia de módulos**, ou seja, com uma descrição **estrutural**: quatro *multiplexers* 4x1 com a seleção partilhada, em que `mux`*i* trata o *bit* *i* das quatro entradas (' + r('lst_mux16') + '). A hierarquia (' + r('fig_viv_hier') + ') é igual à da Fig. 29 do enunciado.'),
    ...Listagem(N, 'lst_mux16', 'multiplexer16x4/multiplexer16x4.v', '*Multiplexer* 16x4 construído com quatro *multiplexers* 4x1'),
    ...Figura(N, 'fig_viv_hier', 'viv_mux16x4_hierarquia.png', 8.5, 'Hierarquia de módulos do *multiplexer* 16x4 na janela *Sources* do Vivado.'),
    P('As entradas usam os 16 interruptores, a seleção duas teclas e a saída os LEDs LD3 a LD0 (' + r('tab_mux16_pinos') + ' e ' + r('lst_mux16_xdc') + ').'),
    ...Tabela(N, 'tab_mux16_pinos', 'Ligação dos sinais do *multiplexer* 16x4 à Basys3.',
      ['Sinal', 'Elemento da Basys3'],
      [['DataIn0[3:0]', 'Interruptores SW3 a SW0'], ['DataIn1[3:0]', 'Interruptores SW7 a SW4'], ['DataIn2[3:0]', 'Interruptores SW11 a SW8'],
       ['DataIn3[3:0]', 'Interruptores SW15 a SW12'], ['Sel[1] / Sel[0]', 'Teclas BTNL / BTNR (premida = 1)'], ['DataOut[3:0]', 'LEDs LD3 a LD0']],
      [1, 2], { largura: 6500 }),
    ...Listagem(N, 'lst_mux16_xdc', 'multiplexer16x4/multiplexer16x4.xdc', 'Ficheiro de restrições do *multiplexer* 16x4'),
    P('O *testbench* (' + r('lst_mux16_tb') + ', no Anexo A) coloca A, 5, C e 3 nas entradas e percorre as seleções; depois muda uma entrada não selecionada (a saída não muda) e a selecionada (a saída acompanha-a) e aplica 1, 2, 4 e 8 para confirmar a ligação de cada *bit*. Na ' + r('fig_viv_mux16') + ' a saída é sempre igual à entrada selecionada. Resultado: `Simulacao OK: multiplexer16x4 sem erros`; *bitstream* sem erros (' + R.util.multiplexer16x4.lut + ' LUT, uma por *bit*).'),
    ...Figura(N, 'fig_viv_mux16', 'viv_mux16x4_sim.png', 16.5, 'Simulação comportamental do *multiplexer* 16x4 no Vivado.'),
    P('Na placa (' + r('fig_placa_mux16') + ') cada grupo de interruptores tem um valor e as teclas escolhem o grupo mostrado nos LEDs: (a) com BTNR premida, 1010 (DataIn1); (b) com as duas teclas, 1001 (DataIn3).'),
    ...Figura(N, 'fig_placa_mux16', 'placa_mux16x4.jpg', 16.5, 'Ensaio do *multiplexer* 16x4 na placa Basys3: (a) BTNR premida, entrada DataIn1; (b) BTNL e BTNR premidas, entrada DataIn3.'),
  ];
};
