#!/usr/bin/env python3
"""Gera as vistas das formas de onda (.wcfg) usadas nas simulacoes do Vivado.

Cada testbench fica com um ficheiro <testbench>.wcfg ao lado, com os sinais mais
importantes, a base numerica de cada um e o intervalo de tempo a mostrar (cores do Vivado).
O scripts/abre_wcfg.tcl abre a do testbench que esta como top ao correr a simulacao no
Vivado (Run Behavioral Simulation).
Uso (na pasta lab2): python3 scripts/gera_wcfg.py
"""
import os

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CORES = {'ent': '#FFFF00', 'sai': '#00FF00', 'clk': '#FF8000', 'ctl': '#00FFFF', 'int': '#FF66FF'}
RADIX = {'b': 'BINARYRADIX', 'h': 'HEXRADIX', 'u': 'UNSIGNEDDECRADIX'}

# testbench -> (pasta, inicio_ns, fim_ns, [sinais])
# sinal: ('caminho relativo ao testbench', radix, cor, expandir)
VISTAS = {
    'sincronizador_teste1': ('sincronizador', 0, 560, [
        ('Clock', 'b', 'clk', False), ('Entrada', 'b', 'ent', False), ('UUT/meta', 'b', 'int', False),
        ('UUT/sinc', 'b', 'int', False), ('UUT/contagem', 'u', 'int', False), ('Saida', 'b', 'sai', False)]),
    'sincronizadorreset_teste1': ('sincronizador', 0, 200, [
        ('Clock', 'b', 'clk', False), ('Entrada', 'b', 'ent', False), ('UUT/q1', 'b', 'int', False),
        ('Saida', 'b', 'sai', False)]),
    'lfsr32_teste1': ('lfsr32', 0, 110, [
        ('Clock', 'b', 'clk', False), ('Enable', 'b', 'ent', False), ('Init', 'b', 'ent', False),
        ('UUT/regLFSR', 'h', 'int', False), ('UUT/regXNOR', 'b', 'int', False), ('OutLFSR', 'b', 'sai', False)]),
    'memoria4x2_teste1': ('memoria4x2', 100, 220, [
        ('Clk', 'b', 'clk', False), ('Data', 'b', 'ent', False), ('Shift', 'b', 'ent', False), ('CLR', 'b', 'ent', False),
        ('Pos0', 'b', 'sai', False), ('Pos1', 'b', 'sai', False), ('Pos2', 'b', 'sai', False), ('Pos3', 'b', 'sai', False)]),
    'temporizador_teste1': ('temporizador', 0, 240, [
        ('Clock', 'b', 'clk', False), ('Reset', 'b', 'ent', False), ('Start', 'b', 'ent', False),
        ('Periodo', 'u', 'ent', False), ('UUT/contagem', 'u', 'int', False), ('Tempo', 'b', 'sai', False)]),
    'temporizadorvariavel_teste1': ('temporizador', 0, 190, [
        ('Clock', 'b', 'clk', False), ('RstTemp', 'b', 'ent', False), ('StartTemp', 'b', 'ent', False),
        ('Faster', 'b', 'ent', False), ('UUT/Periodo', 'u', 'int', False),
        ('UUT/temporizador/contagem', 'u', 'int', False), ('Tempo', 'b', 'sai', False)]),
    'beat_teste1': ('beat', 100, 200, [
        ('Clk', 'b', 'clk', False), ('Tgl', 'b', 'ent', False), ('CLR', 'b', 'ent', False), ('Q', 'b', 'sai', False)]),
    'gestaodisplays_teste1': ('gestaodisplays', 100, 475, [
        ('Clock', 'b', 'clk', False), ('Pos0', 'b', 'ent', False), ('Pos1', 'b', 'ent', False),
        ('Pos2', 'b', 'ent', False), ('Pos3', 'b', 'ent', False), ('UUT/ClockVarrimento', 'b', 'int', False),
        ('UUT/mux16x4/Sel', 'u', 'ctl', False), ('Anodos', 'b', 'sai', False), ('UUT/ValorAtivo', 'u', 'int', False),
        ('Segmentos', 'b', 'sai', False), ('DotPoint', 'b', 'sai', False)]),
    'controlador_teste1': ('controlador', 0, 230, [
        ('Clock', 'b', 'clk', False), ('Reset', 'b', 'ent', False), ('Start', 'b', 'ent', False), ('Tempo', 'b', 'ent', False),
        ('UUT/S0', 'b', 'int', False), ('UUT/S1', 'b', 'int', False), ('UUT/S2', 'b', 'int', False),
        ('UUT/S3', 'b', 'int', False), ('UUT/S4', 'b', 'int', False), ('UUT/S5', 'b', 'int', False),
        ('ClrMem', 'b', 'sai', False), ('InitLFSR', 'b', 'sai', False), ('RstTemp', 'b', 'sai', False),
        ('EnLFSR', 'b', 'sai', False), ('Ready', 'b', 'sai', False), ('ShiftMem', 'b', 'sai', False),
        ('StartTemp', 'b', 'sai', False), ('TglBeat', 'b', 'sai', False), ('Waiting', 'b', 'sai', False),
        ('Faster', 'b', 'sai', False)]),
    'guitarhero_teste1': ('guitarhero', 0, 2830, [
        ('BtnReset', 'b', 'ent', False), ('BtnStart', 'b', 'ent', False), ('UUT/Reset', 'b', 'int', False),
        ('UUT/Start', 'b', 'int', False), ('LedEstado', 'b', 'sai', False), ('LedReady', 'b', 'sai', False),
        ('LedWaiting', 'b', 'sai', False), ('LedBeat', 'b', 'sai', False), ('UUT/Tempo', 'b', 'int', False),
        ('UUT/temporizador/Periodo', 'u', 'int', False), ('UUT/OutLFSR', 'b', 'int', False),
        ('UUT/Pos0', 'b', 'int', False), ('UUT/Pos1', 'b', 'int', False), ('UUT/Pos2', 'b', 'int', False),
        ('UUT/Pos3', 'b', 'int', False)]),
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
    'sincronizador_teste1': {'UUT/contagem': 32},
    'sincronizadorreset_teste1': {},
    'lfsr32_teste1': {'UUT/regLFSR': 32, 'OutLFSR': 2},
    'memoria4x2_teste1': {'Data': 2, 'Pos0': 2, 'Pos1': 2, 'Pos2': 2, 'Pos3': 2},
    'temporizador_teste1': {'Periodo': 8, 'UUT/contagem': 8},
    'temporizadorvariavel_teste1': {'UUT/Periodo': 8, 'UUT/temporizador/contagem': 8},
    'beat_teste1': {},
    'gestaodisplays_teste1': {'Pos0': 2, 'Pos1': 2, 'Pos2': 2, 'Pos3': 2, 'UUT/mux16x4/Sel': 2, 'Anodos': 4,
                              'UUT/ValorAtivo': 4, 'Segmentos': 7},
    'controlador_teste1': {},
    'guitarhero_teste1': {'LedEstado': 6, 'UUT/temporizador/Periodo': 28, 'UUT/OutLFSR': 2,
                          'UUT/Pos0': 2, 'UUT/Pos1': 2, 'UUT/Pos2': 2, 'UUT/Pos3': 2},
}

if __name__ == '__main__':
    for tb in VISTAS:
        print(gera(tb, LARGURAS[tb]))
