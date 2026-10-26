// Seccoes 5 a 7 do relatorio: modulos da aula 2.
const { P, Bullet, H1, H2, Figura, FiguraPorTirar, Tabela, Listagem } = require('./lib');
const { AlignmentType } = require('docx');

module.exports = function aula2(N, R) {
  const r = id => N.ref(id);
  return [
    // =====================================================================================
    H1('5 Transcodificador BCD para display de 7 segmentos'),
    P('O transcodificador `Transcod7Seg` converte `Numero[3:0]` em `Segmentos[6:0]` (índice 6 = segmento *a*, índice 0 = segmento *g*), com saídas **ativas a Low**. Para 0 a 9 usaram-se os algarismos da Fig. 30 do enunciado; para 10 a 15 criaram-se símbolos originais (' + r('tab_simbolos') + ' e ' + r('fig_simbolos') + '): as iniciais do grupo, **r** e **d**, as letras **L**, **E** e **C** (de LEEC) e um traço, escolhidos para não se confundirem com nenhum algarismo (por exemplo, o "d" é minúsculo porque o "D" seria igual ao 0).'),
    ...Tabela(N, 'tab_simbolos', 'Configuração dos segmentos para cada valor de Numero (0 = segmento aceso).',
      ['Numero', 'Segmentos[6:0] (a b c d e f g)', 'Segmentos acesos', 'Símbolo'],
      [['0', '0000001', 'a b c d e f', '0'], ['1', '1001111', 'b c', '1'], ['2', '0010010', 'a b d e g', '2'],
       ['3', '0000110', 'a b c d g', '3'], ['4', '1001100', 'b c f g', '4'], ['5', '0100100', 'a c d f g', '5'],
       ['6', '0100000', 'a c d e f g', '6'], ['7', '0001111', 'a b c', '7'], ['8', '0000000', 'a b c d e f g', '8'],
       ['9', '0000100', 'a b c d f g', '9'], ['10', '1111010', 'e g', 'r'], ['11', '1000010', 'b c d e g', 'd'],
       ['12', '1110001', 'd e f', 'L'], ['13', '0110000', 'a d e f g', 'E'], ['14', '0110001', 'a d e f', 'C'],
       ['15', '1111110', 'g', '-']],
      [1, 2.4, 2, 1.8], { largura: 8000, mono: [false, true, false, false], destaque: (l) => (+l[0] >= 10 ? 'FCE4D6' : undefined) }),
    ...Figura(N, 'fig_simbolos', 'simbolos7seg.png', 16, 'Os 16 símbolos do transcodificador, desenhados a partir dos valores de `transcod7seg.v` (a vermelho os segmentos acesos).'),
    P('O módulo (' + r('lst_transcod') + ') foi adaptado do exemplo do Moodle, cujos erros são analisados na secção 9.2. Sendo combinatório, a saída é `output reg` atribuída num `always @(*)` com atribuições bloqueantes.'),
    ...Listagem(N, 'lst_transcod', 'transcod7seg/transcod7seg.v', 'Transcodificador para *display* de 7 segmentos (adaptado do exemplo do Moodle)'),
    P('O *testbench* (' + r('lst_transcod_tb') + ', no Anexo A) compara a saída com uma tabela de referência dos segmentos acesos, verifica que não há segmentos indefinidos e que os 16 símbolos são diferentes, e repete os valores por ordem aleatória (48 verificações). Na ' + r('fig_viv_transcod') + ' os *bits* de `S` coincidem para cada `N` com a ' + r('tab_simbolos') + ' (por exemplo, todos a 0 para N = 8). Resultado: `Simulacao OK: Transcod7Seg sem erros (48 verificacoes)`.'),
    ...Figura(N, 'fig_viv_transcod', 'viv_transcod_sim.png', 16.5, 'Simulação comportamental do transcodificador no Vivado (200 a 1000 ns).'),

    H2('5.1 Ensaio do transcodificador na placa'),
    P('Para o ensaio na placa criou-se o módulo de topo `displayBCD` (' + r('lst_displaybcd') + ', ' + r('tab_displaybcd') + ' e ' + r('lst_displaybcd_xdc') + '): o valor vem de SW3 a SW0 e SW15 a SW12 escolhem os *displays* que acendem (negados, porque os ânodos são ativos a *Low*); o ponto decimal fica apagado.'),
    ...Listagem(N, 'lst_displaybcd', 'transcod7seg/displayBCD.v', 'Circuito de ensaio do transcodificador'),
    ...Tabela(N, 'tab_displaybcd', 'Ligação dos sinais do circuito `displayBCD` à Basys3.',
      ['Sinal', 'Pinos da FPGA', 'Elemento da Basys3'],
      [['Numero[3:0]', 'W17 W16 V16 V17', 'Interruptores SW3 a SW0'],
       ['Liga[3:0]', 'R2 T1 U1 W2', 'Interruptores SW15 a SW12'],
       ['Segmentos[6:0]', 'W7 W6 U8 V8 U5 V5 U7', 'Segmentos CA a CG (ativos a Low)'],
       ['DotPoint', 'V7', 'Ponto decimal DP (ativo a Low)'],
       ['Anodos[3:0]', 'W4 V4 U4 U2', 'Ânodos AN3 a AN0 (ativos a Low)']],
      [2, 2.6, 3], { largura: 8500 }),
    ...Listagem(N, 'lst_displaybcd_xdc', 'transcod7seg/displayBCD.xdc', 'Ficheiro de restrições do circuito `displayBCD`'),
    P('O *bitstream* foi gerado sem erros (' + R.util.displayBCD.lut + ' LUT). Na ' + r('fig_placa_transcod') + ': em (a), só com SW12 e SW3 a SW0 = 1011, o *display* da direita mostra "d"; em (b), com SW15, SW13 e SW12 e o valor 0101, três *displays* mostram 5 e o desligado fica apagado.'),
    ...Figura(N, 'fig_placa_transcod', 'placa_transcod.jpg', 16.5, 'Ensaio do transcodificador na placa Basys3: (a) símbolo "d" no *display* da direita; (b) algarismo 5 em três *displays*.'),

    // =====================================================================================
    H1('6 Registo de 4 bits com clear e enable'),
    P('O `Registo4` (' + r('lst_registo') + ') usa quatro primitivas **FDCE** da Xilinx, uma por *bit*: *flip-flop* D sensível ao flanco ascendente, com *clock enable* (`CE`) e *clear* assíncrono (`CLR`, ativo a *High*, com prioridade sobre a carga). Com `CLR = 0` a saída copia `D` no flanco ascendente se `CE = 1` e mantém o valor se `CE = 0`; `INIT = 0` define o valor inicial. A instanciação segue o modelo do Vivado (Tools > Language Templates).'),
    ...Listagem(N, 'lst_registo', 'registo4/registo4.v', 'Registo de 4 *bits* com quatro primitivas FDCE'),
    P('O *testbench* (' + r('lst_registo_tb') + ', no Anexo A), com relógio de 100 MHz, tem casos dirigidos (valor inicial, carga só com `CE = 1`, *clear* assíncrono a meio de um ciclo e com prioridade sobre `CE`, todos os valores) e 2000 ciclos com entradas aleatórias, comparados com um modelo de referência.'),
    P('Na ' + r('fig_viv_registo') + ', com `CE = 0` a saída `Q` não muda; com `CE = 1` carrega 5 e A nos flancos de 115 e 125 ns. Aos 183 ns, entre dois flancos, o `CLR` põe `Q` imediatamente a 0, mesmo com `CE = 1`, e só no flanco seguinte (205 ns) o registo carrega o F. O modelo de referência coincide sempre com `Q`. Resultado: `Simulacao OK: Registo4 sem erros (' + R.verificacoesRegisto + ' verificacoes)`.'),
    ...Figura(N, 'fig_viv_registo', 'viv_registo4_sim.png', 16.5, 'Simulação do registo de 4 *bits* no Vivado: casos dirigidos (0 a 460 ns).'),

    // =====================================================================================
    H1('7 Divisor de clock e contador de módulo 4'),
    H2('7.1 Divisor de clock'),
    P('O `DivisorClock` (' + r('lst_divisor') + ') reduz os 100 MHz da placa para o varrimento: conta ciclos de `ClockIn` e inverte `ClockOut` ao fim de `METADE` ciclos (*duty cycle* de 50 %):'),
    P('f_out = f_in / (2 × METADE) = 100 MHz / (2 × 25 000) = 2 kHz', { align: AlignmentType.CENTER, run: { italics: true } }),
    P('`METADE = 25000` dá 2 kHz, dentro do intervalo pedido (1 a 10 kHz). Por ser um parâmetro, pode ser reduzido na simulação ou aumentado na placa para *debug* visual (25 000 000 dá 2 Hz). O módulo simplifica os divisores do Moodle (secção 9.3).'),
    ...Listagem(N, 'lst_divisor', 'divisorclock/divisorclock.v', 'Divisor de *clock* (baseado nos exemplos do Moodle)'),
    P('O *testbench* (' + r('lst_divisor_tb') + ', no Anexo A) usa `METADE` = 1, 2, 5 e 7 e confirma que a saída fica exatamente `METADE` ciclos a 1 e a 0, mudando só nos flancos ascendentes; uma instância com 25 000 confirma os 2000 Hz. Na ' + r('fig_viv_divisor') + ' `Out1` muda a cada ciclo e `Out7` a cada 7 ciclos, com o contador interno a contar de 0 a 6. Resultado: `Simulacao OK: DivisorClock sem erros`.'),
    ...Figura(N, 'fig_viv_divisor', 'viv_divisor_sim.png', 16.5, 'Simulação do divisor de *clock* no Vivado para METADE = 1, 2, 5 e 7 (0 a 400 ns).'),

    H2('7.2 Contador de módulo 4'),
    P('O `Contador4` (' + r('lst_contador') + ') é um registo de 2 *bits* que soma 1 em cada flanco ascendente e volta naturalmente a 0 depois de 3; foi obtido do "contador simples" do Moodle (secção 9.4). As saídas `Q1` e `Q0` são as variáveis de varrimento `Control1` e `Control0` da Fig. 31: a 2 kHz, cada *display* fica ativo 0,5 ms e, por persistência da imagem na retina, os quatro parecem sempre acesos.'),
    ...Listagem(N, 'lst_contador', 'contador4/contador4.v', 'Contador de módulo 4 (baseado no exemplo do Moodle)'),
    P('O *testbench* (' + r('lst_contador_tb') + ', no Anexo A) verifica o estado inicial e a sequência durante 100 flancos. Na ' + r('fig_viv_contador') + ' vê-se 0, 1, 2, 3, 0, …, com `Q0` a mudar em todos os flancos ascendentes e `Q1` a cada dois. Resultado: `Simulacao OK: Contador4 sem erros (100 ciclos)`.'),
    ...Figura(N, 'fig_viv_contador', 'viv_contador4_sim.png', 16.5, 'Simulação do contador de módulo 4 no Vivado (0 a 300 ns).'),
  ];
};
