#!/usr/bin/env python3
"""Gera as vistas das formas de onda (.wcfg) usadas nas simulacoes do Vivado.

Cada testbench fica com um ficheiro <testbench>.wcfg ao lado, com os sinais mais
importantes, a base numerica de cada um e o intervalo de tempo a mostrar (cores do Vivado).
O scripts/build.tcl acrescenta-os ao projeto: ao correr a simulacao no Vivado
(Run Behavioral Simulation) a janela das formas de onda abre ja assim.
Uso (na raiz do repositorio): python3 scripts/gera_wcfg.py
"""
import os

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CORES = {'ent': '#FFFF00', 'sai': '#00FF00', 'clk': '#FF8000', 'ctl': '#00FFFF', 'int': '#FF66FF'}
RADIX = {'b': 'BINARYRADIX', 'h': 'HEXRADIX', 'u': 'UNSIGNEDDECRADIX'}

# testbench -> (pasta, inicio_ns, fim_ns, [sinais])
# sinal: ('caminho relativo ao testbench', radix, cor, expandir) ou ('--', 'texto do separador')
VISTAS = {
    'multiplexer4x1_teste1': ('multiplexer4x1', 0, 1100, [
        ('--', 'Entradas'), ('S', 'b', 'ent', True), ('D', 'b', 'ent', True),
        ('--', 'Saida'), ('Z', 'b', 'sai', False)]),
    'descodificador2x4_teste1': ('descodificador2x4', 0, 1100, [
        ('--', 'Entradas'), ('B', 'b', 'ent', True), ('E', 'b', 'ent', True),
        ('--', 'Saidas'), ('O', 'b', 'sai', True)]),
    'multiplexer16x4_teste1': ('multiplexer16x4', 0, 1000, [
        ('--', 'Entradas'), ('S', 'u', 'ent', False), ('D0', 'h', 'ent', False), ('D1', 'h', 'ent', False),
        ('D2', 'h', 'ent', False), ('D3', 'h', 'ent', False),
        ('--', 'Saida'), ('Z', 'h', 'sai', True)]),
    'transcod7seg_teste1': ('transcod7seg', 0, 1700, [
        ('--', 'Entrada'), ('N', 'u', 'ent', False),
        ('--', 'Saida a..g (ativa a Low)'), ('S', 'b', 'sai', True)]),
    'registo4_teste1': ('registo4', 0, 460, [
        ('--', 'Entradas'), ('Clk', 'b', 'clk', False), ('D', 'h', 'ent', False), ('CE', 'b', 'ent', False),
        ('CLR', 'b', 'ent', False),
        ('--', 'Saida'), ('Q', 'h', 'sai', True),
        ('--', 'Modelo de referencia'), ('referencia', 'h', 'int', False)]),
    'divisorclock_teste1': ('divisorclock', 0, 400, [
        ('--', 'ClockIn (100 MHz)'), ('Clk', 'b', 'clk', False),
        ('--', 'ClockOut (METADE = 1, 2, 5, 7)'), ('Out1', 'b', 'sai', False), ('Out2', 'b', 'sai', False),
        ('Out5', 'b', 'sai', False), ('Out7', 'b', 'sai', False),
        ('--', 'Contagem (METADE = 7)'), ('UUT7/contagem', 'u', 'int', False)]),
    'contador4_teste1': ('contador4', 0, 300, [
        ('--', 'Relogio'), ('Clk', 'b', 'clk', False),
        ('--', 'Saidas'), ('Q1', 'b', 'sai', False), ('Q0', 'b', 'sai', False),
        ('--', 'Estado interno'), ('UUT/estado', 'u', 'int', False)]),
    'controlodisplays_teste1': ('controlodisplays', 0, 4700, [
        ('--', 'Entradas'), ('D3', 'h', 'ent', False), ('D2', 'h', 'ent', False), ('D1', 'h', 'ent', False),
        ('D0', 'h', 'ent', False), ('Load', 'b', 'ent', False), ('DP', 'b', 'ent', False), ('LoadDP', 'b', 'ent', False),
        ('En', 'b', 'ent', False), ('Clr', 'b', 'ent', False), ('ClrDP', 'b', 'ent', False),
        ('--', 'Varrimento'), ('UUT/ClockVarrimento', 'b', 'clk', False), ('Sel', 'u', 'ctl', False),
        ('UUT/ValorAtivo', 'h', 'int', False),
        ('--', 'Saidas'), ('Anodos', 'b', 'sai', False), ('Segmentos', 'b', 'sai', False), ('DotPoint', 'b', 'sai', False)]),
    'testedisplays_teste1': ('controlodisplays', 0, 3700, [
        ('--', 'Interruptores e teclas'), ('Data', 'h', 'ent', False), ('LD3', 'b', 'ent', False),
        ('LD2', 'b', 'ent', False), ('LD1', 'b', 'ent', False), ('LD0', 'b', 'ent', False),
        ('LDDP', 'b', 'ent', False), ('EN', 'b', 'ent', False), ('Clear', 'b', 'ent', False),
        ('--', 'Pinos dos displays'), ('An', 'b', 'sai', False), ('Seg', 'b', 'sai', False), ('DP', 'b', 'sai', False)]),
}


