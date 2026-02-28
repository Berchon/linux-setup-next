# Troubleshooting - V1

## 1. Objetivo
Registrar diagnóstico rápido e ações corretivas para os problemas mais comuns de execução e validação da TUI.

## 2. Terminal não restaura corretamente após interrupção
Sintomas:
- cursor invisível;
- terminal sem echo;
- comportamento estranho após `CTRL+C`.

Ações:
1. Executar reset básico do terminal:
   - `stty sane`
2. Limpar e reabrir sessão de terminal, se necessário.
3. Reexecutar `src/app/main.sh` e validar saída limpa.

## 3. Falha por capacidade mínima de terminal
Sintomas:
- inicialização abortada por ambiente sem capabilities esperadas.

Ações:
1. Validar variável `TERM` atual:
   - `echo "$TERM"`
2. Testar em terminal com suporte ANSI básico.
3. Executar `tests/unit/runtime_terminal_capabilities_test.sh` para confirmar comportamento esperado.

## 4. Testes falhando localmente
Sintomas:
- runner sequencial reporta `Failed > 0`.

Ações:
1. Rodar novamente para confirmar reprodutibilidade:
   - `scripts/run_tests_sequential.sh`
2. Rodar teste isolado reportado no log.
3. Verificar regressões em módulos relacionados (`src/` e `tests/` da mesma feature).

## 5. Ação externa falha com timeout
Sintomas:
- retorno de timeout em ação `install/remove/status`.

Ações:
1. Confirmar script-alvo existente em `scripts/keyboards/...`.
2. Verificar permissões de execução:
   - `chmod +x scripts/keyboards/<device>/<action>.sh`
3. Validar cenários de timeout e severidade nos testes:
   - `tests/unit/external_runner_timeout_test.sh`
   - `tests/integration/external_runner_reference_actions_integration_test.sh`

## 6. Mensagem de i18n inesperada (fallback de chave)
Sintomas:
- exibição do próprio ID da chave ou fallback em PT.

Ações:
1. Verificar presença da chave em:
   - `src/i18n/locale_pt.sh`
   - `src/i18n/locale_en.sh`
2. Validar fallback automatizado:
   - `tests/unit/i18n_fallback_test.sh`

## 7. Referências
- `docs/GUIA_DE_OPERACAO.md`
- `docs/PLANO_DE_TESTES.md`
- `docs/RELATORIO_H8.1_TESTES_FINAIS.md`
