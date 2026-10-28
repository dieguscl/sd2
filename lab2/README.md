# SD2 - 2.º Trabalho de Laboratório

**Sistemas Digitais II · LEEC · ESTSetúbal/IPS · 2026/27**
Realizações diretas: gestão dos displays para o jogo Guitar Hero (Basys3).

| Aula | O que pede o enunciado | Onde está |
|---|---|---|
| 1 | Módulos da arquitetura a controlar com os sinais de entrada e saída e a sua natureza; fluxograma do controlo | **`aula1/aula1.pdf`** (arquitetura, fluxograma, equações da realização direta, tabela dos sinais) |
| 2 | Módulos Verilog (incluindo a máquina de estados) para teste e integração | pastas dos módulos, abaixo; testbenches com verificação automática |
| 3 | Testes e correções finais com o sistema integrado | `guitarhero/` + `bitstreams/guitarhero.bit` |
| — | Relatório | **`relatorio/SD2_Lab2_Relatorio.pdf`** (capa oficial + corpo; `.docx` do corpo ao lado) |

## Módulos

| Módulo | Pasta | Função |
|---|---|---|
| `Controlador` | `controlador/` | Máquina de estados por realização direta: 6 flip-flops (FDPE em S0, FDCE nos outros), um por estado, com as portas lógicas das equações do fluxograma (modelo estrutural) |
| `LFSR32` | `lfsr32/` | LFSR de 32 bits do enunciado (XNOR 32, 22, 2, 1); 2 bits escolhem a corda |
| `Memoria4x2` | `memoria4x2/` | Fila de 4 posições de 2 bits feita com 4 `Registo4` do 1.º trabalho |
| `TemporizadorVariavel` | `temporizador/` | `Velocidade` (registo do período, 0,5 s → 0,2 s, −5 ms por passo) + `Temporizador` (Tempo = 1 durante Periodo ciclos) |
| `Sincronizador` | `sincronizador/` | Sincronização da tecla Start (2 FF) e anti-ressalto de 10 ms |
| `SincronizadorReset` | `sincronizador/` | Reset ativado de imediato e libertado num flanco do relógio (2 FDPE) |
| `Beat` | `beat/` | Flip-flop T (FDCE com D = /Q) do LED Beat |
| `GestaoDisplays` | `gestaodisplays/` | Sistema do 1.º trabalho (divisor, contador, mux 16x4, descodificador) com o transcodificador alterado `TranscodCordas` |
| `GuitarHero` | `guitarhero/` | Circuito de topo e restrições da Basys3 (`guitarhero.xdc`) |

Os módulos do 1.º trabalho são usados diretamente a partir de `../lab1/` (não há cópias).

## Fluxograma (resumo)

```
Reset → S0 INICIA      ClrMem, InitLFSR, EnLFSR, RstTemp
        S1 ESPERA_START Ready, EnLFSR            Start=1 → S2
        S2 LIBERTA      Ready, EnLFSR            Start=0 → S3
        S3 DESLOCA      ShiftMem, TglBeat, StartTemp, EnLFSR
        S4 ESPERA_TEMPO Waiting, EnLFSR          Tempo=0 → S5
        S5 ACELERA      Faster, EnLFSR (opcional)        → S3
```

D_S0 = 0 · D_S1 = S0 + S1·/Start · D_S2 = S1·Start + S2·Start · D_S3 = S2·/Start + S5 · D_S4 = S3 + S4·Tempo · D_S5 = S4·/Tempo

## Simulação

```bash
scripts/simula.sh                       # os 10 testbenches (cerca de 45 s), com o xsim do Vivado
scripts/simula.sh controlador_teste1    # só um
```

Cada testbench compara a UUT com um modelo de referência e termina com `Simulacao OK` ou `Simulacao FALHOU`
(resumo em `simulacao/resultados.txt`; formas de onda em `simulacao/<testbench>.wdb`).
O `controlador_teste1` compara os 6 flip-flops e as 10 saídas com o fluxograma descrito com `case`, com Start e Tempo
aleatórios e Resets assíncronos fora do flanco. O `guitarhero_teste1` testa o sistema completo com tempos curtos
(Reset, Start com ressaltos, 12 passos do jogo com aceleração, Reset a meio do jogo), com um modelo próprio do LFSR e
uma fila de referência comandada só pelos LEDs dos estados.
Os testbenches foram validados com mutações: alterar uma transição, uma saída, o mapeamento dos displays, o período,
a fila, o limite da aceleração, a realimentação do LFSR, a ligação LFSR → memória ou retirar o sincronizador do Reset
faz sempre falhar pelo menos um testbench.

## Projeto Vivado e bitstream

```bash
vivado -mode batch -source scripts/build.tcl     # recria vivado/guitarhero e gera bitstreams/guitarhero.bit (~4 min)
```

