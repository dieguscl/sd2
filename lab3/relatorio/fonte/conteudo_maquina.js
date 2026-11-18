// Seccao 3 do relatorio: projeto da maquina de estados assincrona pelos passos da metodologia.
// As tabelas sao geradas a partir de simulacao/projeto.json (scripts/projeto.py), para coincidirem
// com o que o script conferiu.
const { P, Bullet, H1, H2, Figura, Tabela, Listagem } = require('./lib');
const { AlignmentType } = require('docx');

const COLS = ['00', '01', '11', '10'];
const VERDE = 'E2EFDA', LARANJA = 'FCE4D6', CINZA = 'EDEDED';

module.exports = function maquina(N, R) {
  const r = id => N.ref(id);
  const esq = (...c) => Object.fromEntries(c.map(i => [i, AlignmentType.LEFT]));
  const PJ = R.projeto;
  const EST = Object.keys(PJ.prim);
  const v = R.virgula;

  // --- 1. Tabela primitiva
  const prim = EST.map(s => {
    const p = PJ.prim[s];
    return [s, ...p.prox.map(n => (n === null ? '–' : n === s ? `(${n})` : n)), String(p.kd), String(p.f), p.desc];
  });

  // --- 3. Tabela de implicacoes (triangular): recalcula os pares implicados para os mostrar
  const implicados = (x, y) => {
    const px = PJ.prim[x], py = PJ.prim[y];
    if (px.kd !== py.kd || px.f !== py.f) return null;          // saidas diferentes
    const req = [];
    px.prox.forEach((nx, j) => {
      const ny = py.prox[j];
      if (nx === null || ny === null || nx === ny) return;
      const par = [nx, ny].sort().join(',');
      if (par !== [x, y].sort().join(',')) req.push(par);
    });
    return req;
  };
  const compat = new Set(PJ.compativeis.map(p => p.join(',')));
  const impl = EST.slice(1).map((s, i) => [s, ...EST.slice(0, -1).map((t, j) => {
    if (j > i) return '';
    const par = [t, s].join(',');
    const req = implicados(t, s);
    if (compat.has(par)) return '✓';
    if (req === null) return '✗';
    return req.join('; ') + ' ✗';
  })]);

  // --- 4. Tabela reduzida
  const G = PJ.grupos;
  const red = Object.entries(PJ.reduzida).map(([s, d]) => {
    const prox = d.prox.map((n, j) => {
      let t = n === null ? '–' : (n === s ? `(${n})` : n);
      if (s === 'S0' && (j === 1 || j === 2)) t += '*';
      return t;
    });
    return [s, G[s].join(', '), ...prox, String(d.kd), String(d.f)];
  });

  // --- 6. Tabela de transicoes (linhas pela ordem do anel de Johnson e depois os codigos nao usados)
  const NOME = Object.fromEntries(Object.entries(PJ.codigo).map(([k, c]) => [c, k]));
  const ordem = ['000', '001', '011', '111', '110', '100', '010', '101'];
  const indiretas = new Set(Object.keys(PJ.indiretas).map(k => { const [g, c] = k.split(','); return PJ.codigo[g] + c; }));
  const trans = ordem.map(c => [NOME[c] || '–', c, ...PJ.transicoes[c].map(x => x || '–')]);
  const fillTrans = (l, i) => {
    if (i < 2) return undefined;
    if (l[i] === '–') return undefined;
    if (l[i] === l[1]) return VERDE;
    if (indiretas.has(l[1] + COLS[i - 2])) return LARANJA;
    return undefined;
  };

  // --- atrasos (acidentes essenciais)
  const at = [];
  for (const [t, a] of Object.entries(R.atrasos)) {
    for (const [canto, k] of [['rápido', 'rapido'], ['lento', 'lento']]) {
      at.push([t.replace('tecla', 'Tecla '), canto, String(a.caso1[k].dir), String(a.caso1[k].ind), String(a.caso1[k].margem),
        String(a.caso2[k].dir), String(a.caso2[k].ind), String(a.caso2[k].margem)]);
    }
  }
  const margens = Object.values(R.atrasos).flatMap(a => [a.caso1.rapido.margem, a.caso1.lento.margem, a.caso2.rapido.margem, a.caso2.lento.margem]);
  const margemMin = Math.min(...margens);
  const slices = Object.entries(R.atrasos).map(([t, a]) => {
    const s = new Set(['Y2', 'Y1', 'Y0', 'YY2', 'YY1', 'YY0'].map(n => a['slice_' + n]));
    return `${t.replace('tecla', 'tecla ')}: ${s.size === 1 ? 'todos no ' + [...s][0] : s.size + ' *slices* vizinhos'}`;
  });

  // --- caminhos das transicoes indiretas (saidas ao longo do caminho)
  const cod = PJ.codigo;
  const saidas = c => `${c[2]}${c[0]}`;      // Kd = y0, F = y2
  const ind = [['S2', '00', 'S3', 'S4', 'Tecla largada antes do fim da temporização ao premir (d → f)'],
               ['S5', '10', 'S0', 'S1', 'Tecla premida outra vez antes do fim da temporização ao largar (h → b)'],
               ['S0', '11', 'S1', 'S2', 'Arranque: tecla premida com o temporizador a contar']]
    .map(([a, c, via, fim, desc]) => [`${a} em ${c}`, `${a} → ${via} → ${fim}`, `${cod[a]} → ${cod[via]} → ${cod[fim]}`,
      `${saidas(cod[a])} → ${saidas(cod[via])} → ${saidas(cod[fim])}`, desc]);

  // --- mutacoes
  const mut = R.mutacoes.map(m => [m.mutacao, m.falharam ? m.quais.map(q => '`' + q + '`').join(', ') : 'nenhum (ver texto)']);

  return [
    // =====================================================================================
    H1('3 Máquina de estados assíncrona'),
    P('A máquina de estados foi projetada pela metodologia lecionada para circuitos sequenciais assíncronos em modo fundamental (só muda uma entrada de cada vez e a máquina estabiliza antes da mudança seguinte), nos passos da ' + r('tab_passos') + '. Cada passo foi repetido e conferido pelo *script* `scripts/projeto.py`, que escreve o resumo em `simulacao/projeto.txt`; as tabelas desta secção são geradas a partir do resultado desse *script*.'),
    ...Tabela(N, 'tab_passos', 'Passos do projeto da máquina de estados.',
      ['Passo', 'O que se faz', 'Secção'],
      [['1', 'Construir a tabela de estados primitiva', '3.1'],
       ['2', 'Eliminar estados redundantes, por inspeção visual e por partições', '3.2'],
       ['3', 'Agregar estados compatíveis pelo método de fusão', '3.2'],
       ['4', 'Desenhar a tabela de estados reduzida', '3.3'],
       ['5', 'Determinar uma codificação dos estados livre de corridas críticas', '3.4'],
       ['6', 'Desenhar a tabela de transições (excitação)', '3.5'],
       ['7', 'Determinar o valor das saídas nas transições, sem picos', '3.6'],
       ['8 e 9', 'Equações de excitação e de saída, sem acidentes', '3.7 e 3.8'],
       ['10', 'Desenhar o diagrama lógico, com as realimentações', '3.9'],
       ['11', 'Verificar e testar o circuito', '3.10 e 7']],
      [1, 6, 1.2], { largura: 7500, alinhar: esq(1) }),

    H2('3.1 Tabela de estados primitiva (passo 1)'),
    P('As entradas da máquina são a tecla K e a saída do temporizador To; as saídas são Kd e F (saídas de Moore, associadas a cada estado). A tabela de estados primitiva (' + r('tab_prim') + ') foi construída pelo grupo a partir da Fig. 2 do enunciado, começando pela situação de repouso (tecla largada e temporizador parado, estado **a**) e criando um estado novo, estável numa só combinação das entradas, para cada situação diferente. As colunas estão em código de Gray (K To = 00, 01, 11, 10); o estado entre parênteses é o estado estável dessa linha.'),
    ...Tabela(N, 'tab_prim', 'Tabela de estados primitiva (estado seguinte para K To = 00, 01, 11 e 10).',
      ['Estado', '00', '01', '11', '10', 'Kd', 'F', 'Descrição'], prim,
      [0.9, 0.9, 0.9, 0.9, 0.9, 0.7, 0.7, 4.6],
      { juntar: true, alinhar: esq(7), destaque: (l, i) => (i >= 1 && i <= 4 && l[i].startsWith('(') ? VERDE : undefined),
        negrito: (l, i) => i === 0 || (i >= 1 && i <= 4 && l[i].startsWith('(')) }),
    P('A sequência normal da Fig. 2 é a → b → c → e → f → g → a:'),
    Bullet('**a → b** (K sobe): Kd sobe de imediato; com F = 0, Ti = K sobe e dispara o temporizador.'),
    Bullet('**b → c** (To sobe): temporização ao premir. Os ressaltos levam a máquina entre **c** (K = 1) e **d** (K = 0) sem mudar Kd, e cada regresso de K a 1 é um novo flanco de Ti, que reinicia a temporização.'),
    Bullet('**c → e** (To desce com K = 1): a tecla está premida e estável; F sobe, pelo que Ti = K ⊕ F = 0 e o temporizador passa a esperar pelo flanco descendente de K.'),
    Bullet('**e → f** (K desce): Kd desce de imediato; Ti = 0 ⊕ 1 sobe e dispara o temporizador.'),
    Bullet('**f → g** (To sobe): temporização ao largar, com os ressaltos entre **g** e **h**; **g → a** quando To desce com K = 0 (F volta a 0 com K = 0, sem flanco em Ti).'),
    P('As situações que a Fig. 2 não mostra também estão na tabela: os estados **i** e **j** cobrem um ressalto que chega antes de To subir (o temporizador sincroniza Ti, pelo que To só sobe alguns ciclos depois do flanco); a passagem **d → f** responde à pergunta do enunciado (a tecla é largada antes do fim da temporização: quando To desce com K = 0, a largada é aceite e começa a temporização ao largar, pelo que Kd fica a 1 durante pelo menos T); e **h → b** é a situação simétrica (a tecla volta a ser premida antes do fim da temporização ao largar e a nova pressão é aceite no fim da temporização).'),
    P('As células indiferentes (–) são de dois tipos: as que exigiriam mudar K e To ao mesmo tempo, que não ocorrem em modo fundamental, e duas que são impossíveis porque To não sobe sem um flanco em Ti: **a** com K To = 01 (em repouso Ti = K = 0) e **e** com K To = 11 (em **e** Ti = K ⊕ F = 0).'),

    H2('3.2 Redução de estados (passos 2 e 3)'),
    P('**Inspeção visual.** Não há duas linhas iguais (mesmas saídas e mesmos estados seguintes).'),
    P(`**Partições.** Só podem ser idênticos estados com as mesmas saídas e estáveis na mesma combinação das entradas. Os quatro estados com Kd F = 10 (b, c, d, i) são estáveis em colunas diferentes, e o mesmo acontece com os quatro com Kd F = 01 (f, g, h, j); logo, a primeira partição já tem uma classe por estado, P1 = ${PJ.particoes[0].map(b => '(' + b.join('') + ')').join('')}, e não há estados redundantes.`),
    P('**Fusão.** Dois estados são compatíveis se tiverem as mesmas saídas e se, em cada coluna, os estados seguintes forem iguais, um deles for indiferente, ou formarem um par também compatível. A tabela de implicações (' + r('tab_impl') + ') mostra o resultado: ✗ sem mais indicação quando as saídas são diferentes, e o par implicado quando a incompatibilidade vem dos estados seguintes. Por exemplo, (b, c) implica (b, e) na coluna 10, e b e e têm saídas diferentes.'),
    ...Tabela(N, 'tab_impl', 'Tabela de implicações (✓ compatível; ✗ incompatível; par implicado incompatível antes de ✗).',
      ['', ...EST.slice(0, -1)], impl, [0.7, 1, 1, 1, 1, 1, 1, 1, 1, 1],
      { juntar: true, tamanho: 16, negrito: (l, i) => i === 0, destaque: (l, i) => (l[i] === '✓' ? VERDE : (i > 0 && l[i] === '' ? CINZA : undefined)) }),
    P(`Os únicos pares compatíveis são ${PJ.compativeis.map(p => '(' + p.join(', ') + ')').join(', ')}, e nenhum deles implica outro par. O diagrama de fusão (${r('fig_fusao')}) tem por isso quatro arestas isoladas e uma só solução: (a), (b, i), (c, d), (e), (f, j), (g, h). Ficam 6 estados, que precisam de 3 variáveis de estado (2² < 6 ≤ 2³).`),
    ...Figura(N, 'fig_fusao', 'diagrama_fusao.png', 7, 'Diagrama de fusão: pares de estados compatíveis e estados da tabela reduzida.'),

    H2('3.3 Tabela de estados reduzida (passo 4)'),
    P('A ' + r('tab_red') + ' é a tabela reduzida: cada estado novo reúne os estados primitivos de uma classe. Os seis estados correspondem às fases do funcionamento: **S0** repouso; **S1** tecla premida, à espera que o temporizador arranque; **S2** temporização ao premir; **S3** tecla premida e estável; **S4** tecla largada, à espera que o temporizador arranque; **S5** temporização ao largar. A ' + r('fig_estados') + ' mostra o diagrama de estados.'),
    ...Tabela(N, 'tab_red', 'Tabela de estados reduzida (K To = 00, 01, 11, 10; * = indiferenças especificadas para o arranque).',
      ['Estado', 'Primitivos', '00', '01', '11', '10', 'Kd', 'F'], red,
      [1, 1.3, 1, 1, 1, 1, 0.7, 0.7],
      { largura: 7600, juntar: true, destaque: (l, i) => (i >= 2 && i <= 5 && l[i].startsWith('(') ? VERDE : (l[i].endsWith('*') ? LARANJA : undefined)),
        negrito: (l, i) => i === 0 || (i >= 2 && i <= 5 && l[i].startsWith('(')) }),
    P('**Arranque (secção 2.1 do enunciado).** O Reset põe a máquina em S0 (000) mas não para o temporizador, que pode estar a contar. As duas células de S0 com To = 1 eram indiferentes na tabela primitiva e foram especificadas para que o arranque seja sempre coerente:'),
    Bullet('**S0 com K To = 01 → S0** (estável): a máquina espera, em repouso, que o temporizador acabe; é o "transitório inicial" que o enunciado manda deixar terminar.'),
    Bullet('**S0 com K To = 11 → S2**: se a tecla for premida durante esse transitório, o seu flanco ascendente (com F = 0, Ti = K) também redispara o temporizador, pelo que a situação é exatamente a de S2 (tecla premida e temporização em curso); Kd sobe de imediato.'),
    P('Sem esta escolha, uma pressão da tecla com To = 1 em S0 podia levar a S1 sem um novo flanco de Ti, e S1 ficaria à espera de um To que não volta a subir. As mesmas células cobrem ainda um caso raro no funcionamento normal: um ressalto amostrado pelo temporizador mesmo no fim da contagem pode redisparar To já em S0 ou em S3; as equações mantêm a máquina em S0 (K To = 01) e em S3 (K To = 11), à espera que To volte a 0.'),
    ...Figura(N, 'fig_estados', 'diagrama_estados.png', 13.5, 'Diagrama de estados da tabela reduzida (transições etiquetadas com K To; a tracejado as que são feitas através de um estado intermédio, secção 3.4).'),

    H2('3.4 Codificação dos estados (passo 5)'),
    P(`Para não haver corridas, cada transição só pode mudar uma variável de estado (códigos adjacentes). As transições da tabela reduzida são ${PJ.caminhos ? '' : ''}S0–S1, S1–S2, S2–S3, S3–S4, S4–S5, S5–S0, S2–S4 e S5–S1, e ainda S0–S2 no arranque. O grafo destas transições tem dois triângulos (S0–S1–S5 e S2–S3–S4) e o cubo das três variáveis de estado não tem ciclos de comprimento ímpar: não há nenhuma codificação de 6 estados com 3 variáveis em que todos estes pares sejam adjacentes.`),
    P('Aplicou-se a primeira técnica lecionada para estes casos: **alterar o estado seguinte para outro estado instável na mesma combinação das entradas, que leva ao mesmo estado final** (corrida não crítica, por um caminho indireto). Em todos os casos o estado intermédio já existe e vai para o destino pretendido nessa coluna:'),
    Bullet('S2 com K To = 00 → **S3** (e S3 com 00 → S4), em vez de S2 → S4;'),
    Bullet('S5 com K To = 10 → **S0** (e S0 com 10 → S1), em vez de S5 → S1;'),
    Bullet('S0 com K To = 11 → **S1** (e S1 com 11 → S2), em vez de S0 → S2 (arranque).'),
    P('As transições que restam formam um só ciclo, S0 → S1 → S2 → S3 → S4 → S5 → S0, que se codifica com um código de Gray de 6 palavras: o código de um contador de Johnson de 3 *bits* (' + r('tab_cod') + ' e ' + r('fig_cod') + '). Os códigos 010 e 101 não são usados.'),
    ...Tabela(N, 'tab_cod', 'Codificação dos estados (YY2 YY1 YY0) e saídas.',
      ['Estado', 'YY2 YY1 YY0', 'Kd', 'F', 'Significado'],
      Object.entries(PJ.codigo).map(([s, c]) => [s, c, String(PJ.reduzida[s].kd), String(PJ.reduzida[s].f),
        { S0: 'Repouso', S1: 'Premida, espera que To suba', S2: 'Temporização ao premir', S3: 'Premida e estável',
          S4: 'Largada, espera que To suba', S5: 'Temporização ao largar' }[s]]),
      [1, 1.6, 0.7, 0.7, 4], { largura: 7600, juntar: true, alinhar: esq(4), mono: { 1: true } }),
    P('Esta codificação tem uma vantagem adicional: **Kd = YY0 e F = YY2** em todos os estados (Kd = 1 em S1, S2, S3 e F = 1 em S3, S4, S5). As saídas são as próprias variáveis de estado, sem lógica de saída.'),
    ...Figura(N, 'fig_cod', 'codificacao.png', 11, 'Codificação dos estados no cubo das variáveis de estado: o ciclo das transições usa só arestas do cubo.'),

    H2('3.5 Tabela de transições (passo 6)'),
    P('A ' + r('tab_trans') + ' é a tabela de transições: para cada código presente (YY2 YY1 YY0) e cada combinação de K To, o valor das variáveis secundárias de excitação Y2 Y1 Y0. A verde estão os estados estáveis (Y = YY) e a laranja as transições feitas por um estado intermédio.'),
    ...Tabela(N, 'tab_trans', 'Tabela de transições: Y2 Y1 Y0 para K To = 00, 01, 11 e 10 (– = indiferente).',
      ['Estado', 'YY2 YY1 YY0', '00', '01', '11', '10'], trans,
      [1, 1.6, 1.2, 1.2, 1.2, 1.2], { largura: 7000, juntar: true, mono: { 1: true, 2: true, 3: true, 4: true, 5: true },
        destaque: fillTrans, negrito: (l, i) => i === 0 }),

    H2('3.6 Saídas nas transições (passo 7)'),
    P('Como Kd = YY0 e F = YY2, cada saída só muda quando muda a respetiva variável de estado, e cada transição muda uma só variável de estado de cada vez: nas transições diretas muda no máximo uma saída, uma só vez. Nas transições indiretas (' + r('tab_ind') + ') o estado intermédio também não provoca picos: cada saída muda no máximo uma vez ao longo do caminho, sempre no mesmo sentido. Não foi preciso alterar o valor das saídas em nenhuma transição.'),
    ...Tabela(N, 'tab_ind', 'Transições indiretas e saídas (Kd F) ao longo do caminho.',
      ['Situação', 'Caminho', 'Códigos', 'Kd F', 'Significado'], ind,
      [1, 1.7, 2.1, 1.7, 3.5], { alinhar: esq(4), tamanho: 17, mono: { 2: true, 3: true } }),
    P('Em S2 → S3 → S4, F sobe antes de Kd descer, e é a subida de F (com K = 0) que faz Ti subir e disparar a temporização ao largar. Em S5 → S0 → S1, F desce primeiro (com K = 1, Ti sobe e dispara a temporização ao premir) e Kd sobe a seguir.'),

    H2('3.7 Equações de excitação e de saída (passos 8 e 9)'),
    P('Os mapas de Karnaugh da ' + r('fig_kv') + ' foram tirados da tabela de transições. Cada variável secundária só depende de três variáveis: Y2 de To, YY2 e YY1; Y1 de To, YY1 e YY0; Y0 de K, YY2 e YY0. O *script* confere que todas as células da tabela de transições com os mesmos valores dessas três variáveis têm o mesmo valor, pelo que cada mapa tem só 8 células, todas especificadas.'),
    ...Figura(N, 'fig_kv', 'mapas_kv.png', 16.9, 'Mapas de Karnaugh das variáveis secundárias de excitação, com os agrupamentos usados.'),
    ...Tabela(N, 'tab_eq', 'Equações de excitação e de saída.',
      ['Variável', 'Equação', 'Leitura'],
      [['Y2', PJ.equacoes.Y2, 'Enquanto o temporizador conta, YY2 mantém-se; quando acaba, YY2 copia YY1'],
       ['Y1', PJ.equacoes.Y1, 'Enquanto o temporizador conta, YY1 copia YY0; quando acaba, YY1 mantém-se'],
       ['Y0', PJ.equacoes.Y0, 'Função maioria de K, /YY2 e YY0'],
       ['Kd', 'YY0', 'Saída de Moore, sem lógica'],
       ['F', 'YY2', 'Saída de Moore, sem lógica']],
      [0.8, 3.6, 4.4], { alinhar: esq(1, 2), mono: { 1: true } }),
    P('**Acidentes estáticos.** Em Y2 e Y1 os dois primeiros termos chegam para a função, mas quando To muda com YY2 = YY1 = 1 (ou YY1 = YY0 = 1) a saída passaria de um termo para o outro e poderia ter um pico a 0: o terceiro termo (YY2·YY1 e YY1·YY0) é o **termo de consenso** que cobre essas duas células adjacentes e elimina o acidente. Em Y0 (função maioria) os três termos são essenciais e cada par de células adjacentes a 1 já está no mesmo termo. O *script* confere, para as três equações e para todas as 32 combinações das cinco variáveis, que duas combinações adjacentes a 1 estão sempre cobertas por um mesmo termo. Sendo somas de produtos (dois níveis), não há acidentes dinâmicos. Na FPGA cada equação é um único LUT, que não preserva a forma em soma de produtos: quando muda uma só entrada e a saída não deve mudar, o LUT passa a ler outra célula de memória com o mesmo valor, o que normalmente não produz picos, embora a folha de características não o garanta. A ausência de acidentes estáticos fica garantida para a realização com portas lógicas (diagrama lógico da secção 3.9).'),
    P(`**Indiferenças.** Os valores que as equações dão às células indiferentes são seguros: S3 com To = 1 vai para S4 (K = 0) ou fica em S3 (K = 1), e os códigos não usados levam sempre a estados válidos (010 → ${PJ.indiferentes.filter(x => x[0] === '010').map(x => NOME[x[2]] || x[2]).join(', ')} e 101 → ${PJ.indiferentes.filter(x => x[0] === '101').map(x => NOME[x[2]] || x[2]).join(', ')}, para K To = 00, 01, 11, 10), pelo que a máquina nunca fica presa fora dos seis estados.`),

    H2('3.8 Corridas e acidentes essenciais'),
    P(`**Corridas.** O *script* parte de cada um dos ${new Set(PJ.caminhos.map(c => c.de + c.col)).size} estados totais estáveis, muda uma entrada de cada vez (${PJ.caminhos.length} transições) e explora todas as ordens possíveis de mudança das variáveis de estado excitadas. Em todos os casos a máquina chega a um único estado estável, mudando uma só variável de estado em cada passo, e sem oscilar: não há corridas, críticas ou não críticas. O mesmo vale para a libertação do Clear (o estado 000 com qualquer combinação de K To): 00 e 01 ficam em S0, 10 vai para S1 e 11 para S2 (através de S1). Em S1, a máquina espera que To suba; como o temporizador não é inicializado, a gestão da tecla mantém Ti a 0 enquanto o Clear está ativo, para que a libertação do Clear com a tecla premida dê um flanco em Ti e dispare o temporizador (secção 5).`),
    P(`**Acidentes essenciais.** Um acidente essencial acontece quando uma entrada muda, a máquina reage, e a mudança das variáveis de estado chega a uma das portas antes da própria mudança da entrada. É uma propriedade da tabela de estados e não se elimina com a lógica (critério de Unger: a partir de S1 com K To = 00, uma mudança de To leva a S2, mas três mudanças levam a S5). Só To chega a mais do que uma equação (Y2 e Y1), por isso só To pode provocar acidentes essenciais. O *script* simula cada transição com uma das equações a ver To mais tarde do que as outras, deixando a máquina avançar entretanto por todas as ordens possíveis, e encontrou ${PJ.essenciais.length} casos, em dois grupos:`),
    Bullet('**caso 1, To sobe em S1 ou em S4** (4 casos): Y1 muda e, se YY1 chegar à porta de Y2 antes de To, Y2 vê a combinação errada (em S1 com K = 1 a máquina iria para S3); para não haver acidente, To tem de chegar ao LUT de Y2 antes da volta To → Y1 → YY1 → Y2;'),
    Bullet('**caso 2, To desce em S2 com K = 0 ou em S5 com K = 1** (2 casos): a máquina faz a transição indireta e, se Y1 ainda vir To = 1 depois de YY0 mudar, perde YY1 (em S5 iria para S3 em vez de S1); para não haver acidente, To tem de chegar ao LUT de Y1 antes da volta mais longa To → Y2 → YY2 → Y0 → YY0 → Y1.'),
    P(`Na FPGA cada equação é um LUT e os atrasos vêm do *place & route*. A ${r('tab_atrasos')} tem os atrasos das ligações lidos no projeto implementado (\`scripts/atrasos.tcl\`) nos dois cantos de funcionamento: em cada máquina, em cada canto e nos dois casos, o caminho indireto é mais lento do que o direto, mesmo sem contar o atraso dos LUT que tem pelo caminho (margem mínima de ${margemMin} ps). O Vivado colocou os LUT de cada máquina juntos (${slices.join('; ')}), o que mantém as ligações curtas. Esta margem depende da colocação e foi confirmada para esta implementação; se o projeto mudar, deve repetir-se a verificação.`),
    ...Tabela(N, 'tab_atrasos', 'Atrasos das ligações (ps): caminho direto (máximo), caminho indireto (mínimo, só as ligações, sem os LUT) e margem.',
      ['Máquina', 'Canto', 'Caso 1: To → Y2', 'Caso 1: To → Y1 → YY1 → Y2', 'Margem 1', 'Caso 2: To → Y1', 'Caso 2: To → Y2 → YY2 → Y0 → YY0 → Y1', 'Margem 2'], at,
      [1.1, 0.9, 1.1, 1.5, 0.9, 1.1, 1.9, 0.9], { tamanho: 16, juntar: true, destaque: (l, i) => (i === 4 || i === 7 ? VERDE : undefined) }),

    H2('3.9 Diagrama lógico e código Verilog (passo 10)'),
    P('A ' + r('fig_logi') + ' é o diagrama lógico da máquina: as três somas de produtos à esquerda e as portas AND2B1 do Clear (Fig. 3 do enunciado) nas realimentações, que voltam ao barramento das variáveis de estado. O Clear é ativo a High, como a porta AND2B1 da Fig. 3 (entrada negada) e como a tecla da Basys3 (premida = 1).'),
    ...Figura(N, 'fig_logi', 'logigrama.png', 14, 'Diagrama lógico da máquina de estados, com as realimentações e o Clear.'),
    P('O código (' + r('lst_maq') + ') segue a exigência do enunciado: não tem *flip-flops* nem `always`; cada variável secundária (Y2, Y1, Y0) é um `assign` com a sua equação, cada variável de estado (YY2, YY1, YY0) é a realimentação dessa equação através da porta do Clear, e as saídas são atribuídas às variáveis de estado. A correspondência entre equações, variáveis e linhas do código é direta. O atributo `DONT_TOUCH` impede o Vivado de fundir ou eliminar estas ligações, e o `#1` modela o atraso do circuito de excitação na simulação (é ignorado na síntese), o que torna visíveis nas formas de onda os estados intermédios das transições indiretas.'),
    ...Listagem(N, 'lst_maq', 'maquinatecla/maquinatecla.v', 'Máquina de estados assíncrona'),
    P('O esquema gerado pelo Vivado a partir do código (RTL Analysis, Elaborated Design, ' + r('fig_rtl') + ') mostra as mesmas portas e as realimentações das saídas para as entradas das portas AND. Na implementação, cada Y e cada YY passou a ser um LUT3 (o Clear junta-se ao reset de arranque no mesmo LUT da realimentação), num total de seis LUT por máquina.'),
    ...Figura(N, 'fig_rtl', 'viv_maquinatecla_esquema.png', 16.9, 'Esquema RTL da máquina de estados gerado pelo Vivado (Elaborated Design).'),

    H2('3.10 Verificação da máquina de estados (passo 11)'),
    P(`O testbench da máquina (${r('lst_tb_maq')}, no Anexo A) impõe K, To e Clear diretamente (sem temporizador), começa com o Clear ativo, como pede o enunciado, e muda uma só entrada de cada vez, esperando 10 ns antes de conferir o estado e as saídas. O percurso passa pelas 22 transições especificadas da tabela reduzida (as 24 a partir dos 12 estados totais estáveis, menos as duas de S3 com To = 1, que não ocorrem), pelas três transições indiretas, pelo arranque com To = 1 e pelo Clear em S2, S3 e com as quatro combinações de K To na libertação. Resultado: \`Simulacao OK (${R.ver.maquinatecla_teste1} verificacoes)\`.`),
    P('Nas ' + r('fig_sim_maq_a') + ' e ' + r('fig_sim_maq_b') + ' vêem-se os ressaltos ao premir (S1 e S2 sem mudar Kd) e ao largar (S4 e S5 sem mudar Kd), e as transições indiretas: aos 100 ns, To desce com K = 1 e a máquina vai de 011 para 111 (S3, F sobe); aos 200 ns, To desce com K = 0 e a máquina passa por 111 a caminho de 110; aos 280 ns passa por 000 a caminho de 001. Como cada equação tem 1 ns de atraso, o estado intermédio dura 1 ns e as saídas mudam uma de cada vez.'),
    ...Figura(N, 'fig_sim_maq_a', 'viv_maquinatecla_sim_a.png', 16.9, 'Simulação da máquina de estados (0 a 240 ns): ressaltos ao premir e ao largar e transição indireta S2 → S3 → S4.'),
    ...Figura(N, 'fig_sim_maq_b', 'viv_maquinatecla_sim_b.png', 16.9, 'Simulação da máquina de estados (230 a 470 ns): transição S5 → S0 → S1, arranque com To = 1 e Clear.'),
    P('Para confirmar que os testbenches detetam erros, aplicou-se uma alteração de cada vez a uma cópia do projeto e correram-se os cinco testbenches (' + r('tab_mut') + '). Todos os erros de função foram detetados. A remoção de um termo de consenso não é detetada, como era de esperar: a função não muda e, na simulação, cada `assign` é calculado de uma só vez, sem os atrasos diferentes de cada porta que produziriam o pico. Os acidentes estáticos foram verificados no projeto (secção 3.7) e não por simulação.'),
    ...Tabela(N, 'tab_mut', 'Validação dos testbenches com alterações propositadas.',
      ['Alteração', 'Testbenches que falharam'], mut, [4, 5], { alinhar: esq(0, 1), tamanho: 17 }),
  ];
};
