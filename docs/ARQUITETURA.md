# Arquitetura Técnica - linux-setup-next

## 1. Objetivo arquitetural
Definir um motor TUI em Bash puro baseado em componentes reutilizáveis e renderização incremental, com atualização mínima de tela e foco em compatibilidade Linux.

## 2. Princípios
1. Atualizar apenas o necessário.
2. Componentes composáveis e independentes.
3. Estado explícito e previsível.
4. Fallback ASCII como padrão seguro.
5. Separação clara entre UI e lógica de negócio.

## 3. Estrutura proposta de diretórios
```text
linux-setup-next/
  config/
    ui.conf
    ui.conf.example
  docs/
  src/
    app/
      main.sh
      bootstrap.sh
    core/
      terminal.sh
      event_loop.sh
      clock.sh
      logger.sh
    render/
      cell_buffer.sh
      diff_renderer.sh
      dirty_regions.sh
      styles.sh
      ascii_fallback.sh
    components/
      rectangle.sh
      shadow.sh
      panel.sh
      header.sh
      footer.sh
      menu.sh
      modal.sh
      toast.sh
    state/
      app_state.sh
      ui_state.sh
      menu_state.sh
      toast_state.sh
      modal_state.sh
    config/
      config_loader.sh
      config_store.sh
      config_schema.sh
    i18n/
      i18n.sh
      locale_pt.sh
      locale_en.sh
    actions/
      external_runner.sh
      action_router.sh
  tests/
    unit/
    component/
    integration/
    e2e/
    perf/
```

## 4. Modelo de runtime
## 4.1 Inicialização
1. Carregar configuração (`config/ui.conf`) em memória.
2. Validar schema e aplicar defaults.
3. Inicializar i18n.
4. Entrar em alternate screen.
5. Ativar modo de input não-canônico sem echo.
6. Inicializar buffers de render e estado global.
7. Fazer primeiro render completo.

## 4.2 Loop principal
1. Ler evento de teclado (não bloqueante).
2. Traduzir evento para ação de domínio.
3. Atualizar estado apenas do módulo afetado.
4. Marcar regiões sujas (`dirty regions`).
5. Re-renderizar somente componentes afetados no back buffer.
6. Gerar diff entre `front buffer` e `back buffer`.
7. Emitir ANSI mínimo necessário.
8. Trocar buffers (`swap`).

## 4.3 Encerramento
1. Sair do alternate screen.
2. Restaurar cursor e `stty` original.
3. Garantir cleanup idempotente em saídas normais e sinais.

## 5. Modelo de renderização
## 5.1 Estruturas de dados
- `Cell`: `char`, `fg`, `bg`, `bold`.
- `Rect`: `x`, `y`, `width`, `height`.
- `Style`: atributos visuais normalizados.

Dois buffers em memória:
- `front_buffer`: estado atualmente exibido.
- `back_buffer`: estado do próximo frame.

## 5.2 Pipeline de render
1. Limpar somente regiões sujas no `back_buffer`.
2. Executar render dos componentes afetados por ordem de z-index.
3. Comparar `back_buffer` x `front_buffer` por célula dentro das regiões sujas.
4. Agrupar runs contíguos com mesmo estilo para reduzir ANSI.
5. Emitir sequência ANSI mínima.

## 5.3 Política de invalidação
Eventos e granularidade mínima esperada:
- mover seleção no menu sem scroll: invalidar 2 linhas (linha anterior e nova linha selecionada);
- scroll do menu: invalidar viewport do menu;
- abrir modal: invalidar retângulo do modal + regiões sobrepostas;
- atualizar relógio: invalidar apenas área de relógio;
- toast com animação: invalidar caixa do toast e trilha de limpeza;
- resize: invalidar tela inteira.

## 6. Contrato de componentes
Todo componente deve expor:
1. `component_measure(state, config)` -> `Rect`/dimensões.
2. `component_render(buffer, state, config, rect)`.
3. `component_handle_event(state, event)` (quando aplicável).
4. `component_get_dirty_regions(prev_state, next_state)`.

## 6.1 Componentes base
- `Rectangle`: preenchimento, borda e título opcional.
- `Shadow`: desenha sombra com offset e clipping.
- `Panel`: composição de `Rectangle` + conteúdo.

## 6.2 Componentes compostos
- `Menu`: usa `Panel` + render de linhas + estado de seleção.
- `Modal`: usa `Panel`, botões e bloqueio de fundo.
- `Toast`: usa `Panel`, severidade, timeout e fila.

## 7. Configuração e persistência
## 7.1 Carregamento
- Ler arquivo `config/ui.conf` apenas no startup.
- Armazenar tudo em memória em estrutura de acesso O(1).

## 7.2 Atualização em runtime
- Mudanças via menu de configurações alteram estado em memória.
- Persistência imediata em arquivo.
- Mostrar toast de sucesso/falha.

## 7.3 Validação
- `config_schema.sh` define tipo, faixa válida e default de cada chave.
- Valor inválido deve cair em default e registrar aviso.

## 8. i18n
1. Chaves de texto centralizadas.
2. Dicionários separados por idioma.
3. UI em PT-BR e EN na V1.
4. Persistência de idioma via configuração.

## 9. Integração com scripts externos
## 9.1 Contrato de ação
- `install`
- `remove`
- `status`

## 9.2 Regras
1. Execução não interativa com timeout.
2. Captura de `stdout/stderr`.
3. Sanitização para apresentação na UI.
4. Mapeamento claro de códigos de saída.

## 10. Compatibilidade
1. ASCII-safe como padrão visual.
2. ANSI básico para controle de cursor/cores.
3. Degradação graciosa quando capacidades opcionais não existirem.
4. Não bloquear por nome de `TERM`; validar capacidades de terminal.
5. `xterm-256color` é recomendado, não obrigatório.
6. Perfil base de cor: 16 cores; habilitar 256 cores automaticamente quando disponíveis.
7. Truecolor é opcional, sempre com fallback.

## 11. Observabilidade e diagnóstico
1. Modo debug opcional por variável de ambiente.
2. Métricas básicas:
- tempo por frame;
- quantidade de células atualizadas;
- quantidade de regiões sujas por evento.
3. Logs legíveis para troubleshooting sem poluir UI principal.

## 12. Segurança e robustez
1. Evitar `eval` sem necessidade.
2. Quoting rigoroso de variáveis.
3. Tratamento de erro explícito em operações de I/O.
4. Cleanup garantido por `trap` e guardas de idempotência.

## 13. Estratégia de implementação por precedência
1. Núcleo de terminal e loop.
2. Buffers e diff renderer.
3. Componentes base (`Rectangle`, `Shadow`, `Panel`).
4. Componentes compostos (`Menu`, `Modal`, `Toast`).
5. Integração com ações externas.
6. Menu de configurações e persistência.
7. i18n e refinamentos.

## 14. Anti-padrões proibidos
1. Redraw completo em eventos simples.
2. Parse ANSI de frame completo em todo loop.
3. Leitura de arquivo de configuração durante render.
4. Acoplamento direto entre componente visual e script externo.