Abrir com **File > Project > Open** → `vivado/guitarhero/guitarhero.xpr`. Os testbenches estão em *Simulation Sources*
(o ativo é `guitarhero_teste1`; para outro: botão direito → **Set as Top** → **Run Behavioral Simulation**).
Resultado da implementação: 97 LUTs, 158 flip-flops, todas as restrições de tempo cumpridas (WNS = +5,1 ns),
nenhum aviso crítico de CDC (o Reset dos 6 FF do controlador já não vem diretamente da tecla).
O Vivado duplica alguns flip-flops do controlador na implementação (`FF_S0_lopt_replica`, ...) por terem várias cargas;
as réplicas são logicamente iguais e no esquema da síntese aparecem só os 6 flip-flops dos estados.

## Ensaio na Basys3 (Adept → Program `bitstreams/guitarhero.bit`)

| Placa | Sinal |
|---|---|
| BTNU | Reset (põe a máquina em S0) |
| BTNC | Start (carregar e largar começa o jogo) |
| LD0 / LD1 / LD2 | Ready / Beat / Waiting |
| LD10 … LD15 | estados S0 … S5 (um LED por flip-flop) |
| 4 displays | cordas: segmento a (cima), g (meio), d (baixo) ou apagado (pausa); entram à esquerda e avançam para a direita |

Esperado: depois de Reset, LD0 (Ready) aceso, displays apagados e LD11 (S1) aceso. Carregar e largar BTNC: Ready apaga-se,
as cordas começam a entrar pela esquerda a cada 0,5 s, LD1 (Beat) muda de estado em cada passo e a sequência acelera
até um passo a cada 0,2 s. BTNU em qualquer momento volta ao início.

## Decisões face ao rascunho inicial (`Lab2Relatório.docx`)

- A tecla Reset é um botão (BTNU), como pede o enunciado ("2 teclas"), e não um interruptor.
- O temporizador variável foi dividido em `Velocidade` + `Temporizador`, para o temporizador ter a entrada com o
  tempo total a temporizar (`Periodo`), como pede a secção 2.3.
- Estados codificados one-hot (código Q5…Q0 no fluxograma) e equações da realização direta acrescentadas.
- LEDs LD10…LD15 mostram o estado ativo (permitido pela secção 2.4), útil para a demonstração ao docente.
- `SincronizadorReset` entre a tecla e o controlador: o Reset continua a pôr a máquina em S0 de imediato (secção 2.7),
  mas a libertação passa a ser síncrona. Com a tecla ligada diretamente ao PRE/CLR, se fosse largada junto a um flanco,
  FF_S0 podia sair do PRE (e carregar D = 0) antes de FF_S1 sair do CLR e a máquina ficava sem estado ativo (000000),
  sem recuperação. O mesmo podia acontecer ao configurar a FPGA.

## Placa virtual (fpga.dieguscl.com)

Link partilhado: **https://fpga.dieguscl.com/s/UGvQD9BPwA** (separador *Board* → *Run*, aceleração desligada).
O projeto partilhado tem os mesmos ficheiros do Vivado e o topo `placavirtual/guitarhero_virtual.v`
(`GuitarHeroVirtual`), que instancia o `GuitarHero` com tempos reduzidos para o simulador do browser
(~300 mil ciclos/s): passo de 100 000 ciclos (≈0,3–0,5 s), anti-ressalto de 2000 ciclos, varrimento com
`METADE = 250`, e um reset de arranque porque o simulador ignora os valores INIT dos flip-flops.
A aceleração (*Speed-up*) do site tem de ficar desligada: só reduz as constantes das comparações e estragaria o
registo da velocidade (o período mínimo seria reduzido mas o inicial não).

## Relatório

`relatorio/gerar.sh` volta a gerar o PDF: capa oficial (`capa/capa_original.odt`, preenchida por
`fonte/preencher_capa.py`) + corpo gerado por `fonte/gerar.js` (docx-js) a partir dos ficheiros do repositório,
das figuras e dos resultados de `scripts/simula.sh` e `scripts/build.tcl` (correr esses primeiro). Requisitos:
node com o pacote `docx`, LibreOffice com python3-uno e poppler-utils.

- Diagramas (arquitetura, fluxograma, diagrama de estados, diagrama lógico): `relatorio/figuras/*.drawio`, editáveis
  no draw.io. Os `.png` ao lado têm o diagrama embebido (também abrem no draw.io) e regeneram-se com
  `relatorio/fonte/exporta_diagramas.sh` (draw.io desktop + Xvfb).
- Formas de onda (`relatorio/figuras/viv_*_sim.png`): capturas do Vivado com as vistas `<testbench>.wcfg`
  (geradas por `scripts/gera_wcfg.py`; ao correr a simulação no projeto, `scripts/abre_wcfg.tcl` abre a vista do
  testbench que está como top).
- Falta: fotografias do ensaio na placa e confirmação dos resultados (secção 10.4, a vermelho no relatório);
  confirmar a data da capa (`fonte/preencher_capa.py`).
