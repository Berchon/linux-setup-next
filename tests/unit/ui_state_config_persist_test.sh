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
# shellcheck source=src/state/menu_state.sh
source "${TEST_ROOT}/src/state/menu_state.sh"
# shellcheck source=src/components/menu.sh
source "${TEST_ROOT}/src/components/menu.sh"
# shellcheck source=src/state/config_menu_state.sh
source "${TEST_ROOT}/src/state/config_menu_state.sh"
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
theme.menu.fg=15
CFG

ui_state_reset
menu_state_reset
ui_state_boot_config "${test_config_file}"
config_menu_state_build_tree "settings" "Settings"

ui_state_apply_config_input "cfg_key_app_language" "l"
assert_eq "$(ui_state_get_config "app.language")" "en" "language should change in memory after keyboard input"
assert_eq "$(awk -F= '$1=="app.language" {print $2}' "${test_config_file}")" "en" "language should persist to config file automatically"

set +o errexit
ui_state_apply_config_input "cfg_key_app_language" "h" "${test_config_file}.missing-dir/ui.conf"
rc="$?"
set -o errexit
assert_eq "${rc}" "1" "persist should fail for invalid path override"
assert_eq "$(ui_state_get_config "app.language")" "en" "failed persist should rollback in-memory value"
assert_eq "$(awk -F= '$1=="app.language" {print $2}' "${test_config_file}")" "en" "failed persist should keep file unchanged"

rm -f "${test_config_file}"
printf "PASS: ui state config persist tests\n"
