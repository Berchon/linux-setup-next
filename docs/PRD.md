# PRD - linux-setup-next

## 1. Informações do documento
- Produto: `linux-setup-next`
- Versão do documento: `v1.0`
- Idioma oficial desta fase: Português (Brasil)
- Data: 2026-02-25
- Status: Aprovado para iniciar implementação

## 2. Visão do produto
O `linux-setup-next` é uma aplicação TUI (Text User Interface) em Bash puro para configuração de sistema Linux. A aplicação deve oferecer navegação por teclado, execução de scripts externos de configuração, componentes visuais reutilizáveis e renderização incremental com foco em fluidez.

A V1 deve atingir o mesmo estágio funcional já validado na versão atual de referência, cobrindo:
- menu e submenus;
- modal de status/confirmação;
- notificações toast;
- i18n;
- integração com scripts externos.

## 3. Problema e oportunidade
### Problema atual
Uma implementação de framebuffer em Bash pode degradar a fluidez quando o pipeline redesenha/processa a tela inteira em cada frame.

### Oportunidade
Adotar um motor novo baseado em:
- componentes reutilizáveis;
- invalidação granular por região;
- diff por célula;
- atualização mínima (somente o que mudou).

## 4. Objetivos
### 4.1 Objetivos de produto
1. Entregar uma TUI estável e fluida em Bash puro.
2. Preservar paridade funcional com a versão atual de referência na V1.
3. Viabilizar evolução futura com componentes reutilizáveis (retângulo, sombra, modal, toast, menu etc.).
4. Permitir personalização da UI por arquivo de configuração `key=value` e por menu interno de configurações.

### 4.2 Objetivos técnicos
1. Redesenhar somente regiões/células alteradas.
2. Evitar parse de frame ANSI completo em todo evento.
3. Carregar configuração no boot e manter em memória durante o runtime.
4. Garantir fallback ASCII para compatibilidade ampla de terminal.

## 5. Fora de escopo (V1)
1. CI/CD no início do projeto.
2. Tema visual totalmente novo (V1 manterá visual padrão da versão atual de referência).
3. Suporte a Unicode avançado no render base.
4. Reescrita da lógica de negócio dos scripts externos além do necessário para integração.

## 6. Usuários e cenários
### 6.1 Perfil principal
Usuário técnico/intermediário em Linux que deseja executar configurações recorrentes por interface textual guiada.

### 6.2 Cenários principais
1. Configurar teclado externo (instalar, remover, verificar status).
2. Navegar por menus/submenus com teclado.
3. Receber feedback visual rápido (toast e status).
4. Alterar idioma da interface.
5. Alterar parâmetros visuais e comportamentais da TUI via menu de configurações.

## 7. Requisitos funcionais

## RF-001 - Execução em Bash puro
- A aplicação deve executar com Bash sem frameworks externos.
- Deve depender apenas de utilitários comuns em Linux, com fallback quando possível.

## RF-002 - Modo de tela e input interativo
- Deve usar alternate screen buffer durante a execução.
- Deve usar modo de input não-canônico sem echo durante a sessão.
- Deve restaurar terminal/cursor em qualquer saída (normal, erro, sinal).

## RF-003 - Renderização incremental
- O sistema deve recalcular e redesenhar apenas componentes/regiões alterados.
- Eventos simples (ex.: mudança de seleção no menu sem scroll) não devem causar redraw completo da tela.

## RF-004 - Componentização visual
- Deve existir biblioteca de componentes reutilizáveis com API clara.
- Componentes mínimos da V1:
  - `Rectangle`
  - `Shadow`
  - `Panel`
  - `Menu`
  - `Modal`
  - `Toast`
  - `Header`
  - `Footer`

## RF-005 - Composição de componentes
- Componentes complexos devem reaproveitar componentes base.
- Exemplo obrigatório: `Toast` deve usar `Rectangle` (com opção de sombra) + texto.

## RF-006 - Configuração de tema e comportamento
- Deve existir arquivo em `config/` na raiz do projeto com formato `key=value`.
- A configuração deve ser carregada no startup e mantida em memória.
- Não pode haver leitura de arquivo de configuração a cada render.

## RF-007 - Menu de configurações da TUI
- Deve existir submenu para ajustar configurações da própria interface.
- Alterações devem ser salvas automaticamente.
- Cada persistência deve emitir toast com sucesso/falha.

## RF-008 - Navegação e menu hierárquico
- Navegação por teclado (setas, Enter, Esc, Q).
- Submenus devem abrir/fechar sem regressão de usabilidade.
- Deve haver item de saída do aplicativo.

## RF-009 - Modal e diálogo
- Modal de status e modal de confirmação com bloqueio de navegação de fundo.
- Teclas aceitas em confirmação devem ser restritas ao fluxo esperado.

## RF-010 - Toast
- Deve suportar severidade, fila, timeout e renderização não intrusiva.
- Deve suportar configuração de cores e duração via `config`.

