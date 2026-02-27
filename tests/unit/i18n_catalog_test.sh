#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=src/i18n/i18n.sh
source "${TEST_ROOT}/src/i18n/i18n.sh"

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  if [[ "${actual}" != "${expected}" ]]; then
    printf "FAIL: %s\nexpected: %q\nactual:   %q\n" "${message}" "${expected}" "${actual}" >&2
    exit 1
  fi
}

i18n_load_catalog "en"
assert_eq "${i18n_current_language}" "en" "catalog should keep english language code"
assert_eq "$(i18n_translate "${I18N_KEY_CONFIG_MENU_ROOT_LABEL}")" "Settings" "english catalog should map settings label"
assert_eq "$(i18n_translatef "${I18N_KEY_TOAST_CONFIG_SAVE_SUCCESS}" "app.language" "en")" "Saved app.language=en" "english catalog should format success toast"

i18n_load_catalog "pt"
assert_eq "${i18n_current_language}" "pt" "catalog should keep portuguese language code"
assert_eq "$(i18n_translate "${I18N_KEY_CONFIG_MENU_ROOT_LABEL}")" "Configuracoes" "portuguese catalog should map settings label"
assert_eq "$(i18n_translatef "${I18N_KEY_TOAST_CONFIG_SAVE_ERROR}" "app.language")" "Falha ao salvar app.language" "portuguese catalog should format error toast"

assert_eq "$(i18n_normalize_language "EN")" "en" "language normalization should be case insensitive"
assert_eq "$(i18n_normalize_language "es")" "en" "unsupported language should fallback to english by default"

printf "PASS: i18n catalog tests\n"
