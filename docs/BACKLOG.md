# Backlog - Épicos, Histórias e Tasks

## 1. Regras de execução
1. Ordem de precedência obrigatória.
2. Um item em progresso por vez no nível de história.
3. Cada história deve fechar com evidência de teste.
4. Sem avanço para próxima história sem aceite da atual.

## 2. Visão macro de precedência
1. E0 - Fundação do projeto
2. E1 - Núcleo de terminal e render incremental
3. E2 - Componentes base
4. E3 - Navegação e menu
5. E4 - Modal, diálogo e toast
6. E5 - Configuração da TUI
7. E6 - i18n
8. E7 - Integração com scripts externos
9. E8 - Hardening e validação final da V1
10. E9 - Paridade funcional com legacy para release v1.0.0

## 3. Épicos detalhados

## E0 - Fundação do projeto
Objetivo: estabelecer estrutura, contratos e padrões antes de codificar funcionalidades.

### H0.1 - Estrutura inicial
- T0.1.1 Criar árvore de diretórios `src/`, `config/`, `tests/`, `docs/`.
- T0.1.2 Criar entrypoint mínimo (`src/app/main.sh`).
- T0.1.3 Criar arquivo de configuração exemplo (`config/ui.conf.example`).
- T0.1.4 Definir carregador de módulos com ordem determinística.

### H0.2 - Contratos e convenções
- T0.2.1 Definir contrato de componentes.
- T0.2.2 Definir contrato de eventos.
- T0.2.3 Definir contrato de integração externa (`install/remove/status`).
- T0.2.4 Definir política de fallback ASCII.

Critério de saída E0:
- Projeto inicial executa, carrega módulos e encerra com cleanup válido.

## E1 - Núcleo de terminal e render incremental
Objetivo: criar engine de render eficiente e previsível.

### H1.1 - Terminal runtime
- T1.1.1 Implementar alternate screen on/off.
- T1.1.2 Implementar input não-canônico sem echo.
- T1.1.3 Implementar traps (`EXIT`, `INT`, `TERM`, `WINCH`) com idempotência.
- T1.1.4 Implementar detecção de capacidades mínimas de terminal sem depender do nome de `TERM`.

### H1.2 - Estruturas de buffer
- T1.2.1 Implementar `Cell` e buffers front/back.
- T1.2.2 Implementar operações base de escrita em buffer.
- T1.2.3 Implementar limpeza por retângulo.

### H1.3 - Dirty regions
- T1.3.1 Implementar registro de regiões sujas.
- T1.3.2 Implementar merge de regiões sobrepostas.
- T1.3.3 Implementar clipping nos limites da tela.

### H1.4 - Diff renderer
- T1.4.1 Comparar front/back apenas em regiões sujas.
- T1.4.2 Agrupar runs por estilo.
- T1.4.3 Emitir ANSI mínimo e swap de buffers.
- T1.4.4 Aplicar política de cor com base em capacidade (16 cores base, 256 quando disponível).

Critério de saída E1:
- Prova de render parcial funcionando com teste automatizado.

## E2 - Componentes base
Objetivo: entregar primitives reutilizáveis.

### H2.1 - Rectangle
- T2.1.1 Preenchimento de área.
- T2.1.2 Borda (`none|single|double`) com fallback ASCII.
- T2.1.3 Título opcional com clipping.

### H2.2 - Shadow
- T2.2.1 Offset configurável (`dx`, `dy`).
- T2.2.2 Regras de clipping e sobreposição.
- T2.2.3 Ativação/desativação por componente.

### H2.3 - Panel
- T2.3.1 Composição `Rectangle + Shadow`.
- T2.3.2 Padding interno configurável.
- T2.3.3 API de conteúdo interno.

Critério de saída E2:
- Componentes base estáveis e validados por testes de componente.

## E3 - Navegação e menu
Objetivo: implementar menu hierárquico com atualização mínima.

### H3.1 - Modelo de menu
- T3.1.1 Definir estrutura de nós (`id`, `parent`, `label`, `desc`, `action`).
- T3.1.2 Implementar pilha de navegação (submenu).

### H3.2 - Render do menu
- T3.2.1 Implementar render de linha de menu.
- T3.2.2 Implementar atualização de seleção por delta (linha antiga + linha nova).
- T3.2.3 Implementar viewport/scroll com invalidação local.

