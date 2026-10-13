// Funcoes auxiliares para gerar o relatorio com a biblioteca docx (docx-js).
const fs = require('fs');
const path = require('path');
const {
  Paragraph, TextRun, ImageRun, Table, TableRow, TableCell, AlignmentType, BorderStyle,
  WidthType, ShadingType, HeadingLevel, TabStopType, PageBreak, VerticalAlign, Bookmark,
} = require('docx');

const RAIZ = path.resolve(__dirname, '..', '..');
const FIG = path.join(RAIZ, 'relatorio', 'figuras');
const LARGURA = 9638;                 // largura util em DXA (A4, margens de 2 cm)
const FONTE = 'Arial';
const MONO = 'Consolas';

// --- Texto com marcacao simples: **negrito**, *italico*, `codigo` -------------------
function runs(texto, base = {}) {
  const out = [];
  const re = /(\*\*[^*]+\*\*|\*[^*]+\*|`[^`]+`)/g;
  let i = 0, m;
  while ((m = re.exec(texto))) {
    if (m.index > i) out.push(new TextRun({ text: texto.slice(i, m.index), ...base }));
    const t = m[0];
    if (t.startsWith('**')) out.push(new TextRun({ text: t.slice(2, -2), bold: true, ...base }));
    else if (t.startsWith('`')) out.push(new TextRun({ text: t.slice(1, -1), font: MONO, size: 19, ...base }));
    else out.push(new TextRun({ text: t.slice(1, -1), italics: true, ...base }));
    i = m.index + t.length;
  }
  if (i < texto.length) out.push(new TextRun({ text: texto.slice(i), ...base }));
  return out;
}

function P(texto, opts = {}) {
  return new Paragraph({
    alignment: opts.align || AlignmentType.JUSTIFIED,
    spacing: { after: opts.after ?? 120, before: opts.before ?? 0, line: 276 },
    keepNext: opts.keepNext,
    children: runs(texto, opts.run || {}),
  });
}

function Bullet(texto, nivel = 0) {
  return new Paragraph({
    numbering: { reference: 'marcas', level: nivel },
    alignment: AlignmentType.JUSTIFIED,
    spacing: { after: 60, line: 276 },
    children: runs(texto),
  });
}

function Num(texto, ref = 'numeros') {
  return new Paragraph({
    numbering: { reference: ref, level: 0 },
    alignment: AlignmentType.JUSTIFIED,
    spacing: { after: 60, line: 276 },
    children: runs(texto),
  });
}

function H1(texto, novaPagina = true) {
  return new Paragraph({ heading: HeadingLevel.HEADING_1, pageBreakBefore: novaPagina, children: [new TextRun(texto)] });
}
function H2(texto) {
  return new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun(texto)] });
}
function H3(texto) {
  return new Paragraph({ heading: HeadingLevel.HEADING_3, children: [new TextRun(texto)] });
}

// --- Numeracao de figuras, tabelas e listagens (duas passagens para referencias) ----
class Numerador {
  constructor(anterior) { this.n = { Figura: 0, Tabela: 0, Listagem: 0 }; this.mapa = {}; this.anterior = anterior; }
  proximo(tipo, id) {
    this.n[tipo] += 1;
    if (id) this.mapa[id] = `${tipo} ${this.n[tipo]}`;
    return this.n[tipo];
  }
  // referencia a uma figura/tabela/listagem pelo id (resolvida na segunda passagem)
  ref(id) {
    const m = (this.anterior && this.anterior.mapa[id]) || this.mapa[id];
    if (!m && this.anterior) throw new Error('referencia desconhecida: ' + id);
    return m || '??';
  }
}

function legenda(texto) {
  return new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { before: 60, after: 240 },
    children: runs(texto, { italics: true, size: 18 }),
  });
}

function dimImagem(ficheiro) {
  const b = fs.readFileSync(ficheiro);
  if (b.readUInt32BE(0) === 0x89504e47) return { w: b.readUInt32BE(16), h: b.readUInt32BE(20), tipo: 'png' };
  // JPEG: procura o marcador SOF
  let i = 2;
  while (i < b.length) {
    const marca = b.readUInt16BE(i), tam = b.readUInt16BE(i + 2);
    if (marca >= 0xffc0 && marca <= 0xffc3) return { w: b.readUInt16BE(i + 7), h: b.readUInt16BE(i + 5), tipo: 'jpg' };
    i += 2 + tam;
  }
  throw new Error('dimensoes desconhecidas: ' + ficheiro);
}

// Figura com largura em cm (a altura segue a proporcao da imagem)
function Figura(N, id, ficheiro, larguraCm, texto) {
  const f = path.join(FIG, ficheiro);
  const d = dimImagem(f);
  const maxCm = 16.9;
  const wcm = Math.min(larguraCm, maxCm);
  let wpx = wcm / 2.54 * 96, hpx = wpx * d.h / d.w;
  const maxH = 22 / 2.54 * 96;                 // nunca mais alta do que 22 cm
  if (hpx > maxH) { wpx *= maxH / hpx; hpx = maxH; }
  const n = N.proximo('Figura', id);
  return [
    new Paragraph({
      alignment: AlignmentType.CENTER, keepNext: true, spacing: { before: 120, after: 0 },
      children: [new ImageRun({
        type: d.tipo, data: fs.readFileSync(f),
        transformation: { width: Math.round(wpx), height: Math.round(hpx) },
        altText: { title: texto, description: texto, name: ficheiro },
      })],
    }),
    legenda(`Figura ${n} – ${texto}`),
  ];
}

