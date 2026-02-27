#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=src/config/config_loader.sh
source "${TEST_ROOT}/src/config/config_loader.sh"
# shellcheck source=src/config/config_schema.sh
source "${TEST_ROOT}/src/config/config_schema.sh"
# shellcheck source=src/i18n/i18n.sh
source "${TEST_ROOT}/src/i18n/i18n.sh"
# shellcheck source=src/state/ui_state.sh
source "${TEST_ROOT}/src/state/ui_state.sh"

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  if [[ "${actual}" != "${expected}" ]]; then
    printf "FAIL: %s\nexpected: %q\nactual:   %q\n" "${message}" "${expected}" "${actual}" >&2
    exit 1
  fi
}

test_config_file="$(mktemp)"
cat > "${test_config_file}" <<'CFG'
app.language=pt
CFG

ui_state_reset
i18n_load_catalog "en"
ui_state_boot_config "${test_config_file}"
assert_eq "${i18n_current_language}" "pt" "boot should load catalog from app.language config"

cat > "${test_config_file}" <<'CFG'
app.language=en
CFG

ui_state_reset
ui_state_boot_config "${test_config_file}"
assert_eq "${i18n_current_language}" "en" "boot should support english catalog from config"

rm -f "${test_config_file}"
printf "PASS: ui state i18n boot language tests\n"
