# Corre no arranque de cada simulacao do projeto controlodisplays (xsim.simulate.tcl.post):
# abre a vista das formas de onda (<testbench>.wcfg) do testbench que esta como top,
# ja que o projeto tem cinco testbenches e o Vivado so permite uma vista fixa.
set tb [string trimleft [lindex [get_scopes /*] 0] /]
set raiz [file dirname [file dirname [file normalize [info script]]]]
set wcfg [lindex [glob -nocomplain $raiz/*/$tb.wcfg] 0]
if {$wcfg ne ""} {
    # fecha a janela "Untitled" que o Vivado cria quando nao ha vista definida
    set vazia [current_wave_config]
    if {[string length $vazia]} { close_wave_config -force $vazia }
    open_wave_config $wcfg
}
