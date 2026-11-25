#!/bin/bash
# Cria entrega/SD2_Lab3_Verilog.zip com o codigo, testbenches, restricoes, vistas e scripts do 3.o trabalho.
# Uso (na pasta lab3): scripts/empacota.sh
set -e
cd "$(dirname "$0")/../.."
mkdir -p lab3/entrega
rm -f lab3/entrega/SD2_Lab3_Verilog.zip
zip -q -X lab3/entrega/SD2_Lab3_Verilog.zip lab3/README.md \
    lab3/maquinatecla/*.v lab3/maquinatecla/*.wcfg lab3/monoestavel/*.v lab3/monoestavel/*.wcfg \
    lab3/tecla/*.v lab3/tecla/*.wcfg lab3/validacao/*.v lab3/validacao/*.wcfg lab3/ensaio/*.v \
    lab3/gestaoteclas/*.v lab3/gestaoteclas/*.xdc lab3/gestaoteclas/*.wcfg lab3/modulos_lab1/*.v \
    lab3/scripts/*.sh lab3/scripts/*.tcl lab3/scripts/*.py \
    lab3/simulacao/projeto.txt lab3/simulacao/resultados.txt lab3/simulacao/mutacoes.txt
unzip -l lab3/entrega/SD2_Lab3_Verilog.zip | tail -1
