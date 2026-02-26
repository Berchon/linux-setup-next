# Padrão de Descrição de Pull Request

## 1. Objetivo
Padronizar descrições de PR para garantir contexto mínimo, rastreabilidade e leitura rápida durante revisão.

## 2. Estrutura obrigatória
Toda descrição de PR deve usar exatamente as seções abaixo:

1. `## Resumo`
2. `## O que foi feito`
3. `## Validação executada`
4. `## Impacto`

## 3. Template oficial
```markdown
## Resumo
<escopo da história/épico e tasks cobertas>

## O que foi feito
- <mudança 1>
- <mudança 2>
- <mudança 3>

## Validação executada
- <teste/comando 1>
- <teste/comando 2>
- <teste/comando 3>

## Impacto
- <risco/compatibilidade>
- <próximo passo>
```

## 4. Regras de preenchimento
1. Texto objetivo e curto, sem contexto irrelevante.
2. Citar IDs de backlog quando aplicável (`E#/H#/T#`).
3. Em validação, listar comandos/casos realmente executados.
4. Em impacto, informar risco e próximo passo imediato.
5. A descrição de PR e o resumo devem ser entregues em Markdown.
