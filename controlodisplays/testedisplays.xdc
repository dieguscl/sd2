# Ensaio do controlador dos displays na Basys3 (modulo de topo TesteDisplays, Fig. 32)

# Relogio interno da Basys3: 100 MHz
set_property PACKAGE_PIN W5 [get_ports CLKBasys]
    set_property IOSTANDARD LVCMOS33 [get_ports CLKBasys]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports CLKBasys]

# Relogio do varrimento, gerado pelo divisor (100 MHz / 50000 = 2 kHz)
create_generated_clock -name clk_varrimento -source [get_ports CLKBasys] -divide_by 50000 [get_pins controlo/divisor/ClockOut_reg/Q]
# O unico caminho entre os dois relogios e a realimentacao do proprio divisor
# (ClockOut_reg/Q -> inversor -> ClockOut_reg/D), sem periodo comum que o Vivado consiga analisar
set_false_path -from [get_clocks clk_varrimento] -to [get_clocks sys_clk_pin]

# Interruptores, teclas e displays sao lentos e assincronos em relacao ao relogio:
# nao ha requisitos de tempo nas entradas e saidas
set_false_path -from [get_ports {Data[*] LD3 LD2 LD1 LD0 LDDP EN Clear}]
set_false_path -to [get_ports {Seg[*] DP An[*]}]

# Valor a carregar nos registos (interruptores SW3 a SW0)
set_property PACKAGE_PIN W17 [get_ports {Data[3]}]
set_property PACKAGE_PIN W16 [get_ports {Data[2]}]
set_property PACKAGE_PIN V16 [get_ports {Data[1]}]
set_property PACKAGE_PIN V17 [get_ports {Data[0]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {Data[*]}]

# Carga dos registos dos simbolos (interruptores SW15 a SW12, alinhados com os displays:
# SW15 carrega o display da esquerda e SW12 o da direita)
set_property PACKAGE_PIN R2 [get_ports LD3]
    set_property IOSTANDARD LVCMOS33 [get_ports LD3]
set_property PACKAGE_PIN T1 [get_ports LD2]
    set_property IOSTANDARD LVCMOS33 [get_ports LD2]
set_property PACKAGE_PIN U1 [get_ports LD1]
    set_property IOSTANDARD LVCMOS33 [get_ports LD1]
set_property PACKAGE_PIN W2 [get_ports LD0]
    set_property IOSTANDARD LVCMOS33 [get_ports LD0]

# Carga do registo dos pontos decimais (interruptor SW11)
set_property PACKAGE_PIN R3 [get_ports LDDP]
    set_property IOSTANDARD LVCMOS33 [get_ports LDDP]

# Enable dos 4 displays (interruptor SW10)
set_property PACKAGE_PIN T2 [get_ports EN]
    set_property IOSTANDARD LVCMOS33 [get_ports EN]

# Clear de todos os registos (tecla BTNC)
set_property PACKAGE_PIN U18 [get_ports Clear]
    set_property IOSTANDARD LVCMOS33 [get_ports Clear]

# Segmentos a..g (Seg[6] = a ... Seg[0] = g), ativos a Low
set_property PACKAGE_PIN W7 [get_ports {Seg[6]}]
set_property PACKAGE_PIN W6 [get_ports {Seg[5]}]
set_property PACKAGE_PIN U8 [get_ports {Seg[4]}]
set_property PACKAGE_PIN V8 [get_ports {Seg[3]}]
set_property PACKAGE_PIN U5 [get_ports {Seg[2]}]
set_property PACKAGE_PIN V5 [get_ports {Seg[1]}]
set_property PACKAGE_PIN U7 [get_ports {Seg[0]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {Seg[*]}]

# Ponto decimal, ativo a Low
set_property PACKAGE_PIN V7 [get_ports DP]
    set_property IOSTANDARD LVCMOS33 [get_ports DP]

# Anodos comuns dos 4 displays, ativos a Low (An[0] e o display da direita)
set_property PACKAGE_PIN U2 [get_ports {An[0]}]
set_property PACKAGE_PIN U4 [get_ports {An[1]}]
set_property PACKAGE_PIN V4 [get_ports {An[2]}]
set_property PACKAGE_PIN W4 [get_ports {An[3]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {An[*]}]

# Definir a tensao correta da placa Basys3
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
