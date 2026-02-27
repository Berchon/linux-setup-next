# Changelog

Todas as mudanças relevantes do projeto devem ser registradas neste arquivo.

Este projeto segue o princípio de atualização contínua do changelog:
- todo Pull Request deve incluir atualização do `CHANGELOG.md`;
- a entrada deve descrever o que mudou, impacto e referência da atividade (épico/história/task quando aplicável).
- toda entrada deve incluir referência de rastreabilidade técnica (`PR` e `commit`).

## Formato padrão de entrada
- `- <descrição objetiva da mudança> (E#/H#/T# quando aplicável) [PR #<número>] [commit <hash-curto>]`

Exemplos:
- `- Implementa merge de dirty regions para reduzir redraw (E1/H1.3/T1.3.2) [PR #27] [commit a1b2c3d]`
- `- Corrige limpeza do toast ao encerrar animação (E4/H4.2/T4.2.3) [PR #31] [commit d4e5f6g]`

## Política de versões
- O projeto usa tags SemVer no formato `vMAJOR.MINOR.PATCH` (ex.: `v1.0.0`).
- Cada release no GitHub deve apontar para uma tag SemVer.
- Ao gerar release:
  1. mover itens relevantes de `Unreleased` para a nova seção da versão;
  2. registrar data da release;
  3. manter referências de PR e commit em cada entrada.

## [Unreleased]

### Added
- Estrutura documental inicial do projeto (`PRD`, arquitetura, backlog, testes, padrões, rastreabilidade e planejamento de entrega). [PR MAIN] [commit cb88534]
- Definição de baseline técnico para V1 (Bash >= 4.0, terminal por capacidades, perfil base de 16 cores com upgrade para 256 cores quando disponível). [PR MAIN] [commit cb88534]
- Cria árvore inicial de diretórios base (`src/`, `config/`, `tests/`) para fundação do projeto (E0/H0.1/T0.1.1). [PR #1] [commit 99b4537]
- Cria entrypoint mínimo executável em `src/app/main.sh` com fluxo base de `main` e `cleanup` idempotente por `trap` (E0/H0.1/T0.1.2). [PR #1] [commit f592be5]
- Adiciona `config/ui.conf.example` com todas as chaves obrigatórias da V1 para tema e idioma (E0/H0.1/T0.1.3). [PR #1] [commit b5e86f6]
- Define carregador de módulos com ordem determinística em `src/app/bootstrap.sh`, integrado ao entrypoint em `main.sh` (E0/H0.1/T0.1.4). [PR #1] [commit bc87452]
- Implementa alternate screen on/off no runtime com integração ao ciclo init/cleanup e teste unitário dedicado (E1/H1.1/T1.1.1). [PR #2] [commit 8e49ade]
- Implementa input não-canônico sem echo com snapshot/restauração de `stty` e teste unitário de idempotência (E1/H1.1/T1.1.2). [PR #2] [commit 9a878b8]
- Implementa traps `EXIT`, `INT`, `TERM` e `WINCH` no runtime com cleanup idempotente e cobertura unitária (E1/H1.1/T1.1.3). [PR #2] [commit f5b606c]
- Implementa detecção de capacidades mínimas de terminal por capabilities (sem acoplamento ao nome de `TERM`) e perfil de cor base/256 com testes unitários (E1/H1.1/T1.1.4). [PR #2] [commit 0135136]
- Define template oficial de descrição de PR e formaliza sua obrigatoriedade nos padrões de engenharia. [PR #2] [commit d798b7b]
- Implementa estrutura de `Cell` e buffers front/back com inicialização, indexação e swap em `src/render/cell_buffer.sh` (E1/H1.2/T1.2.1). [PR #3] [commit 297e664]
- Implementa operações base de escrita em buffer (`write_cell` e `write_text` com clipping horizontal) e testes unitários (E1/H1.2/T1.2.2). [PR #3] [commit 3359573]
- Implementa limpeza por retângulo com clipping no viewport (`clear_rect`) e testes unitários de fronteira (E1/H1.2/T1.2.3). [PR #3] [commit 77e1dfb]
- Implementa registro de regiões sujas em `src/render/dirty_regions.sh` com API de inicialização, append, consulta e reset (E1/H1.3/T1.3.1). [PR #4] [commit 14a2b73]
- Implementa merge automático de dirty regions sobrepostas (incluindo cadeias de sobreposição) para reduzir redraw redundante (E1/H1.3/T1.3.2). [PR #4] [commit 0882987]
- Implementa clipping de dirty regions nos limites do viewport e descarte de regiões totalmente fora da tela (E1/H1.3/T1.3.3). [PR #4] [commit 86547c6]
- Compara `front/back` exclusivamente dentro de dirty regions para reduzir o custo de diff por evento (E1/H1.4/T1.4.1). [PR #5] [commit 15d842d]
- Agrupa células alteradas em runs contíguos por estilo (`fg/bg/bold`) para reduzir fragmentação de render (E1/H1.4/T1.4.2). [PR #5] [commit fc760d7]
- Emite ANSI mínimo por run (cursor + estilo somente quando necessário), aplica flush e realiza `swap` de buffers com limpeza de dirty regions (E1/H1.4/T1.4.3). [PR #5] [commit fda9a2f]
- Aplica política de cor baseada em capacidade (`16` cores base com upgrade para `256`) no diff renderer (E1/H1.4/T1.4.4). [PR #5] [commit 388ca0d]
- Implementa primitive `Rectangle` com preenchimento de área e clipping no viewport em `src/components/rectangle.sh`, com teste de componente dedicado (E2/H2.1/T2.1.1). [PR #x] [commit bb9de42]
- Implementa borda configurável `none|single|double` no `Rectangle`, com fallback ASCII-safe e cobertura de testes para estilos e clipping (E2/H2.1/T2.1.2). [PR #x] [commit 8024729]
- Implementa título opcional no `Rectangle` com clipping para área disponível (com e sem borda), validado por testes de componente (E2/H2.1/T2.1.3). [PR #x] [commit 537c03c]
