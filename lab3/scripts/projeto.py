#!/usr/bin/env python3
"""Projeto da máquina de estados assíncrona do 3.º trabalho (anti-ressalto de uma tecla).

Segue os passos da metodologia lecionada e confere cada um de forma automática:
  1. tabela de estados primitiva (a da folha "SD2 Lab3 - Tabela de Estados Primitiva");
  2-3. redução de estados: partições e tabela de implicações (fusão);
  4. tabela de estados reduzida;
  5. codificação dos estados livre de corridas críticas (com transições indiretas);
  6. tabela de transições;
  7-9. equações de excitação e de saída e verificação de acidentes estáticos;
  e ainda: corridas (todas as ordens possíveis de mudança das variáveis de estado),
  acidentes essenciais e picos nas saídas durante as transições.
Escreve o resumo em simulacao/projeto.txt e os dados para o relatório em simulacao/projeto.json.
Uso (na pasta lab3): python3 scripts/projeto.py
"""
import itertools, json, os, sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
COLS = ['00', '01', '11', '10']           # K To, em código de Gray
linhas_txt = []
def out(*a):
    s = ' '.join(str(x) for x in a); linhas_txt.append(s); print(s)

# ---------------------------------------------------------------------------------------
# 1. Tabela de estados primitiva: estado -> (estado seguinte em 00, 01, 11, 10), (Kd, F), descrição
#    None = indiferente; o estado estável é o próprio estado
PRIM = {
    'a': (['a', None, None, 'b'], (0, 0), 'Repouso'),
    'b': (['i', None, 'c', 'b'], (1, 0), 'Tecla premida, inicia temporização'),
    'c': ([None, 'd', 'c', 'e'], (1, 0), 'Temporização ao premir'),
    'd': (['f', 'd', 'c', None], (1, 0), 'Ressalto ao premir'),
    'e': (['f', None, None, 'e'], (1, 1), 'Tecla premida estável'),
    'f': (['f', 'g', None, 'j'], (0, 1), 'Tecla largada, inicia temporização'),
    'g': (['a', 'g', 'h', None], (0, 1), 'Temporização ao largar'),
    'h': ([None, 'g', 'h', 'b'], (0, 1), 'Ressalto ao largar'),
    'i': (['i', 'd', None, 'b'], (1, 0), 'Ressalto ao premir, antes da temporização'),
    'j': (['f', None, 'h', 'j'], (0, 1), 'Ressalto ao largar, antes da temporização'),
}
EST = list(PRIM)

out('== 1. Tabela primitiva')
for s in EST:
    ns, (kd, f), d = PRIM[s]
    cel = [('(' + n + ')' if n == s else n) if n else '-' for n in ns]
    out(f'  {s}: ' + ' '.join(f'{c:>4}' for c in cel) + f'   Kd F = {kd}{f}   {d}')
# cada estado é estável numa só coluna (tabela primitiva)
for s in EST:
    assert sum(n == s for n in PRIM[s][0]) == 1, s
# Indiferenças: (1) modo fundamental: exigiam mudar K e To ao mesmo tempo; (2) To não pode subir
# sozinho: em a (Ti = K = 0) e em e (Ti = K xor F = 0) não há flanco em Ti que dispare o temporizador
IMPOSSIVEIS = {('a', '01'), ('e', '11')}
for s in EST:
    col = PRIM[s][0].index(s)
    for j, n in enumerate(PRIM[s][0]):
        dist = sum(a != b for a, b in zip(COLS[col], COLS[j]))
        assert (n is None) == (dist == 2 or (s, COLS[j]) in IMPOSSIVEIS), (s, COLS[j])
out('  indiferenças: as que exigiam mudar K e To ao mesmo tempo e ainda a em 01 e e em 11'
    ' (To não sobe sem um flanco em Ti)')

# ---------------------------------------------------------------------------------------
# 2. Partições (estados equivalentes: mesmas saídas e estáveis na mesma coluna)
out('\n== 2. Partições')
def bloco_de(p, s):
    return next(i for i, b in enumerate(p) if s in b)
