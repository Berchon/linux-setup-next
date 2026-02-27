#!/usr/bin/env bash

if [[ -z "${i18n_module_loaded:-}" ]]; then
  i18n_module_loaded=1

  readonly I18N_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  # shellcheck source=src/i18n/keys.sh
  source "${I18N_DIR}/keys.sh"
  # shellcheck source=src/i18n/locale_pt.sh
  source "${I18N_DIR}/locale_pt.sh"
  # shellcheck source=src/i18n/locale_en.sh
  source "${I18N_DIR}/locale_en.sh"

  declare -g i18n_current_language="en"
  declare -Ag i18n_catalog=()
fi

i18n_normalize_language() {
  local language="${1:-}"
  language="${language,,}"

  case "${language}" in
    pt|en)
      printf '%s\n' "${language}"
      ;;
    *)
      printf 'en\n'
      ;;
  esac
}

i18n_load_catalog() {
  local language="${1:-en}"
  language="$(i18n_normalize_language "${language}")"

  i18n_locale_pt_load
  i18n_locale_en_load

  i18n_catalog=()
  i18n_current_language="${language}"

  case "${language}" in
    pt)
      i18n_catalog=()
      for key in "${!I18N_LOCALE_PT[@]}"; do
        i18n_catalog["${key}"]="${I18N_LOCALE_PT[${key}]}"
      done
      ;;
    en)
      i18n_catalog=()
      for key in "${!I18N_LOCALE_EN[@]}"; do
        i18n_catalog["${key}"]="${I18N_LOCALE_EN[${key}]}"
      done
      ;;
  esac
}

i18n_translate() {
  local key="$1"

  if [[ -v "i18n_catalog[${key}]" ]]; then
    printf '%s\n' "${i18n_catalog[${key}]}"
    return 0
  fi

  if [[ -v "I18N_LOCALE_PT[${key}]" ]]; then
    printf '%s\n' "${I18N_LOCALE_PT[${key}]}"
    return 0
  fi

  printf '%s\n' "${key}"
  return 0
}

i18n_translatef() {
  local key="$1"
  shift
  local template=""

  template="$(i18n_translate "${key}")"
  printf -- "${template}\n" "$@"
}
