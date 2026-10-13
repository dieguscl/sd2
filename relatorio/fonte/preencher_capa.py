#!/usr/bin/env python3
"""Preenche a capa oficial de SD2 (SD2 CapaRelat.odt) com os dados do trabalho.

Uso: python3 preencher_capa.py <capa_original.odt> <capa_preenchida.odt> [num_paginas]
Os campos estao todos em DADOS, para ser facil corrigir.
"""
import re, sys, zipfile, shutil
from xml.sax.saxutils import escape

DADOS = {
    'ano': '2026/27',
    'laboratorio': '1',
    'data': '09/10/2026',
    'docente': 'José Sousa',
    'curso': 'LEEC',
    'turma': '02',
    'alunos': [('202300553', 'Rodrigo Silva Costa'), ('2025184378', 'Diego Alejandro Castro Laya')],
    'titulo': ['1.º Trabalho de Laboratório', 'Gestão do display da placa Basys3', '(Tutorial Digital e Vivado)'],
}

# nome da forma na capa -> campo
CAMPOS = {
    'Shape9': 'laboratorio', 'Shape8': 'data', 'Shape14': 'docente', 'Shape7': 'curso', 'Shape6': 'turma',
    'Shape12': ('alunos', 0, 0), 'Shape11': ('alunos', 0, 1),
    'Shape3': ('alunos', 1, 0), 'Shape2': ('alunos', 1, 1),
}

origem, destino = sys.argv[1], sys.argv[2]
paginas = sys.argv[3] if len(sys.argv) > 3 else ''
shutil.copy(origem, destino)
with zipfile.ZipFile(origem) as z:
    conteudo = z.read('content.xml').decode('utf-8')
    outros = {n: z.read(n) for n in z.namelist() if n != 'content.xml'}

# Estilos novos: texto dos campos (Arial 11, a esquerda) e do titulo na caixa grande
estilos = '''<style:style style:name="grCampo" style:family="graphic" style:parent-style-name="gr1"><style:graphic-properties draw:fill="solid" draw:fill-color="#ffffff" draw:textarea-horizontal-align="justify" draw:textarea-vertical-align="middle" fo:padding-left="0.15cm" fo:padding-right="0.1cm" fo:padding-top="0cm" fo:padding-bottom="0cm" style:run-through="foreground" style:wrap="run-through" style:vertical-pos="from-top" style:vertical-rel="page" style:horizontal-pos="from-left" style:horizontal-rel="page" loext:allow-overlap="true" style:flow-with-text="false"/></style:style>
<style:style style:name="grCaixa" style:family="graphic"><style:graphic-properties draw:fill="none" draw:textarea-horizontal-align="justify" draw:textarea-vertical-align="middle" draw:fit-to-size="false" style:shrink-to-fit="false" fo:padding-left="1cm" fo:padding-right="1cm" style:run-through="foreground" style:wrap="run-through" style:vertical-pos="from-top" style:vertical-rel="page" style:horizontal-pos="from-left" style:horizontal-rel="page" loext:allow-overlap="true" style:flow-with-text="false"/></style:style>
<style:style style:name="PCampo" style:family="paragraph"><style:paragraph-properties fo:text-align="start"/><style:text-properties style:font-name="Arial" fo:font-size="11pt" fo:language="pt" fo:country="PT" style:font-size-asian="11pt" style:font-size-complex="11pt"/></style:style>
<style:style style:name="PPaginas" style:family="paragraph"><style:paragraph-properties fo:text-align="center"/><style:text-properties style:font-name="Arial" fo:font-size="12pt" fo:language="pt" fo:country="PT"/></style:style>
<style:style style:name="PTit1" style:family="paragraph"><style:paragraph-properties fo:text-align="center" fo:margin-bottom="0.5cm"/><style:text-properties style:font-name="Arial" fo:font-size="16pt" fo:font-weight="bold" fo:language="pt" fo:country="PT" style:font-weight-asian="bold" style:font-weight-complex="bold"/></style:style>
<style:style style:name="PTit2" style:family="paragraph"><style:paragraph-properties fo:text-align="center" fo:margin-bottom="0.3cm"/><style:text-properties style:font-name="Arial" fo:font-size="22pt" fo:font-weight="bold" fo:color="#c9211e" fo:language="pt" fo:country="PT" style:font-weight-asian="bold" style:font-weight-complex="bold"/></style:style>
<style:style style:name="PTit3" style:family="paragraph"><style:paragraph-properties fo:text-align="center"/><style:text-properties style:font-name="Arial" fo:font-size="14pt" fo:language="pt" fo:country="PT"/></style:style>
'''
conteudo = conteudo.replace('</office:automatic-styles>', estilos + '</office:automatic-styles>')

