# Plano de Testes - linux-setup-next

## 1. Objetivo
Validar funcionalidade, performance, robustez e compatibilidade da TUI em Bash puro com foco em renderização incremental e estabilidade de terminal.

## 2. Princípios
1. Testar por risco e por impacto.
2. Automatizar tudo que for repetível.
3. Garantir evidência objetiva para cada requisito do PRD.
4. Evitar regressão de terminal (cleanup/stty/alternate screen).

## 3. Níveis de teste
## 3.1 Testes unitários
Escopo: funções puras e utilitários sem dependência de terminal real.
Exemplos:
- parser `key=value`;
- validação de schema;
- normalização de idioma;
- merge de dirty regions;
- clipping de retângulos.

## 3.2 Testes de componente
Escopo: primitives e componentes visuais isolados.
Exemplos:
- `Rectangle` com borda `none/single/double`;
- `Shadow` com clipping;
- `Panel` com padding;
- render de uma linha de menu selecionada/não selecionada.

## 3.3 Testes de integração
Escopo: módulos trabalhando juntos.
Exemplos:
- loop de input + menu + render incremental;
- modal bloqueando fundo;
- toast em fila com timeout;
- persistência de configuração com toast de retorno.

## 3.4 Testes E2E (terminal)
Escopo: fluxo completo em PTY.
Exemplos:
- navegar até submenu e voltar;
- executar ação externa e validar feedback;
- trocar idioma e persistir;
- sair com `q` e `CTRL+C` preservando terminal.

## 3.5 Testes de performance
Escopo: custo de eventos comuns.
Métricas:
- tempo de processamento por evento;
- número de células alteradas por evento;
- quantidade de bytes ANSI emitidos.

## 4. Matriz de compatibilidade
## 4.1 Bash
- Bash 4.x (mínimo oficial: 4.0)
- Bash 5.x

## 4.2 Tamanho de terminal
- 50x14
- 80x24
- 120x40
- resize agressivo

## 4.3 Capacidades de terminal
- ANSI básico
- alternate screen disponível e indisponível
- 16 cores (perfil base)
- 256 cores quando disponível (`tput colors >= 256`)
- com e sem suporte avançado de tema

## 4.4 Dependências opcionais
- com e sem utilitários opcionais de teclado externo.

## 5. Casos obrigatórios por requisito

## CT-RF003-001 (render incremental)
- Cenário: mover seleção para baixo sem scroll.
- Esperado: apenas duas linhas de menu invalidadas e redesenhadas.

## CT-RF003-002 (sem redraw full indevido)
- Cenário: 20 eventos de navegação simples.
- Esperado: zero redraw full fora de resize/layout change.

## CT-RF007-001 (persistência automática)
- Cenário: alterar cor do menu nas configurações.
- Esperado: arquivo salvo automaticamente e toast de sucesso.

## CT-RF007-002 (erro de persistência)
- Cenário: simular falha de escrita.
- Esperado: toast de erro e estado consistente em memória.

## CT-RF009-001 (modal bloqueia fundo)
- Cenário: abrir modal e pressionar setas de menu.
- Esperado: menu não muda enquanto modal estiver ativo.

## CT-RF010-001 (fila de toast)
- Cenário: disparar 3 toasts em sequência.
- Esperado: exibição FIFO com tempos corretos e limpeza visual.

## CT-RF011-001 (script timeout)
- Cenário: ação externa excede timeout.
- Esperado: retorno controlado, mensagem clara e sem travar UI.

## CT-RF012-001 (troca de idioma)
- Cenário: trocar PT -> EN -> PT.
- Esperado: textos atualizados e persistência entre execuções.

## CT-RNF002-001 (capacidade sem acoplamento a TERM)
- Cenário: executar com nomes distintos de `TERM` que ofereçam capacidades mínimas.
- Esperado: aplicação funcional sem bloqueio por nome de terminal.

## 6. Critérios de aceite de performance
1. Evento simples de seleção: <= 16 ms alvo em 80x24 (máquina de referência).
2. Evento de abertura de modal/submenu: <= 33 ms alvo.
3. Sem crescimento não controlado de bytes ANSI emitidos por evento simples.

## 7. Estratégia de automação
1. Scripts de teste em Bash para manter compatibilidade de stack.
2. Harness simples com assertivas padronizadas (`assert_eq`, `assert_contains`, `assert_rc`).
3. Execução em lote por categoria (`unit`, `component`, `integration`, `e2e`, `perf`).
4. Runner oficial para execução manual sequencial: `scripts/run_tests_sequential.sh`.
5. Todo novo teste automatizado deve ser adicionado em `tests/` com nome `*_test.sh`; o runner oficial faz descoberta automática, então não existe lista manual de registro por arquivo.

## 8. Evidências de teste
Cada história deve anexar:
1. lista de casos executados;
2. resultado (PASS/FAIL);
3. logs resumidos de falhas;
4. correção aplicada (se houver).

## 9. Definição de pronto para release V1
1. 100% dos casos críticos aprovados.
2. 0 falha bloqueante aberta.
3. critérios de performance atingidos ou risco formalmente aceito por você.
4. documentação atualizada conforme comportamento final.

## 10. Testes manuais obrigatórios por entrega
1. iniciar, navegar e sair com terminal restaurado.
2. resize contínuo durante navegação.
3. abrir/fechar modal repetidamente.
4. fila de toast em sequência rápida.
5. alteração de configuração com salvamento automático.

## 11. Casos não funcionais complementares
- CT-COMP-001: validar execução em matriz de tamanhos de terminal.
- CT-COMP-002: validar degradação graciosa com capacidades opcionais ausentes.
- CT-COMP-003: validar operação correta em perfil de 16 cores.
- CT-COMP-004: validar upgrade automático para 256 cores quando disponível.
- CT-REL-001: validar cleanup idempotente em saídas normais e por sinal.
