#!/bin/bash
# Valida os testbenches com alteracoes propositadas (mutacoes): aplica uma de cada vez a uma copia
# do projeto, corre os testbenches (scripts/simula.sh) e regista quais falharam.
# Uso (na pasta lab3): scripts/mutacoes.sh > simulacao/mutacoes.txt   (alguns minutos)
L=$(cd "$(dirname "$0")/.." && pwd)
T=$(mktemp -d)
run() { # descricao ficheiro expressao-sed
  rm -rf $T/mut && mkdir -p $T/mut && cp -r $L/{maquinatecla,monoestavel,tecla,validacao,ensaio,gestaoteclas,modulos_lab1,scripts} $T/mut/
  sed -i "$3" $T/mut/$2
  if cmp -s $T/mut/$2 $L/$2; then echo "$1: MUTACAO NAO APLICADA"; return; fi
  r=$(cd $T/mut && scripts/simula.sh 2>/dev/null | grep -c FALHOU)
  echo "$1: testbenches que falharam = $r"; (cd $T/mut && grep FALHOU simulacao/resultados.txt | cut -d: -f1 | tr '\n' ' '); echo
}
run "Y0 sem o termo /YY2·YY0" maquinatecla/maquinatecla.v 's/ | (~YY2 \& YY0);/;/'
run "Y2 com To trocado" maquinatecla/maquinatecla.v 's/assign #1 Y2 = (To \& YY2) | (~To \& YY1)/assign #1 Y2 = (~To \& YY2) | (To \& YY1)/'
run "F = YY1" maquinatecla/maquinatecla.v 's/assign F  = YY2;/assign F  = YY1;/'
run "Clear sem efeito em YY0" maquinatecla/maquinatecla.v 's/assign YY0 = Y0 \& ~Clear;/assign YY0 = Y0;/'
run "temporizador dispara nos dois flancos" monoestavel/monoestavel.v 's/wire flanco = sinc \& ~anterior;/wire flanco = sinc ^ anterior;/'
run "temporizador sem redisparo" monoestavel/monoestavel.v 's/if (flanco) begin/if (flanco \&\& !To) begin/'
run "M sem o termo K1·K3" validacao/validacao.v 's/ | (K1 \& K3)//'
run "Ti = K (sem XOR)" tecla/tecla.v 's/assign Ti = (K ^ F) \& ~Clear;/assign Ti = K \& ~Clear;/'
run "Ti sem a porta do Clear" tecla/tecla.v 's/assign Ti = (K ^ F) \& ~Clear;/assign Ti = K ^ F;/'
run "Y2 sem o termo de consenso YY2·YY1" maquinatecla/maquinatecla.v 's/ | (YY2 \& YY1);/;/'
run "Y1 sem o termo de consenso YY1·YY0" maquinatecla/maquinatecla.v 's/ | (YY1 \& YY0);/;/'
rm -rf $T
