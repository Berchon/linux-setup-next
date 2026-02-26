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
- Implementa alternate screen on/off no runtime com integração ao ciclo init/cleanup e teste unitário dedicado (E1/H1.1/T1.1.1). [PR #N/A] [commit N/A]
- Implementa input não-canônico sem echo com snapshot/restauração de `stty` e teste unitário de idempotência (E1/H1.1/T1.1.2). [PR #N/A] [commit N/A]
- Implementa traps `EXIT`, `INT`, `TERM` e `WINCH` no runtime com cleanup idempotente e cobertura unitária (E1/H1.1/T1.1.3). [PR #N/A] [commit N/A]
