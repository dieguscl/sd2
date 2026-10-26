#!/usr/bin/env python3
"""Desenha os 16 simbolos do transcodificador (Fig. 30 + simbolos originais "rdLEC-").

Le os valores dos segmentos diretamente de transcod7seg/transcod7seg.v, para a figura
do relatorio ser sempre igual ao que esta no codigo.
Uso (na raiz do repositorio): python3 relatorio/fonte/simbolos7seg.py
"""
import re, os
from PIL import Image, ImageDraw, ImageFont

raiz = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
codigo = open(os.path.join(raiz, 'transcod7seg/transcod7seg.v')).read()
valores = {int(n): b for n, b in re.findall(r"4'd(\d+):\s+Segmentos = 7'b([01]{7})", codigo)}
assert sorted(valores) == list(range(16))

S = 4                       # escala (desenho a 4x e reduzido no fim, para suavizar)
W, H, M = 70 * S, 120 * S, 10 * S
t = 9 * S                   # espessura dos segmentos
L = W - 2 * M               # comprimento dos horizontais
V = (H - 2 * M - 3 * t) // 2 + t

def seg_poly(nome):
    x0, y0 = M, M
    xs = {'a': (x0 + t // 2, y0, 'h'), 'g': (x0 + t // 2, y0 + V, 'h'), 'd': (x0 + t // 2, y0 + 2 * V, 'h'),
          'f': (x0, y0 + t // 2, 'v'), 'b': (x0 + L, y0 + t // 2, 'v'),
          'e': (x0, y0 + V + t // 2, 'v'), 'c': (x0 + L, y0 + V + t // 2, 'v')}
    x, y, o = xs[nome]
    h = t // 2
    if o == 'h':
        l = L - t
        return [(x + h, y), (x + l - h, y), (x + l, y + h), (x + l - h, y + t), (x + h, y + t), (x, y + h)]
    l = V - t
    return [(x + h, y + h), (x + t, y + t), (x + t, y + l), (x + h, y + l + h), (x, y + l), (x, y + t)]

try:
    fonte = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 15 * S)
except OSError:
    fonte = ImageFont.load_default()

cols, rows = 8, 2
cw, ch = W + 16 * S, H + 34 * S
img = Image.new('RGB', (cols * cw, rows * ch), 'white')
d = ImageDraw.Draw(img)
for n in range(16):
    cx, cy = (n % cols) * cw + 8 * S, (n // cols) * ch + 4 * S
    d.rectangle([cx, cy, cx + W, cy + H], fill=(30, 30, 30))
    bits = valores[n]
    for i, nome in enumerate('abcdefg'):
        aceso = bits[i] == '0'                      # ativo a Low
        cor = (255, 40, 30) if aceso else (70, 70, 70)
        d.polygon([(cx + px, cy + py) for px, py in seg_poly(nome)], fill=cor)
    txt = f'{n}'
    tw = d.textlength(txt, font=fonte)
    d.text((cx + W / 2 - tw / 2, cy + H + 6 * S), txt, fill='black', font=fonte)
img = img.resize((img.width // 2, img.height // 2), Image.LANCZOS)
saida = os.path.join(raiz, 'relatorio/figuras/simbolos7seg.png')
img.save(saida)
print(saida)
