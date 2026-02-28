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
# shellcheck source=src/components/menu.sh
source "${TEST_ROOT}/src/components/menu.sh"
# shellcheck source=src/state/menu_state.sh
source "${TEST_ROOT}/src/state/menu_state.sh"
# shellcheck source=src/state/config_menu_state.sh
source "${TEST_ROOT}/src/state/config_menu_state.sh"
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
menu_state_reset
i18n_load_catalog "en"
ui_state_boot_config "${test_config_file}"
config_menu_state_build_tree "settings" "Settings"
assert_eq "${i18n_current_language}" "pt" "boot should start with portuguese catalog"

ui_state_apply_config_input "cfg_key_app_language" "l"
assert_eq "$(ui_state_get_config "app.language")" "en" "language value should update in config state"
assert_eq "${i18n_current_language}" "en" "runtime catalog should switch to english after menu edit"

ui_state_apply_config_input "cfg_key_app_language" "h"
assert_eq "$(ui_state_get_config "app.language")" "pt" "language value should support switching back"
assert_eq "${i18n_current_language}" "pt" "runtime catalog should switch back to portuguese"

rm -f "${test_config_file}"
printf "PASS: ui state i18n runtime switch tests\n"
