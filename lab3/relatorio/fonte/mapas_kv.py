#!/usr/bin/env python3
"""Desenha os mapas de Karnaugh das equações de excitação (relatorio/figuras/mapas_kv.png).

Cada variável secundária (Y2, Y1, Y0) é uma função das cinco variáveis K, To, YY2, YY1 e YY0, pelo
que cada mapa tem 32 células: 8 linhas com os códigos de estado YY2 YY1 YY0 e 4 colunas com K To,
ambos em código de Gray, com a mesma forma da tabela de transições. As células são tiradas
diretamente da tabela de transições calculada por scripts/projeto.py (simulacao/projeto.json);
'-' é uma célula indiferente (combinação que não ocorre em modo fundamental ou código não usado,
010 e 101).
Num mapa de 8 linhas em código de Gray refletido, as linhas simétricas em relação ao meio (traço
grosso) só diferem em YY2 e também são adjacentes; por isso alguns agrupamentos têm duas partes.
O script confere que os agrupamentos cobrem todos os 1 e nenhum 0, e que dois 1 adjacentes estão
sempre no mesmo agrupamento (sem acidentes estáticos).
Uso (na pasta lab3): python3 relatorio/fonte/mapas_kv.py
"""
import json, os
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, Rectangle

RAIZ = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
P = json.load(open(os.path.join(RAIZ, 'simulacao', 'projeto.json')))
LIN = ['000', '001', '011', '010', '110', '111', '101', '100']   # YY2 YY1 YY0 (Gray refletido)
COL = ['00', '01', '11', '10']                                   # K To (como na tabela de transições)
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


def celula(r, c):
    """Valores das cinco variaveis na celula (linha r, coluna c)."""
    return {'K': int(COL[c][0]), 'To': int(COL[c][1]), 'YY2': int(LIN[r][0]), 'YY1': int(LIN[r][1]), 'YY0': int(LIN[r][2])}


def valor(bit, v):
    prox = P['transicoes'][f"{v['YY2']}{v['YY1']}{v['YY0']}"][COL.index(f"{v['K']}{v['To']}")]
    return None if prox is None else prox[bit]


def cobre(lits, v):
    return all(v[k] == x for k, x in lits.items())


def trocos(idx, n):
    """Linhas ou colunas de um agrupamento em troços contíguos: (inicio, fim, aberto_antes, aberto_depois).
    Se o agrupamento usa a primeira e a última (dá a volta ao mapa), esses troços ficam abertos na borda."""
    runs = []
    for i in sorted(idx):
        if runs and i == runs[-1][1] + 1:
            runs[-1][1] = i
        else:
            runs.append([i, i])
    volta = len(runs) > 1 and runs[0][0] == 0 and runs[-1][1] == n - 1
    return [(a, b, volta and k == 0, volta and k == len(runs) - 1) for k, (a, b) in enumerate(runs)]


fig = plt.figure(figsize=(13, 8.4))
ax = fig.add_axes([0, 0, 1, 1])
ax.set_xlim(-0.6, 19.0); ax.set_ylim(-1.75, 10.9); ax.invert_yaxis(); ax.axis('off'); ax.set_aspect('equal')
for k, (Y, bit, termos) in enumerate(MAPAS):
    # --- confere a cobertura e os acidentes estaticos nas 32 celulas
    for r in range(8):
        for c in range(4):
            v = celula(r, c)
            val = valor(bit, v)
            coberto = any(cobre(t[0], v) for t in termos)
            if val == '1': assert coberto, (Y, v)
            if val == '0': assert not coberto, (Y, v)
            for var in VARS:                     # vizinho que difere numa so variavel
                w = dict(v); w[var] = 1 - w[var]
                if val == '1' and valor(bit, w) == '1':
                    assert any(cobre(t[0], v) and cobre(t[0], w) for t in termos), ('acidente', Y, v, var)

    x0 = 1.9 + 6.45 * k                          # canto superior esquerdo do mapa
    ax.text(x0 + 2, -1.25, Y, ha='center', va='center', fontsize=17, fontweight='bold')
    ax.text(x0 - 0.12, -0.12, 'YY2 YY1 YY0 \\ K To', ha='right', va='bottom', fontsize=8.5, style='italic')
    for c in range(4):
        ax.text(x0 + c + 0.5, -0.12, COL[c], ha='center', va='bottom', fontsize=11)
    for r in range(8):
        ax.text(x0 - 0.15, r + 0.5, LIN[r], ha='right', va='center', fontsize=11)
        for c in range(4):
            ax.add_patch(Rectangle((x0 + c, r), 1, 1, fill=False, lw=1.0, color='#555555'))
            val = valor(bit, celula(r, c))
            ax.text(x0 + c + 0.5, r + 0.5, '-' if val is None else val, ha='center', va='center',
                    fontsize=13, color='#9a9a9a' if val is None else 'black')
    # eixo de simetria: as linhas simetricas em relacao a este traco tambem sao adjacentes
    ax.plot([x0 - 0.25, x0 + 4.25], [4, 4], color='black', lw=2.6, solid_capstyle='butt')
    borda = Rectangle((x0, 0), 4, 8, transform=ax.transData)
    # --- agrupamentos
    for j, (lits, cor, _) in enumerate(termos):
        linhas = [r for r in range(8) if cobre({a: b for a, b in lits.items() if a.startswith('YY')}, celula(r, 0))]
        colunas = [c for c in range(4) if cobre({a: b for a, b in lits.items() if a in ('K', 'To')}, celula(0, c))]
        d = 0.07 + 0.07 * j
        for r0, r1, ra, rd in trocos(linhas, 8):
            for c0, c1, ca, cd in trocos(colunas, 4):
                xa = x0 - 0.6 if ca else x0 + c0 + d
                xb = x0 + 4.6 if cd else x0 + c1 + 1 - d
                ya = -0.6 if ra else r0 + d
                yb = 8.6 if rd else r1 + 1 - d
                p = FancyBboxPatch((xa, ya), xb - xa, yb - ya, boxstyle='round,pad=0,rounding_size=0.22',
                                   fill=False, lw=2.3, ec=cor)
                ax.add_patch(p)
                p.set_clip_path(borda)
    # --- equacao e legenda das cores
    eq = ' + '.join(t[2].split(' ')[0] for t in termos)
    ax.text(x0 + 2, 8.65, f'{Y} = {eq}', ha='center', va='center', fontsize=12)
    for j, (_, cor, nome) in enumerate(termos):
        yl = 9.35 + 0.5 * j
        ax.plot([x0 + 0.2, x0 + 0.85], [yl, yl], color=cor, lw=2.6)
        ax.text(x0 + 1.05, yl, nome, ha='left', va='center', fontsize=10.5)
saida = os.path.join(RAIZ, 'relatorio', 'figuras', 'mapas_kv.png')
plt.savefig(saida, dpi=160, facecolor='white')
print(saida)
