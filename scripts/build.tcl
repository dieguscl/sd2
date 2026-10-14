# Recria os projetos Vivado do 1o trabalho, corre a simulacao comportamental de
# todos os testbenches e gera o bitstream de cada projeto.
# Uso (na raiz do repositorio):
#     vivado -mode batch -source scripts/build.tcl                  (todos os projetos)
#     vivado -mode batch -source scripts/build.tcl -tclargs displayBCD   (so um)
set root [file normalize [file dirname [info script]]/..]
set part xc7a35ticpg236-1L   ;# FPGA da Basys3 indicada no enunciado

# nome do projeto -> modulo de topo, fontes de desenho, restricoes, testbenches
set projetos {
    multiplexer4x1 {
        multiplexer4x1
        {multiplexer4x1/multiplexer4x1.v}
        multiplexer4x1/multiplexer4x1.xdc
        {multiplexer4x1/multiplexer4x1_teste1.v}
    }
    descodificador2x4 {
        descodificador2x4
        {descodificador2x4/descodificador2x4.v}
        descodificador2x4/descodificador2x4.xdc
        {descodificador2x4/descodificador2x4_teste1.v}
    }
    multiplexer16x4 {
        multiplexer16x4
        {multiplexer4x1/multiplexer4x1.v multiplexer16x4/multiplexer16x4.v}
        multiplexer16x4/multiplexer16x4.xdc
        {multiplexer16x4/multiplexer16x4_teste1.v}
    }
    displayBCD {
        displayBCD
        {transcod7seg/transcod7seg.v transcod7seg/displayBCD.v}
        transcod7seg/displayBCD.xdc
        transcod7seg/transcod7seg_teste1.v
    }
    controlodisplays {
        TesteDisplays
        {multiplexer4x1/multiplexer4x1.v multiplexer16x4/multiplexer16x4.v
         descodificador2x4/descodificador2x4.v transcod7seg/transcod7seg.v
         registo4/registo4.v divisorclock/divisorclock.v contador4/contador4.v
         controlodisplays/controlodisplays.v controlodisplays/testedisplays.v}
        controlodisplays/testedisplays.xdc
        {registo4/registo4_teste1.v divisorclock/divisorclock_teste1.v
         contador4/contador4_teste1.v controlodisplays/controlodisplays_teste1.v
         controlodisplays/testedisplays_teste1.v}
    }
}

set escolhidos $argv
file mkdir $root/bitstreams/relatorios $root/simulacao
set resultados {}
set ::resultados_sim {}
foreach {nome def} $projetos {
    if {[llength $escolhidos] && [lsearch -exact $escolhidos $nome] < 0} continue
    lassign $def topo fontes xdc testes
    set dir $root/vivado/$nome
    create_project $nome $dir -part $part -force
    foreach f $fontes { add_files -norecurse $root/$f }
    add_files -fileset constrs_1 -norecurse $root/$xdc
    foreach t $testes {
        add_files -fileset sim_1 -norecurse $root/$t
        # vista das formas de onda (.wcfg) do testbench, se existir
        set wcfg $root/[file rootname $t].wcfg
        if {[file exists $wcfg]} { add_files -fileset sim_1 -norecurse $wcfg }
    }
    set_property top $topo [current_fileset]
    update_compile_order -fileset sources_1

    # Simulacao comportamental de cada testbench, com registo VCD das formas de onda
    set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]
    foreach t $testes {
        set tb [file rootname [file tail $t]]
        set_property top $tb [get_filesets sim_1]
        # abre so a vista .wcfg deste testbench (as outras referem sinais que nao existem)
        set wcfg [get_files -quiet -of_objects [get_filesets sim_1] *${tb}.wcfg]
        if {[llength $wcfg]} { set_property xsim.view $wcfg [get_filesets sim_1] }
        update_compile_order -fileset sim_1
        launch_simulation -simset sim_1 -mode behavioral
        open_vcd $root/simulacao/$tb.vcd
        log_vcd [get_objects -r /$tb/*]
        restart
        if {$tb eq "divisorclock_teste1"} {
            # 6 ms a 100 MHz dariam um VCD com dezenas de MB: regista so os primeiros 2 us
            run 2us
            close_vcd
            run all
        } else {
            run all
            close_vcd
        }
        close_sim
        # guarda a mensagem final do testbench (Simulacao OK / FALHOU) em simulacao/resultados.txt
        set fh [open $dir/$nome.sim/sim_1/behav/xsim/simulate.log]
        foreach linha [split [read $fh] "\n"] {
            if {[string match "Simulacao *" $linha] && [lsearch -exact $::resultados_sim "$tb: $linha"] < 0} { lappend ::resultados_sim "$tb: $linha" }
        }
        close $fh
    }
    # deixa como testbench ativo o primeiro da lista
    set_property top [file rootname [file tail [lindex $testes 0]]] [get_filesets sim_1]

    # Sintese, implementacao e bitstream
    launch_runs synth_1 -jobs 8
    wait_on_run synth_1
    launch_runs impl_1 -to_step write_bitstream -jobs 8
    wait_on_run impl_1
    if {[get_property PROGRESS [get_runs impl_1]] ne "100%"} { error "$nome: implementacao falhou" }
    file copy -force $dir/$nome.runs/impl_1/$topo.bit $root/bitstreams/$nome.bit
    open_run impl_1
    report_utilization -file $root/bitstreams/relatorios/${nome}_utilizacao.txt
    report_timing_summary -file $root/bitstreams/relatorios/${nome}_tempos.txt
    report_methodology -file $root/bitstreams/relatorios/${nome}_metodologia.txt
    close_project
    lappend resultados $nome
}
set fh [open $root/simulacao/resultados.txt [expr {[llength $escolhidos] ? "a" : "w"}]]
foreach r $::resultados_sim { puts $fh $r }
close $fh
puts "Projetos gerados: $resultados"
