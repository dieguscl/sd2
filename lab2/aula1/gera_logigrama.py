#!/usr/bin/env python3
"""Gera aula1/logigrama.svg: circuito da realização direta do controlador (um FF por estado).

Cada linha é um flip-flop (FF_Sk) com a lógica do estado seguinte (D_Sk) à esquerda; à direita
estão as saídas de Moore. Os nomes cinzentos são os nomes das instâncias em controlador/controlador.v.
Uso: python3 aula1/gera_logigrama.py
"""
import os

AQUI = os.path.dirname(os.path.abspath(__file__))

# estado -> lista de termos do D; termo = ('and', a, b, instância) ou ('lit', sinal)
ESTADOS = [
    ('S0', 'FDPE', 'PRE', [], 'ns0'),
    ('S1', 'FDCE', 'CLR', [('lit', 'S0'), ('and', 'S1', '/Start', 'dec_s1_0')], 'ns1'),
    ('S2', 'FDCE', 'CLR', [('and', 'S1', 'Start', 'dec_s1_1'), ('and', 'S2', 'Start', 'dec_s2_1')], 'ns2'),
    ('S3', 'FDCE', 'CLR', [('and', 'S2', '/Start', 'dec_s2_0'), ('lit', 'S5')], 'ns3'),
    ('S4', 'FDCE', 'CLR', [('lit', 'S3'), ('and', 'S4', 'Tempo', 'dec_s4_1')], 'ns4'),
    ('S5', 'FDCE', 'CLR', [('and', 'S4', '/Tempo', 'dec_s4_0')], 'ns5'),
]

# saídas de Moore: (nome, estados, instância)
SAIDAS = [
    ('ClrMem', ['S0'], 'o_clrmem'), ('InitLFSR', ['S0'], 'o_initlfsr'), ('RstTemp', ['S0'], 'o_rsttemp'),
    ('EnLFSR', ['S0', 'S1', 'S2', 'S3', 'S4', 'S5'], 'o_enlfsr'),
    ('Ready', ['S1', 'S2'], 'o_ready'),
    ('ShiftMem', ['S3'], 'o_shiftmem'), ('TglBeat', ['S3'], 'o_tglbeat'), ('StartTemp', ['S3'], 'o_starttemp'),
    ('Waiting', ['S4'], 'o_waiting'), ('Faster', ['S5'], 'o_faster'),
]

W, H = 1180, 640
svg = []
add = svg.append


def linha(*pts, seta=False):
    d = 'M' + ' L'.join(f'{x},{y}' for x, y in pts)
    add(f'<path d="{d}" class="w"{" marker-end=\"url(#a)\"" if seta else ""}/>')


def texto(x, y, t, cls='n', anchor='start'):
    add(f'<text x="{x}" y="{y}" class="{cls}" text-anchor="{anchor}">{t}</text>')


def porta_and(x, y, h=30):
    """AND com o canto superior esquerdo em (x, y); devolve a saída."""
    r = h / 2
    add(f'<path d="M{x},{y} H{x + 18} A{r},{r} 0 0 1 {x + 18},{y + h} H{x} Z" class="g"/>')
    return (x + 18 + r, y + r)


def porta_or(x, y, h=30):
    add(f'<path d="M{x},{y} Q{x + 12},{y + h / 2} {x},{y + h} Q{x + 30},{y + h} {x + 42},{y + h / 2} '
        f'Q{x + 30},{y} {x},{y} Z" class="g"/>')
    return (x + 42, y + h / 2)


def ponto(x, y):
    add(f'<circle cx="{x}" cy="{y}" r="2.6" fill="#333"/>')


