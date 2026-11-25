#!/usr/bin/env bash
# Simula os testbenches do 3.o trabalho com o xsim do Vivado (sem criar projeto).
# Uso (na pasta lab3):
#     scripts/simula.sh                        (todos os testbenches)
#     scripts/simula.sh maquinatecla_teste1    (so um)
# As formas de onda ficam em simulacao/<testbench>.wdb e as mensagens finais em
# simulacao/resultados.txt.
set -euo pipefail
cd "$(dirname "$0")/.."
VIVADO_BIN=$(dirname "$(command -v vivado)")
GLBL="$VIVADO_BIN/../data/verilog/src/glbl.v"

# copias dos modulos do 1.o trabalho (sistema dos displays, usado so no circuito de ensaio)
LAB1=(modulos_lab1/registo4.v modulos_lab1/divisorclock.v modulos_lab1/contador4.v
      modulos_lab1/multiplexer4x1.v modulos_lab1/multiplexer16x4.v modulos_lab1/descodificador2x4.v
      modulos_lab1/transcod7seg.v modulos_lab1/controlodisplays.v)
FONTES=("${LAB1[@]}" maquinatecla/maquinatecla.v monoestavel/monoestavel.v tecla/tecla.v
        validacao/validacao.v ensaio/contaimpulsos.v gestaoteclas/gestaoteclas.v)
TESTES=(maquinatecla/maquinatecla_teste1 monoestavel/monoestavel_teste1 tecla/tecla_teste1
        validacao/validacao_teste1 gestaoteclas/gestaoteclas_teste1)

mkdir -p simulacao/xsim
cd simulacao/xsim
xvlog --nolog "${FONTES[@]/#/../../}" "$GLBL" $(for t in "${TESTES[@]}"; do echo ../../$t.v; done) > xvlog.out || { cat xvlog.out; exit 1; }

touch ../resultados.txt
for t in "${TESTES[@]}"; do
    tb=$(basename "$t")
    if [ $# -gt 0 ] && [[ " $* " != *" $tb "* ]]; then continue; fi
    xelab --nolog -debug typical -L unisims_ver "$tb" glbl -s "$tb" > "$tb.elab.out" || { cat "$tb.elab.out"; exit 1; }
    xsim --nolog "$tb" -R -wdb "../$tb.wdb" > "$tb.sim.out" || true
    linha=$(grep -h "^Simulacao" "$tb.sim.out" | tail -1)
    grep -h "^ERRO" "$tb.sim.out" || true
    echo "$tb: ${linha:-sem mensagem final}"
    grep -v "^$tb:" ../resultados.txt > ../resultados.tmp || true
    echo "$tb: ${linha:-sem mensagem final}" >> ../resultados.tmp
    sort ../resultados.tmp > ../resultados.txt
    rm -f ../resultados.tmp
done
