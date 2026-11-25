// Dados do relatorio lidos dos resultados do projeto da maquina (scripts/projeto.py), das simulacoes
// (scripts/simula.sh) e da implementacao no Vivado (scripts/build.tcl). Usados por gerar.js.
const fs = require('fs');
const path = require('path');
const { RAIZ } = require('./lib');

const ler = f => fs.readFileSync(path.join(RAIZ, f), 'utf8');
const virgula = x => String(x).replace('.', ',');

function util(nome) {
  const t = ler(`bitstreams/relatorios/${nome}_utilizacao.txt`);
  return { lut: +t.match(/\| Slice LUTs\s+\|\s+(\d+)/)[1], ff: +t.match(/\| Slice Registers\s+\|\s+(\d+)/)[1] };
}
function wns(nome) {
  const t = ler(`bitstreams/relatorios/${nome}_tempos.txt`);
  return virgula(t.match(/WNS\(ns\)[^\n]*\n[ -]+\n\s+(-?[\d.]+)/)[1]);
}
// mensagem final de cada testbench: "<tb>: Simulacao OK (<n> verificacoes)"
const resultados = ler('simulacao/resultados.txt');
function verificacoes(tb) {
  const m = resultados.match(new RegExp('^' + tb + ': Simulacao OK \\((\\d+) verificacoes\\)', 'm'));
  if (!m) throw new Error('resultado da simulacao em falta: ' + tb);
  return m[1];
}
const TESTBENCHES = ['maquinatecla_teste1', 'monoestavel_teste1', 'tecla_teste1', 'validacao_teste1', 'gestaoteclas_teste1'];

// Atrasos das ligacoes (ps) de cada maquina, depois do place & route (scripts/atrasos.tcl)
function atrasos() {
  const t = ler('bitstreams/relatorios/gestaoteclas_atrasos.txt');
  const res = {};
  let atual = null;
  const celula = {};
  for (const l of t.split('\n')) {
    let m;
    if ((m = l.match(/^== (\S+)/))) { atual = m[1]; res[atual] = {}; continue; }
    if ((m = l.match(/^celula (\S+) (\S+) (\S+) (\S+)/))) { celula[atual + m[1]] = m[3]; res[atual]['slice_' + m[1]] = m[4]; continue; }
    if ((m = l.match(/^net (\S+) -> (\S+)\/(I\d) \(\S+\) fast_min=(\d+) fast_max=(\d+) slow_min=(\d+) slow_max=(\d+)/))) {
      const [, de, cel, pino, fmin, fmax, smin, smax] = m;
      const para = Object.keys(celula).find(k => k.startsWith(atual) && celula[k] === cel);
      if (!para) continue;
      res[atual][de + '>' + para.slice(atual.length)] = { fmin: +fmin, fmax: +fmax, smin: +smin, smax: +smax, pino };
    }
  }
  // margens dos acidentes essenciais (sem contar os atrasos dos LUT pelo caminho):
  //  caso 1 (To sobe em S1/S4, Y2 atrasada): indireto To -> Y1 -> YY1 -> Y2 menos o direto To -> Y2
  //  caso 2 (To desce em S2/S5, Y1 atrasada): indireto To -> Y2 -> YY2 -> Y0 -> YY0 -> Y1 menos o direto To -> Y1
  const soma = (r, ks, campo) => ks.reduce((s, k) => s + r[k][campo], 0);
  for (const r of Object.values(res)) {
    const c1 = ['To>Y1', 'Y1>YY1', 'YY1>Y2'], c2 = ['To>Y2', 'Y2>YY2', 'YY2>Y0', 'Y0>YY0', 'YY0>Y1'];
    r.caso1 = { rapido: { dir: r['To>Y2'].fmax, ind: soma(r, c1, 'fmin') }, lento: { dir: r['To>Y2'].smax, ind: soma(r, c1, 'smin') } };
    r.caso2 = { rapido: { dir: r['To>Y1'].fmax, ind: soma(r, c2, 'fmin') }, lento: { dir: r['To>Y1'].smax, ind: soma(r, c2, 'smin') } };
    for (const c of [r.caso1, r.caso2]) for (const k of ['rapido', 'lento']) c[k].margem = c[k].ind - c[k].dir;
  }
  return res;
}

// Resultado da validacao dos testbenches com mutacoes (simulacao/mutacoes.txt)
function mutacoes() {
  const f = path.join(RAIZ, 'simulacao/mutacoes.txt');
  if (!fs.existsSync(f)) return [];
  const linhas = fs.readFileSync(f, 'utf8').trim().split('\n');
  const out = [];
  for (let i = 0; i < linhas.length; i++) {
    const m = linhas[i].match(/^(.+): testbenches que falharam = (\d+)/);
    if (m) out.push({ mutacao: m[1], falharam: +m[2], quais: (linhas[i + 1] || '').trim().split(/\s+/).filter(Boolean) });
  }
  return out;
}

const R = {
  versaoVivado: '2026.1',
  util: util('gestaoteclas'),
  wns: wns('gestaoteclas'),
  ver: Object.fromEntries(TESTBENCHES.map(tb => [tb, verificacoes(tb)])),
  numTestbenches: String(TESTBENCHES.length),
  projeto: JSON.parse(ler('simulacao/projeto.json')),
  atrasos: atrasos(),
  mutacoes: mutacoes(),
  virgula,
};

module.exports = R;
