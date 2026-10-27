# Recria o projeto Vivado do 2o trabalho (GuitarHero) e gera o bitstream para a Basys3.
# Os testbenches ficam no projeto (Simulation Sources) para correr no Vivado;
# para simular todos de uma vez sem abrir o Vivado usar scripts/simula.sh.
# Uso (na pasta lab2):
#     vivado -mode batch -source scripts/build.tcl
set root [file normalize [file dirname [info script]]/..]
set part xc7a35ticpg236-1L   ;# FPGA da Basys3
set nome guitarhero
set topo GuitarHero

# modulos do 1o trabalho reutilizados (caminhos relativos a lab2)
set fontes {
    ../lab1/registo4/registo4.v ../lab1/divisorclock/divisorclock.v ../lab1/contador4/contador4.v
    ../lab1/multiplexer4x1/multiplexer4x1.v ../lab1/multiplexer16x4/multiplexer16x4.v
    ../lab1/descodificador2x4/descodificador2x4.v
    lfsr32/lfsr32.v memoria4x2/memoria4x2.v temporizador/temporizador.v temporizador/velocidade.v
    temporizador/temporizadorvariavel.v sincronizador/sincronizador.v sincronizador/sincronizadorreset.v
    beat/beat.v
    gestaodisplays/transcodcordas.v gestaodisplays/gestaodisplays.v controlador/controlador.v
    guitarhero/guitarhero.v
}
set testes {
    guitarhero/guitarhero_teste1.v controlador/controlador_teste1.v lfsr32/lfsr32_teste1.v
    memoria4x2/memoria4x2_teste1.v temporizador/temporizador_teste1.v
    temporizador/temporizadorvariavel_teste1.v sincronizador/sincronizador_teste1.v sincronizador/sincronizadorreset_teste1.v
    beat/beat_teste1.v gestaodisplays/gestaodisplays_teste1.v
}

set dir $root/vivado/$nome
create_project $nome $dir -part $part -force
foreach f $fontes { add_files -norecurse [file normalize $root/$f] }
add_files -fileset constrs_1 -norecurse $root/guitarhero/guitarhero.xdc
foreach t $testes { add_files -fileset sim_1 -norecurse $root/$t }
set_property top $topo [current_fileset]
set_property top guitarhero_teste1 [get_filesets sim_1]
set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# Sintese, implementacao e bitstream
launch_runs synth_1 -jobs 8
wait_on_run synth_1
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] ne "100%"} { error "$nome: implementacao falhou" }
file mkdir $root/bitstreams/relatorios
file copy -force $dir/$nome.runs/impl_1/$topo.bit $root/bitstreams/$nome.bit
open_run impl_1
report_utilization -file $root/bitstreams/relatorios/${nome}_utilizacao.txt
report_timing_summary -file $root/bitstreams/relatorios/${nome}_tempos.txt
report_methodology -file $root/bitstreams/relatorios/${nome}_metodologia.txt
close_project
puts "Bitstream: bitstreams/$nome.bit"
