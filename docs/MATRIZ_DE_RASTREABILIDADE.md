# Matriz de Rastreabilidade

## 1. Objetivo
Garantir rastreabilidade completa entre requisitos do PRD, backlog de implementação e cobertura de testes.

## 2. Legenda
- Requisito: ID `RF-*` / `RNF-*`
- Backlog: Épico/História/Task
- Testes: IDs `CT-*`

## 3. Matriz

| Requisito | Backlog (fonte de implementação) | Casos de teste mínimos |
|---|---|---|
| RF-001 Execução em Bash puro | E0/H0.1 + E1/H1.1 | CT-RF001-001, CT-RF001-002 |
| RF-002 Modo de tela/input | E1/H1.1 | CT-RF002-001, CT-RF002-002 |
| RF-003 Render incremental | E1/H1.3 + E1/H1.4 + E3/H3.2 | CT-RF003-001, CT-RF003-002 |
| RF-004 Componentização visual | E2/H2.1 + E2/H2.2 + E2/H2.3 | CT-RF004-001 |
| RF-005 Composição de componentes | E2/H2.3 + E4/H4.2 | CT-RF005-001 |
| RF-006 Configuração em memória | E5/H5.1 | CT-RF006-001 |
| RF-007 Menu de configurações + autosave | E5/H5.2 | CT-RF007-001, CT-RF007-002 |
| RF-008 Navegação hierárquica | E3/H3.1 + E3/H3.3 | CT-RF008-001 |
| RF-009 Modal e diálogo | E4/H4.1 | CT-RF009-001 |
| RF-010 Toast | E4/H4.2 | CT-RF010-001 |
| RF-011 Scripts externos | E7/H7.1 + E7/H7.2 + E7/H7.3 | CT-RF011-001 |
| RF-012 i18n PT/EN | E6/H6.1 + E6/H6.2 | CT-RF012-001 |
| RF-013 Fallback ASCII | E0/H0.2 + E2/H2.1 | CT-RF013-001 |
| RNF-001 Fluidez | E1 + E3 + E8/H8.1 | CT-PERF-001, CT-PERF-002 |
| RNF-002 Compatibilidade | E1/H1.1 + E8/H8.1 | CT-RNF002-001, CT-COMP-001, CT-COMP-002, CT-COMP-003, CT-COMP-004 |
| RNF-003 Confiabilidade | E1/H1.1 + E8/H8.1 | CT-REL-001 |
| RNF-004 Manutenibilidade | E0/H0.2 + padrões de engenharia | Revisão técnica + checklist |
| RNF-005 Documentação | E8/H8.2 | Auditoria documental |

## 4. Catálogo mínimo de casos adicionais

## 4.1 Casos funcionais complementares
- CT-RF001-001: iniciar app em Bash suportado.
- CT-RF001-002: validar ausência de dependências obrigatórias não previstas.
- CT-RF002-001: confirmar entrada/saída do alternate screen.
- CT-RF002-002: confirmar restauração de `stty` em `CTRL+C`.
- CT-RF004-001: validar render de componentes base sem acoplamento.
- CT-RF005-001: validar `Toast` composto por primitive de retângulo/sombra.
- CT-RF006-001: validar leitura única de configuração no boot.
- CT-RF008-001: validar abertura/fechamento de submenu.
- CT-RF013-001: validar fallback ASCII para borda e ícones.

## 4.2 Casos não funcionais
- CT-PERF-001: medir tempo por evento simples.
- CT-PERF-002: medir bytes ANSI emitidos por evento simples.
- CT-COMP-001: validar execução em matriz de tamanhos de terminal.
- CT-COMP-002: validar degradação graciosa com capacidades opcionais ausentes.
- CT-COMP-003: validar operação correta em perfil de 16 cores.
- CT-COMP-004: validar upgrade automático para 256 cores quando disponível.
- CT-REL-001: validar cleanup idempotente em saídas normais e por sinal.

## 5. Regras de governança
1. Requisito novo só pode entrar se tiver mapeamento para backlog e testes.
2. Task concluída sem cobertura mínima não pode ser marcada como finalizada.
3. Mudança de requisito exige atualização imediata desta matriz.
