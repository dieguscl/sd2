#!/usr/bin/env python3
"""Gera as vistas das formas de onda (.wcfg) usadas nas simulacoes do Vivado.

Cada testbench fica com um ficheiro <testbench>.wcfg ao lado, com os sinais mais
importantes, a base numerica de cada um e o intervalo de tempo a mostrar (cores do Vivado).
O scripts/abre_wcfg.tcl abre a do testbench que esta como top ao correr a simulacao no
Vivado (Run Behavioral Simulation).
Uso (na pasta lab3): python3 scripts/gera_wcfg.py
"""
import os

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CORES = {'ent': '#FFFF00', 'sai': '#00FF00', 'clk': '#FF8000', 'ctl': '#00FFFF', 'int': '#FF66FF'}
RADIX = {'b': 'BINARYRADIX', 'h': 'HEXRADIX', 'u': 'UNSIGNEDDECRADIX'}

# testbench -> (pasta, inicio_ns, fim_ns, [sinais])
# sinal: ('caminho relativo ao testbench', radix, cor, expandir)
VISTAS = {
    'maquinatecla_teste1': ('maquinatecla', 0, 480, [
        ('Clear', 'b', 'ent', False), ('K', 'b', 'ent', False), ('To', 'b', 'ent', False),
        ('UUT/Y2', 'b', 'int', False), ('UUT/Y1', 'b', 'int', False), ('UUT/Y0', 'b', 'int', False),
        ('Estado', 'b', 'int', False), ('Kd', 'b', 'sai', False), ('F', 'b', 'sai', False)]),
    'monoestavel_teste1': ('monoestavel', 0, 290, [
        ('Clock', 'b', 'clk', False), ('Ti', 'b', 'ent', False), ('UUT/meta', 'b', 'int', False),
        ('UUT/sinc', 'b', 'int', False), ('UUT/anterior', 'b', 'int', False), ('UUT/flanco', 'b', 'int', False),
        ('UUT/contagem', 'u', 'int', False), ('To', 'b', 'sai', False)]),
    'tecla_teste1': ('tecla', 0, 5300, [
        ('Clear', 'b', 'ent', False), ('K', 'b', 'ent', False), ('Ti', 'b', 'int', False),
        ('To', 'b', 'int', False), ('Estado', 'b', 'int', False), ('F', 'b', 'sai', False),
        ('Kd', 'b', 'sai', False)]),
    'validacao_teste1': ('validacao', 0, 80, [
        ('K1', 'b', 'ent', False), ('K2', 'b', 'ent', False), ('K3', 'b', 'ent', False),
        ('U', 'b', 'sai', False), ('M', 'b', 'sai', False)]),
    'gestaoteclas_teste1': ('gestaoteclas', 0, 3200, [
        ('BtnReset', 'b', 'ent', False), ('BtnK1', 'b', 'ent', False), ('BtnK2', 'b', 'ent', False),
        ('BtnK3', 'b', 'ent', False), ('UUT/Estado1', 'b', 'int', False), ('UUT/Estado2', 'b', 'int', False),
        ('UUT/Estado3', 'b', 'int', False), ('LedKd', 'b', 'sai', False), ('LedU', 'b', 'sai', False),
        ('LedM', 'b', 'sai', False), ('UUT/ImpulsosK', 'u', 'int', False), ('UUT/ImpulsosKd', 'u', 'int', False)]),
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
    'maquinatecla_teste1': {'Estado': 3},
    'monoestavel_teste1': {'UUT/contagem': 3},
    'tecla_teste1': {'Estado': 3},
    'validacao_teste1': {},
    'gestaoteclas_teste1': {'UUT/Estado1': 3, 'UUT/Estado2': 3, 'UUT/Estado3': 3, 'LedKd': 3,
                            'UUT/ImpulsosK': 8, 'UUT/ImpulsosKd': 8},
}

if __name__ == '__main__':
    for tb in VISTAS:
        print(gera(tb, LARGURAS[tb]))