P = []
for s in EST:
    chave = (PRIM[s][1], PRIM[s][0].index(s))
    for b in P:
        if (PRIM[b[0]][1], PRIM[b[0]][0].index(b[0])) == chave: b.append(s); break
    else: P.append([s])
it = 1
particoes = [[list(b) for b in P]]
out(f'  P{it} =', ' '.join('(' + ''.join(b) + ')' for b in P))
while True:
    novo = []
    for b in P:
        sub = []
        for s in b:
            assin = tuple(None if n is None else bloco_de(P, n) for n in PRIM[s][0])
            for g in sub:
                a2 = tuple(None if n is None else bloco_de(P, n) for n in PRIM[g[0]][0])
                if all(x is None or y is None or x == y for x, y in zip(assin, a2)) and assin == a2:
                    g.append(s); break
            else: sub.append([s])
        novo += sub
    it += 1
    out(f'  P{it} =', ' '.join('(' + ''.join(b) + ')' for b in novo))
    particoes.append([list(b) for b in novo])
    if len(novo) == len(P): break
    P = novo
assert all(len(b) == 1 for b in P), 'há estados equivalentes por eliminar'
out('  nenhum par de estados equivalentes (todas as classes têm um só estado)')

# ---------------------------------------------------------------------------------------
# 3. Fusão: tabela de implicações (saídas iguais e estados seguintes compatíveis)
out('\n== 3. Tabela de implicações')
pares = list(itertools.combinations(EST, 2))
impl = {}
for x, y in pares:
    if PRIM[x][1] != PRIM[y][1]:
        impl[(x, y)] = 'X'; continue
    req = set(); ok = True
    for nx, ny in zip(PRIM[x][0], PRIM[y][0]):
        if nx is None or ny is None or nx == ny: continue
        par = tuple(sorted((nx, ny)))
        if par != (x, y): req.add(par)
    impl[(x, y)] = sorted(req)
mudou = True
while mudou:
    mudou = False
    for p, v in impl.items():
        if v != 'X' and any(impl[q] == 'X' for q in v):
            impl[p] = 'X'; mudou = True
compat = [p for p, v in impl.items() if v != 'X']
for p, v in impl.items():
    out(f'  {p[0]},{p[1]}:', 'incompatível' if v == 'X' else ('compatível ' + (str(v) if v else '(sem implicações)')))
out('  pares compatíveis:', ', '.join(f'({x},{y})' for x, y in compat))

# grupos escolhidos (diagrama de fusão): todos os pares compatíveis são disjuntos
GRUPOS = {'S0': ['a'], 'S1': ['b', 'i'], 'S2': ['c', 'd'], 'S3': ['e'], 'S4': ['f', 'j'], 'S5': ['g', 'h']}
for g in GRUPOS.values():
    for x, y in itertools.combinations(g, 2):
        assert tuple(sorted((x, y))) in compat
