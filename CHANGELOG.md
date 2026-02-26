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
- Estrutura documental inicial do projeto (`PRD`, arquitetura, backlog, testes, padrões, rastreabilidade e planejamento de entrega). [PR #N/A] [commit N/A]
- Definição de baseline técnico para V1 (Bash >= 4.0, terminal por capacidades, perfil base de 16 cores com upgrade para 256 cores quando disponível). [PR #N/A] [commit N/A]