add(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" font-family="DejaVu Sans, Arial, sans-serif">')
add('<defs><marker id="a" viewBox="0 0 8 8" refX="8" refY="4" markerWidth="6" markerHeight="6" orient="auto">'
    '<path d="M0,0 L8,4 L0,8 z" fill="#333"/></marker></defs>')
add('<style>.w{stroke:#333;stroke-width:1.3;fill:none}.g{fill:#eeeefc;stroke:#4b46a8;stroke-width:1.5}'
    '.ff{fill:#e3f4ec;stroke:#1d6b4a;stroke-width:1.6}.n{font-size:13px;fill:#222}'
    '.i{font-size:10.5px;fill:#888;font-family:DejaVu Sans Mono,monospace}.b{font-size:13px;font-weight:bold;fill:#1d6b4a}'
    '.p{font-size:10.5px;fill:#555}.t{font-size:14px;font-weight:bold;fill:#444}'
    '.r{stroke:#1d6b4a;stroke-width:3.2;fill:none;opacity:.55}.rl{font-size:12px;fill:#1d6b4a;font-style:italic}</style>')

# ---------------------------------------------------------------- inversores (canto superior esquerdo)
texto(20, 22, 'Condições negadas', 't')
for k, (ent, inst) in enumerate([('Start', 'inv_start'), ('Tempo', 'inv_tempo')]):
    y = 50 + 44 * k
    texto(20, y + 5, ent)
    linha((70, y), (110, y))
    add(f'<path d="M110,{y - 12} L132,{y} L110,{y + 12} Z" class="g"/>')
    add(f'<circle cx="136" cy="{y}" r="4" class="g"/>')
    linha((140, y), (180, y))
    texto(186, y + 5, '/' + ent)
    texto(110, y - 16, inst, 'i')
texto(20, 160, 'Realimentações (verde): as saídas', 'p')
texto(20, 175, 'Q dos FF (S0…S5) voltam às portas', 'p')
texto(20, 190, 'do estado seguinte.', 'p')
texto(20, 210, '/Start, /Tempo: saídas dos inversores.', 'p')
texto(20, 230, 'Relógio: CLKBasys (100 MHz) em todos os FF.', 'p')
texto(20, 245, 'Reset: saída do SincronizadorReset', 'p')
texto(20, 260, '(PRE do FF_S0, CLR dos outros).', 'p')
texto(20, 285, 'AND = decisão (estado · condição),', 'p')
texto(20, 300, 'OR = reunião dos percursos que', 'p')
texto(20, 315, 'entram no mesmo estado.', 'p')
texto(20, 340, 'Cinzento: nome da instância em', 'p')
texto(20, 355, 'controlador/controlador.v.', 'p')

# ---------------------------------------------------------------- flip-flops e estado seguinte
texto(330, 22, 'Estado seguinte (D) e flip-flops', 't')
X_AND, X_OR, X_FF = 410, 525, 610
XB_E, XB_D, YB = 300, 790, 42       # barramento de realimentação: esquerda, direita, cima
Y0, DY = 105, 92
ultimo = Y0 + DY * (len(ESTADOS) - 1) - 14
add(f'<path d="M{XB_D},{Y0 - 14} V{YB} H{XB_E} V{ultimo + 40}" class="r"/>')
texto(XB_E + 160, YB - 5, 'realimentação S0…S5 (saídas Q dos flip-flops)', 'rl')
for k, (est, prim, pin, termos, inst_ns) in enumerate(ESTADOS):
    yc = Y0 + DY * k                 # centro do FF
    yd = yc - 14                      # entrada D
    # flip-flop
    add(f'<rect x="{X_FF}" y="{yc - 30}" width="74" height="60" rx="3" class="ff"/>')
    texto(X_FF + 6, yd + 4, 'D', 'p')
    add(f'<path d="M{X_FF},{yc + 8} L{X_FF + 9},{yc + 14} L{X_FF},{yc + 20}" class="w"/>')
    texto(X_FF + 66, yd + 4, 'Q', 'p', 'end')
    texto(X_FF + 37, yc + 26, pin, 'p', 'middle')
    linha((X_FF - 22, yc + 14), (X_FF, yc + 14))
    texto(X_FF - 25, yc + 18, 'Clock', 'p', 'end')
    linha((X_FF + 37, yc + 30), (X_FF + 37, yc + 40))
    texto(X_FF + 42, yc + 42, 'Reset', 'p')
    texto(X_FF + 37, yc - 34, f'FF_{est} ({prim})', 'b', 'middle')
    # saída Q: vai para o barramento de realimentação
    add(f'<path d="M{X_FF + 74},{yd} H{XB_D}" class="w"/>')
    if k > 0:
        add(f'<path d="M{XB_D},{yd} V{yd - DY}" class="r"/>')
    ponto(XB_D, yd)
    texto(X_FF + 100, yd - 5, est, 'b')
    # lógica do D
    if not termos:
        linha((X_FF - 40, yd), (X_FF, yd))
        texto(X_FF - 46, yd + 5, '0', 'n', 'end')
        texto(X_FF - 46, yd - 10, f'{inst_ns}: D = 0 (só PRE)', 'i', 'end')
        continue
    saidas = []
    for j, t in enumerate(termos):
        ya = yd - 26 + 40 * j if len(termos) == 2 else yd - 15
        if t[0] == 'and':
            _, a, b, inst = t
            # a = estado (vem da realimentação), b = condição (entrada ou inversor)
            linha((XB_E, ya + 8), (X_AND, ya + 8))
            ponto(XB_E, ya + 8)
            texto(XB_E + 8, ya + 4, a, 'b')
            linha((X_AND - 26, ya + 22), (X_AND, ya + 22))
            texto(X_AND - 30, ya + 26, b, 'n', 'end')
            o = porta_and(X_AND, ya)
            texto(X_AND + 36, ya + 11, inst, 'i')
            saidas.append(o)
        else:
            y = ya + 15
            linha((XB_E, y), (X_AND + 33, y))
            ponto(XB_E, y)
            texto(XB_E + 8, y - 4, t[1], 'b')
            saidas.append((X_AND + 33, y))
    if len(saidas) == 2:
        oy = yd - 15
        xo1, xo2 = X_OR - 30, X_OR - 18
        linha(saidas[0], (xo1, saidas[0][1]), (xo1, oy + 8), (X_OR + 5, oy + 8))
        linha(saidas[1], (xo2, saidas[1][1]), (xo2, oy + 22), (X_OR + 5, oy + 22))
        o = porta_or(X_OR, oy)
        texto(X_OR + 6, oy - 4, inst_ns, 'i')
        linha(o, (X_FF, yd))
    else:
        linha(saidas[0], (X_FF, yd))
        texto(X_OR, yd - 6, inst_ns + ' (buf)', 'i')

# ---------------------------------------------------------------- saídas de Moore
X_S = 850
texto(X_S, 22, 'Saídas (Moore)', 't')
y = 52
for nome, ests, inst in SAIDAS:
    if len(ests) == 1:
        texto(X_S + 26, y + 4, ests[0], 'n', 'end')
        linha((X_S + 30, y), (X_S + 160, y), seta=True)
        texto(X_S + 166, y + 5, nome, 'n')
        texto(X_S + 60, y - 5, inst, 'i')
        y += 30
    else:
        h = max(30, 14 * len(ests) + 4)
        for j, e in enumerate(ests):
            yy = y + 9 + 14 * j
            texto(X_S + 26, yy + 4, e, 'n', 'end')
            linha((X_S + 30, yy), (X_S + 68, yy))
        o = porta_or(X_S + 62, y, h)
        linha(o, (X_S + 160, o[1]), seta=True)
        texto(X_S + 166, o[1] + 5, nome, 'n')
        texto(X_S + 108, o[1] - 5, inst, 'i')
        y += h + 16

add('</svg>')
with open(os.path.join(AQUI, 'logigrama.svg'), 'w') as f:
    f.write('\n'.join(svg))
print('logigrama.svg gerado')