def tempo(ns):
    return f'{ns * 1000:,} ps'


def objeto(tb, caminho, radix, cor, expandir, largura, ind):
    fp = f'/{tb}/{caminho}'
    nome = caminho.split('/')[-1]
    tipo = 'array' if largura > 1 else 'logic'
    curto = f'{nome}[{largura - 1}:0]' if largura > 1 else nome
    s = [f'{ind}<wvobject type="{tipo}" fp_name="{fp}">',
         f'{ind}   <obj_property name="ElementShortName">{curto}</obj_property>',
         f'{ind}   <obj_property name="ObjectShortName">{curto}</obj_property>']
    if largura > 1:
        s.append(f'{ind}   <obj_property name="Radix">{RADIX[radix]}</obj_property>')
    if expandir and largura > 1:
        s.append(f'{ind}   <obj_property name="isExpanded"></obj_property>')
        for b in range(largura - 1, -1, -1):
            s += [f'{ind}   <wvobject type="logic" fp_name="{fp}[{b}]">',
                  f'{ind}      <obj_property name="ElementShortName">[{b}]</obj_property>',
                  f'{ind}      <obj_property name="ObjectShortName">{nome}[{b}]</obj_property>',
                  f'{ind}   </wvobject>']
    s.append(f'{ind}</wvobject>')
    return s


def gera(tb, larguras, saida=None):
    pasta, ini, fim, sinais = VISTAS[tb]
    objs, n, div = [], 0, 0
    for s in sinais:
        if s[0] == '--':
            continue                      # sem separadores: aspeto por omissao do Vivado
            div += 1
            objs += [f'   <wvobject type="divider" fp_name="divider{div}">',
                     f'      <obj_property name="label">{s[1]}</obj_property>',
                     '      <obj_property name="DisplayName">label</obj_property>',
                     '   </wvobject>']
        else:
            objs += objeto(tb, s[0], s[1], s[2], s[3], larguras.get(s[0], 1), '   ')
        n += 1
    xml = f'''<?xml version="1.0" encoding="UTF-8"?>
<wave_config>
   <wave_state>
   </wave_state>
   <db_ref_list>
      <db_ref path="{tb}_behav.wdb" id="1">
         <top_modules>
            <top_module name="glbl" />
            <top_module name="{tb}" />
         </top_modules>
      </db_ref>
   </db_ref_list>
   <zoom_setting>
      <ZoomStartTime time="{tempo(ini)}"></ZoomStartTime>
      <ZoomEndTime time="{tempo(fim)}"></ZoomEndTime>
      <Cursor1Time time="{tempo(fim)}"></Cursor1Time>
   </zoom_setting>
   <column_width_setting>
      <NameColumnWidth column_width="220"></NameColumnWidth>
      <ValueColumnWidth column_width="90"></ValueColumnWidth>
   </column_width_setting>
   <WVObjectSize size="{n}" />
''' + '\n'.join(objs) + '\n</wave_config>\n'
    saida = saida or os.path.join(RAIZ, pasta, tb + '.wcfg')
    open(saida, 'w').write(xml)
    return saida


# Larguras dos barramentos (em bits) de cada sinal
LARGURAS = {
    'multiplexer4x1_teste1': {'S': 2, 'D': 4},
    'descodificador2x4_teste1': {'B': 2, 'E': 4, 'O': 4},
    'multiplexer16x4_teste1': {'S': 2, 'D0': 4, 'D1': 4, 'D2': 4, 'D3': 4, 'Z': 4},
    'transcod7seg_teste1': {'N': 4, 'S': 7},
    'registo4_teste1': {'D': 4, 'Q': 4, 'referencia': 4},
    'divisorclock_teste1': {'UUT7/contagem': 32},
    'contador4_teste1': {'UUT/estado': 2},
    'controlodisplays_teste1': {'D3': 4, 'D2': 4, 'D1': 4, 'D0': 4, 'Load': 4, 'DP': 4, 'En': 4, 'Clr': 4,
                                'Sel': 2, 'UUT/ValorAtivo': 4, 'Anodos': 4, 'Segmentos': 7},
    'testedisplays_teste1': {'Data': 4, 'An': 4, 'Seg': 7},
}

if __name__ == '__main__':
    for tb in VISTAS:
        print(gera(tb, LARGURAS[tb]))
