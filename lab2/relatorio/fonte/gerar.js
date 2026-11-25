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
const { Numerador, FONTE } = require('./lib');
const arquitetura = require('./conteudo_arquitetura');
const controlador = require('./conteudo_controlador');
const sistema = require('./conteudo_sistema');

const totalPaginas = process.argv[2] || '?';

const R = require('./dados');

// --- Conteudo (duas passagens para resolver as referencias a figuras e tabelas) -----------
function conteudo(N) {
  return [
    new Paragraph({ style: 'TituloIndice', children: [new TextRun('Índice')] }),
    new TableOfContents('Índice', { hyperlink: true, headingStyleRange: '1-2' }),
    ...arquitetura(N, R), ...controlador(N, R), ...sistema(N, R),
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
  { level: 1, format: LevelFormat.BULLET, text: '◦', alignment: AlignmentType.LEFT,
    style: { paragraph: { indent: { left: 1080, hanging: 360 } } } }],
});

const cabecalho = new Header({
  children: [new Paragraph({
    tabStops: [{ type: TabStopType.RIGHT, position: 9638 }],
    border: { bottom: { style: BorderStyle.SINGLE, size: 4, color: '808080', space: 4 } },
    children: [
      new TextRun({ text: '2.º Trabalho de Laboratório: Gestão dos displays para o jogo Guitar Hero', size: 16, color: '595959' }),
      new TextRun({ text: '\tSistemas Digitais II (LEEC), 2026/27', size: 16, color: '595959' }),
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
  title: 'SD2, 2.º Trabalho de Laboratório: Gestão dos displays para o jogo Guitar Hero',
  description: 'Relatório do 2.º trabalho de laboratório de Sistemas Digitais II',
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
