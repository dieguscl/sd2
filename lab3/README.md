# SD2 - 3.º Trabalho de Laboratório

**Sistemas Digitais II · LEEC · ESTSetúbal/IPS · 2026/27**
Circuitos sequenciais assíncronos: gestão das teclas para o jogo Guitar Hero (Basys3).

| O que pede o enunciado | Onde está |
|---|---|
| Máquina de estados assíncrona projetada pela metodologia lecionada | `maquinatecla/` + `scripts/projeto.py` (confere todos os passos) |
| Temporizador monoestável redisparável | `monoestavel/` |
| 3 instâncias (K1, K2, K3) e função U / M | `tecla/`, `validacao/`, `gestaoteclas/` |
| Reset nas realimentações (Fig. 3) | `maquinatecla/maquinatecla.v` (`YYi = Yi & ~Clear`) |
| Simulação, pinos, bitstream | `scripts/simula.sh`, `gestaoteclas/gestaoteclas.xdc`, `bitstreams/gestaoteclas.bit` |
| Relatório | **`relatorio/SD2_Lab3_Relatorio.pdf`** (capa oficial + corpo; `.docx` do corpo ao lado) |
| Figuras de referência | `relatorio/SD2_Lab3_Figuras.pdf` (só as figuras e tabelas principais, para mostrar ao docente) |

## Máquina de estados (resumo)

Tabela primitiva (folha do grupo): 10 estados a..j, entradas K To, saídas Kd F.
Fusão: (a) (b,i) (c,d) (e) (f,j) (g,h) → 6 estados. Codificação de Johnson, livre de corridas, com
três transições indiretas (S2 → S3 → S4, S5 → S0 → S1, S0 → S1 → S2):

```
S0 000 repouso                   Kd F = 00     S3 111 premida estável          Kd F = 11
S1 001 premida, espera To        Kd F = 10     S4 110 largada, espera To       Kd F = 01
S2 011 temporização ao premir    Kd F = 10     S5 100 temporização ao largar   Kd F = 01

Y2 = To·YY2 + /To·YY1 + YY2·YY1      (consenso: YY2·YY1)
Y1 = To·YY0 + /To·YY1 + YY1·YY0      (consenso: YY1·YY0)
Y0 = K·/YY2 + K·YY0 + /YY2·YY0       (função maioria)
YYi = Yi · /Clear      Kd = YY0      F = YY2      Ti = K xor F
```

`python3 scripts/projeto.py` refaz a redução, a codificação e as equações e confere: tabela de
transições, acidentes estáticos (32 combinações), corridas (todas as ordens de mudança das variáveis
de estado, 24 transições), picos nas saídas e acidentes essenciais (resumo em `simulacao/projeto.txt`).
Os acidentes essenciais (To a subir em S1 e S4) são confirmados com os atrasos do *place & route*
(`scripts/atrasos.tcl` → `bitstreams/relatorios/gestaoteclas_atrasos.txt`).

## Simulação

```bash
scripts/simula.sh                        # os 5 testbenches (xsim do Vivado)
scripts/simula.sh maquinatecla_teste1    # só um
scripts/mutacoes.sh > simulacao/mutacoes.txt   # validação dos testbenches com erros propositados
```

## Projeto Vivado e bitstream

```bash
vivado -mode batch -source scripts/build.tcl     # recria vivado/gestaoteclas e gera bitstreams/gestaoteclas.bit
```

O XDC tem `ALLOW_COMBINATORIAL_LOOPS` nas realimentações YY* (sem isso o Vivado recusa o bitstream,
DRC LUTLP-1). Cada máquina ocupa 6 LUT e nenhum flip-flop.

## Ensaio na Basys3

| Placa | Sinal |
|---|---|
| BTNL / BTNC / BTNR | K1 / K2 / K3 |
| BTNU | Reset das máquinas de estados (e das contagens de ensaio) |
| LD0..LD2 | Kd1..Kd3 |
| LD4..LD12 | YY0 YY1 YY2 das máquinas 1, 2, 3 |
| LD15 / LD14 | U / M |
| displays | flancos das teclas com ressaltos (esquerda) . sem ressaltos (direita), hexadecimal |

Falta: fotografias do ensaio e confirmação dos resultados (secção 7.4 do relatório, a vermelho);
confirmar a data da capa (`relatorio/fonte/preencher_capa.py`).

## Relatório

`relatorio/gerar.sh` gera o relatório (capa oficial + corpo gerado por `relatorio/fonte/gerar.js` a partir dos ficheiros
do repositório e dos resultados de `scripts/projeto.py`, `scripts/simula.sh`, `scripts/build.tcl` e
`scripts/mutacoes.sh`) e a folha de figuras (`relatorio/fonte/gerar_figuras.js`; as tabelas da máquina
vêm de `relatorio/fonte/tabelas_maquina.js`, as mesmas do relatório). Diagramas: `relatorio/fonte/gera_diagramas.py` → `relatorio/figuras/*.drawio`
(PNG com `relatorio/fonte/exporta_diagramas.sh`); mapas de Karnaugh: `relatorio/fonte/mapas_kv.py`.