### H3.3 - Input de navegação
- T3.3.1 Mapear teclas de navegação.
- T3.3.2 Debounce/coalescência de repetição.
- T3.3.3 Fluxo de sair (`Q`, item sair, sinais).

Critério de saída E3:
- Navegação completa sem redraw full em eventos simples.

## E4 - Modal, diálogo e toast
Objetivo: concluir feedback e interação contextual.

### H4.1 - Modal
- T4.1.1 Modal de texto com bloqueio de fundo.
- T4.1.2 Modal de confirmação com foco de botão.
- T4.1.3 Regras de teclado restritas por contexto.

### H4.2 - Toast
- T4.2.1 Fila FIFO.
- T4.2.2 Timeout configurável.
- T4.2.3 Render incremental com limpeza correta ao fechar.

### H4.3 - Estado e composição
- T4.3.1 Integrar modal/toast ao z-order.
- T4.3.2 Evitar artefatos em sobreposição e resize.

Critério de saída E4:
- Fluxos de modal/toast estáveis com testes de regressão visual.

## E5 - Configuração da TUI
Objetivo: tornar estilo/comportamento configuráveis e persistentes.

### H5.1 - Arquivo `key=value`
- T5.1.1 Implementar parser robusto (`key=value`, comentários e linhas vazias).
- T5.1.2 Validar schema e aplicar defaults.
- T5.1.3 Carregar uma vez no boot e manter em memória.

### H5.2 - Menu de configurações
- T5.2.1 Adicionar árvore de configurações na UI.
- T5.2.2 Implementar alteração de opções por teclado.
- T5.2.3 Persistir automaticamente após alteração.
- T5.2.4 Emitir toast de sucesso/falha.

### H5.3 - Chaves obrigatórias
- T5.3.1 Tema de wallpaper.
- T5.3.2 Tema de menu/modal/toast.
- T5.3.3 Borda e sombra por componente.
- T5.3.4 TTL do toast.

Critério de saída E5:
- Configuração editável via UI e persistência automática validada.

## E6 - i18n
Objetivo: suportar PT-BR e EN sem acoplamento com lógica.

### H6.1 - Dicionários
- T6.1.1 Centralizar chaves de texto.
- T6.1.2 Criar catálogos PT/EN.
- T6.1.3 Definir fallback de chave ausente.

### H6.2 - Runtime de idioma
- T6.2.1 Carregar idioma da configuração.
- T6.2.2 Permitir troca em runtime via menu.
- T6.2.3 Persistir alteração com toast.

Critério de saída E6:
- Troca de idioma sem reiniciar e sem textos hardcoded fora do i18n.

## E7 - Integração com scripts externos
Objetivo: executar ações reais com segurança e previsibilidade.

### H7.1 - Runner seguro
- T7.1.1 Resolver caminho de scripts permitido.
- T7.1.2 Executar com timeout.
- T7.1.3 Capturar e sanitizar saída.

### H7.2 - Mapeamento de estado
- T7.2.1 Mapear `exit code` para severidade.
- T7.2.2 Exibir resultado em modal/toast conforme ação.
- T7.2.3 Tratar falta de dependência opcional sem quebrar app.

### H7.3 - Ações de referência
- T7.3.1 Integrar K380.
- T7.3.2 Integrar K270.
- T7.3.3 Preservar comportamentos de validação (instalado/remoção/confirmação).

Critério de saída E7:
- Fluxos externos de V1 completos e estáveis.

## E8 - Hardening e validação final da V1
Objetivo: fechar qualidade, performance e documentação.

### H8.1 - Testes finais
- T8.1.1 Rodar suíte completa (unit/component/integration/e2e/perf).
- T8.1.2 Fechar regressões.
- T8.1.3 Consolidar matriz de compatibilidade.

### H8.2 - Documentação final da fase
- T8.2.1 Revisão técnica completa em PT-BR.
- T8.2.2 Atualizar guias de operação e troubleshooting.
- T8.2.3 Preparar backlog pós-V1.

Critério de saída E8:
- V1 pronta para uso com critérios de aceite totalmente cumpridos.

