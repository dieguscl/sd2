## Restrições do circuito GuitarHero na placa Basys3 (xc7a35ticpg236-1L)
## Tecla Reset = BTNU, tecla Start = BTNC
## LD0 = Ready, LD1 = Beat, LD2 = Waiting, LD10 a LD15 = estados S0 a S5 (um LED por flip-flop)

## Relógio de 100 MHz
set_property PACKAGE_PIN W5 [get_ports CLKBasys]
    set_property IOSTANDARD LVCMOS33 [get_ports CLKBasys]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports CLKBasys]

## Relógio do varrimento dos displays (100 MHz / 50000 = 2 kHz), gerado pelo DivisorClock
## (-divide_by = 2 x METADE: atualizar se METADE mudar).
create_generated_clock -name clk_varrimento -source [get_ports CLKBasys] -divide_by 50000 [get_pins displays/divisor/ClockOut_reg/Q]
## O único caminho clk_varrimento -> sys_clk_pin é a realimentação do próprio divisor (ClockOut -> /ClockOut,
## um LUT, ~1,5 ns). Sem este false path o Vivado tenta analisá-lo e, como 50000 períodos não têm período comum
## dentro do limite que expande, dá TIMING-8 (Critical Warning); com ele fica só TIMING-9, como no 1.º trabalho.
set_false_path -from [get_clocks clk_varrimento] -to [get_clocks sys_clk_pin]

## Teclas (assíncronas: as duas passam por sincronizadores; o Reset atua de imediato no PRE
## dos flip-flops do SincronizadorReset e a libertação para o controlador já é síncrona)
set_false_path -from [get_ports {BtnReset BtnStart}]
## LEDs e displays: sem requisitos de tempo
set_false_path -to [get_ports {Seg[*] DP An[*] LedReady LedBeat LedWaiting LedEstado[*]}]

## Teclas
set_property PACKAGE_PIN T18 [get_ports BtnReset]
    set_property IOSTANDARD LVCMOS33 [get_ports BtnReset]
set_property PACKAGE_PIN U18 [get_ports BtnStart]
    set_property IOSTANDARD LVCMOS33 [get_ports BtnStart]

## LEDs de sinalização
set_property PACKAGE_PIN U16 [get_ports LedReady]
    set_property IOSTANDARD LVCMOS33 [get_ports LedReady]
set_property PACKAGE_PIN E19 [get_ports LedBeat]
    set_property IOSTANDARD LVCMOS33 [get_ports LedBeat]
set_property PACKAGE_PIN U19 [get_ports LedWaiting]
    set_property IOSTANDARD LVCMOS33 [get_ports LedWaiting]

## LEDs dos estados: LD10 = S0 ... LD15 = S5
set_property PACKAGE_PIN W3 [get_ports {LedEstado[0]}]
set_property PACKAGE_PIN U3 [get_ports {LedEstado[1]}]
set_property PACKAGE_PIN P3 [get_ports {LedEstado[2]}]
set_property PACKAGE_PIN N3 [get_ports {LedEstado[3]}]
set_property PACKAGE_PIN P1 [get_ports {LedEstado[4]}]
set_property PACKAGE_PIN L1 [get_ports {LedEstado[5]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {LedEstado[*]}]

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