# "Pag 1 de" usa a letra Tahoma2, que nao existe na maioria dos computadores e faz o texto
# partir em duas linhas: passa a Arial 12
conteudo = conteudo.replace('<style:style style:name="T11" style:family="text"><style:text-properties style:font-name="Tahoma2" fo:font-size="14pt" style:font-size-asian="14pt" style:font-size-complex="14pt"/>',
                            '<style:style style:name="T11" style:family="text"><style:text-properties style:font-name="Arial" fo:font-size="12pt" style:font-size-asian="12pt" style:font-size-complex="12pt"/>')

# Ano letivo (o original tem 2025/26 partido em varios spans)
ano_antigo = ('<text:span text:style-name="T7">20</text:span><text:span text:style-name="T8">2</text:span>'
              '<text:span text:style-name="T9">5</text:span><text:span text:style-name="T7">/</text:span>'
              '<text:span text:style-name="T10">2</text:span><text:span text:style-name="T9">6</text:span>')
assert ano_antigo in conteudo, 'ano letivo nao encontrado na capa'
conteudo = conteudo.replace(ano_antigo, f'<text:span text:style-name="T7">{DADOS["ano"]}</text:span>')

def valor(campo):
    if isinstance(campo, tuple):
        nome, i, j = campo
        return DADOS[nome][i][j]
    return DADOS[campo]

def preenche_forma(xml, nome, novo_estilo, paragrafos):
    marca = f'draw:name="{nome}"'
    i = xml.index(marca)
    ini = xml.rindex('<draw:', 0, i)
    tag = xml[ini + 1:xml.index(' ', ini)]          # draw:rect ou draw:frame
    fim = xml.index(f'</{tag}>', i) + len(tag) + 3
    bloco = xml[ini:fim]
    if novo_estilo:
        bloco = re.sub(r'draw:style-name="[^"]*"', f'draw:style-name="{novo_estilo}"', bloco, count=1)
    if tag == 'draw:rect':
        bloco = bloco[:bloco.index('<text:p')] + paragrafos + f'</{tag}>'
    else:                                           # caixa de texto: substitui o paragrafo vazio
        bloco = bloco.replace('<text:p/>', paragrafos, 1)
    return xml[:ini] + bloco + xml[fim:]

for forma, campo in CAMPOS.items():
    conteudo = preenche_forma(conteudo, forma, 'grCampo',
                              f'<text:p text:style-name="PCampo">{escape(valor(campo))}</text:p>')

t = DADOS['titulo']
conteudo = preenche_forma(conteudo, 'Shape10', 'grCaixa',
                          f'<text:p text:style-name="PTit1">{escape(t[0])}</text:p>'
                          f'<text:p text:style-name="PTit2">{escape(t[1])}</text:p>'
                          f'<text:p text:style-name="PTit3">{escape(t[2])}</text:p>')
if paginas:
    conteudo = preenche_forma(conteudo, 'Shape4', None,
                              f'<text:p text:style-name="PPaginas">{escape(paginas)}</text:p>')

with zipfile.ZipFile(destino, 'w') as z:
    z.writestr(zipfile.ZipInfo('mimetype'), outros.pop('mimetype'), compress_type=zipfile.ZIP_STORED)
    z.writestr('content.xml', conteudo, compress_type=zipfile.ZIP_DEFLATED)
    for n, d in outros.items():
        z.writestr(n, d, compress_type=zipfile.ZIP_DEFLATED)
print(destino)