assert sorted(sum(GRUPOS.values(), [])) == sorted(EST)
assert len(compat) == sum(len(g) * (len(g) - 1) // 2 for g in GRUPOS.values()), 'há outras fusões possíveis'
grupo = {s: G for G, g in GRUPOS.items() for s in g}

# ---------------------------------------------------------------------------------------
# 4. Tabela reduzida
out('\n== 4. Tabela reduzida')
RED = {}
for G, g in GRUPOS.items():
    prox = []
    for j in range(4):
        vals = {grupo[PRIM[s][0][j]] for s in g if PRIM[s][0][j]}
        assert len(vals) <= 1
        prox.append(vals.pop() if vals else None)
    sai = PRIM[g[0]][1]
    assert all(PRIM[s][1] == sai for s in g)
    RED[G] = (prox, sai)
    out(f'  {G} ({",".join(g)}): ' + ' '.join(f'{(n if n != G else "(" + n + ")") if n else "-":>5}' for n in prox) + f'   Kd F = {sai[0]}{sai[1]}')

# Arranque: depois do Reset a máquina está em S0 (000) com o temporizador possivelmente a contar.
# As indiferenças de S0 em To = 1 passam a ser especificadas:
#   01 -> S0 (fica em S0, à espera que o temporizador acabe: transitório inicial)
#   11 -> S2 (tecla premida com o temporizador a contar = temporização ao premir), via S1
RED['S0'][0][1] = 'S0'
RED['S0'][0][2] = 'S2'
out('  arranque: S0 em 01 -> S0 (estável) e S0 em 11 -> S2')

# ---------------------------------------------------------------------------------------
# 5. Codificação: transições pedidas e diagrama de transições
out('\n== 5. Codificação')
trans = set()
for G, (prox, _) in RED.items():
    for n in prox:
        if n and n != G: trans.add(tuple(sorted((G, n))))
out('  transições:', ', '.join(f'{a}-{b}' for a, b in sorted(trans)))
COD = {'S0': '000', 'S1': '001', 'S2': '011', 'S3': '111', 'S4': '110', 'S5': '100'}   # y2 y1 y0
def ham(a, b): return sum(x != y for x, y in zip(a, b))
diag = [t for t in sorted(trans) if ham(COD[t[0]], COD[t[1]]) > 1]
out('  transições com mais de uma variável a mudar (corridas):', ', '.join(f'{a}-{b}' for a, b in diag))
# triângulos no grafo -> não há codificação direta com 3 variáveis
# transições indiretas: estado instável intermédio na mesma coluna
INDIRETA = {('S2', '00'): 'S3', ('S5', '10'): 'S0', ('S0', '11'): 'S1'}
for (G, c), via in INDIRETA.items():
    j = COLS.index(c); final = RED[G][0][j]
    assert RED[via][0][j] == final, (G, c, via)
    assert ham(COD[G], COD[via]) == 1 and ham(COD[via], COD[final]) == 1
    out(f'  {G} em {c}: {G} -> {via} -> {final} ({COD[G]} -> {COD[via]} -> {COD[final]})')

# ---------------------------------------------------------------------------------------
# 6. Tabela de transições
out('\n== 6. Tabela de transições (Y2 Y1 Y0)')
TT = {}   # (y, col) -> Y ou None
for c in ['000', '001', '011', '111', '110', '100', '010', '101']:
    TT[c] = [None] * 4
for G, (prox, _) in RED.items():
    for j, n in enumerate(prox):
        if n is None: continue
        alvo = INDIRETA.get((G, COLS[j]), n)
        TT[COD[G]][j] = COD[alvo]
for c, v in TT.items():
    out(f'  {c}: ' + ' '.join(f'{x or "---":>4}' for x in v))

# ---------------------------------------------------------------------------------------
# 8-9. Equações (somas de produtos) e verificação
# variáveis: K, To, y2, y1, y0 ; termos como dicionários {var: valor}
EQ = {
    'Y2': [{'To': 1, 'y2': 1}, {'To': 0, 'y1': 1}, {'y2': 1, 'y1': 1}],
    'Y1': [{'To': 1, 'y0': 1}, {'To': 0, 'y1': 1}, {'y1': 1, 'y0': 1}],
    'Y0': [{'K': 1, 'y2': 0}, {'K': 1, 'y0': 1}, {'y2': 0, 'y0': 1}],
}
def avalia(termos, v):
    return int(any(all(v[k] == b for k, b in t.items()) for t in termos))
def varset(y, col):
    return {'y2': int(y[0]), 'y1': int(y[1]), 'y0': int(y[2]), 'K': int(col[0]), 'To': int(col[1])}
out('\n== 8. Equações de excitação')
nomes = {'K': 'K', 'To': 'To', 'y2': 'YY2', 'y1': 'YY1', 'y0': 'YY0'}
def texto(termos):
    return ' + '.join('·'.join(('' if b else '/') + nomes[k] for k, b in t.items()) for t in termos)
for Y, termos in EQ.items():
    out(f'  {Y} = {texto(termos)}')
    i = int(Y[1]); bit = 2 - i
    for y, v in TT.items():
        for j, col in enumerate(COLS):
            if v[j] is None: continue
            assert avalia(termos, varset(y, col)) == int(v[j][bit]), (Y, y, col)
out('  as equações reproduzem todas as células especificadas da tabela de transições')
# acidentes estáticos (SOP: só acidentes de 1): duas combinações adjacentes a 1 têm de estar no mesmo termo
VARS = ['K', 'To', 'y2', 'y1', 'y0']
for Y, termos in EQ.items():
    for bits in itertools.product([0, 1], repeat=5):
        v = dict(zip(VARS, bits))
        if not avalia(termos, v): continue
        for k in VARS:
            w = dict(v); w[k] ^= 1
            if avalia(termos, w):
                assert any(all(v[a] == b for a, b in t.items()) and all(w[a] == b for a, b in t.items()) for t in termos), (Y, v, k)
out('  sem acidentes estáticos: cada par de combinações adjacentes a 1 está coberto por um mesmo termo')

def proximo(y, col):
    v = varset(y, col)
    return ''.join(str(avalia(EQ[f'Y{i}'], v)) for i in (2, 1, 0))
SAIDAS = {'Kd': lambda y: int(y[2]), 'F': lambda y: int(y[0])}
for G, (_, (kd, f)) in RED.items():
    assert SAIDAS['Kd'](COD[G]) == kd and SAIDAS['F'](COD[G]) == f
out('\n== 9. Equações de saída: Kd = yy0, F = yy2 (iguais às variáveis de estado)')

# valores que as equações dão às células indiferentes (estados 010 e 101 não usados e S3 com To = 1)
out('  células indiferentes preenchidas pelas equações:')
indif = []
for y, v in TT.items():
    for j, col in enumerate(COLS):
        if v[j] is None:
            indif.append((y, col, proximo(y, col)))
            out(f'    {y} em {col} -> {proximo(y, col)}')

# ---------------------------------------------------------------------------------------
# Corridas: a partir de cada estado estável, mudar uma entrada e explorar todas as ordens possíveis
# de mudança das variáveis de estado excitadas (atrasos arbitrários nas realimentações)
out('\n== Corridas (todas as ordens de mudança das variáveis de estado)')
NOME = {v: k for k, v in COD.items()}
def destinos(y, col, visto=None):
    visto = visto or set()
    if (y, col) in visto: return {'OSCILA'}
    visto = visto | {(y, col)}
    Y = proximo(y, col)
    if Y == y: return {y}
    res = set()
    for i in range(3):
        if Y[i] != y[i]:
            res |= destinos(y[:i] + Y[i] + y[i + 1:], col, visto)
    return res
estaveis = [(y, col) for y in COD.values() for col in COLS if proximo(y, col) == y]
caminhos = []
for y, col in estaveis:
    for k in range(2):
        nc = col[:k] + str(1 - int(col[k])) + col[k + 1:]
        d = destinos(y, nc)
        assert len(d) == 1 and 'OSCILA' not in d, (y, col, nc, d)
        # percurso e saídas ao longo dele (só muda uma variável de cada vez: sem corridas)
        p = [y]
        while proximo(p[-1], nc) != p[-1]:
            Y = proximo(p[-1], nc); assert ham(Y, p[-1]) == 1, (y, nc, Y)
            p.append(Y)
        kd = [SAIDAS['Kd'](q) for q in p]; f = [SAIDAS['F'](q) for q in p]
        monot = lambda s: all(a <= b for a, b in zip(s, s[1:])) or all(a >= b for a, b in zip(s, s[1:]))
        assert monot(kd) and monot(f), ('pico nas saídas', p)
        caminhos.append({'de': NOME[y], 'col': col, 'nova': nc, 'percurso': [NOME[q] for q in p]})
out(f'  {len(estaveis)} estados totais estáveis, {len(caminhos)} transições: todas chegam a um único estado,')
out('  mudando uma variável de estado de cada vez, e Kd e F nunca têm picos (mudam no máximo uma vez)')
# Arranque: Reset força 000; ao libertar, as entradas podem ter qualquer valor
for col in COLS:
    d = destinos('000', col)
    assert len(d) == 1
    out(f'  libertação do Reset com K To = {col}: 000 -> {NOME[d.pop()]}')

# ---------------------------------------------------------------------------------------
# Acidentes essenciais: a entrada que mudou chega mais tarde a uma das equações que dela dependem
# (equação "atrasada"). Enquanto isso, as outras equações já vêem a entrada nova e a máquina pode
# avançar vários passos; quando a entrada chega por fim à equação atrasada, a máquina tem de acabar
# no estado certo. Exploram-se todas as ordens de mudança das variáveis de estado.
out('\n== Acidentes essenciais (uma equação vê a entrada nova mais tarde do que as outras)')
def proximo_misto(y, col_velha, col_nova, atrasadas):
    """estado seguinte com as equações em 'atrasadas' ainda a ver col_velha"""
    s = ''
    for i in (2, 1, 0):
        eq = f'Y{i}'
        s += str(avalia(EQ[eq], varset(y, col_velha if eq in atrasadas else col_nova)))
    return s
def alcancaveis(y, f):
    """todos os estados alcançáveis a partir de y com a função de estado seguinte f"""
    visto, pilha = {y}, [y]
    while pilha:
        a = pilha.pop(); Y = f(a)
        for i in range(3):
            if Y[i] != a[i]:
                b = a[:i] + Y[i] + a[i + 1:]
                if b not in visto: visto.add(b); pilha.append(b)
    return visto
essenciais = []
for y, col in estaveis:
    for k, nomev in enumerate(['K', 'To']):
        nc = col[:k] + str(1 - int(col[k])) + col[k + 1:]
        if proximo(y, nc) == y: continue
        certo = destinos(y, nc)
        dep = [e for e in ('Y2', 'Y1', 'Y0') if any(nomev in t for t in EQ[e])]
        for atr in dep:
            if len(dep) < 2: continue                       # a entrada só chega a uma equação: sem acidente
            meio = alcancaveis(y, lambda a: proximo_misto(a, col, nc, {atr}))
            for m in sorted(meio):
                fim = destinos(m, nc)
                if fim != certo:
                    # percurso mais curto até m (para o relatório)
                    essenciais.append({'de': NOME[y], 'col': col, 'nova': nc, 'entrada': nomev, 'atrasada': atr,
                                       'via': m, 'fica': sorted(NOME.get(z, z) for z in fim), 'certo': sorted(NOME[z] for z in certo)})
                    out(f'  {NOME[y]} ({y}) {col}->{nc}: com {atr} ainda a ver {nomev} antigo a máquina pode chegar a {m}'
                        f' e acabar em {sorted(NOME.get(z, z) for z in fim)} em vez de {sorted(NOME[z] for z in certo)}')
                    break

# ---------------------------------------------------------------------------------------
dados = {
    'prim': {s: {'prox': PRIM[s][0], 'kd': PRIM[s][1][0], 'f': PRIM[s][1][1], 'desc': PRIM[s][2]} for s in EST},
    'particoes': particoes,
    'implicacoes': {f'{x},{y}': v for (x, y), v in impl.items()},
    'compativeis': compat,
    'grupos': GRUPOS,
    'reduzida': {G: {'prox': p, 'kd': s[0], 'f': s[1]} for G, (p, s) in RED.items()},
    'codigo': COD,
    'indiretas': {f'{G},{c}': v for (G, c), v in INDIRETA.items()},
    'transicoes': TT,
    'equacoes': {Y: texto(t) for Y, t in EQ.items()},
    'indiferentes': indif,
    'caminhos': caminhos,
    'essenciais': essenciais,
}
os.makedirs(os.path.join(RAIZ, 'simulacao'), exist_ok=True)
json.dump(dados, open(os.path.join(RAIZ, 'simulacao', 'projeto.json'), 'w'), ensure_ascii=False, indent=1)
open(os.path.join(RAIZ, 'simulacao', 'projeto.txt'), 'w').write('\n'.join(linhas_txt) + '\n')
out('\nProjeto OK')
