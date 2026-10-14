# Variáveis de seleção do multiplexer 4x1 (interruptores SW5 e SW4)
set_property PACKAGE_PIN V15 [get_ports Sel1]
    set_property IOSTANDARD LVCMOS33 [get_ports Sel1]
set_property PACKAGE_PIN W15 [get_ports Sel0]
    set_property IOSTANDARD LVCMOS33 [get_ports Sel0]

# Variáveis de entrada do multiplexer 4x1 (interruptores SW0 a SW3)
set_property PACKAGE_PIN V17 [get_ports DataIn0]
    set_property IOSTANDARD LVCMOS33 [get_ports DataIn0]
set_property PACKAGE_PIN V16 [get_ports DataIn1]
    set_property IOSTANDARD LVCMOS33 [get_ports DataIn1]
set_property PACKAGE_PIN W16 [get_ports DataIn2]
    set_property IOSTANDARD LVCMOS33 [get_ports DataIn2]
set_property PACKAGE_PIN W17 [get_ports DataIn3]
    set_property IOSTANDARD LVCMOS33 [get_ports DataIn3]

# Variável de saída do multiplexer 4x1 (LED LD0)
set_property PACKAGE_PIN U16 [get_ports DataOut]
    set_property IOSTANDARD LVCMOS33 [get_ports DataOut]

# Definir a tensão correta da placa Basys3
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
