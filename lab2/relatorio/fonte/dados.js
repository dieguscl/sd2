// Dados do relatorio lidos dos resultados do Vivado e das simulacoes (usados por gerar.js e revisao.js).
const fs = require('fs');
const path = require('path');
const { RAIZ } = require('./lib');

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
// mensagem final de cada testbench (scripts/simula.sh): "<tb>: Simulacao OK (<n> verificacoes)"
const resultados = fs.readFileSync(path.join(RAIZ, 'simulacao/resultados.txt'), 'utf8');
function verificacoes(tb) {
  const m = resultados.match(new RegExp('^' + tb + ': Simulacao OK \\((\\d+) verificacoes\\)', 'm'));
  if (!m) throw new Error('resultado da simulacao em falta: ' + tb);
  return m[1];
}
const TESTBENCHES = ['sincronizador_teste1', 'sincronizadorreset_teste1', 'lfsr32_teste1', 'memoria4x2_teste1',
  'temporizador_teste1', 'temporizadorvariavel_teste1', 'beat_teste1', 'gestaodisplays_teste1',
  'controlador_teste1', 'guitarhero_teste1'];
const R = {
  versaoVivado: '2026.1',
  util: util('guitarhero'),
  wns: wns('guitarhero'),
  ver: Object.fromEntries(TESTBENCHES.map(tb => [tb, verificacoes(tb)])),
  numTestbenches: String(TESTBENCHES.length),
};

module.exports = R;
