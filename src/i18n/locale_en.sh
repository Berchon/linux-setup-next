#!/usr/bin/env bash

if [[ -z "${i18n_locale_en_module_loaded:-}" ]]; then
  i18n_locale_en_module_loaded=1
  declare -gA I18N_LOCALE_EN=()
fi

i18n_locale_en_load() {
  I18N_LOCALE_EN["${I18N_KEY_CONFIG_MENU_ROOT_LABEL:-config.menu.root.label}"]="Settings"
  I18N_LOCALE_EN["${I18N_KEY_CONFIG_MENU_ROOT_DESC:-config.menu.root.desc}"]="UI settings"
  I18N_LOCALE_EN["${I18N_KEY_TOAST_CONFIG_SAVE_SUCCESS:-toast.config.save.success}"]="Saved %s=%s"
  I18N_LOCALE_EN["${I18N_KEY_TOAST_CONFIG_SAVE_ERROR:-toast.config.save.error}"]="Failed to save %s"
}
