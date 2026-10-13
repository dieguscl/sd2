# SD2 - 1.º Trabalho de Laboratório

**Sistemas Digitais II · LEEC · ESTSetúbal/IPS · 2026/27**
Gestão do *display* da placa Basys3 (Tutorial Digital e Vivado).

Trabalho completo das três aulas do enunciado:

| Aula | Módulos | Pasta |
|---|---|---|
| 1 | Multiplexer 4x1 (Digital → Verilog) | `multiplexer4x1/` |
| 1 | Descodificador 2x4 com *enables* individuais (Digital → Verilog) | `descodificador2x4/` |
| 1 | Multiplexer 16x4 por hierarquia de módulos (4 × multiplexer 4x1) | `multiplexer16x4/` |
| 2 | Transcodificador para 7 segmentos (símbolos originais "rdLEC-") e circuito de ensaio `displayBCD` | `transcod7seg/` |
| 2 | Registo de 4 bits com *clear* e *enable* (4 primitivas FDCE) | `registo4/` |
| 2 | Divisor de *clock* (100 MHz → 2 kHz, parametrizável) | `divisorclock/` |
| 2 | Contador de módulo 4 | `contador4/` |
| 3 | Controlador dos 4 *displays* (Fig. 31) e circuito de teste na placa (Fig. 32) | `controlodisplays/` |

O relatório final está em **`relatorio/SD2_Lab1_Relatorio.pdf`** (capa oficial + corpo).

Ferramentas: Digital v0.31 (H. Neemann), Vivado 2026.1 (WebPACK), FPGA `xc7a35ticpg236-1L` (Basys3).

## Estrutura

```
digital/            Esquemas do Digital (.dig), Verilog exportado e .svg
<módulo>/           <módulo>.v, <módulo>_teste1.v (testbench), <testbench>.wcfg (vista das formas de onda)
                    e, se o módulo vai à placa, o ficheiro de restrições .xdc
vivado/<p>/<p>.xpr  Projetos Vivado (multiplexer4x1, descodificador2x4, multiplexer16x4, displayBCD, controlodisplays)
simulacao/          Formas de onda (VCD) de todas as simulações e resultados.txt (mensagem final de cada testbench)
bitstreams/         Ficheiros .bit para a Basys3; relatorios/ com utilização, tempos e metodologia de cada projeto
scripts/            build.tcl (recria tudo), teste_mutacoes.py, gera_wcfg.py, gen_dig.py, ExportVerilog.java, fdce_modelo.v
relatorio/          Relatório (PDF e DOCX do corpo), capa oficial preenchida (.odt), figuras e geradores
```

## Projetos Vivado

| Projeto | Topo | Testbenches (Simulation Sources) |
|---|---|---|
| `multiplexer4x1` | `multiplexer4x1` | `multiplexer4x1_teste1` |
| `descodificador2x4` | `descodificador2x4` | `descodificador2x4_teste1` |
| `multiplexer16x4` | `multiplexer16x4` | `multiplexer16x4_teste1` |
| `displayBCD` | `displayBCD` | `transcod7seg_teste1`, `displayBCD_teste1` |
| `controlodisplays` | `TesteDisplays` | `registo4_teste1`, `divisorclock_teste1`, `contador4_teste1`, `controlodisplays_teste1`, `testedisplays_teste1` |

Abrir com **File > Project > Open** e escolher `vivado/<projeto>/<projeto>.xpr`. Os ficheiros fonte estão nas pastas dos módulos e são referidos por caminhos relativos.
Para simular um testbench: em *Simulation Sources*, botão direito no testbench → **Set as Top** → **Run Behavioral Simulation**. A janela das formas de onda abre logo com os sinais mais importantes (ficheiro `.wcfg`).

Os `.xpr` foram criados com o Vivado 2026.1; se não abrirem noutra versão (por exemplo, a 2025.1 do laboratório), recriam-se com o comando abaixo, que só depende das pastas dos módulos.

Para recriar todos os projetos de raiz, correr todas as simulações e gerar todos os bitstreams:

```bash
vivado -mode batch -source scripts/build.tcl                       # todos (cerca de 25 min)
vivado -mode batch -source scripts/build.tcl -tclargs displayBCD   # só um projeto
```

Todos os testbenches verificam as saídas automaticamente e terminam com `Simulacao OK` ou `Simulacao FALHOU` (ver `simulacao/resultados.txt`).

## Ensaio na Basys3 (Adept → Program)

| Bitstream | Como ensaiar |
|---|---|
| `multiplexer4x1.bit` | SW15/SW14 escolhem a tecla (00 BTND, 01 BTNR, 10 BTNC, 11 BTNL); LD7 acende enquanto essa tecla estiver premida |
| `descodificador2x4.bit` | SW15/SW14 escolhem a saída, SW0 a SW3 são os *enables*; acende no máximo um LED (LD0 a LD3) |
| `multiplexer16x4.bit` | LD3 a LD0 mostram SW3 a SW0 (sem teclas), SW7 a SW4 (BTNR), SW11 a SW8 (BTNL) ou SW15 a SW12 (BTNL+BTNR) |
| `displayBCD.bit` | SW3 a SW0 = símbolo; SW15 a SW12 escolhem os *displays* acesos |
| `controlodisplays.bit` | SW10 = EN; valor em SW3 a SW0; ligar/desligar SW15…SW12 carrega o *display* da esquerda…direita; SW11 carrega os pontos decimais; BTNC = *clear* |

Exemplo no controlador: SW10 ligado; 0010 + SW15, 0000 + SW14, 0010 + SW13, 0110 + SW12 → **2026**; 0100 + SW11 → **20.26**.

## Testes de mutações

`python3 scripts/teste_mutacoes.py` (precisa do Icarus Verilog) introduz, um de cada vez, 30 erros típicos nos módulos das aulas 2 e 3 (clear síncrono, flanco errado, ânodos não negados, registos trocados, …) e confirma que o testbench respetivo deteta todos: **30/30**.

## Relatório

`relatorio/gerar.sh` volta a gerar o PDF (capa oficial `relatorio/capa/capa_original.odt` preenchida por `fonte/preencher_capa.py` + corpo gerado por `fonte/gerar.js` a partir das figuras, dos ficheiros do repositório e dos resultados do Vivado). Os dados da capa estão em `relatorio/fonte/preencher_capa.py`.

Falta fazer no laboratório: o ensaio físico na placa, as fotografias (no relatório estão assinaladas a vermelho as figuras a inserir) e a apresentação ao docente.
