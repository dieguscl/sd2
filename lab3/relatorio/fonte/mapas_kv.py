#!/usr/bin/env python3
"""Desenha os mapas de Karnaugh das equações de excitação (relatorio/figuras/mapas_kv.png).

Cada variável secundária (Y2, Y1, Y0) é uma função das cinco variáveis K, To, YY2, YY1 e YY0, pelo
que cada mapa é o mapa de 5 variáveis habitual: dois mapas de 4 x 4, um para YY2 = 0 e outro para
YY2 = 1, com YY1 YY0 nas linhas e K To nas colunas (código de Gray, como na tabela de transições).
As células são tiradas diretamente da tabela de transições calculada por scripts/projeto.py
(simulacao/projeto.json); '-' é uma célula indiferente (combinação que não ocorre em modo
fundamental ou código não usado, 010 e 101).
O script confere que os agrupamentos cobrem todos os 1 e nenhum 0, e que dois 1 adjacentes estão
sempre no mesmo agrupamento (sem acidentes estáticos).
Uso (na pasta lab3): python3 relatorio/fonte/mapas_kv.py
"""
import json, os
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, Rectangle
from matplotlib.lines import Line2D

RAIZ = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
P = json.load(open(os.path.join(RAIZ, 'simulacao', 'projeto.json')))
GRAY = ['00', '01', '11', '10']          # linhas: YY1 YY0; colunas: K To (mesma ordem da tabela de transições)
VARS = ['K', 'To', 'YY2', 'YY1', 'YY0']
AZUL, VERM, VERDE = '#1f77b4', '#d62728', '#2ca02c'

# (variavel, bit em Y2 Y1 Y0, termos: (literais, cor, texto))
MAPAS = [
    ('Y2', 0, [({'To': 1, 'YY2': 1}, AZUL, 'To·YY2'), ({'To': 0, 'YY1': 1}, VERM, '/To·YY1'),
               ({'YY2': 1, 'YY1': 1}, VERDE, 'YY2·YY1 (consenso)')]),
    ('Y1', 1, [({'To': 1, 'YY0': 1}, AZUL, 'To·YY0'), ({'To': 0, 'YY1': 1}, VERM, '/To·YY1'),
               ({'YY1': 1, 'YY0': 1}, VERDE, 'YY1·YY0 (consenso)')]),
    ('Y0', 2, [({'K': 1, 'YY2': 0}, AZUL, 'K·/YY2'), ({'K': 1, 'YY0': 1}, VERM, 'K·YY0'),
               ({'YY2': 0, 'YY0': 1}, VERDE, '/YY2·YY0')]),
]


def celula(yy2, r, c):
    """Valores das cinco variaveis na celula (linha r, coluna c) do mapa de YY2 = yy2."""
    return {'K': int(GRAY[c][0]), 'To': int(GRAY[c][1]), 'YY2': yy2, 'YY1': int(GRAY[r][0]), 'YY0': int(GRAY[r][1])}


def valor(bit, v):
    prox = P['transicoes'][f"{v['YY2']}{v['YY1']}{v['YY0']}"][GRAY.index(f"{v['K']}{v['To']}")]
    return None if prox is None else prox[bit]


def cobre(lits, v):
    return all(v[k] == x for k, x in lits.items())


def segmentos(idx):
    """Indices (linhas ou colunas) de um agrupamento em troços contíguos; {0, 3} dá a volta ao mapa."""
    idx = sorted(idx)
    if idx == [0, 3]:
        return [(0, 0, 'antes'), (3, 3, 'depois')]
    assert idx == list(range(idx[0], idx[-1] + 1)), idx
    return [(idx[0], idx[-1], None)]


