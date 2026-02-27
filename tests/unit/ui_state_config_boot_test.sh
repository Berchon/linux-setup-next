#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=src/config/config_loader.sh
source "${TEST_ROOT}/src/config/config_loader.sh"
# shellcheck source=src/config/config_schema.sh
source "${TEST_ROOT}/src/config/config_schema.sh"
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

config_file="$(mktemp)"
cat > "${config_file}" <<'CFG'
app.language=en
theme.menu.fg=42
CFG

ui_state_reset
ui_state_boot_config "${config_file}"
assert_eq "${ui_state_config_loaded}" "1" "config should be marked as loaded after first boot"
assert_eq "${ui_state_config_load_count}" "1" "boot should load config once"
assert_eq "$(ui_state_get_config "app.language" "pt")" "en" "state should expose loaded values"
assert_eq "$(ui_state_get_config "theme.menu.fg" "15")" "42" "state should expose numeric config values"

cat > "${config_file}" <<'CFG'
app.language=pt
theme.menu.fg=99
CFG

ui_state_boot_config "${config_file}"
assert_eq "${ui_state_config_load_count}" "1" "second boot should not reload config"
assert_eq "$(ui_state_get_config "app.language" "pt")" "en" "memory state should keep first loaded value"
assert_eq "$(ui_state_get_config "theme.menu.fg" "15")" "42" "memory state should not be overwritten after first boot"

missing_path="${config_file}.missing"
ui_state_reset
set +o errexit
ui_state_boot_config "${missing_path}"
rc="$?"
set -o errexit
assert_eq "${rc}" "1" "boot should fail for missing explicit config"
assert_eq "${ui_state_config_loaded}" "0" "failed boot should not mark config as loaded"

rm -f "${config_file}"
printf "PASS: ui state config boot tests\n"
