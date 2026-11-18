#!/usr/bin/env python3
"""Gera os diagramas do relatório do 3.º trabalho como ficheiros .drawio (relatorio/figuras).

Diagramas: arquitetura (blocos), diagrama_fusao, diagrama_estados, codificacao (cubo das
variáveis de estado) e logigrama (máquina de estados com as realimentações).
Os .drawio abrem e editam-se no draw.io; os .png geram-se com fonte/exporta_diagramas.sh.
Uso (na pasta lab3): python3 relatorio/fonte/gera_diagramas.py
"""
import math, os
from xml.sax.saxutils import escape

SAIDA = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'figuras')

BLOCO = 'rounded=0;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;'
CONT = 'rounded=0;whiteSpace=wrap;html=1;fillColor=#fff2cc;strokeColor=#d6b656;'
VERDE = 'rounded=0;whiteSpace=wrap;html=1;fillColor=#d5e8d4;strokeColor=#82b366;'
VERM = 'rounded=0;whiteSpace=wrap;html=1;fillColor=#f8cecc;strokeColor=#b85450;'
ROXO = 'rounded=0;whiteSpace=wrap;html=1;fillColor=#e1d5e7;strokeColor=#9673a6;'
CINZA = 'rounded=0;whiteSpace=wrap;html=1;fillColor=#f5f5f5;strokeColor=#666666;fontColor=#333333;'
BRANCO = 'rounded=0;whiteSpace=wrap;html=1;'
TXT = 'text;html=1;whiteSpace=wrap;strokeColor=none;fillColor=none;align=left;verticalAlign=middle;rounded=0;'
TXTC = 'text;html=1;whiteSpace=wrap;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;rounded=0;'
EDGE = 'edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;'
RETA = 'rounded=0;html=1;'
FIO = EDGE + 'endArrow=none;'
PORTA = 'verticalLabelPosition=bottom;shadow=0;dashed=0;align=center;html=1;verticalAlign=top;fontSize=9;'
AND = PORTA + 'shape=mxgraph.electrical.logic_gates.logic_gate;operation=and;'
OR3 = PORTA + 'shape=mxgraph.electrical.logic_gates.logic_gate;operation=or;numInputs=3;'
XOR = PORTA + 'shape=mxgraph.electrical.logic_gates.logic_gate;operation=xor;'
NOT = PORTA + 'shape=mxgraph.electrical.logic_gates.inverter_2;'
PONTO = 'ellipse;whiteSpace=wrap;html=1;aspect=fixed;fillColor=#000000;strokeColor=none;'
BOLA = 'ellipse;whiteSpace=wrap;html=1;aspect=fixed;fillColor=#ffffff;'
ESTADO = 'ellipse;whiteSpace=wrap;html=1;aspect=fixed;fontSize=11;'


