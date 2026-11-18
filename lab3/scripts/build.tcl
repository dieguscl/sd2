# Recria o projeto Vivado do 3.o trabalho (GestaoTeclas) e gera o bitstream para a Basys3.
# Os testbenches ficam no projeto (Simulation Sources) para correr no Vivado;
# para simular todos de uma vez sem abrir o Vivado usar scripts/simula.sh.
# Uso (na pasta lab3):
#     vivado -mode batch -source scripts/build.tcl
set root [file normalize [file dirname [info script]]/..]
set part xc7a35ticpg236-1L   ;# FPGA da Basys3
set nome gestaoteclas
set topo GestaoTeclas

# copias dos modulos do 1.o trabalho (sistema dos displays) e modulos do 3.o trabalho
set fontes {
    modulos_lab1/registo4.v modulos_lab1/divisorclock.v modulos_lab1/contador4.v
    modulos_lab1/multiplexer4x1.v modulos_lab1/multiplexer16x4.v modulos_lab1/descodificador2x4.v
    modulos_lab1/transcod7seg.v modulos_lab1/controlodisplays.v
    maquinatecla/maquinatecla.v monoestavel/monoestavel.v tecla/tecla.v validacao/validacao.v
    ensaio/contaimpulsos.v gestaoteclas/gestaoteclas.v
}
set testes {
    gestaoteclas/gestaoteclas_teste1.v maquinatecla/maquinatecla_teste1.v monoestavel/monoestavel_teste1.v
    tecla/tecla_teste1.v validacao/validacao_teste1.v
}

set dir $root/vivado/$nome
create_project $nome $dir -part $part -force
foreach f $fontes { add_files -norecurse [file normalize $root/$f] }
add_files -fileset constrs_1 -norecurse $root/gestaoteclas/gestaoteclas.xdc
foreach t $testes { add_files -fileset sim_1 -norecurse $root/$t }
# vista das formas de onda do testbench que esta como top (ver scripts/abre_wcfg.tcl)
set_property xsim.simulate.tcl.post ../../../../../../scripts/abre_wcfg.tcl [get_filesets sim_1]
set_property top $topo [current_fileset]
set_property top maquinatecla_teste1 [get_filesets sim_1]
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
report_utilization -hierarchical -file $root/bitstreams/relatorios/${nome}_utilizacao_hier.txt
report_timing_summary -file $root/bitstreams/relatorios/${nome}_tempos.txt
report_methodology -file $root/bitstreams/relatorios/${nome}_metodologia.txt
report_drc -file $root/bitstreams/relatorios/${nome}_drc.txt
# atrasos das ligacoes das maquinas de estados (acidentes essenciais, secao do relatorio)
source $root/scripts/atrasos.tcl
close_project
puts "Bitstream: bitstreams/$nome.bit"
