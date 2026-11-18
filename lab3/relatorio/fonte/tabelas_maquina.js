// Tabelas do projeto da maquina de estados, geradas a partir de simulacao/projeto.json (scripts/projeto.py)
// para coincidirem com o que o script conferiu. Usadas pelo relatorio (conteudo_maquina.js) e pela
// folha de figuras de referencia (gerar_figuras.js).
const { Tabela } = require('./lib');
const { AlignmentType } = require('docx');

const COLS = ['00', '01', '11', '10'];
const VERDE = 'E2EFDA', LARANJA = 'FCE4D6', CINZA = 'EDEDED';
const SIGNIFICADO = {
  S0: 'Repouso', S1: 'Premida, espera que To suba', S2: 'Temporização ao premir', S3: 'Premida e estável',
  S4: 'Largada, espera que To suba', S5: 'Temporização ao largar',
};

module.exports = function tabelasMaquina(R) {
  const PJ = R.projeto;
  const EST = Object.keys(PJ.prim);
  const esq = (...c) => Object.fromEntries(c.map(i => [i, AlignmentType.LEFT]));

  // --- Tabela primitiva
  const prim = EST.map(s => {
    const p = PJ.prim[s];
    return [s, ...p.prox.map(n => (n === null ? '–' : n === s ? `(${n})` : n)), String(p.kd), String(p.f), p.desc];
  });

  // --- Tabela de implicacoes (triangular): recalcula os pares implicados para os mostrar
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

  // --- Tabela reduzida
  const G = PJ.grupos;
  const red = Object.entries(PJ.reduzida).map(([s, d]) => {
    const prox = d.prox.map((n, j) => {
      let t = n === null ? '–' : (n === s ? `(${n})` : n);
      if (s === 'S0' && (j === 1 || j === 2)) t += '*';
      return t;
    });
    return [s, G[s].join(', '), ...prox, String(d.kd), String(d.f)];
  });

  // --- Tabela de transicoes (linhas pela ordem do anel de Johnson e depois os codigos nao usados)
  const NOME = Object.fromEntries(Object.entries(PJ.codigo).map(([k, c]) => [c, k]));
  const ordem = ['000', '001', '011', '111', '110', '100', '010', '101'];
  const indiretas = new Set(Object.keys(PJ.indiretas).map(k => { const [g, c] = k.split(','); return PJ.codigo[g] + c; }));
  // cada celula mostra o codigo Y2 Y1 Y0 e o nome do estado com esse codigo
  const nomeDe = x => { if (!NOME[x]) throw new Error('codigo sem estado: ' + x); return NOME[x]; };
  const trans = ordem.map(c => [NOME[c] || '–', c, ...PJ.transicoes[c].map(x => (x ? `${x} **${nomeDe(x)}**` : '–'))]);
  const fillTrans = (l, i) => {             // l[1] e o codigo da linha; o valor vem da tabela, nao do texto
    if (i < 2) return undefined;
    const x = PJ.transicoes[l[1]][i - 2];
    if (x === null) return undefined;
    if (x === l[1]) return VERDE;
    if (indiretas.has(l[1] + COLS[i - 2])) return LARANJA;
    return undefined;
  };

  return {
    EST, NOME,
    prim: N => Tabela(N, 'tab_prim', 'Tabela de estados primitiva (estado seguinte para K To = 00, 01, 11 e 10).',
      ['Estado', '00', '01', '11', '10', 'Kd', 'F', 'Descrição'], prim,
      [0.9, 0.9, 0.9, 0.9, 0.9, 0.7, 0.7, 4.6],
      { juntar: true, alinhar: esq(7), destaque: (l, i) => (i >= 1 && i <= 4 && l[i].startsWith('(') ? VERDE : undefined),
        negrito: (l, i) => i === 0 || (i >= 1 && i <= 4 && l[i].startsWith('(')) }),
    impl: N => Tabela(N, 'tab_impl', 'Tabela de implicações (✓ compatível; ✗ incompatível; par implicado incompatível antes de ✗).',
      ['', ...EST.slice(0, -1)], impl, [0.7, 1, 1, 1, 1, 1, 1, 1, 1, 1],
      { juntar: true, tamanho: 16, negrito: (l, i) => i === 0, destaque: (l, i) => (l[i] === '✓' ? VERDE : (i > 0 && l[i] === '' ? CINZA : undefined)) }),
    red: N => Tabela(N, 'tab_red', 'Tabela de estados reduzida (K To = 00, 01, 11, 10; * = indiferenças especificadas para o arranque).',
      ['Estado', 'Primitivos', '00', '01', '11', '10', 'Kd', 'F'], red,
      [1, 1.3, 1, 1, 1, 1, 0.7, 0.7],
      { largura: 7600, juntar: true, destaque: (l, i) => (i >= 2 && i <= 5 && l[i].startsWith('(') ? VERDE : (l[i].endsWith('*') ? LARANJA : undefined)),
        negrito: (l, i) => i === 0 || (i >= 2 && i <= 5 && l[i].startsWith('(')) }),
    cod: N => Tabela(N, 'tab_cod', 'Codificação dos estados (YY2 YY1 YY0) e saídas.',
      ['Estado', 'YY2 YY1 YY0', 'Kd', 'F', 'Significado'],
      Object.entries(PJ.codigo).map(([s, c]) => [s, c, String(PJ.reduzida[s].kd), String(PJ.reduzida[s].f), SIGNIFICADO[s]]),
      [1, 1.6, 0.7, 0.7, 4], { largura: 7600, juntar: true, alinhar: esq(4), mono: { 1: true } }),
    trans: N => Tabela(N, 'tab_trans', 'Tabela de transições: Y2 Y1 Y0 e estado correspondente, para K To = 00, 01, 11 e 10 (– = indiferente).',
      ['Estado', 'YY2 YY1 YY0', '00', '01', '11', '10'], trans,
      [1, 1.6, 1.2, 1.2, 1.2, 1.2], { largura: 7000, juntar: true, mono: { 1: true, 2: true, 3: true, 4: true, 5: true },
        destaque: fillTrans, negrito: (l, i) => i === 0 }),
    eq: N => Tabela(N, 'tab_eq', 'Equações de excitação e de saída.',
      ['Variável', 'Equação', 'Leitura'],
      [['Y2', PJ.equacoes.Y2, 'Enquanto o temporizador conta, YY2 mantém-se; quando acaba, YY2 copia YY1'],
       ['Y1', PJ.equacoes.Y1, 'Enquanto o temporizador conta, YY1 copia YY0; quando acaba, YY1 mantém-se'],
       ['Y0', PJ.equacoes.Y0, 'Função maioria de K, /YY2 e YY0'],
       ['Kd', 'YY0', 'Saída de Moore, sem lógica'],
       ['F', 'YY2', 'Saída de Moore, sem lógica']],
      [0.8, 3.6, 4.4], { alinhar: esq(1, 2), mono: { 1: true } }),
  };
};
