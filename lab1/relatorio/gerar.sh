#!/bin/bash
# Gera o relatorio final (capa oficial + corpo) em relatorio/SD2_Lab1_Relatorio.pdf
# Requisitos: node com o pacote docx, LibreOffice (com python3-uno), poppler-utils (pdfunite, pdfinfo).
# Os resultados das simulacoes e dos bitstreams vem de scripts/build.tcl (correr esse primeiro).
set -e
cd "$(dirname "$0")"
export NODE_PATH=${NODE_PATH:-$(npm root -g)}
TMP=$(mktemp -d)
python3 fonte/simbolos7seg.py >/dev/null
# 1.a passagem: so para saber o numero de paginas
node fonte/gerar.js '?' >/dev/null
python3 fonte/render.py fonte/corpo.docx $TMP/corpo.docx $TMP/corpo.pdf >/dev/null
TOTAL=$(( $(pdfinfo $TMP/corpo.pdf | awk '/^Pages:/ {print $2}') + 1 ))
# 2.a passagem: com o total de paginas certo no rodape e na capa
node fonte/gerar.js $TOTAL >/dev/null
python3 fonte/render.py fonte/corpo.docx SD2_Lab1_Relatorio_corpo.docx $TMP/corpo.pdf >/dev/null
python3 fonte/preencher_capa.py capa/capa_original.odt capa/SD2_Lab1_Capa.odt $TOTAL >/dev/null
soffice --headless --convert-to pdf --outdir $TMP capa/SD2_Lab1_Capa.odt >/dev/null 2>&1
pdfunite $TMP/SD2_Lab1_Capa.pdf $TMP/corpo.pdf SD2_Lab1_Relatorio.pdf
rm -rf $TMP fonte/corpo.docx
echo "relatorio/SD2_Lab1_Relatorio.pdf ($TOTAL paginas)"
