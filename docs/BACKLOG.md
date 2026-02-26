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

## 5. Definição de pronto por história
1. Código implementado e revisado.
2. Testes automatizados relevantes passando.
3. Teste manual do fluxo validado.
4. Documentação atualizada.
5. `CHANGELOG.md` atualizado com a mudança da história.
6. Aprovado por você antes de avançar.
