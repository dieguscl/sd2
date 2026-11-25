#!/bin/bash
# Exporta os diagramas do draw.io (relatorio/figuras/*.drawio) para PNG, com o diagrama embebido
# (o PNG volta a abrir no draw.io para edicao).
# Requisitos: draw.io desktop (comando drawio ou DRAWIO=<caminho>) e Xvfb.
set -e
cd "$(dirname "$0")/../figuras"
DRAWIO=${DRAWIO:-drawio}
for f in *.drawio; do
    xvfb-run -a "$DRAWIO" --no-sandbox --disable-gpu -x -f png -s 2 -b 10 -e -o "${f%.drawio}.png" "$f" >/dev/null 2>&1
    echo "${f%.drawio}.png"
done
