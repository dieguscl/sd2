#!/usr/bin/env bash
# Simula os testbenches do 2.o trabalho com o xsim do Vivado (sem criar projeto).
# Uso (na pasta lab2):
#     scripts/simula.sh                      (todos os testbenches)
#     scripts/simula.sh controlador_teste1   (so um)
# As formas de onda ficam em simulacao/<testbench>.wdb e as mensagens finais em
# simulacao/resultados.txt.
set -euo pipefail
cd "$(dirname "$0")/.."
VIVADO_BIN=$(dirname "$(command -v vivado)")
GLBL="$VIVADO_BIN/../data/verilog/src/glbl.v"

# modulos do 1.o trabalho reutilizados
LAB1=(../lab1/registo4/registo4.v ../lab1/divisorclock/divisorclock.v ../lab1/contador4/contador4.v
      ../lab1/multiplexer4x1/multiplexer4x1.v ../lab1/multiplexer16x4/multiplexer16x4.v
      ../lab1/descodificador2x4/descodificador2x4.v)
FONTES=("${LAB1[@]}" lfsr32/lfsr32.v memoria4x2/memoria4x2.v temporizador/temporizador.v
        temporizador/velocidade.v temporizador/temporizadorvariavel.v sincronizador/sincronizador.v
        sincronizador/sincronizadorreset.v beat/beat.v gestaodisplays/transcodcordas.v gestaodisplays/gestaodisplays.v
        controlador/controlador.v guitarhero/guitarhero.v)
TESTES=(lfsr32/lfsr32_teste1 memoria4x2/memoria4x2_teste1 temporizador/temporizador_teste1
        temporizador/temporizadorvariavel_teste1 sincronizador/sincronizador_teste1
        sincronizador/sincronizadorreset_teste1 beat/beat_teste1
        gestaodisplays/gestaodisplays_teste1 controlador/controlador_teste1 guitarhero/guitarhero_teste1)

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