## 4. Dependências entre épicos
- `E1` depende de `E0`.
- `E2` depende de `E1`.
- `E3` depende de `E2`.
- `E4` depende de `E2` e `E3`.
- `E5` depende de `E0` e `E3`.
- `E6` depende de `E5` (idioma em configuração) e `E3`.
- `E7` depende de `E3` e `E4`.
- `E8` depende de `E0` a `E7`.
- `E9` depende de `E0` a `E8`.

## 5. Definição de pronto por história
1. Código implementado e revisado.
2. Testes automatizados relevantes passando.
3. Teste manual do fluxo validado.
4. Documentação atualizada.
5. `CHANGELOG.md` atualizado com a mudança da história.
6. Aprovado por você antes de avançar.

## 6. Backlog pós-V1 (paridade para release v1.0.0)
Objetivo: lançar `v1.0.0` quando o `linux-setup-next` rodar como o `linux-setup-legacy/menu.sh`, preservando todas as funcionalidades essenciais.

Princípios:
1. Priorizar entrega da aplicação funcional antes de novas features.
2. Manter implementação em camadas modulares do `next`, usando o `legacy` como referência de comportamento.
3. Fechar cada história com evidência automatizada e checklist de paridade manual.

Definição de paridade funcional (`legacy -> next`):
1. Fluxos principais de navegação e submenus equivalentes.
2. Ações externas (`install/remove/status`) funcionando no fluxo real de UI.
3. Modal, toast, barra de mensagem e i18n operando em runtime.
4. Terminal restaurado corretamente em saída normal e por sinal.
5. Suíte oficial sem falhas e checklist de paridade aprovado.

## E9 - Paridade funcional com linux-setup-legacy (release v1.0.0)
Objetivo: entregar a aplicação rodando fim a fim com comportamento equivalente ao `legacy`, pronta para tag `v1.0.0`.

### H9.1 - App shell em runtime real
- T9.1.1 Integrar loop principal de runtime no entrypoint da aplicação.
- T9.1.2 Renderizar layout base (background, header, footer e área central).
- T9.1.3 Garantir barra de mensagem inicial e cleanup terminal idempotente no fluxo completo.

### H9.2 - Menu principal e submenus em tela real
- T9.2.1 Conectar modelo de menu ao render da tela principal.
- T9.2.2 Implementar navegação completa (`up/down/enter/back/quit`) no app rodando.
- T9.2.3 Validar caminhos de submenu equivalentes aos fluxos do `legacy`.

### H9.3 - Fluxos de ações externas fim a fim
- T9.3.1 Ligar itens de menu ao `action_router` e ao `external_runner`.
- T9.3.2 Exibir retorno de `install/remove/status` no contexto correto da UI.
- T9.3.3 Garantir mapeamento de severidade e timeout no fluxo real.

### H9.4 - Modal e confirmação no fluxo real
- T9.4.1 Exibir modal de status após ações que exigem detalhe de retorno.
- T9.4.2 Exibir modal de confirmação em ações destrutivas/sensíveis.
- T9.4.3 Garantir bloqueio de fundo e foco correto enquanto modal está ativo.

### H9.5 - Toast e barra de mensagem operacional
- T9.5.1 Exibir toast para feedback curto de sucesso/erro/aviso.
- T9.5.2 Integrar barra de mensagem com estado contextual da tela ativa.
- T9.5.3 Garantir convivência visual de menu/modal/toast/barra sem artefatos.

### H9.6 - i18n em runtime com persistência
- T9.6.1 Disponibilizar troca de idioma PT/EN durante execução.
- T9.6.2 Atualizar textos renderizados após mudança de idioma.
- T9.6.3 Persistir idioma selecionado e validar comportamento pós-restart.

### H9.7 - Hardening de paridade e release candidate
- T9.7.1 Consolidar checklist `legacy vs next` com cobertura dos fluxos principais.
- T9.7.2 Corrigir lacunas de paridade identificadas na validação final.
- T9.7.3 Preparar pacote de release (`CHANGELOG`, validações finais e prontidão para tag `v1.0.0`).

Critério de saída E9:
- `linux-setup-next` funcionalmente equivalente ao `legacy` nos fluxos essenciais, com suíte oficial passando e pronto para release `v1.0.0`.
