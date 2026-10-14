#!/usr/bin/env python3
"""Teste de mutacoes dos testbenches das aulas 2 e 3 (precisa do Icarus Verilog).

Introduz erros tipicos numa copia de cada modulo e confirma que o testbench
respetivo deteta todos: se um testbench deixasse passar um modulo errado, nao
serviria para certificar o modulo certo.
Uso (na raiz do repositorio): python3 scripts/teste_mutacoes.py
"""
import subprocess, os, tempfile
raiz = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(raiz)
S = tempfile.mkdtemp()
fontes = [
    'multiplexer4x1/multiplexer4x1.v', 'multiplexer16x4/multiplexer16x4.v',
    'descodificador2x4/descodificador2x4.v', 'transcod7seg/transcod7seg.v',
    'transcod7seg/displayBCD.v', 'registo4/registo4.v', 'divisorclock/divisorclock.v',
    'contador4/contador4.v', 'controlodisplays/controlodisplays.v',
    'controlodisplays/testedisplays.v',
]
testbench = {
    'registo4': 'registo4/registo4_teste1.v',
    'transcod7seg': 'transcod7seg/transcod7seg_teste1.v',
    'divisorclock': 'divisorclock/divisorclock_teste1.v',
    'contador4': 'contador4/contador4_teste1.v',
    'controlodisplays': 'controlodisplays/controlodisplays_teste1.v',
    'testedisplays': 'controlodisplays/testedisplays_teste1.v',
}
stub = 'scripts/fdce_modelo.v'   # modelo da primitiva FDCE para o Icarus
# Registo4 em comportamental equivalente, para poder introduzir erros de comportamento
reg_beh = '''`timescale 1ns / 1ps
module Registo4(input [3:0] Data, input CE, input Clk, input CLR, output reg [3:0] DataOut = 0);
  always @(%s) if (%s) DataOut <= 0; else if (%s) DataOut <= %s;
endmodule
'''
R, T, DV, C = 'registo4/registo4.v', 'transcod7seg/transcod7seg.v', 'divisorclock/divisorclock.v', 'contador4/contador4.v'
CD, TD = 'controlodisplays/controlodisplays.v', 'controlodisplays/testedisplays.v'
muts = [
 ('registo4', R, 'CE ignorado',          reg_beh % ('posedge Clk or posedge CLR', 'CLR', '1', 'Data')),
 ('registo4', R, 'clear sincrono',       reg_beh % ('posedge Clk', 'CLR', 'CE', 'Data')),
 ('registo4', R, 'CLR ignorado',         reg_beh % ('posedge Clk', '0', 'CE', 'Data')),
 ('registo4', R, 'flanco descendente',   reg_beh % ('negedge Clk or posedge CLR', 'CLR', 'CE', 'Data')),
 ('registo4', R, 'bits 0 e 1 trocados',  reg_beh % ('posedge Clk or posedge CLR', 'CLR', 'CE', '{Data[3:2],Data[0],Data[1]}')),
 ('registo4', R, 'bit 3 preso a 0',      reg_beh % ('posedge Clk or posedge CLR', 'CLR', 'CE', "{1'b0,Data[2:0]}")),
 ('transcod7seg', T, '7 com segmento f',  ("4'd7:  Segmentos = 7'b0001111", "4'd7:  Segmentos = 7'b0001101")),
 ('transcod7seg', T, 'ativo a High',      None),
 ('transcod7seg', T, 'C igual a 0',       ("4'd14: Segmentos = 7'b0110001", "4'd14: Segmentos = 7'b0000001")),
 ('transcod7seg', T, 'valor 15 em falta', ("4'd15: Segmentos = 7'b1111110;", "")),
 ('divisorclock', DV, 'conta METADE+1',   ("contagem == METADE - 1", "contagem == METADE")),
 ('divisorclock', DV, 'flanco descendente', ("posedge ClockIn", "negedge ClockIn")),
 ('divisorclock', DV, 'METADE por omissao 250', ("parameter METADE = 25000", "parameter METADE = 250")),
 ('contador4', C, 'conta a descer',       ("estado <= estado + 1", "estado <= estado - 1")),
 ('contador4', C, 'modulo 3',             ("estado <= estado + 1", "estado <= (estado == 2) ? 0 : estado + 1")),
 ('contador4', C, 'flanco descendente',   ("posedge Clock", "negedge Clock")),
 ('contador4', C, 'Q1 e Q0 trocados',     ("assign Q1 = estado[1];", "assign Q1 = estado[0]; //")),
 ('controlodisplays', CD, 'anodos nao negados',      ("assign Anodos = ~DisplayAtivo;", "assign Anodos = DisplayAtivo;")),
 ('controlodisplays', CD, 'ponto nao negado',        ("assign DotPoint = ~PontoAtivo;", "assign DotPoint = PontoAtivo;")),
 ('controlodisplays', CD, 'registos 0 e 1 trocados', (".DataIn0(Valor0),\n         .DataIn1(Valor1),", ".DataIn0(Valor1),\n         .DataIn1(Valor0),")),
 ('controlodisplays', CD, 'selecao do mux invertida', (".Sel({Control1, Control0})", ".Sel({Control0, Control1})")),
 ('controlodisplays', CD, 'pontos 2 e 3 trocados',   (".DataIn2(Pontos[2]),\n         .DataIn3(Pontos[3]),", ".DataIn2(Pontos[3]),\n         .DataIn3(Pontos[2]),")),
 ('controlodisplays', CD, 'enables 1 e 2 trocados',  (".En1(Enable1),\n         .En2(Enable2),", ".En1(Enable2),\n         .En2(Enable1),")),
 ('controlodisplays', CD, 'Load3 carrega reg2',      (".CE(Load2),", ".CE(Load3),")),
 ('controlodisplays', CD, 'ClrDP ignorado',          (".CLR(ClrDP)", ".CLR(1'b0)")),
 ('testedisplays', TD, 'LD1 e LD0 trocados',  (".Load1(LD1)", ".Load1(LD0)")),
 ('testedisplays', TD, 'Clear nao limpa os pontos', (".ClrDP(Clear)", ".ClrDP(1'b0)")),
 ('testedisplays', TD, 'EN so liga o display 0', (".Enable3(EN)", ".Enable3(1'b0)")),
]
apanhados = 0
for tb, f, nome, m in muts:
    files = {x: open(x).read() for x in fontes}
    if nome == 'ativo a High':
        files[f] = (files[f].replace("output reg [6:0] Segmentos", "output [6:0] Segmentos")
                    .replace("always @(*)", "reg [6:0] s; assign Segmentos = ~s; always @(*)")
                    .replace("Segmentos = 7'", "s = 7'"))
    elif isinstance(m, tuple):
        assert m[0] in files[f], (nome, m[0])
        files[f] = files[f].replace(m[0], m[1])
    else:
        files[f] = m
    paths = []
    for x, c in files.items():
        p = f"{S}/{x.replace('/', '_')}"; open(p, 'w').write(c); paths.append(p)
    if not (f == R and isinstance(m, str)): paths.append(stub)
    vvp = f'{S}/t.vvp'
    top = os.path.basename(testbench[tb])[:-2]
    r = subprocess.run(['iverilog', '-g2012', '-o', vvp, *paths, testbench[tb], '-s', top], capture_output=True, text=True)
    if r.returncode: print('COMPILACAO FALHOU', nome, r.stderr[:300]); continue
    out = subprocess.run(['vvp', '-n', vvp], capture_output=True, text=True, timeout=600).stdout
    ok = 'Simulacao OK' in out
    apanhados += not ok
    print(f"{'NAO DETETADO' if ok else 'detetado    '}  {tb:17s} {nome}")
print(f'{apanhados}/{len(muts)} erros detetados')
