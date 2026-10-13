// Gera o corpo do relatorio (relatorio/fonte/corpo.docx) a partir do conteudo das seccoes.
// Uso: NODE_PATH=$(npm root -g) node relatorio/fonte/gerar.js [total_de_paginas]
// O total de paginas (capa incluida) aparece no rodape "Pag X de N"; o script gerar.sh
// corre isto duas vezes para o acertar.
const fs = require('fs');
const path = require('path');
const {
  Document, Packer, Paragraph, TextRun, Header, Footer, AlignmentType, LevelFormat, TabStopType,
  PageNumber, TableOfContents, BorderStyle,
} = require('docx');
const { Numerador, RAIZ, FONTE } = require('./lib');
const aula1 = require('./conteudo_aula1');
const aula2 = require('./conteudo_aula2');
const aula3 = require('./conteudo_aula3');

const totalPaginas = process.argv[2] || '?';

// --- Dados lidos dos resultados do Vivado ------------------------------------------------
function util(nome) {
  const t = fs.readFileSync(path.join(RAIZ, 'bitstreams/relatorios', nome + '_utilizacao.txt'), 'utf8');
  const lut = +t.match(/\| Slice LUTs\s+\|\s+(\d+)/)[1];
  const ff = +t.match(/\| Slice Registers\s+\|\s+(\d+)/)[1];
  return { lut, ff };
}
function wns(nome) {
  const t = fs.readFileSync(path.join(RAIZ, 'bitstreams/relatorios', nome + '_tempos.txt'), 'utf8');
  const m = t.match(/WNS\(ns\)[^\n]*\n[ -]+\n\s+(-?[\d.]+)/);
  return m[1].replace('.', ',');
}
function verificacoes(tb) {
  const t = fs.readFileSync(path.join(RAIZ, 'simulacao/resultados.txt'), 'utf8');
  const m = t.match(new RegExp('Simulacao OK: ' + tb + ' sem erros \\((\\d+) verificacoes\\)'));
  if (!m) throw new Error('resultado da simulacao em falta: ' + tb);
  return m[1];
}
function arvore() {
  const ign = new Set(['.git', '.Xil', 'logs', 'node_modules', '.omc']);
  const desc = {
    'digital': 'esquemas do Digital (.dig e .svg) e Verilog exportado',
    'multiplexer4x1': 'secção 2', 'descodificador2x4': 'secção 3', 'multiplexer16x4': 'secção 4',
    'transcod7seg': 'secção 5 (transcodificador e circuito displayBCD)', 'registo4': 'secção 6',
    'divisorclock': 'secção 7.1', 'contador4': 'secção 7.2', 'controlodisplays': 'secção 8 (Fig. 31 e Fig. 32)',
    'simulacao': 'formas de onda (VCD) de todas as simulações', 'bitstreams': 'ficheiros .bit e relatórios do Vivado',
    'vivado': 'projetos Vivado (.xpr)', 'scripts': 'automatização (Tcl e Python)', 'relatorio': 'este relatório e as figuras',
  };
  const linhas = ['sd2lab1/'];
  const pastas = fs.readdirSync(RAIZ).filter(n => !ign.has(n) && fs.statSync(path.join(RAIZ, n)).isDirectory()).sort((a, b) => {
    const ordem = Object.keys(desc);
    return ordem.indexOf(a) - ordem.indexOf(b);
  });
  for (const p of pastas) {
    linhas.push(`├── ${(p + '/').padEnd(20)}${desc[p] ? '# ' + desc[p] : ''}`);
    if (['multiplexer4x1', 'descodificador2x4', 'multiplexer16x4', 'transcod7seg', 'registo4', 'divisorclock', 'contador4', 'controlodisplays'].includes(p)) {
      const fs_ = fs.readdirSync(path.join(RAIZ, p)).sort();
      fs_.forEach((f, i) => linhas.push(`│   ${i === fs_.length - 1 ? '└──' : '├──'} ${f}`));
    }
  }
  linhas.push('└── README.md');
  return linhas.join('\n');
}

