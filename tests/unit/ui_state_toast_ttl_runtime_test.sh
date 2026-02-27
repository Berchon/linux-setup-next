#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=src/config/config_loader.sh
source "${TEST_ROOT}/src/config/config_loader.sh"
# shellcheck source=src/config/config_schema.sh
source "${TEST_ROOT}/src/config/config_schema.sh"
# shellcheck source=src/config/config_store.sh
source "${TEST_ROOT}/src/config/config_store.sh"
# shellcheck source=src/config/theme_config.sh
source "${TEST_ROOT}/src/config/theme_config.sh"
# shellcheck source=src/state/menu_state.sh
source "${TEST_ROOT}/src/state/menu_state.sh"
# shellcheck source=src/components/menu.sh
source "${TEST_ROOT}/src/components/menu.sh"
# shellcheck source=src/state/config_menu_state.sh
source "${TEST_ROOT}/src/state/config_menu_state.sh"
# shellcheck source=src/state/toast_state.sh
source "${TEST_ROOT}/src/state/toast_state.sh"
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
theme.toast.ttl_ms=1900
app.language=pt
CFG

toast_state_reset
ui_state_reset
menu_state_reset
ui_state_boot_config "${test_config_file}"
assert_eq "$(toast_state_get_default_ttl_ms)" "1900" "boot should apply toast ttl from config to runtime"

config_menu_state_build_tree "settings" "Settings"
ui_state_apply_config_input "cfg_key_theme_toast_ttl_ms" "l"
assert_eq "$(ui_state_get_config "theme.toast.ttl_ms")" "1901" "menu edit should update ttl in memory"
assert_eq "$(toast_state_get_default_ttl_ms)" "1901" "menu edit should refresh runtime toast ttl"

rm -f "${test_config_file}"
printf "PASS: ui state toast ttl runtime tests\n"