fig, eixos = plt.subplots(3, 1, figsize=(11.5, 13.2))
for ax, (Y, bit, termos) in zip(eixos, MAPAS):
    # --- confere a cobertura e os acidentes estaticos nas 32 celulas
    todas = [celula(m, r, c) for m in (0, 1) for r in range(4) for c in range(4)]
    for v in todas:
        val = valor(bit, v)
        coberto = any(cobre(t[0], v) for t in termos)
        if val == '1': assert coberto, (Y, v)
        if val == '0': assert not coberto, (Y, v)
        for var in VARS:                         # vizinho que difere numa so variavel
            w = dict(v); w[var] = 1 - w[var]
            if val == '1' and valor(bit, w) == '1':
                assert any(cobre(t[0], v) and cobre(t[0], w) for t in termos), ('acidente', Y, v, var)

    ax.set_xlim(-2.6, 11.3); ax.set_ylim(-1.3, 5.6); ax.invert_yaxis(); ax.axis('off'); ax.set_aspect('equal')
    ax.text(-2.5, 2.0, Y, ha='left', va='center', fontsize=20, fontweight='bold')
    for m in (0, 1):
        x0 = 0.6 + 6.3 * m                      # canto superior esquerdo do mapa
        ax.text(x0 + 2, -1.0, f'YY2 = {m}', ha='center', va='center', fontsize=13, fontweight='bold')
        ax.text(x0 - 0.1, -0.15, 'YY1 YY0 \\ K To', ha='right', va='bottom', fontsize=9.5, style='italic')
        for c in range(4):
            ax.text(x0 + c + 0.5, -0.12, GRAY[c], ha='center', va='bottom', fontsize=11.5)
        for r in range(4):
            ax.text(x0 - 0.15, r + 0.5, GRAY[r], ha='right', va='center', fontsize=11.5)
            for c in range(4):
                ax.add_patch(Rectangle((x0 + c, r), 1, 1, fill=False, lw=1.1, color='#444444'))
                val = valor(bit, celula(m, r, c))
                ax.text(x0 + c + 0.5, r + 0.5, '-' if val is None else val, ha='center', va='center',
                        fontsize=14, color='#9a9a9a' if val is None else 'black')
        borda = Rectangle((x0, 0), 4, 4, transform=ax.transData)
        # --- agrupamentos (um troço de cada lado quando o agrupamento dá a volta ao mapa)
        for k, (lits, cor, _) in enumerate(termos):
            if 'YY2' in lits and lits['YY2'] != m:
                continue
            linhas = [r for r in range(4) if cobre({a: b for a, b in lits.items() if a in ('YY1', 'YY0')}, celula(m, r, 0))]
            colunas = [c for c in range(4) if cobre({a: b for a, b in lits.items() if a in ('K', 'To')}, celula(m, 0, c))]
            d = 0.07 + 0.07 * k
            for r0, r1, _ in segmentos(linhas):
                for c0, c1, lado in segmentos(colunas):
                    xa, xb = x0 + c0 + d, x0 + c1 + 1 - d
                    if lado == 'antes': xa = x0 - 0.6
                    if lado == 'depois': xb = x0 + 4.6
                    p = FancyBboxPatch((xa, r0 + d), xb - xa, r1 + 1 - r0 - 2 * d,
                                       boxstyle='round,pad=0,rounding_size=0.22', fill=False, lw=2.3, ec=cor)
                    ax.add_patch(p)
                    p.set_clip_path(borda)
    eq = ' + '.join(t[2].split(' ')[0] for t in termos)
    ax.text(5.75, 4.75, f'{Y} = {eq}', ha='center', va='center', fontsize=14)
    ax.legend(handles=[Line2D([], [], color=t[1], lw=2.6) for t in termos], labels=[t[2] for t in termos],
              loc='upper center', bbox_to_anchor=(0.5, 0.06), ncol=3, frameon=False, fontsize=11.5)
plt.tight_layout(h_pad=1.2)
saida = os.path.join(RAIZ, 'relatorio', 'figuras', 'mapas_kv.png')
plt.savefig(saida, dpi=160, facecolor='white')
print(saida)