// Espaco reservado para uma fotografia que so pode ser tirada no laboratorio
function FiguraPorTirar(N, id, texto, instrucao) {
  const n = N.proximo('Figura', id);
  const tracejado = { style: BorderStyle.DASHED, size: 8, color: 'C00000' };
  return [
    new Table({
      width: { size: LARGURA, type: WidthType.DXA }, columnWidths: [LARGURA],
      rows: [new TableRow({
        height: { value: 2600, rule: 'atLeast' },
        children: [new TableCell({
          width: { size: LARGURA, type: WidthType.DXA },
          borders: { top: tracejado, bottom: tracejado, left: tracejado, right: tracejado },
          shading: { fill: 'FFF4E5', type: ShadingType.CLEAR },
          verticalAlign: VerticalAlign.CENTER,
          children: [new Paragraph({
            alignment: AlignmentType.CENTER,
            children: [new TextRun({ text: `[A INSERIR NO LABORATÓRIO: ${instrucao}]`, color: 'C00000', bold: true, size: 20 })],
          })],
        })],
      })],
    }),
    legenda(`Figura ${n} – ${texto}`),
  ];
}

// --- Tabelas --------------------------------------------------------------------------
const borda = { style: BorderStyle.SINGLE, size: 4, color: '808080' };
const bordas = { top: borda, bottom: borda, left: borda, right: borda };

function celula(texto, largura, opts = {}) {
  return new TableCell({
    width: { size: largura, type: WidthType.DXA }, borders: bordas,
    shading: opts.fill ? { fill: opts.fill, type: ShadingType.CLEAR } : undefined,
    margins: { top: 40, bottom: 40, left: 80, right: 80 },
    verticalAlign: VerticalAlign.CENTER,
    children: [new Paragraph({
      alignment: opts.align || AlignmentType.CENTER,
      children: runs(String(texto), { bold: opts.bold, size: opts.size || 18, font: opts.mono ? MONO : undefined }),
    })],
  });
}

// colunas: lista de larguras relativas; cab: cabecalhos; linhas: lista de listas
function Tabela(N, id, texto, cab, linhas, colunas, opts = {}) {
  const total = colunas.reduce((a, b) => a + b, 0);
  const larg = opts.largura || LARGURA;
  const w = colunas.map(c => Math.round(c / total * larg));
  w[w.length - 1] += larg - w.reduce((a, b) => a + b, 0);
  const n = N.proximo('Tabela', id);
  const linhasTab = [new TableRow({ tableHeader: true, children: cab.map((c, i) => celula(c, w[i], { bold: true, fill: 'D9E2F3' })) })];
  for (const l of linhas) {
    linhasTab.push(new TableRow({
      cantSplit: true,
      children: l.map((c, i) => celula(c, w[i], {
        align: (opts.alinhar && opts.alinhar[i]) || AlignmentType.CENTER,
        mono: opts.mono && opts.mono[i], fill: opts.destaque && opts.destaque(l, i),
      })),
    }));
  }
  return [
    new Paragraph({ alignment: AlignmentType.CENTER, keepNext: true, spacing: { before: 120, after: 60 },
      children: runs(`Tabela ${n} – ${texto}`, { italics: true, size: 18 }) }),
    new Table({ width: { size: larg, type: WidthType.DXA }, columnWidths: w, alignment: AlignmentType.CENTER, rows: linhasTab }),
    new Paragraph({ spacing: { after: 120 }, children: [] }),
  ];
}

// --- Listagens de codigo ----------------------------------------------------------------
function Listagem(N, id, ficheiroOuCodigo, texto, opts = {}) {
  let codigo = ficheiroOuCodigo;
  let nome = '';
  if (!ficheiroOuCodigo.includes('\n')) {
    nome = ficheiroOuCodigo;
    codigo = fs.readFileSync(path.join(RAIZ, ficheiroOuCodigo), 'utf8');
  }
  codigo = codigo.replace(/\t/g, '    ').replace(/\s+$/, '');
  const linhas = codigo.split('\n');
  const n = N.proximo('Listagem', id);
  const cinza = { style: BorderStyle.SINGLE, size: 4, color: 'A6A6A6' };
  const tam = opts.tamanho || 15;               // 7,5 pt
  const pars = linhas.map((l, i) => new Paragraph({
    spacing: { after: 0, line: 228 },
    indent: { left: 420, hanging: 420 },          // linhas partidas ficam alinhadas depois do numero
    children: [
      new TextRun({ text: String(i + 1).padStart(3, ' ') + '  ', font: MONO, size: tam, color: '9A9A9A' }),
      new TextRun({ text: l.length ? l : ' ', font: MONO, size: tam, color: l.trim().startsWith('//') || l.trim().startsWith('#') ? '2E7D32' : '000000' }),
    ],
  }));
  return [
    new Paragraph({ keepNext: true, spacing: { before: 120, after: 60 },
      children: runs(`Listagem ${n} – ${texto}` + (nome ? ` (\`${nome}\`)` : ''), { italics: true, size: 18 }) }),
    new Table({
      width: { size: LARGURA, type: WidthType.DXA }, columnWidths: [LARGURA],
      rows: [new TableRow({ children: [new TableCell({
        width: { size: LARGURA, type: WidthType.DXA },
        borders: { top: cinza, bottom: cinza, left: cinza, right: cinza },
        shading: { fill: 'F7F7F7', type: ShadingType.CLEAR },
        margins: { top: 80, bottom: 80, left: 120, right: 120 },
        children: pars,
      })] })],
    }),
    new Paragraph({ spacing: { after: 160 }, children: [] }),
  ];
}

module.exports = { P, Bullet, Num, H1, H2, H3, Numerador, Figura, FiguraPorTirar, Tabela, Listagem, runs, RAIZ, FIG, LARGURA, FONTE, MONO };