class Diagrama:
    def __init__(self, nome):
        self.nome, self.cel, self.n = nome, [], 1

    def _id(self):
        self.n += 1
        return f'{self.nome[:3]}{self.n}'

    def v(self, valor, x, y, w, h, estilo, pai='1'):
        i = self._id()
        self.cel.append(f'<mxCell id="{i}" value="{escape(valor, {chr(34): "&quot;"})}" style="{estilo}" vertex="1" parent="{pai}">'
                        f'<mxGeometry x="{x}" y="{y}" width="{w}" height="{h}" as="geometry"/></mxCell>')
        return i

    def e(self, src=None, tgt=None, pts=(), estilo=EDGE, rot=None, sai=None, ent=None, sp=None, tp=None, rpos=0, roff=(0, 0)):
        i = self._id()
        st = estilo
        if sai: st += f'exitX={sai[0]};exitY={sai[1]};exitDx=0;exitDy=0;'
        if ent: st += f'entryX={ent[0]};entryY={ent[1]};entryDx=0;entryDy=0;'
        a = f'<mxCell id="{i}" style="{st}" edge="1" parent="1"'
        if src: a += f' source="{src}"'
        if tgt: a += f' target="{tgt}"'
        g = '<mxGeometry relative="1" as="geometry">'
        if sp: g += f'<mxPoint x="{sp[0]}" y="{sp[1]}" as="sourcePoint"/>'
        if tp: g += f'<mxPoint x="{tp[0]}" y="{tp[1]}" as="targetPoint"/>'
        if pts: g += '<Array as="points">' + ''.join(f'<mxPoint x="{x}" y="{y}"/>' for x, y in pts) + '</Array>'
        g += '</mxGeometry>'
        self.cel.append(a + '>' + g + '</mxCell>')
        if rot:
            j = self._id()
            self.cel.append(f'<mxCell id="{j}" value="{escape(rot)}" style="edgeLabel;html=1;align=center;verticalAlign=middle;resizable=0;points=[];fontSize=11;" '
                            f'vertex="1" connectable="0" parent="{i}"><mxGeometry x="{rpos}" relative="1" as="geometry">'
                            f'<mxPoint x="{roff[0]}" y="{roff[1]}" as="offset"/></mxGeometry></mxCell>')
        return i

    def fio(self, *pontos, seta=False, estilo=None):
        """Fio por pontos absolutos (o primeiro e o último são as pontas)."""
        st = estilo or (EDGE if seta else FIO)
        return self.e(None, None, pts=pontos[1:-1], estilo=st, sp=pontos[0], tp=pontos[-1])

    def ponto(self, x, y):
        return self.v('', x - 3, y - 3, 6, 6, PONTO)

    def grava(self):
        xml = ('<mxfile host="drawio">\n  <diagram name="' + self.nome + '" id="' + self.nome + '">\n'
               '    <mxGraphModel grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="0" '
               'pageScale="1" math="0" shadow="0">\n      <root>\n        <mxCell id="0"/>\n        <mxCell id="1" parent="0"/>\n'
               + ''.join('        ' + c + '\n' for c in self.cel) +
               '      </root>\n    </mxGraphModel>\n  </diagram>\n</mxfile>\n')
        f = os.path.join(SAIDA, self.nome + '.drawio')
        open(f, 'w').write(xml)
        print(f)


# ===================================================================== arquitetura
d = Diagrama('arquitetura')
# teclas e oscilador (esquerda)
k1 = d.v('Tecla K1<br>(BTNL)', 20, 105, 100, 50, VERM)
k2 = d.v('Tecla K2<br>(BTNC)', 20, 320, 100, 50, VERM)
k3 = d.v('Tecla K3<br>(BTNR)', 20, 400, 100, 50, VERM)
krs = d.v('Tecla Reset<br>(BTNU)', 20, 490, 100, 50, VERM)
osc = d.v('Oscilador<br>100 MHz (W5)', 20, 600, 100, 50, ROXO)
# tecla 1 em pormenor
d.v('', 200, 30, 600, 260, CONT)
d.v('Gestão da tecla 1 (Tecla)', 560, 34, 230, 24, TXT + 'fontStyle=1;align=right;')
me = d.v('Máquina de estados assíncrona<br>(MaquinaTecla)<br><font style="font-size:10px">Y2, Y1, Y0 com realimentações<br>YY2, YY1, YY0; sem flip-flops</font>',
         250, 70, 230, 110, BLOCO)
xr = d.v('', 560, 145, 60, 40, XOR)
mo = d.v('Temporizador monoestável<br>redisparável (Monoestavel)<br><font style="font-size:10px">To = 1 durante T = 10 ms<br>depois de cada flanco ↑ de Ti</font>',
         520, 205, 250, 75, BLOCO)
