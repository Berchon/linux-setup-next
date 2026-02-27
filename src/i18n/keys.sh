#!/usr/bin/env bash

if [[ -z "${i18n_keys_module_loaded:-}" ]]; then
  i18n_keys_module_loaded=1

  readonly I18N_KEY_CONFIG_MENU_ROOT_LABEL="config.menu.root.label"
  readonly I18N_KEY_CONFIG_MENU_ROOT_DESC="config.menu.root.desc"
  readonly I18N_KEY_TOAST_CONFIG_SAVE_SUCCESS="toast.config.save.success"
  readonly I18N_KEY_TOAST_CONFIG_SAVE_ERROR="toast.config.save.error"
fi

i18n_keys_all() {
  printf '%s\n' \
    "${I18N_KEY_CONFIG_MENU_ROOT_LABEL}" \
    "${I18N_KEY_CONFIG_MENU_ROOT_DESC}" \
    "${I18N_KEY_TOAST_CONFIG_SAVE_SUCCESS}" \
    "${I18N_KEY_TOAST_CONFIG_SAVE_ERROR}"
}

i18n_key_exists() {
  local key="$1"
  local candidate=""

  while IFS= read -r candidate; do
    if [[ "${candidate}" == "${key}" ]]; then
      return 0
    fi
  done < <(i18n_keys_all)

  return 1
}
