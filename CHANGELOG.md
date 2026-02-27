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
- Implementa primitive `Rectangle` com preenchimento de área e clipping no viewport em `src/components/rectangle.sh`, com teste de componente dedicado (E2/H2.1/T2.1.1). [PR #6] [commit bb9de42]
- Implementa borda configurável `none|single|double` no `Rectangle`, com fallback ASCII-safe e cobertura de testes para estilos e clipping (E2/H2.1/T2.1.2). [PR #6] [commit 8024729]
- Implementa título opcional no `Rectangle` com clipping para área disponível (com e sem borda), validado por testes de componente (E2/H2.1/T2.1.3). [PR #6] [commit 537c03c]
- Ajusta render de bordas para suportar box-drawing Unicode (`single`/`double`) com fallback ASCII configurável por charset (`auto|unicode|ascii`) no `Rectangle` (E2/H2.1). [PR #6] [commit 4c59378]
- Implementa primitive `Shadow` com offset configurável (`dx`, `dy`) e cobertura de testes de componente para offsets positivos, zero e negativos (E2/H2.2/T2.2.1). [PR #7] [commit 6ecc1d0]
- Implementa clipping da `Shadow` no viewport e regras de sobreposição para a área visível da sombra (E2/H2.2/T2.2.2). [PR #7] [commit 70d5298]
- Implementa ativação/desativação de `Shadow` por componente via flag de render (`enabled`) com suporte a flags numéricas e textuais (E2/H2.2/T2.2.3). [PR #7] [commit 5cd60a6]
- Implementa `Panel` como composição de `Rectangle + Shadow` com render integrado e teste de componente dedicado (E2/H2.3/T2.3.1). [PR #8] [commit 14e9cea]
- Adiciona padding interno configurável por lado no `Panel` com cálculo explícito de área de conteúdo (`content rect`) e cobertura de casos limite (E2/H2.3/T2.3.2). [PR #8] [commit 40e3ad6]
- Expõe API de conteúdo interno no `Panel` via callback com passagem de `content rect` e validação de callback inexistente (E2/H2.3/T2.3.3). [PR #8] [commit bdca513]
- Define modelo de nós de menu com estrutura `id/parent/label/desc/action`, validações de consistência e consultas de hierarquia (E3/H3.1/T3.1.1). [PR #9] [commit 55ec613]
- Implementa pilha de navegação para submenu com operações de entrar/voltar e validação de escopo hierárquico (E3/H3.1/T3.1.2). [PR #9] [commit 7a9b30c]
- Adiciona runner sequencial de testes com descoberta automática, execução por categoria e resumo de progresso/pass-fail no terminal. [PR #10] [commit 9af13e4]
- Implementa render de linha de menu com estilo de seleção e clipping por largura em `src/components/menu.sh` (E3/H3.2/T3.2.1). [PR #11] [commit 233b4dd]
- Implementa atualização de seleção por delta com invalidação apenas da linha anterior e da nova linha selecionada (E3/H3.2/T3.2.2). [PR #11] [commit 5b9ec0a]
- Implementa viewport/scroll de menu com ajuste de janela e invalidação local do viewport somente quando há mudança de scroll (E3/H3.2/T3.2.3). [PR #11] [commit 7f5a07e]
- Implementa mapeamento de teclas de navegação para ações canônicas (`up/down/left/right/enter/back/quit`) no menu (E3/H3.3/T3.3.1). [PR #12] [commit 4fe569b]
- Implementa debounce/coalescência de repetição para ações de navegação com janela configurável de tempo (E3/H3.3/T3.3.2). [PR #12] [commit d237b56]
- Implementa resolução de fluxo de saída via tecla `Q`, item de sair e sinais de término (`INT/TERM/HUP/EXIT`) (E3/H3.3/T3.3.3). [PR #12] [commit 734ee40]
- Implementa modal de texto com estado dedicado e bloqueio de input de fundo durante atividade do modal (E4/H4.1/T4.1.1). [PR #13] [commit 8c65556]
- Implementa modal de confirmação com foco explícito de botão (`confirm/cancel`), alternância de foco e resolução de ação (E4/H4.1/T4.1.2). [PR #13] [commit 17c5eb5]
- Implementa regras de teclado restritas por contexto de modal (texto/confirmação), com consumo de input enquanto modal está ativo (E4/H4.1/T4.1.3). [PR #13] [commit ef976b8]
- Implementa fila FIFO para notificações toast com ativação sequencial do próximo item após dismiss (E4/H4.2/T4.2.1). [PR #14] [commit 5de7c0f]
- Adiciona timeout configurável para toast com fallback seguro para valores ausentes/inválidos (E4/H4.2/T4.2.2). [PR #14] [commit ce01080]
- Implementa render incremental de toast com marcação de dirty region e limpeza correta da área ao fechar (E4/H4.2/T4.2.3). [PR #14] [commit b950f76]
