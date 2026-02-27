#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=src/i18n/keys.sh
source "${TEST_ROOT}/src/i18n/keys.sh"

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  if [[ "${actual}" != "${expected}" ]]; then
    printf "FAIL: %s\nexpected: %q\nactual:   %q\n" "${message}" "${expected}" "${actual}" >&2
    exit 1
  fi
}

assert_true() {
  local message="$1"
  shift

  if ! "$@"; then
    printf "FAIL: %s\n" "${message}" >&2
    exit 1
  fi
}

mapfile -t all_keys < <(i18n_keys_all)
assert_eq "${#all_keys[@]}" "4" "key registry should expose all required keys"

assert_true "keys should include config menu root label" i18n_key_exists "${I18N_KEY_CONFIG_MENU_ROOT_LABEL}"
assert_true "keys should include config menu root description" i18n_key_exists "${I18N_KEY_CONFIG_MENU_ROOT_DESC}"
assert_true "keys should include success toast message key" i18n_key_exists "${I18N_KEY_TOAST_CONFIG_SAVE_SUCCESS}"
assert_true "keys should include error toast message key" i18n_key_exists "${I18N_KEY_TOAST_CONFIG_SAVE_ERROR}"

if i18n_key_exists "missing.key"; then
  printf "FAIL: unknown key should not be registered\n" >&2
  exit 1
fi

printf "PASS: i18n key registry tests\n"