## RF-011 - Integração com scripts externos
- Deve executar ações não interativas (`install/remove/status`) com timeout.
- Deve sanitizar saída para apresentação na UI.
- Deve tratar erro, timeout e ausência de dependências com mensagens claras.

## RF-012 - Internacionalização (i18n)
- Deve suportar PT-BR e EN na V1.
- Troca de idioma deve poder ser feita no menu.
- Persistência de idioma deve sobreviver entre execuções.

## RF-013 - Fallback ASCII
- Render base deve usar conjunto ASCII-safe.
- Deve haver fallback configurável para bordas, ícones e elementos visuais.

## 8. Requisitos não funcionais

## RNF-001 - Fluidez
- Interações comuns devem manter sensação de resposta imediata.
- Orçamento de referência:
  - evento simples (mudar seleção sem scroll): alvo de processamento <= 16 ms em terminal 80x24 em máquina de referência;
  - evento médio (abrir submenu/modal): alvo <= 33 ms.

## RNF-002 - Compatibilidade
- Compatível com distribuições Linux amplamente usadas e hardware antigo.
- Degradação graciosa quando recursos opcionais não estiverem disponíveis.

## RNF-003 - Confiabilidade
- Cleanup idempotente em todos os caminhos de saída.
- Sem deixar terminal em estado inconsistente após falha/sinal.

## RNF-004 - Manutenibilidade
- Nomes de variáveis/funções/componentes em inglês.
- Código modular e contratos explícitos por módulo.

## RNF-005 - Documentação
- Toda documentação da fase de desenvolvimento em PT-BR.
- Escrita assertiva, consistente e tecnicamente correta.

## 9. Requisitos de configuração (V1)
Chaves iniciais obrigatórias no arquivo `config/ui.conf`:
- `theme.wallpaper.enabled`
- `theme.wallpaper.fg`
- `theme.wallpaper.bg`
- `theme.menu.fg`
- `theme.menu.bg`
- `theme.menu.border_style` (`none|single|double`)
- `theme.menu.shadow.enabled`
- `theme.modal.fg`
- `theme.modal.bg`
- `theme.modal.border_style`
- `theme.modal.shadow.enabled`
- `theme.toast.fg`
- `theme.toast.bg`
- `theme.toast.border_style`
- `theme.toast.shadow.enabled`
- `theme.toast.ttl_ms`
- `theme.header.fg`
- `theme.header.bg`
- `theme.footer.fg`
- `theme.footer.bg`
- `app.language` (`pt|en`)

## 10. Critérios de aceite da V1
1. Paridade funcional com a versão atual de referência para menu, modal, toast, i18n e scripts externos.
2. Configurações da UI alteráveis por menu e persistidas automaticamente com toast de resultado.
3. Renderização incremental validada por testes (sem redraw full em eventos simples).
4. Sem dependência de Unicode para funcionamento base.
5. Documentação e plano de testes completos em PT-BR.

## 11. Métricas de sucesso
1. Percentual de interações simples que atualizam somente regiões alteradas: alvo >= 95%.
2. Regressões funcionais em fluxos principais: 0 bloqueantes.
3. Falhas de restauração de terminal em testes de saída/sinal: 0.
4. Cobertura de cenários críticos definidos no plano de testes: 100%.

## 12. Riscos e mitigação
1. Risco: Bash limitar throughput de render.
   - Mitigação: diff por célula, dirty regions e minimização de SGR/cursor moves.
2. Risco: variação entre terminais/emuladores.
   - Mitigação: perfil ASCII-safe e testes em matriz de terminais.
3. Risco: crescimento de complexidade com componentes.
   - Mitigação: contratos de API e regras de composição estritas.

## 13. Dependências
1. Bash e utilitários base de sistema.
2. Ferramentas opcionais específicas de recursos (ex.: teclado externo via X11).
3. Ambiente de terminal com suporte ANSI básico.

## 14. Premissas
1. O projeto não incluirá CI na fase inicial.
2. A branch `main` do novo repositório será protegida e com merge via PR.
3. O visual padrão inicial seguirá o padrão já validado na versão atual de referência.

## 15. Baseline técnico aprovado
### 15.1 Bash
1. Versão mínima oficial da V1: `>= 4.0`.
2. Faixa alvo validada em testes: Bash 4.x e 5.x.

### 15.2 Terminal
1. `xterm-256color` é fortemente recomendado, mas não obrigatório.
2. A aplicação não deve bloquear por nome de `TERM`; deve validar capacidades.
3. Capacidades mínimas para operação:
   - posicionamento de cursor;
   - limpeza de tela;
   - ocultar/mostrar cursor;
   - entrada não-canônica e sem echo.
4. Alternate screen buffer deve ser usado quando disponível.

### 15.3 Cores e fallback
1. Perfil base obrigatório: 16 cores.
2. Se `tput colors >= 256`, habilitar paleta 256 automaticamente.
3. Truecolor (`*-direct`) é opcional, sempre com fallback automático.
4. Fallback ASCII permanece obrigatório para garantir robustez.