d.e(k1, me, sai=(1, 0.5), ent=(0, 0.5))
d.v('K1', 128, 108, 30, 18, TXT + 'fontSize=11;')
d.ponto(170, 130)
d.fio((170, 130), (170, 50), (530, 50), (530, 155), (562, 155), seta=False)
d.e(None, xr, estilo=FIO, sp=(530, 155), ent=(0, 0.25))
d.e(me, xr, sai=(1, 0.75), ent=(0, 0.75), rot='F', rpos=-0.4)
d.e(xr, mo, sai=(1, 0.5), ent=(0.85, 0), pts=[(732, 165)])
d.v('Ti = (K⊕F)·/Clear', 628, 142, 130, 20, TXT + 'fontSize=11;')
d.e(mo, me, sai=(0, 0.5), ent=(0.5, 1), pts=[(365, 243)], rot='To', rpos=-0.3)
d.e(osc, mo, sai=(1, 0.5), ent=(0.3, 1), pts=[(170, 625), (170, 300), (595, 300)], rot='CLK', rpos=0.5)
# teclas 2 e 3
t2 = d.v('Gestão da tecla 2 (Tecla): igual à da tecla 1 (mesmo Clear e mesmo CLK)', 200, 320, 600, 50, CONT)
t3 = d.v('Gestão da tecla 3 (Tecla): igual à da tecla 1 (mesmo Clear e mesmo CLK)', 200, 400, 600, 50, CONT)
d.e(k2, t2, sai=(1, 0.5), ent=(0, 0.5), rot='K2')
d.e(k3, t3, sai=(1, 0.5), ent=(0, 0.5), rot='K3')
# reset
rst = d.v('Clear = BtnReset + reset de arranque<br><font style="font-size:10px">(4 ciclos depois de configurar a FPGA)</font>', 200, 485, 280, 60, BRANCO)
d.e(krs, rst, sai=(1, 0.5), ent=(0, 0.5), rot='BtnReset')
d.e(rst, me, sai=(0, 0.25), ent=(0, 0.86), pts=[(185, 500), (185, 165)], estilo=EDGE + 'dashed=1;')
d.v('Clear', 192, 166, 40, 18, TXT + 'fontSize=11;')
# validacao e LEDs (direita)
va = d.v('Validação<br>(Validacao)<br><font style="font-size:10px">U = uma só tecla<br>M = mais do que uma</font>', 900, 225, 150, 90, BLOCO)
leds_kd = d.v('LEDs LD0 a LD2<br>(Kd1, Kd2, Kd3)', 1120, 110, 150, 50, BLOCO)
leds_um = d.v('LEDs LD15 (U)<br>e LD14 (M)', 1120, 245, 150, 50, BLOCO)
leds_e = d.v('LEDs LD4 a LD12<br>(variáveis de estado)', 1120, 340, 150, 50, BLOCO)
d.e(me, va, sai=(1, 0.25), ent=(0, 0.2), pts=[(860, 98), (860, 243)], rot='Kd1', rpos=-0.6)
d.e(t2, va, sai=(1, 0.5), ent=(0, 0.6), pts=[(840, 345), (840, 279)], rot='Kd2', rpos=-0.6)
d.e(t3, va, sai=(1, 0.5), ent=(0, 0.9), pts=[(870, 425), (870, 306)], rot='Kd3', rpos=-0.6)
d.e(va, leds_um, sai=(1, 0.5), ent=(0, 0.5), rot='U, M')
d.fio((860, 98), (1000, 98), (1000, 135), (1120, 135), seta=True)
d.ponto(860, 98)
d.v('Kd1, Kd2, Kd3', 1010, 112, 100, 20, TXT + 'fontSize=11;')
d.fio((800, 365), (1000, 365), seta=True, estilo=EDGE + 'endArrow=none;dashed=1;')
d.fio((1000, 365), (1120, 365), seta=True)
d.v('YY2..YY0 (×3)', 1010, 345, 110, 20, TXT + 'fontSize=11;')
# circuito de ensaio
d.v('', 520, 520, 760, 160, VERDE)
d.v('Circuito auxiliar de ensaio (fora do sistema pedido)', 530, 522, 400, 24, TXT + 'fontStyle=1;')
ck = d.v('ContaImpulsos<br>(flancos de K1+K2+K3)', 545, 555, 170, 50, BRANCO)
ckd = d.v('ContaImpulsos<br>(flancos de Kd1+Kd2+Kd3)', 545, 615, 170, 50, BRANCO)
cd = d.v('ControloDisplays<br>(sistema do 1.º trabalho)', 840, 580, 180, 60, BRANCO)
dsp = d.v('4 displays de<br>7 segmentos', 1120, 580, 140, 60, BLOCO)
d.e(ck, cd, sai=(1, 0.5), ent=(0, 0.3), rot='8 bits', rpos=-0.3)
d.e(ckd, cd, sai=(1, 0.5), ent=(0, 0.7), rot='8 bits', rpos=-0.3)
d.e(cd, dsp, sai=(1, 0.5), ent=(0, 0.5), rot='Seg, DP, An')
d.grava()

