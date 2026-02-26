# Padrões de Engenharia - linux-setup-next

## 1. Objetivo
Estabelecer padrões de código, Git/GitHub, documentação e testes para garantir qualidade técnica consistente desde o início.

## 2. Linguagem e nomenclatura
1. Código-fonte: inglês (variáveis, funções, componentes, mensagens internas).
2. Documentação da fase de desenvolvimento: Português (Brasil).
3. Nomes devem ser descritivos e específicos.
4. Evitar abreviações ambíguas.

## 3. Práticas de Bash
1. Shebang padrão: `#!/usr/bin/env bash`.
2. Preferir funções pequenas e coesas.
3. Quoting obrigatório para variáveis e argumentos.
4. Evitar `eval` e construções inseguras.
5. Separar claramente estado, render e execução de ações externas.

## 4. Render e performance
1. Sem redraw full para eventos simples.
2. Sem leitura de configuração durante render.
3. Sem parse ANSI completo por frame como estratégia principal.
4. Dirty regions e diff por célula são mandatórios.

## 5. Padrões de componentes
1. Todo componente deve ter API clara de render e invalidação.
2. Componentes complexos devem compor componentes base.
3. `Rectangle` e `Shadow` são primitives obrigatórias de composição.
4. Todas as opções visuais devem ser configuráveis por tema quando aplicável.

## 6. Configuração
1. Arquivo `key=value` em `config/`.
2. Carregamento único no startup.
3. Persistência automática ao alterar no menu de configurações.
4. Em caso de erro de escrita, emitir toast e manter estado consistente.

## 7. Compatibilidade visual
1. Base visual ASCII-safe.
2. Fallback para bordas/ícones quando necessário.
3. Não depender de Unicode para funcionamento correto da V1.
4. Perfil base de cor em 16 cores, com upgrade automático para 256 cores quando disponível.

## 7.1 Baseline de runtime
1. Bash mínimo oficial: `>= 4.0`.
2. Não exigir `xterm-256color` por nome de `TERM`.
3. Exigir capacidades mínimas de terminal e degradar com segurança quando necessário.

## 8. Git e GitHub
## 8.0 Versionamento e releases
1. O projeto adota versionamento semântico (`SemVer`) com tags no formato `vMAJOR.MINOR.PATCH` (ex.: `v1.0.0`).
2. Toda release publicada no GitHub deve corresponder a uma tag SemVer.
3. A seção `Unreleased` do `CHANGELOG.md` deve ser promovida para a versão no momento da release.
4. Incremento de versão:
   - `MAJOR`: quebra de compatibilidade;
   - `MINOR`: nova funcionalidade compatível;
   - `PATCH`: correções compatíveis.

## 8.1 Branching
1. `main` protegida.
2. Trabalho sempre em branches de feature/fix/docs.
3. Merge em `main` somente via Pull Request.

## 8.2 Commits
1. Mensagens em inglês.
2. Uma linha, descritiva, no padrão convencional.
3. Formato recomendado: `type(scope): summary`.

Tipos recomendados:
- `feat`
- `fix`
- `refactor`
- `docs`
- `test`
- `chore`

Exemplos:
- `feat(render): add dirty-region diff renderer`
- `fix(menu): redraw only previous and next selected rows`
- `docs(prd): define v1 scope and acceptance criteria`

## 8.3 Pull Request
1. Escopo pequeno e objetivo.
2. Deve incluir contexto, mudança, riscos e evidências de teste.
3. Não misturar refatoração estrutural com feature sem necessidade.
4. Deve atualizar obrigatoriamente o `CHANGELOG.md`.
5. Entrada de changelog do PR deve conter referência ao número do PR e ao hash curto do commit principal.

## 9. Revisão de código
Checklist mínimo:
1. Contratos de módulo respeitados.
2. Sem regressão de performance evidente.
3. Sem regressão de cleanup terminal.
4. Testes relevantes atualizados e passando.
5. Documentação atualizada no mesmo PR.
6. `CHANGELOG.md` atualizado no mesmo PR.
7. Entrada do changelog com `PR` e `commit` no formato definido.

## 10. Documentação
1. Tom técnico, objetivo e consistente.
2. Acentuação e ortografia corretas.
3. Evitar redundância.
4. Toda decisão arquitetural relevante deve ser registrada.

## 11. Testes
1. Toda funcionalidade nova deve vir com testes proporcionais ao risco.
2. Bugs corrigidos devem ganhar teste de regressão.
3. Testes de terminal devem validar restauração de estado ao sair.

## 12. Gestão de mudanças
1. Requisito alterado -> atualizar PRD e backlog.
2. Arquitetura alterada -> atualizar documento de arquitetura.
3. Comportamento alterado -> atualizar plano de testes e casos.

## 13. Critérios de bloqueio
Não pode ser aprovado:
1. código sem documentação mínima da mudança;
2. feature sem validação funcional;
3. regressão de fluidez em interações comuns;
4. mudança que quebra padrão de nomenclatura em inglês.
