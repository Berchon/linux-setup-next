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

I18N_LOCALE_PT["test.pt.only"]="Somente PT"
assert_eq "$(i18n_translate "test.pt.only")" "Somente PT" "missing key in current language should fallback to portuguese catalog"

assert_eq "$(i18n_translate "test.missing.key")" "test.missing.key" "missing key in all catalogs should fallback to key id"
assert_eq "$(i18n_translatef "test.missing.key" "ignored")" "test.missing.key" "formatted translation should fallback to key id too"

printf "PASS: i18n fallback tests\n"