const R = {
  versaoVivado: '2026.1',
  versaoDigital: 'v0.31',
  util: Object.fromEntries(['multiplexer4x1', 'descodificador2x4', 'multiplexer16x4', 'displayBCD', 'controlodisplays'].map(n => [n, util(n)])),
  wns: wns('controlodisplays'),
  verificacoesRegisto: verificacoes('Registo4'),
  verificacoesControlo: verificacoes('ControloDisplays'),
  verificacoesTeste: verificacoes('TesteDisplays'),
  mutacoes: (() => {
    const t = fs.readFileSync(path.join(RAIZ, 'scripts/teste_mutacoes.py'), 'utf8');
    return String((t.match(/^ \('/gm) || []).length);
  })(),
  numTestbenches: '10',
  arvore: arvore(),
};

// --- Conteudo (duas passagens para resolver as referencias a figuras e tabelas) -----------
function conteudo(N) {
  return [
    new Paragraph({ style: 'TituloIndice', children: [new TextRun('Índice')] }),
    new TableOfContents('Índice', { hyperlink: true, headingStyleRange: '1-2' }),
    ...aula1(N, R), ...aula2(N, R), ...aula3(N, R),
  ];
}
const primeira = new Numerador();
conteudo(primeira);
const N = new Numerador(primeira);
const filhos = conteudo(N);

// --- Documento ---------------------------------------------------------------------------
const listas = (ref, formato, texto) => ({
  reference: ref,
  levels: [{ level: 0, format: formato, text: texto, alignment: AlignmentType.LEFT,
    style: { paragraph: { indent: { left: 720, hanging: 360 } } } },
  { level: 1, format: LevelFormat.BULLET, text: '–', alignment: AlignmentType.LEFT,
    style: { paragraph: { indent: { left: 1080, hanging: 360 } } } }],
});

const cabecalho = new Header({
  children: [new Paragraph({
    tabStops: [{ type: TabStopType.RIGHT, position: 9638 }],
    border: { bottom: { style: BorderStyle.SINGLE, size: 4, color: '808080', space: 4 } },
    children: [
      new TextRun({ text: '1.º Trabalho de Laboratório – Gestão do display da placa Basys3', size: 16, color: '595959' }),
      new TextRun({ text: '\tSistemas Digitais II (LEEC) – 2026/27', size: 16, color: '595959' }),
    ],
  })],
});
const rodape = new Footer({
  children: [new Paragraph({
    alignment: AlignmentType.RIGHT,
    children: [
      new TextRun({ text: 'Pág. ', size: 18 }), new TextRun({ children: [PageNumber.CURRENT], size: 18 }),
      new TextRun({ text: ` de ${totalPaginas}`, size: 18 }),
    ],
  })],
});

const doc = new Document({
  creator: 'Rodrigo Silva Costa, Diego Alejandro Castro Laya',
  title: 'SD2 – 1.º Trabalho de Laboratório – Gestão do display da placa Basys3',
  description: 'Relatório do 1.º trabalho de laboratório de Sistemas Digitais II',
  styles: {
    default: { document: { run: { font: FONTE, size: 21, language: { value: 'pt-PT' } } } },
    paragraphStyles: [
      { id: 'Heading1', name: 'Heading 1', basedOn: 'Normal', next: 'Normal', quickFormat: true,
        run: { size: 30, bold: true, font: FONTE, color: '1F3864' },
        paragraph: { spacing: { before: 120, after: 200 }, outlineLevel: 0, keepNext: true } },
      { id: 'Heading2', name: 'Heading 2', basedOn: 'Normal', next: 'Normal', quickFormat: true,
        run: { size: 25, bold: true, font: FONTE, color: '1F3864' },
        paragraph: { spacing: { before: 240, after: 120 }, outlineLevel: 1, keepNext: true } },
      { id: 'Heading3', name: 'Heading 3', basedOn: 'Normal', next: 'Normal', quickFormat: true,
        run: { size: 22, bold: true, font: FONTE },
        paragraph: { spacing: { before: 160, after: 80 }, outlineLevel: 2, keepNext: true } },
      { id: 'TituloIndice', name: 'Titulo do indice', basedOn: 'Normal', next: 'Normal',
        run: { size: 30, bold: true, font: FONTE, color: '1F3864' }, paragraph: { spacing: { after: 240 } } },
    ],
  },
  numbering: {
    config: [
      listas('marcas', LevelFormat.BULLET, '•'),
      listas('numeros', LevelFormat.DECIMAL, '%1.'),
      listas('numeros2', LevelFormat.DECIMAL, '%1.'),
      listas('numeros3', LevelFormat.DECIMAL, '%1.'),
    ],
  },
  features: { updateFields: true },
  sections: [{
    properties: {
      page: {
        size: { width: 11906, height: 16838 },
        margin: { top: 1300, right: 1134, bottom: 1134, left: 1134, header: 600, footer: 500 },
        pageNumbers: { start: 2 },
      },
    },
    headers: { default: cabecalho },
    footers: { default: rodape },
    children: filhos,
  }],
});

const saida = path.join(__dirname, 'corpo.docx');
Packer.toBuffer(doc).then(b => { fs.writeFileSync(saida, b); console.log(saida); });
