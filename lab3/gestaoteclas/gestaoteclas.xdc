## Restrições do circuito GestaoTeclas na placa Basys3 (xc7a35ticpg236-1L)
## Teclas do jogo: K1 = BTNL, K2 = BTNC, K3 = BTNR; Reset das máquinas de estados = BTNU
## LD0 a LD2 = Kd1 a Kd3; LD4 a LD12 = variáveis de estado (YY0 YY1 YY2 de cada máquina);
## LD14 = M; LD15 = U; displays: flancos das teclas com ressaltos (à esquerda) e sem ressaltos

## Relógio de 100 MHz
set_property PACKAGE_PIN W5 [get_ports CLKBasys]
    set_property IOSTANDARD LVCMOS33 [get_ports CLKBasys]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports CLKBasys]

## Relógio do varrimento dos displays (100 MHz / 50000 = 2 kHz), gerado pelo DivisorClock
create_generated_clock -name clk_varrimento -source [get_ports CLKBasys] -divide_by 50000 \
    [get_pins displays/divisor/ClockOut_reg/Q]
set_false_path -from [get_clocks clk_varrimento] -to [get_clocks sys_clk_pin]

## Máquinas de estados assíncronas: as realimentações (YY2, YY1, YY0) são laços combinatórios
## intencionais. Sem esta propriedade o Vivado recusa gerar o bitstream (DRC LUTLP-1).
set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_nets -hierarchical -filter {NAME =~ *maquina/YY*}]

## Teclas assíncronas: atuam nas máquinas de estados (sem relógio) e nos sincronizadores
set_false_path -from [get_ports {BtnReset BtnK1 BtnK2 BtnK3}]
## LEDs e displays: sem requisitos de tempo
set_false_path -to [get_ports {LedKd[*] LedEstado[*] LedU LedM Seg[*] DP An[*]}]

## Teclas
set_property PACKAGE_PIN T18 [get_ports BtnReset]
    set_property IOSTANDARD LVCMOS33 [get_ports BtnReset]
set_property PACKAGE_PIN W19 [get_ports BtnK1]
    set_property IOSTANDARD LVCMOS33 [get_ports BtnK1]
set_property PACKAGE_PIN U18 [get_ports BtnK2]
    set_property IOSTANDARD LVCMOS33 [get_ports BtnK2]
set_property PACKAGE_PIN T17 [get_ports BtnK3]
    set_property IOSTANDARD LVCMOS33 [get_ports BtnK3]

## LEDs das teclas sem ressaltos: LD0 = Kd1, LD1 = Kd2, LD2 = Kd3
set_property PACKAGE_PIN U16 [get_ports {LedKd[0]}]
set_property PACKAGE_PIN E19 [get_ports {LedKd[1]}]
set_property PACKAGE_PIN U19 [get_ports {LedKd[2]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {LedKd[*]}]

## LEDs das variáveis de estado: LD4..LD6 = YY0..YY2 da tecla 1, LD7..LD9 da 2, LD10..LD12 da 3
set_property PACKAGE_PIN W18 [get_ports {LedEstado[0]}]
set_property PACKAGE_PIN U15 [get_ports {LedEstado[1]}]
set_property PACKAGE_PIN U14 [get_ports {LedEstado[2]}]
set_property PACKAGE_PIN V14 [get_ports {LedEstado[3]}]
set_property PACKAGE_PIN V13 [get_ports {LedEstado[4]}]
set_property PACKAGE_PIN V3  [get_ports {LedEstado[5]}]
set_property PACKAGE_PIN W3  [get_ports {LedEstado[6]}]
set_property PACKAGE_PIN U3  [get_ports {LedEstado[7]}]
set_property PACKAGE_PIN P3  [get_ports {LedEstado[8]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {LedEstado[*]}]

## LEDs da validação: LD14 = M, LD15 = U
set_property PACKAGE_PIN P1 [get_ports LedM]
    set_property IOSTANDARD LVCMOS33 [get_ports LedM]
set_property PACKAGE_PIN L1 [get_ports LedU]
    set_property IOSTANDARD LVCMOS33 [get_ports LedU]

## Displays de 7 segmentos (Seg[6] = a ... Seg[0] = g, ativos a Low)
set_property PACKAGE_PIN W7 [get_ports {Seg[6]}]
set_property PACKAGE_PIN W6 [get_ports {Seg[5]}]
set_property PACKAGE_PIN U8 [get_ports {Seg[4]}]
set_property PACKAGE_PIN V8 [get_ports {Seg[3]}]
set_property PACKAGE_PIN U5 [get_ports {Seg[2]}]
set_property PACKAGE_PIN V5 [get_ports {Seg[1]}]
set_property PACKAGE_PIN U7 [get_ports {Seg[0]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {Seg[*]}]
set_property PACKAGE_PIN V7 [get_ports DP]
    set_property IOSTANDARD LVCMOS33 [get_ports DP]
set_property PACKAGE_PIN U2 [get_ports {An[0]}]
set_property PACKAGE_PIN U4 [get_ports {An[1]}]
set_property PACKAGE_PIN V4 [get_ports {An[2]}]
set_property PACKAGE_PIN W4 [get_ports {An[3]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {An[*]}]

## Configuração
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