# ===================================================================== diagrama de fusao
d = Diagrama('diagrama_fusao')
ordem = ['a', 'b', 'i', 'c', 'd', 'e', 'f', 'j', 'g', 'h']
pos = {}
R, CX, CY = 170, 230, 210
for k, s in enumerate(ordem):
    ang = math.pi / 2 + 2 * math.pi * k / len(ordem)
    x, y = CX + R * math.cos(ang), CY - R * math.sin(ang)
    pos[s] = (x, y)
    pos[s + '_id'] = d.v(s, x - 18, y - 18, 36, 36, BOLA + 'fontSize=13;fontStyle=1;')
for x, y, G in [('b', 'i', 'S1'), ('c', 'd', 'S2'), ('f', 'j', 'S4'), ('g', 'h', 'S5')]:
    d.e(pos[x + '_id'], pos[y + '_id'], estilo=RETA + 'endArrow=none;strokeWidth=2;')
    mx, my = (pos[x][0] + pos[y][0]) / 2, (pos[x][1] + pos[y][1]) / 2
    fx, fy = (mx - CX) * 1.32 + CX, (my - CY) * 1.32 + CY
    d.v(G, fx - 18, fy - 11, 36, 22, TXTC + 'fontSize=12;fontColor=#1F3864;fontStyle=1;')
for s, G in [('a', 'S0'), ('e', 'S3')]:
    x, y = pos[s]
    fx, fy = (x - CX) * 1.25 + CX, (y - CY) * 1.25 + CY
    d.v(G, fx - 18, fy - 11, 36, 22, TXTC + 'fontSize=12;fontColor=#1F3864;fontStyle=1;')
d.grava()

# ===================================================================== diagrama de estados
d = Diagrama('diagrama_estados')
EST = {  # nome: (x, y, codigo, Kd, F, descricao, colunas estaveis)
    'S0': (90, 60, '000', 0, 0, 'repouso', '00, 01'),
    'S1': (390, 60, '001', 1, 0, 'premida,<br>espera To', '00, 10'),
    'S2': (580, 250, '011', 1, 0, 'temporização<br>ao premir', '01, 11'),
    'S3': (390, 440, '111', 1, 1, 'premida<br>estável', '10'),
    'S4': (90, 440, '110', 0, 1, 'largada,<br>espera To', '00, 10'),
    'S5': (-100, 250, '100', 0, 1, 'temporização<br>ao largar', '01, 11'),
}
ids = {}
TAM = 110
for n, (x, y, c, kd, f, desc, est) in EST.items():
    # so o nome do estado: a codificacao so e escolhida depois (secao 3.4, figura codificacao)
    ids[n] = d.v(f'<b>{n}</b><br><font style="font-size:10px">{desc}</font><br>Kd={kd} F={f}', x, y, TAM, TAM, ESTADO)
    d.v(f'⟲ {est}', x + TAM / 2 - 40, y + TAM - 2 if y > 200 else y - 22, 80, 20, TXTC + 'fontSize=10;fontColor=#555555;')
# reset
d.v('', 30, 0, 16, 16, 'ellipse;whiteSpace=wrap;html=1;aspect=fixed;fillColor=#272727;')
d.v('Clear', 2, -22, 60, 20, TXTC + 'fontSize=11;')
d.e(None, ids['S0'], sp=(46, 12), ent=(0.15, 0.15), estilo=RETA)
SETA = RETA + 'endArrow=block;endFill=1;'
TRAC = RETA + 'endArrow=block;endFill=0;dashed=1;'
d.e(ids['S0'], ids['S1'], estilo=SETA, sai=(1, 0.4), ent=(0, 0.4), rot='10')
d.e(ids['S1'], ids['S2'], estilo=SETA, sai=(0.85, 0.85), ent=(0.3, 0.05), rot='01, 11')
d.e(ids['S2'], ids['S3'], estilo=SETA, sai=(0.3, 0.95), ent=(0.85, 0.15), rot='10')
d.e(ids['S3'], ids['S4'], estilo=SETA, sai=(0, 0.6), ent=(1, 0.6), rot='00')
d.e(ids['S4'], ids['S5'], estilo=SETA, sai=(0.15, 0.15), ent=(0.7, 0.95), rot='01, 11')
d.e(ids['S5'], ids['S0'], estilo=SETA, sai=(0.7, 0.05), ent=(0.15, 0.85), rot='00')
# transicoes realizadas de forma indireta (tracejado)
d.e(ids['S2'], ids['S4'], estilo=TRAC, sai=(0.05, 0.7), ent=(0.95, 0.3), rot='00 (via S3)')
d.e(ids['S5'], ids['S1'], estilo=TRAC, sai=(0.95, 0.3), ent=(0.05, 0.7), rot='10 (via S0)')
d.e(ids['S0'], ids['S2'], estilo=TRAC + 'strokeColor=#888888;', sai=(0.6, 1), ent=(0, 0.25), pts=[(156, 230), (420, 230), (420, 278)],
    rot='11 (só no arranque, via S1)', rpos=0.1, roff=(0, -12))
