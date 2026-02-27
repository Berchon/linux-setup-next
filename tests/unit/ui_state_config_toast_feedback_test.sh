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
# shellcheck source=src/state/toast_state.sh
source "${TEST_ROOT}/src/state/toast_state.sh"
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
CFG

ui_state_reset
menu_state_reset
toast_state_reset
ui_state_boot_config "${test_config_file}"
config_menu_state_build_tree "settings" "Settings"

ui_state_apply_config_input "cfg_key_app_language" "l"
success_toast="$(toast_state_get_visible 0)"
assert_eq "${success_toast%%|*}" "success" "successful persist should enqueue success toast"

if [[ "${success_toast}" != *"Saved app.language=en"* ]]; then
  printf "FAIL: success toast should mention persisted key and value\nactual: %q\n" "${success_toast}" >&2
  exit 1
fi

toast_state_reset
set +o errexit
ui_state_apply_config_input "cfg_key_app_language" "h" "${test_config_file}.missing-dir/ui.conf"
rc="$?"
set -o errexit
assert_eq "${rc}" "1" "persist failure should return non-zero"
error_toast="$(toast_state_get_visible 0)"
assert_eq "${error_toast%%|*}" "error" "failed persist should enqueue error toast"

if [[ "${error_toast}" != *"Failed to save app.language"* ]]; then
  printf "FAIL: error toast should mention failed key\nactual: %q\n" "${error_toast}" >&2
  exit 1
fi

rm -f "${test_config_file}"
printf "PASS: ui state config toast feedback tests\n"
