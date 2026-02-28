# Guia de Operação - V1

## 1. Objetivo
Descrever a operação padrão da V1 (`linux-setup-next`) para execução local, validação funcional e rotina de verificação antes de PR/release.

## 2. Pré-requisitos
1. Bash `>= 4.0`.
2. Terminal com capacidades ANSI mínimas (cursor, clear, hide/show cursor e input não-canônico).
3. Permissão de execução nos scripts do repositório.

## 3. Execução da aplicação
1. Entrar na raiz do projeto:
   - `cd /home/lattes/Documentos/dev/linux-setup/linux-setup-next`
2. Executar:
   - `src/app/main.sh`
3. Comportamento esperado:
   - entrada e saída do alternate screen;
   - render imediato do layout base (header, área central e barra de mensagem);
   - mensagem de bootstrap `linux-setup-next: bootstrap ready` somente quando executado em modo não interativo (não-TTY);
   - restauração de terminal em encerramento normal ou por sinal.

## 4. Rotina de validação automatizada
1. Executar a suíte oficial:
   - `scripts/run_tests_sequential.sh`
2. Critério de aprovação:
   - `Failed: 0`.
3. Resultado de referência da baseline atual:
   - `67/67 PASS` no runner oficial (`scripts/run_tests_sequential.sh`).

## 5. Validação rápida das ações externas de referência
1. Scripts disponíveis:
   - `scripts/keyboards/k380/{install,remove,status}.sh`
   - `scripts/keyboards/k270/{install,remove,status}.sh`
2. Contrato funcional:
   - ações aceitas: `install`, `remove`, `status`;
   - execução com timeout e mapeamento de severidade;
   - saída sanitizada para exibição na UI.

## 6. Checklist operacional pré-PR
1. Branch da história criada a partir de `main` atualizada.
2. Commits no padrão convencional e escopo restrito à história.
3. `CHANGELOG.md` atualizado com `[PR #x]` e `[commit hash]`.
4. Suíte oficial executada sem falhas.
5. Descrição de PR preparada no template oficial.