d.v('Etiquetas: K To. ⟲ = colunas em que o estado é estável.<br>Tracejado: transição feita através de um estado instável intermédio.',
    -100, 590, 680, 40, TXT + 'fontSize=11;')
d.grava()

# ===================================================================== codificacao (cubo)
d = Diagrama('codificacao')
# vertices do cubo: (y2 y1 y0) -> posicao
OX, OY, DX, DY = 160, 40, 190, 120
VERT = {}
for c in ['000', '001', '010', '011', '100', '101', '110', '111']:
    y2, y1, y0 = int(c[0]), int(c[1]), int(c[2])
    VERT[c] = (OX + 260 * y0 + DX * y2, OY + 260 * (1 - y1) + DY * (1 - y2))
NOMES = {'000': 'S0', '001': 'S1', '011': 'S2', '111': 'S3', '110': 'S4', '100': 'S5'}
vid = {}
for c, (x, y) in VERT.items():
    usado = c in NOMES
    txt = f'<b>{NOMES[c]}</b><br>{c}' if usado else f'{c}<br><font style="font-size:9px">não usado</font>'
    vid[c] = d.v(txt, x - 32, y - 24, 64, 48, ('rounded=1;whiteSpace=wrap;html=1;fontSize=11;' if usado else CINZA + 'rounded=1;fontSize=11;'))
for a in VERT:
    for b in VERT:
        if a < b and sum(p != q for p, q in zip(a, b)) == 1:
            d.e(vid[a], vid[b], estilo=RETA + 'endArrow=none;strokeColor=#BBBBBB;dashed=1;')
ANEL = ['000', '001', '011', '111', '110', '100', '000']
for a, b in zip(ANEL, ANEL[1:]):
    d.e(vid[a], vid[b], estilo=RETA + 'endArrow=block;endFill=1;strokeWidth=2;strokeColor=#1F3864;')
d.v('Código y2 y1 y0. Setas: transições da máquina, todas entre códigos adjacentes<br>(muda uma só variável de estado).',
    60, 560, 560, 40, TXT + 'fontSize=11;')
d.grava()

# ===================================================================== logigrama
d = Diagrama('logigrama')
# barramento das variaveis (verticais)
BUS = {'K': 60, 'To': 100, '/To': 140, 'YY2': 180, '/YY2': 220, 'YY1': 260, 'YY0': 300}
YT, YB = 70, 760
for nome, x in BUS.items():
    d.fio((x, YT - 52 if nome in ('K', 'To', 'YY2') else YT), (x, YB))
    if nome.startswith('/'):
        d.v(nome, x + 3, YT - 24, 48, 18, TXT + 'fontSize=11;fontStyle=1;')
    else:
        d.v(nome, x - 24, (YT - 70 if nome in ('K', 'To', 'YY2') else YT - 22), 48, 18, TXTC + 'fontSize=11;fontStyle=1;')
# inversores de To e YY2 (no topo)
for orig, neg, yg in [('To', '/To', 20), ('YY2', '/YY2', 20)]:
    pass
