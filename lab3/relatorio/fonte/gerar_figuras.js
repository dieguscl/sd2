// Gera a folha de figuras de referencia do 3.o trabalho (relatorio/fonte/figuras.docx): so as figuras
// e tabelas principais do projeto, sem texto, para mostrar ao docente. As tabelas sao as mesmas do
// relatorio (tabelas_maquina.js) e as figuras sao os ficheiros de relatorio/figuras.
// Uso: NODE_PATH=$(npm root -g) node relatorio/fonte/gerar_figuras.js (o gerar.sh faz o resto)
const fs = require('fs');
const path = require('path');
const {
  Document, Packer, Paragraph, TextRun, Header, Footer, AlignmentType, PageNumber, HeadingLevel,
} = require('docx');
const { Numerador, Figura, FONTE } = require('./lib');
const tabelasMaquina = require('./tabelas_maquina');
const R = require('./dados');

const T = tabelasMaquina(R);
const titulo = (texto, novaPagina = false) => new Paragraph({ heading: HeadingLevel.HEADING_2, pageBreakBefore: novaPagina, children: [new TextRun(texto)] });

function conteudo(N) {
  return [
    new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 60 },
      children: [new TextRun({ text: 'Gestão das teclas para o jogo Guitar Hero', bold: true, size: 32, color: '1F3864' })] }),
    new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 60 },
      children: [new TextRun({ text: 'Sistemas Digitais II, 3.º Trabalho de Laboratório: figuras de referência', size: 22 })] }),
    new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 240 },
      children: [new TextRun({ text: 'Rodrigo Silva Costa (202300553), Diego Alejandro Castro Laya (2025184378). Turma PL1, 2026/27', size: 18, color: '595959' })] }),

    titulo('1 Arquitetura'),
    ...Figura(N, 'fig_arq', 'arquitetura.png', 16.9, 'Diagrama de blocos do sistema (a gestão da tecla 1 em pormenor; as das teclas 2 e 3 são iguais).'),

    titulo('2 Tabela de estados primitiva'),
    ...T.prim(N),

    titulo('3 Redução de estados'),
    ...T.impl(N),
    ...Figura(N, 'fig_fusao', 'diagrama_fusao.png', 6.5, 'Diagrama de fusão: pares compatíveis e estados da tabela reduzida.'),

    titulo('4 Tabela de estados reduzida'),
    ...T.red(N),

    titulo('5 Diagrama de estados'),
    ...Figura(N, 'fig_estados', 'diagrama_estados.png', 14, 'Diagrama de estados da tabela reduzida (transições etiquetadas com K To; a tracejado as que são feitas através de um estado intermédio).'),

    titulo('6 Codificação dos estados', true),   // a figura do cubo fica com a tabela
    ...T.cod(N),
    ...Figura(N, 'fig_cod', 'codificacao.png', 9, 'Codificação no cubo das variáveis de estado: o ciclo S0 → S1 → S2 → S3 → S4 → S5 → S0 usa só arestas do cubo (contador de Johnson).'),

    titulo('7 Tabela de transições'),
    ...T.trans(N),

    titulo('8 Mapas de Karnaugh e equações'),
    ...Figura(N, 'fig_kv', 'mapas_kv.png', 15, 'Mapas de Karnaugh de Y2, Y1 e Y0 (5 variáveis: YY2 = 0 à esquerda, YY2 = 1 à direita), com os agrupamentos usados.'),
    ...T.eq(N),

    titulo('9 Diagrama lógico'),
    ...Figura(N, 'fig_logi', 'logigrama.png', 14, 'Diagrama lógico da máquina de estados, com as realimentações e o Clear (portas AND2B1).'),
    ...Figura(N, 'fig_rtl', 'viv_maquinatecla_esquema.png', 16.9, 'Esquema RTL gerado pelo Vivado a partir do código Verilog (Elaborated Design).'),

    titulo('10 Simulação'),
    ...Figura(N, 'fig_sim', 'viv_tecla_detalhe_sim.png', 16.9, 'Gestão de uma tecla (T = 200 ns na simulação): os ressaltos ao premir e ao largar não passam para Kd.'),
  ];
}
const primeira = new Numerador();
conteudo(primeira);
const filhos = conteudo(new Numerador(primeira));

const pequeno = { size: 16, color: '595959' };
const doc = new Document({
  creator: 'Rodrigo Silva Costa, Diego Alejandro Castro Laya',
  title: 'SD2, 3.º Trabalho de Laboratório: figuras de referência',
  styles: {
    default: { document: { run: { font: FONTE, size: 21, language: { value: 'pt-PT' } } } },
    paragraphStyles: [
      { id: 'Heading2', name: 'Heading 2', basedOn: 'Normal', next: 'Normal', quickFormat: true,
        run: { size: 24, bold: true, font: FONTE, color: '1F3864' },
        paragraph: { spacing: { before: 280, after: 60 }, outlineLevel: 1, keepNext: true } },
    ],
  },
  sections: [{
    properties: { page: { size: { width: 11906, height: 16838 },
      margin: { top: 1000, right: 1134, bottom: 1000, left: 1134, header: 500, footer: 450 } } },
    headers: { default: new Header({ children: [new Paragraph({ alignment: AlignmentType.RIGHT,
      children: [new TextRun({ text: 'SD2, 3.º Trabalho: figuras de referência', ...pequeno })] })] }) },
    footers: { default: new Footer({ children: [new Paragraph({ alignment: AlignmentType.RIGHT,
      children: [new TextRun({ children: [PageNumber.CURRENT], ...pequeno }), new TextRun({ text: ' / ', ...pequeno }),
        new TextRun({ children: [PageNumber.TOTAL_PAGES], ...pequeno })] })] }) },
    children: filhos,
  }],
});

const saida = path.join(__dirname, 'figuras.docx');
Packer.toBuffer(doc).then(b => { fs.writeFileSync(saida, b); console.log(saida); });
