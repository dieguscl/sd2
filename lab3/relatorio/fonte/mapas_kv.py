#!/usr/bin/env python3
"""Desenha os mapas de Karnaugh das equações de excitação (relatorio/figuras/mapas_kv.png).

Os valores vêm da tabela de transições calculada por scripts/projeto.py (simulacao/projeto.json):
cada variável secundária só depende de três variáveis (Y2 de To, YY2, YY1; Y1 de To, YY1, YY0;
Y0 de K, YY2, YY0), pelo que cada mapa tem 2 x 4 células. Uma célula do mapa reúne as células da
tabela de transições com os mesmos valores dessas três variáveis: todas as especificadas têm de
ter o mesmo valor (confere-se aqui), e a célula é indiferente (-) se nenhuma estiver especificada.
Uso (na pasta lab3): python3 relatorio/fonte/mapas_kv.py
"""
import json, os
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch

RAIZ = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
P = json.load(open(os.path.join(RAIZ, 'simulacao', 'projeto.json')))
COLS = ['00', '01', '11', '10']          # K To
GRAY = ['00', '01', '11', '10']

def valores(Y, linha_var, col_vars):
    """mapa[linha][coluna] para a variavel Y (bit 2, 1 ou 0 de Y2 Y1 Y0)."""
    bit = 2 - int(Y[1])
    mapa = [[None] * 4 for _ in range(2)]
    for y, prox in P['transicoes'].items():
        for j, kto in enumerate(COLS):
            if prox[j] is None: continue
            v = {'K': kto[0], 'To': kto[1], 'YY2': y[0], 'YY1': y[1], 'YY0': y[2]}
            r = int(v[linha_var]); c = GRAY.index(v[col_vars[0]] + v[col_vars[1]])
            val = prox[j][bit]
            assert mapa[r][c] in (None, val), (Y, r, c)
            mapa[r][c] = val
    return mapa

# (variavel, linha, colunas, termos: (linha(s), colunas, cor, texto))
MAPAS = [
    ('Y2', 'To', ('YY2', 'YY1'), [([1], [2, 3], '#1f77b4', 'To·YY2'), ([0], [1, 2], '#d62728', '/To·YY1'),
                                  ([0, 1], [2], '#2ca02c', 'YY2·YY1')]),
    ('Y1', 'To', ('YY1', 'YY0'), [([1], [1, 2], '#1f77b4', 'To·YY0'), ([0], [2, 3], '#d62728', '/To·YY1'),
                                  ([0, 1], [2], '#2ca02c', 'YY1·YY0')]),
    ('Y0', 'K', ('YY2', 'YY0'), [([1], [0, 1], '#1f77b4', 'K·/YY2'), ([1], [1, 2], '#d62728', 'K·YY0'),
                                 ([0, 1], [1], '#2ca02c', '/YY2·YY0')]),
]

fig, eixos = plt.subplots(1, 3, figsize=(13.5, 3.6))
for ax, (Y, lv, cv, termos) in zip(eixos, MAPAS):
    m = valores(Y, lv, cv)
    # confere que os termos cobrem os 1 e não cobrem os 0
    for r in range(2):
        for c in range(4):
            coberto = any(r in ls and c in cs for ls, cs, _, _ in termos)
            if m[r][c] == '1': assert coberto, (Y, r, c)
            if m[r][c] == '0': assert not coberto, (Y, r, c)
    ax.set_xlim(-1.2, 4.2); ax.set_ylim(-1.0, 3.1); ax.invert_yaxis(); ax.axis('off')
    for r in range(2):
        for c in range(4):
            ax.add_patch(plt.Rectangle((c, r + 0.4), 1, 1, fill=False, lw=1.2, color='#444444'))
            txt = '-' if m[r][c] is None else m[r][c]
            ax.text(c + 0.5, r + 0.9, txt, ha='center', va='center', fontsize=15,
                    color='#999999' if txt == '-' else 'black')
        ax.text(-0.15, r + 0.9, str(r), ha='right', va='center', fontsize=12)
    for c in range(4):
        ax.text(c + 0.5, 0.25, GRAY[c], ha='center', va='bottom', fontsize=12)
    ax.text(-0.15, 0.25, f'{lv} \\ {cv[0]} {cv[1]}', ha='right', va='bottom', fontsize=11, style='italic')
    ax.text(2.0, -0.55, f'{Y}', ha='center', va='center', fontsize=15, fontweight='bold')
    for k, (ls, cs, cor, nome) in enumerate(termos):
        d = 0.08 + 0.07 * k
        x0, x1 = min(cs) + d, max(cs) + 1 - d
        y0, y1 = min(ls) + 0.4 + d, max(ls) + 1.4 - d
        ax.add_patch(FancyBboxPatch((x0, y0), x1 - x0, y1 - y0, boxstyle='round,pad=0,rounding_size=0.25',
                                    fill=False, lw=2.2, ec=cor))
    eq = ' + '.join(t[3] for t in termos)
    ax.text(2.0, 2.85, f'{Y} = {eq}', ha='center', va='center', fontsize=11.5)
    # legenda das cores
plt.tight_layout()
saida = os.path.join(RAIZ, 'relatorio', 'figuras', 'mapas_kv.png')
plt.savefig(saida, dpi=170, facecolor='white')
print(saida)