# entradas K e To vindas de fora e inversores
g = d.v('', BUS['/To'] - 10, YT - 58, 34, 20, NOT)
d.fio((BUS['To'], YT - 48), (BUS['/To'] - 10, YT - 48))
d.ponto(BUS['To'], YT - 48)
d.fio((BUS['/To'] + 24, YT - 48), (BUS['/To'] + 30, YT - 48), (BUS['/To'] + 30, YT - 30), (BUS['/To'], YT - 30), (BUS['/To'], YT))
g = d.v('', BUS['/YY2'] - 10, YT - 58, 34, 20, NOT)
d.fio((BUS['YY2'], YT - 48), (BUS['/YY2'] - 10, YT - 48))
d.ponto(BUS['YY2'], YT - 48)
d.fio((BUS['/YY2'] + 24, YT - 48), (BUS['/YY2'] + 30, YT - 48), (BUS['/YY2'] + 30, YT - 30), (BUS['/YY2'], YT - 30), (BUS['/YY2'], YT))
d.fio((BUS['To'], YT - 48), (BUS['To'], YT - 26))
XA, XO, XC, XS, XR = 400, 520, 640, 760, 830     # AND, OR, AND2B1, saida, realimentacao
EQS = [
    ('Y2', 'YY2', [('To', 'YY2'), ('/To', 'YY1'), ('YY2', 'YY1')]),
    ('Y1', 'YY1', [('To', 'YY0'), ('/To', 'YY1'), ('YY1', 'YY0')]),
    ('Y0', 'YY0', [('K', '/YY2'), ('K', 'YY0'), ('/YY2', 'YY0')]),
]
XCLR = 600
d.fio((XCLR, YT - 40), (XCLR, YB - 60))
d.v('Clear', XCLR - 25, YT - 62, 50, 18, TXTC + 'fontSize=11;fontStyle=1;')
for k, (Y, YY, termos) in enumerate(EQS):
    y0 = YT + 30 + 230 * k
    ands = []
    for j, (a, b) in enumerate(termos):
        ya = y0 + 60 * j
        gid = d.v('', XA, ya, 60, 36, AND)
        ands.append(gid)
        for frac, var in ((0.25, a), (0.75, b)):
            yy = ya + 36 * frac
            d.e(None, gid, estilo=FIO, sp=(BUS[var], yy), ent=(0, frac))
            d.ponto(BUS[var], yy)
    o = d.v('', XO, y0 + 40, 60, 60, OR3)
    for j, gid in enumerate(ands):
        d.e(gid, o, estilo=FIO, sai=(1, 0.5), ent=(0, (j + 0.5) / 3))
    c = d.v('', XC, y0 + 52, 60, 36, AND)
    d.e(o, c, estilo=FIO, sai=(1, 0.5), ent=(0, 0.25))
    d.v(Y, XO + 66, y0 + 46, 30, 18, TXT + 'fontSize=11;fontStyle=1;')
    # entrada Clear negada (bolha)
    d.v('', XC - 9, y0 + 52 + 27 - 4, 8, 8, BOLA)
    d.fio((XCLR, y0 + 52 + 27), (XC - 9, y0 + 52 + 27))
    d.ponto(XCLR, y0 + 52 + 27)
    d.v('AND2B1', XC, y0 + 90, 60, 14, TXTC + 'fontSize=9;')
    ys = y0 + 52 + 18
    d.e(c, None, estilo=FIO, sai=(1, 0.5), tp=(XR, ys))
    d.ponto(XR, ys)
    d.v(YY, XC + 70, ys - 20, 40, 18, TXT + 'fontSize=11;fontStyle=1;')
    # realimentacao: sobe pela direita e volta ao barramento por baixo
    yr = YB - 40 + 12 * (2 - k) - 10
for k, (Y, YY, _) in enumerate(EQS):
    ys = YT + 30 + 230 * k + 52 + 18
    yr = YB + 10 + 14 * k
    d.fio((XR, ys), (XR + 20 * (2 - k), ys), (XR + 20 * (2 - k), yr), (BUS[YY], yr), (BUS[YY], YB))
    d.ponto(BUS[YY], YB) if False else None
# saidas
d.fio((XR, YT + 30 + 52 + 18 + 460), (XR + 120, YT + 30 + 52 + 18 + 460), seta=True)
d.v('Kd = YY0', XR + 70, YT + 30 + 52 + 18 + 440, 80, 18, TXT + 'fontSize=11;fontStyle=1;')
d.fio((XR, YT + 30 + 52 + 18), (XR + 120, YT + 30 + 52 + 18), seta=True)
d.v('F = YY2', XR + 70, YT + 30 + 52 + 18 - 20, 80, 18, TXT + 'fontSize=11;fontStyle=1;')
d.v('Realimentações', BUS['YY0'] + 30, YB + 40, 120, 18, TXT + 'fontSize=10;')
d.grava()
