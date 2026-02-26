# Planejamento de Entrega - V1

## 1. Objetivo
Definir marcos incrementais com ordem de precedência para implementar a V1 com controle de risco.

## 2. Estratégia
1. Construção por fundação técnica primeiro.
2. Entregas pequenas e testáveis.
3. Bloqueio de avanço sem aceite dos critérios de cada marco.

## 3. Marcos

## M0 - Base do projeto
Escopo:
- estrutura de diretórios;
- bootstrap mínimo;
- contratos centrais.

Critérios de aceite:
- projeto inicial executa e encerra sem corromper terminal.

Dependências:
- nenhuma.

## M1 - Engine incremental
Escopo:
- buffers front/back;
- dirty regions;
- diff renderer.

Critérios de aceite:
- eventos de teste atualizam apenas regiões sujas;
- sem redraw full indevido.

Dependências:
- M0.

## M2 - Componentes base
Escopo:
- `Rectangle`, `Shadow`, `Panel`.

Critérios de aceite:
- primitives reutilizáveis com fallback ASCII.

Dependências:
- M1.

## M3 - Menu navegável
Escopo:
- modelo de menu;
- navegação e submenu;
- render por delta de linha.

Critérios de aceite:
- navegação completa;
- mudança de seleção sem redraw full.

Dependências:
- M2.

## M4 - Modal e toast
Escopo:
- modal de status/confirmação;
- toast com fila e timeout.

Critérios de aceite:
- modal bloqueia fundo;
- toast sem artefato no ciclo abrir/fechar.

Dependências:
- M3.

## M5 - Configuração da TUI
Escopo:
- parser `key=value`;
- menu de configuração;
- persistência automática com toast.

Critérios de aceite:
- alteração de tema/tempo persistida com feedback correto.

Dependências:
- M3 e M4.

## M6 - i18n
Escopo:
- PT-BR/EN;
- persistência de idioma.

Critérios de aceite:
- troca em runtime sem inconsistências.

Dependências:
- M5.

## M7 - Integrações externas
Escopo:
- runner seguro;
- ações `install/remove/status`;
- tratamento de timeout/erro.

Critérios de aceite:
- fluxos externos de referência estáveis.

Dependências:
- M4 e M5.

## M8 - Hardening final
Escopo:
- suíte completa de testes;
- ajustes finais de performance;
- revisão documental.

Critérios de aceite:
- critérios de aceite do PRD cumpridos;
- documentação da V1 consolidada.

Dependências:
- M0 a M7.

## 4. Regras de transição de marco
1. Marco só avança quando todos os critérios de aceite forem cumpridos.
2. Regressão crítica reabre o marco anterior relacionado.
3. Toda mudança de escopo deve atualizar este documento e o backlog.
