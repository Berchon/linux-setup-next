#!/usr/bin/env bash

if [[ -z "${i18n_locale_pt_module_loaded:-}" ]]; then
  i18n_locale_pt_module_loaded=1
  declare -gA I18N_LOCALE_PT=()
fi

i18n_locale_pt_load() {
  I18N_LOCALE_PT["${I18N_KEY_CONFIG_MENU_ROOT_LABEL:-config.menu.root.label}"]="Configuracoes"
  I18N_LOCALE_PT["${I18N_KEY_CONFIG_MENU_ROOT_DESC:-config.menu.root.desc}"]="Ajustes da interface"
  I18N_LOCALE_PT["${I18N_KEY_TOAST_CONFIG_SAVE_SUCCESS:-toast.config.save.success}"]="Salvo %s=%s"
  I18N_LOCALE_PT["${I18N_KEY_TOAST_CONFIG_SAVE_ERROR:-toast.config.save.error}"]="Falha ao salvar %s"
}
