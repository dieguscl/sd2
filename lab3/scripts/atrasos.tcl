# Atrasos (depois do place & route) das ligacoes de cada maquina de estados assincrona.
# Escreve bitstreams/relatorios/gestaoteclas_atrasos.txt com, para cada maquina:
#   - as celulas (LUT) que realizam Y2, Y1, Y0, YY2, YY1, YY0 e a sua localizacao;
#   - o atraso de cada ligacao ate cada pino de destino, nos cantos rapido e lento (ps).
# Serve para confirmar a margem dos acidentes essenciais: quando To sobe em S1 ou S4, To tem de
# chegar ao LUT de Y2 antes da mudanca de YY1 que ele proprio provoca (To -> Y1 -> YY1 -> Y2).
# Uso: no fim de scripts/build.tcl, ou sozinho com o projeto implementado aberto.
set root [file normalize [file dirname [info script]]/..]
set f [open $root/bitstreams/relatorios/gestaoteclas_atrasos.txt w]
foreach t {tecla1 tecla2 tecla3} {
    puts $f "== $t"
    foreach n {Y2 Y1 Y0 YY2 YY1 YY0} {
        set drv [get_cells -of_objects [get_pins -leaf -of_objects [get_nets $t/maquina/$n] -filter {DIRECTION == OUT}]]
        puts $f "celula $n [get_property REF_NAME $drv] $drv [get_property LOC $drv] [get_property BEL $drv]"
    }
    set to [get_nets -of_objects [get_pins $t/temporizador/To_reg/Q]]
    foreach {nome net} [list To $to Y2 [get_nets $t/maquina/Y2] Y1 [get_nets $t/maquina/Y1] Y0 [get_nets $t/maquina/Y0] \
                       YY2 [get_nets $t/maquina/YY2] YY1 [get_nets $t/maquina/YY1] YY0 [get_nets $t/maquina/YY0]] {
        foreach p [get_pins -leaf -of_objects $net -filter {DIRECTION == IN}] {
            set c [get_cells -of_objects $p]
            set d [get_net_delays -of_objects [get_nets -of_objects $p] -to $p]
            puts $f "net $nome -> $p ([get_property REF_NAME $c]) fast_min=[get_property FAST_MIN $d] fast_max=[get_property FAST_MAX $d] slow_min=[get_property SLOW_MIN $d] slow_max=[get_property SLOW_MAX $d]"
        }
    }
}
close $f
