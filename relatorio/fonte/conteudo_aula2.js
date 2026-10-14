// Seccoes 5 a 7 do relatorio: modulos da aula 2.
const { P, Bullet, H1, H2, Figura, FiguraPorTirar, Tabela, Listagem } = require('./lib');
const { AlignmentType } = require('docx');

module.exports = function aula2(N, R) {
  const r = id => N.ref(id);
  return [
    // =====================================================================================
    H1('5 Transcodificador BCD para display de 7 segmentos'),
    P('O transcodificador `Transcod7Seg` recebe o barramento `Numero[3:0]` e produz o barramento `Segmentos[6:0]`, em que o *bit* mais significativo (índice 6) corresponde ao segmento *a* e o menos significativo (índice 0) ao segmento *g*. As saídas são **ativas a Low**: um *bit* a 0 acende o respetivo segmento. O ponto decimal não é tratado neste módulo.'),
    P('Para as entradas 0 a 9 foram usadas as configurações dos algarismos da Fig. 30 do enunciado. Para as entradas 10 a 15, que não são BCD, foram criados símbolos originais (' + r('tab_simbolos') + ' e ' + r('fig_simbolos') + '): as iniciais dos dois elementos do grupo, **r** e **d**, as letras **L**, **E** e **C** (de LEEC) e um traço. As letras foram escolhidas de forma a não se confundirem com nenhum algarismo: o "r" usa só os segmentos *e* e *g*, o "d" é minúsculo (o "D" maiúsculo seria igual ao 0) e o "C" não tem o segmento *g*, ao contrário do 6. Os 16 símbolos são todos diferentes entre si, o que é verificado no *testbench*.'),
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
    P('O módulo foi adaptado do transcodificador `Transcod7Seg` dos exemplos Verilog disponibilizados no Moodle, que tem erros introduzidos intencionalmente; esses erros e as correções feitas são analisados na secção 9.2. O código final está na ' + r('lst_transcod') + '. Por ser um circuito combinatório, a saída é declarada `output reg` e atribuída num bloco `always @(*)` com atribuições bloqueantes (`=`); como os 16 valores possíveis da entrada estão todos no `case`, o `default` nunca é usado, mas mantém-se por segurança.'),
    ...Listagem(N, 'lst_transcod', 'transcod7seg/transcod7seg.v', 'Transcodificador para *display* de 7 segmentos (adaptado do exemplo do Moodle)'),
    P('O *testbench* (' + r('lst_transcod_tb') + ') guarda uma tabela de referência escrita em lógica positiva (segmentos **acesos**), fácil de comparar com a Fig. 30, e compara a saída com a negação dessa tabela. Verifica ainda que nenhum segmento fica indefinido (X ou Z), que os 16 símbolos são todos diferentes e que a saída só depende do valor atual da entrada: para isso, depois de percorrer os 16 valores por ordem crescente, repete-os duas vezes por ordem aleatória (48 verificações no total).'),
    ...Listagem(N, 'lst_transcod_tb', 'transcod7seg/transcod7seg_teste1.v', '*Testbench* do transcodificador'),
    P('A ' + r('fig_viv_transcod') + ' mostra a primeira parte da simulação (de 200 a 1000 ns), em que `N` percorre os valores de 0 a 15 de 50 em 50 ns. Para cada valor, os *bits* de `S` coincidem com a coluna Segmentos[6:0] da ' + r('tab_simbolos') + ': por exemplo, para N = 8 todos os *bits* estão a 0 (todos os segmentos acesos) e para N = 15 só `S[0]` (segmento *g*) está a 0; entre 700 e 1000 ns veem-se os símbolos originais r, d, L, E, C e -. O simulador indicou `Simulacao OK: Transcod7Seg sem erros (48 verificacoes)`.'),
    ...Figura(N, 'fig_viv_transcod', 'viv_transcod_sim.png', 16.5, 'Simulação comportamental do transcodificador no Vivado (200 a 1000 ns).'),

    H2('5.1 Ensaio do transcodificador na placa'),
    P('Para ensaiar o transcodificador isoladamente na Basys3, criou-se o módulo de topo `displayBCD` (' + r('lst_displaybcd') + '): o valor a apresentar vem dos interruptores SW3 a SW0 e os interruptores SW15 a SW12 escolhem quais dos quatro *displays* acendem. Como os ânodos comuns são ativos a *Low*, o módulo nega o valor desses interruptores; o ponto decimal fica sempre apagado (nível 1). Os pinos estão na ' + r('tab_displaybcd') + ' e no ficheiro de restrições da ' + r('lst_displaybcd_xdc') + '.'),
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
    P('O *bitstream* foi gerado sem erros e o circuito ocupa ' + R.util.displayBCD.lut + ' LUT.'),
    P('Na ' + r('fig_placa_transcod') + ' mostram-se dois ensaios na placa. Em (a), só SW12 está ligado e SW3 a SW0 = 1011: o *display* da direita apresenta o símbolo original "d" (valor 11). Em (b), com SW15, SW13 e SW12 ligados e SW3 a SW0 = 0101, três *displays* apresentam o algarismo 5 e o segundo a contar da esquerda fica apagado, o que confirma a negação dos ânodos.'),
    ...Figura(N, 'fig_placa_transcod', 'placa_transcod.jpg', 16.5, 'Ensaio do transcodificador na placa Basys3: (a) símbolo "d" no *display* da direita; (b) algarismo 5 em três *displays*.'),

    // =====================================================================================
    H1('6 Registo de 4 bits com clear e enable'),
    P('O registo `Registo4` foi construído com quatro instâncias da primitiva **FDCE** da Xilinx, uma por *bit* (' + r('lst_registo') + '). A FDCE é um *flip-flop* D sensível ao flanco ascendente do relógio (`C`), com *clock enable* (`CE`) e *clear* assíncrono (`CLR`, ativo a *High*): quando `CLR = 1` a saída passa imediatamente a 0, sem esperar pelo relógio, e o *clear* tem prioridade sobre a carga; com `CLR = 0`, a saída copia a entrada `D` em cada flanco ascendente do relógio se `CE = 1` e mantém o valor se `CE = 0`. O parâmetro `INIT` define o valor inicial do *flip-flop* após a configuração da FPGA (neste caso, 0). As portas do módulo seguem a Fig. 31 do enunciado (`Data`, `CE`, `Clk`, `CLR` e `DataOut`). A instanciação segue o modelo disponível no Vivado em Tools > Language Templates (Verilog > Device Primitive Instantiation > Artix-7 > Register > FDCE).'),
    ...Listagem(N, 'lst_registo', 'registo4/registo4.v', 'Registo de 4 *bits* com quatro primitivas FDCE'),
    P('O *testbench* (' + r('lst_registo_tb') + ') usa um relógio de 100 MHz, como o da placa, e tem duas partes:'),
    Bullet('**casos dirigidos**, que mostram uma a uma as propriedades do registo: valor inicial 0; com `CE = 0` não carrega; com `CE = 1` carrega no flanco ascendente e mantém o valor entre flancos; o `CLR` limpa o registo imediatamente, a meio de um ciclo, e tem prioridade sobre `CE`; depois de libertar o `CLR` o registo só volta a carregar no flanco seguinte; carregamento dos 16 valores possíveis e de um *bit* a 1 (e um *bit* a 0) em cada posição;'),
    Bullet('**2000 ciclos com entradas aleatórias** (`Data`, `CE` e `CLR`, com o `CLR` a mudar em instantes que não coincidem com o relógio). A saída é comparada continuamente com um **modelo de referência** comportamental escrito no próprio *testbench*, e verifica-se que a saída nunca muda fora de um flanco ascendente, a não ser com `CLR` ativo.'),
    ...Listagem(N, 'lst_registo_tb', 'registo4/registo4_teste1.v', '*Testbench* do registo de 4 *bits*'),
    P('A ' + r('fig_viv_registo') + ' mostra os casos dirigidos. Aos 101 ns `D` passa a 5 com `CE = 0` e a saída `Q` mantém-se a 0; quando `CE` passa a 1, `Q` carrega o 5 no flanco ascendente seguinte (115 ns) e o A no flanco de 125 ns. Com `CE = 0`, `Q` mantém o A durante cinco ciclos, embora `D` seja 3. Aos 183 ns, **entre dois flancos**, o `CLR` vai a 1 e `Q` passa imediatamente a 0 (*clear* assíncrono); durante o impulso de `CLR`, mesmo com `CE = 1` e `D = F`, o registo continua a 0. Só no flanco de 205 ns, depois de o `CLR` voltar a 0, carrega o F. Seguem-se os valores 0 a F e os padrões 1, E, 2, D, 4, B, 8, 7 (um *bit* a 1 e um *bit* a 0 em cada posição). O modelo de referência (`referencia`, na última linha) coincide sempre com `Q`. Na consola: `Simulacao OK: Registo4 sem erros (' + R.verificacoesRegisto + ' verificacoes)`.'),
    ...Figura(N, 'fig_viv_registo', 'viv_registo4_sim.png', 16.5, 'Simulação do registo de 4 *bits* no Vivado: casos dirigidos (0 a 460 ns).'),

    // =====================================================================================
    H1('7 Divisor de clock e contador de módulo 4'),
    H2('7.1 Divisor de clock'),
    P('O relógio da Basys3 tem 100 MHz, uma frequência demasiado elevada para o varrimento dos *displays*. O divisor de *clock* `DivisorClock` (' + r('lst_divisor') + ') conta ciclos de `ClockIn` e inverte `ClockOut` ao fim de `METADE` ciclos, pelo que `ClockOut` está `METADE` ciclos a 1 e `METADE` ciclos a 0 (*duty cycle* de 50 %):'),
    P('f_out = f_in / (2 × METADE) = 100 MHz / (2 × 25 000) = 2 kHz', { align: AlignmentType.CENTER, run: { italics: true } }),
    P('O valor por omissão (`METADE = 25000`) dá 2 kHz, dentro do intervalo pedido (1 kHz a 10 kHz). `METADE` é um parâmetro do módulo, o que permite usar valores pequenos na simulação e, na placa, um valor muito maior para fazer *debug* visual (por exemplo, `METADE = 25_000_000` dá 2 Hz e permite ver cada *display* a acender individualmente). O módulo foi obtido simplificando os divisores `clk_div` e `Clock_Divider` dos exemplos Verilog do Moodle (secção 9.3): retiraram-se as entradas de *enable* e de *reset*, que não são necessárias neste projeto, e corrigiu-se a contagem para durar exatamente `METADE` ciclos.'),
    ...Listagem(N, 'lst_divisor', 'divisorclock/divisorclock.v', 'Divisor de *clock* (baseado nos exemplos do Moodle)'),
    P('O *testbench* (' + r('lst_divisor_tb') + ') instancia o mesmo divisor com `METADE` igual a 1, 2, 5 e 7 e, em todos os períodos (pelo menos 50 por instância), mede o tempo a 1 e o tempo a 0 da saída e confirma que são exatamente `METADE` ciclos de 10 ns e que a saída só muda nos flancos ascendentes de `ClockIn`. Simula também uma instância com o valor da placa (25 000) durante 12 períodos de saída (6 ms de simulação) e confirma que a saída está 250 000 ns a 1 e 250 000 ns a 0, ou seja, que a frequência é 2000 Hz, dentro do intervalo pedido.'),
    ...Listagem(N, 'lst_divisor_tb', 'divisorclock/divisorclock_teste1.v', '*Testbench* do divisor de *clock*'),
    P('Na ' + r('fig_viv_divisor') + ' vê-se que `Out1` muda a cada ciclo de `Clk` (período de 20 ns), `Out2` a cada 2 ciclos, `Out5` a cada 5 e `Out7` a cada 7 ciclos (período de 140 ns), sempre num flanco ascendente de `Clk`. O contador interno da instância com `METADE = 7` conta de 0 a 6 e volta a 0, momento em que a saída é invertida. Resultado: `Simulacao OK: DivisorClock sem erros`.'),
    ...Figura(N, 'fig_viv_divisor', 'viv_divisor_sim.png', 16.5, 'Simulação do divisor de *clock* no Vivado para METADE = 1, 2, 5 e 7 (0 a 400 ns).'),

    H2('7.2 Contador de módulo 4'),
    P('O contador `Contador4` (' + r('lst_contador') + ') é um registo de 2 *bits* que soma 1 em cada flanco ascendente de `Clock`; como 3 + 1 = 4 não cabe em 2 *bits*, o estado volta naturalmente a 0, o que dá a sequência 0, 1, 2, 3, 0, … O módulo foi obtido a partir do "contador simples" dos exemplos Verilog do Moodle, retirando o que não era necessário (secção 9.4). As saídas `Q1` e `Q0` são as variáveis de varrimento `Control1` e `Control0` da Fig. 31, que atuam na seleção dos *multiplexers* e nas entradas do descodificador. Com o relógio de 2 kHz do divisor, cada *display* fica ativo durante 0,5 ms e o ciclo completo dos quatro *displays* repete-se 500 vezes por segundo; pela persistência da imagem na retina, o observador tem a sensação de que os quatro *displays* estão sempre acesos.'),
    ...Listagem(N, 'lst_contador', 'contador4/contador4.v', 'Contador de módulo 4 (baseado no exemplo do Moodle)'),
    P('O *testbench* (' + r('lst_contador_tb') + ') verifica o estado inicial (0) e a sequência durante 100 flancos (25 voltas completas); confirma também que o estado não muda no flanco descendente e que as saídas mudam exatamente uma vez por ciclo, sempre no instante de um flanco ascendente. Na ' + r('fig_viv_contador') + ' observa-se a sequência 0, 1, 2, 3, 0, … no estado interno, com `Q0` a mudar em todos os flancos ascendentes e `Q1` a cada dois. Resultado: `Simulacao OK: Contador4 sem erros (100 ciclos)`.'),
    ...Listagem(N, 'lst_contador_tb', 'contador4/contador4_teste1.v', '*Testbench* do contador de módulo 4'),
    ...Figura(N, 'fig_viv_contador', 'viv_contador4_sim.png', 16.5, 'Simulação do contador de módulo 4 no Vivado (0 a 300 ns).'),
  ];
};
